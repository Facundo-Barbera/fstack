#!/usr/bin/env bash
# Read-only helpers for fstack:ui: nothing written to the repo (diff uses one temp dir, removed on exit).
# Needs git, grep, awk; cvd also needs python3.
#   inventory          Tailwind config and theme colours, CSS variables, components.json, component folders, prototypes
#   diff [base]        raw colours/sizes and default-palette classes added since base (exit 1 if any)
#   cvd BG HEX HEX...  colour-blind distance (deutan/protan/tritan, Machado 2009) and WCAG contrast vs BG
set -uo pipefail
cmd=${1:-}; shift || true

# Generated and vendored trees are never the repo's design system.
# An empty list is a normal answer, so the grep must not fail the pipeline under pipefail.
ls_files() { git ls-files "$@" 2>/dev/null | { grep -vE '(^|/)(node_modules|dist|build|vendor)/' || true; }; }
files() { ls_files -- "$@"; }

# Colour names the repo's own theme defines: Tailwind v4 `--color-NAME:` in CSS and keys in a
# v3 tailwind.config. A class built on one of these is a token, even if it shadows a default name.
theme_names() {
  files '*.css' '*.scss' | while IFS= read -r f; do cat "$f"; done 2>/dev/null \
    | grep -oE -- '--color-[a-z0-9-]+[[:space:]]*:' | sed -E 's/^--color-//; s/[[:space:]]*:$//'
  files 'tailwind.config.*' '*/tailwind.config.*' | while IFS= read -r f; do cat "$f"; done 2>/dev/null \
    | sed -nE "s/^[[:space:]]*['\"]?([a-z][a-z0-9-]*)['\"]?[[:space:]]*:.*/\1/p"
}

PAL='red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone|white|black'
PFX='bg|text|border|border-[xytrbls]|ring|ring-offset|outline|divide|fill|stroke|from|via|to|shadow|accent|caret|decoration|placeholder'
# One ERE (POSIX, so BWK awk on macOS reads it too): default-palette class, arbitrary-value
# class with a raw colour or px, bare hex, colour function, bare px.
RE="($PFX)-($PAL)(-[0-9][0-9][0-9]?)?(/([0-9]+|\\[[^] ]+\\]))?|[a-z][a-z0-9-]*-\\[[^] ]*(#|px|rgba?\\(|hsla?\\(|okl(ch|ab)\\()[^] ]*\\]|#[0-9a-fA-F]{3,8}|(rgba?|hsla?|oklch|oklab)\\(|[0-9][0-9.]*px"

# Prints "file<TAB>token<TAB>line" for every raw value on the lines of a "+++ file / +line" stream.
# Comments and custom-property definitions (`--x: #fff`, i.e. defining a token) are skipped.
extract() {
  # Through ENVIRON: awk -v would eat the backslashes in the regex.
  RE=$RE awk '
    BEGIN { re = ENVIRON["RE"] }
    /^\+\+\+ / { f = substr($0, 7); next }
    /^\+/ {
      line = substr($0, 2); s = line
      if (s ~ /^[[:space:]]*(\/\/|\/\*|\*|\{\/\*|<!--)/ || s ~ /^[[:space:]]*--[A-Za-z0-9-]+[[:space:]]*:/) next
      gsub(/\/\*.*\*\//, "", s); sub(/[[:space:]]\/\/.*$/, "", s)
      while (match(s, re)) {
        tok = substr(s, RSTART, RLENGTH)
        pre = RSTART > 1 ? substr(s, RSTART - 1, 1) : ""
        post = substr(s, RSTART + RLENGTH, 1)
        s = substr(s, RSTART + RLENGTH)
        # Whole tokens only: not the middle of a word, a longer hex or a longer shade.
        if (pre ~ /[A-Za-z0-9_]/ || post ~ /[A-Za-z0-9_]/) continue
        print f "\t" tok "\t" line
      }
    }'
}

case $cmd in
inventory)
  echo "## token / theme files"
  files '*.css' '*.scss' '*.ts' '*.js' '*.mjs' '*.cjs' '*.json' | grep -iE 'token|theme|tailwind|palette|colou?rs?\.|design' | head -30
  echo "## shadcn components.json (registry components: use the shadcn MCP if the session has it)"
  files '*components.json' | grep -E '(^|/)components\.json$' | while IFS= read -r f; do
    echo "$f"; grep -E '"(style|baseColor|cssVariables|css|components|ui|registries)"' "$f" | head -8
  done
  echo "## files defining CSS variables"
  files '*.css' '*.scss' | while IFS= read -r f; do grep -lE '(^|[{;[:space:]])--[a-z0-9-]+[[:space:]]*:' "$f"; done 2>/dev/null | head -20
  echo "## theme colour names (use these as bg-NAME, text-NAME...)"
  theme_names | LC_ALL=C sort -u | tr '\n' ' ' | fold -s -w 100; echo
  echo "## component folders (by file count)"
  files '*.tsx' '*.jsx' '*.vue' '*.svelte' | grep -iE '(^|/)(components?|ui|primitives)/' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -15
  echo "## prototype / story routes"
  files | grep -iE 'stor(y|ies)|proto|playground|sandbox|preview' | head -15
  exit 0
  ;;
diff)
  base=${1:-}
  if [ -z "$base" ]; then
    for ref in origin/HEAD origin/main main origin/master master; do
      base=$(git merge-base HEAD "$ref" 2>/dev/null) && break
    done
  fi
  [ -n "$base" ] || base=$(git rev-parse HEAD~1) || exit 2
  skip=(':!*token*' ':!*theme*' ':!*tailwind.config.*' ':!*.lock' ':!*lock.json' ':!*lock.yaml' ':!*.svg' ':!*.md' ':!*.snap')
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/ui-check.XXXXXX") || exit 2
  trap 'rm -rf "$tmp"' EXIT
  # Repo convention: classes already used at base and colours the theme defines are not flagged.
  git grep -h -I -E "$RE" "$base" -- . "${skip[@]}" 2>/dev/null | sed 's/^/+/' | extract | cut -f2 \
    | grep -E '^[a-z].*-' | LC_ALL=C sort -u >"$tmp/used"
  theme_names | LC_ALL=C sort -u >"$tmp/theme"
  # Uncommitted and untracked files count too: workers run this before committing.
  {
    git diff -U0 "$base" -- . "${skip[@]}"
    ls_files --others --exclude-standard -- . "${skip[@]}" | while IFS= read -r f; do echo "+++ b/$f"; grep -I -h '' "$f" | sed 's/^/+/'; done
  } | extract | awk -F'\t' -v pfx="^($PFX)-" -v used="$tmp/used" -v theme="$tmp/theme" '
    BEGIN { while ((getline l < used) > 0) u[l] = 1; while ((getline l < theme) > 0) t[l] = 1 }
    {
      tok = $2
      if (tok ~ /^[a-z].*-/) {
        if (tok in u) next
        name = tok; sub(/\/.*/, "", name)
        if (name !~ /\[/ && sub(pfx, "", name)) { fam = name; sub(/-[0-9]+$/, "", fam); if ((name in t) || (fam in t)) next }
      }
      line = $3; sub(/^[[:space:]]+/, "", line); n++; print $1 ": " tok "    " substr(line, 1, 140)
    }
    END { exit (n > 0) }' >"$tmp/out"
  rc=$?
  if [ "$rc" = 0 ]; then echo "OK: no raw colours, sizes or default-palette classes added since $base"; exit 0; fi
  cat "$tmp/out"
  echo "^ raw values added since $base: use a theme token, or justify each in the report"
  exit 1
  ;;
cvd)
  command -v python3 >/dev/null || { echo "cvd needs python3 (not found): report CVD as NOT VERIFIED" >&2; exit 2; }
  python3 - "$@" <<'PY'
import sys, itertools, math, re
M={'deutan':[[.367322,.860646,-.227968],[.280085,.672501,.047413],[-.01182,.04294,.968881]],
   'protan':[[.152286,1.052583,-.204868],[.114503,.786281,.099216],[-.003882,-.048116,1.051998]],
   'tritan':[[1.255528,-.076749,-.178779],[-.078411,.930809,.147602],[.004733,.691367,.3039]]}
def rgb(h):
    h=h.lstrip('#')
    if not re.fullmatch(r'[0-9a-fA-F]{3}|[0-9a-fA-F]{6}',h): sys.exit(f"not a hex colour: #{h}")
    if len(h)==3: h=''.join(c*2 for c in h)
    return [int(h[i:i+2],16)/255 for i in (0,2,4)]
lin=lambda c:c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def lab(l):
    X=.4124*l[0]+.3576*l[1]+.1805*l[2];Y=.2126*l[0]+.7152*l[1]+.0722*l[2];Z=.0193*l[0]+.1192*l[1]+.9505*l[2]
    f=lambda t:t**(1/3) if t>.008856 else 7.787*t+16/116
    x,y,z=f(X/.9505),f(Y),f(Z/1.089);return (116*y-16,500*(x-y),200*(y-z))
# Machado matrices act on linear RGB; ΔE is CIE76 on the simulated colours.
sim=lambda l,m:[max(0,min(1,sum(m[r][k]*l[k] for k in range(3)))) for r in range(3)]
lum=lambda l:.2126*l[0]+.7152*l[1]+.0722*l[2]
if len(sys.argv)<4: sys.exit("usage: cvd BG HEX HEX...  (background first, then at least two colours)")
bg,*cs=sys.argv[1:]
L={c:[lin(v) for v in rgb(c)] for c in [bg]+cs}
bad=0
for c in cs:
    a,b=sorted((lum(L[c]),lum(L[bg])));r=(b+.05)/(a+.05)
    w="  <- under 3 (fails even for icons)" if r<3 else "  <- under 4.5 (fails for text)" if r<4.5 else ""
    bad+=bool(w);print(f"{c} vs bg {bg}: contrast {r:.2f}{w}")
for a,b in itertools.combinations(cs,2):
    d={n:math.dist(lab(sim(L[a],m)),lab(sim(L[b],m))) for n,m in M.items()}
    w="  <- under 20" if min(d.values())<20 else ""
    bad+=bool(w);print(f"{a}~{b}: "+" ".join(f"{n} {v:.0f}" for n,v in d.items())+w)
sys.exit(1 if bad else 0)
PY
  ;;
*) sed -n 2,6p "$0"; exit 2 ;;
esac
