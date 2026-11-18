#!/usr/bin/env bash
# Read-only helpers for fstack:ui. Writes nothing; needs git and python3.
#   inventory          token files, theme config, component folders, prototype routes
#   diff [base]        raw colours/sizes added since base (default: merge-base with origin/HEAD)
#   cvd BG HEX HEX...  colour-blind distance (deutan/protan/tritan, Machado 2009) and WCAG contrast vs BG
set -euo pipefail
cmd=${1:-}; shift || true
files() { git ls-files -- "$@" 2>/dev/null | grep -v -E '(^|/)(node_modules|dist|build|vendor)/' || true; }
case $cmd in
inventory)
  set +eo pipefail  # an empty section is a finding, not an error
  echo "## token / theme files"
  files '*.css' '*.scss' '*.ts' '*.js' '*.json' | grep -iE 'token|theme|tailwind|palette|colors?\.|design' | head -30
  echo "## files defining CSS variables"
  files '*.css' '*.scss' | xargs -r grep -lE '(^|[{;[:space:]])--[a-z0-9-]+[[:space:]]*:' 2>/dev/null | head -20
  echo "## component folders (by file count)"
  files '*.tsx' '*.jsx' '*.vue' '*.svelte' | grep -iE 'components?/|ui/|primitives/' | xargs -r -n1 dirname | sort | uniq -c | sort -rn | head -15
  echo "## prototype / story routes"
  files | grep -iE 'stor(y|ies)|proto|playground|sandbox|preview' | head -15
  ;;
diff)
  base=${1:-$(git merge-base HEAD origin/HEAD 2>/dev/null || git rev-parse HEAD~1)}
  re='#[0-9a-fA-F]{3,8}\b|\b(rgb|rgba|hsl|hsla|oklch|oklab)\(|\b[0-9.]+px\b|\b(bg|text|border|ring|fill|stroke|from|to)-(red|green|blue|yellow|amber|emerald|rose|orange|lime|sky|indigo|violet|purple|pink|teal|cyan|slate|gray|zinc|neutral|stone)-[0-9]{2,3}\b|-\[#'
  git diff -U0 "$base" -- . ':!*token*' ':!*theme*' ':!*.lock' ':!*lock.json' ':!*.svg' ':!*.md' \
    | awk '/^\+\+\+ /{f=substr($0,7)} /^\+[^+]/{print f": "substr($0,2)}' \
    | grep -E "$re" && { echo "^ raw values added: justify each or move to tokens"; exit 1; } \
    || echo "OK: no raw colours or sizes added since $base"
  ;;
cvd)
  python3 - "$@" <<'PY'
import sys, itertools, math
M={'deutan':[[.367322,.860646,-.227968],[.280085,.672501,.047413],[-.01182,.04294,.968881]],
   'protan':[[.152286,1.052583,-.204868],[.114503,.786281,.099216],[-.003882,-.048116,1.051998]],
   'tritan':[[1.255528,-.076749,-.178779],[-.078411,.930809,.147602],[.004733,.691367,.3039]]}
rgb=lambda h:[int(h.lstrip('#')[i:i+2],16)/255 for i in (0,2,4)]
lin=lambda c:c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def lab(l):
    X=.4124*l[0]+.3576*l[1]+.1805*l[2];Y=.2126*l[0]+.7152*l[1]+.0722*l[2];Z=.0193*l[0]+.1192*l[1]+.9505*l[2]
    f=lambda t:t**(1/3) if t>.008856 else 7.787*t+16/116
    x,y,z=f(X/.9505),f(Y),f(Z/1.089);return (116*y-16,500*(x-y),200*(y-z))
sim=lambda l,m:[max(0,min(1,sum(m[r][k]*l[k] for k in range(3)))) for r in range(3)]
lum=lambda l:.2126*l[0]+.7152*l[1]+.0722*l[2]
bg,*cs=sys.argv[1:]
if not cs: sys.exit("usage: cvd BG HEX HEX...")
L={c:[lin(v) for v in rgb(c)] for c in [bg]+cs}
for c in cs:
    a,b=sorted((lum(L[c]),lum(L[bg])));print(f"{c} vs bg {bg}: contrast {(b+.05)/(a+.05):.2f}")
for a,b in itertools.combinations(cs,2):
    d={n:math.dist(lab(sim(L[a],m)),lab(sim(L[b],m))) for n,m in M.items()}
    w=min(d.values());print(f"{a}~{b}: "+" ".join(f"{n} {v:.0f}" for n,v in d.items())+("  <- under 20" if w<20 else ""))
PY
  ;;
*) sed -n 2,6p "$0"; exit 2 ;;
esac
