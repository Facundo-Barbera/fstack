# shellcheck shell=bash
# Shared helpers for the fstack CLI. Sourced by bin/fstack.
set -o pipefail

die() {
  echo "fstack: $*" >&2
  exit 1
}
info() { echo "fstack: $*" >&2; }

repo_root() { git rev-parse --show-toplevel 2>/dev/null || die "run this inside a git repository"; }

self_version() { tr -d '[:space:]' <"$FSTACK_SELF/VERSION"; }

# fstack.lock is key=value data; read it, never source it.
lock_version() {
  local f=$1/fstack.lock
  [ -f "$f" ] || return 1
  grep -E '^version=' "$f" | tail -n1 | cut -d= -f2- | tr -d '[:space:]'
}

write_lock() {
  printf '# Pinned fstack version for this repo. Change it with: fstack update --to vX.Y.Z\nversion=%s\n' "$2" >"$1/fstack.lock"
}

# Same key=value reader as gates/lib.sh, for the CLI side.
repo_cfg() {
  local f=$1/.fstack/config key=$2 default=${3:-} val=""
  [ -f "$f" ] && val=$(grep -E "^${key//./\\.}=" "$f" | tail -n1 | cut -d= -f2-)
  printf '%s' "${val:-$default}"
}

# Files of a pinned version: the git tag if it exists, else this checkout when it matches.
# Prints a directory path; callers must not modify it.
source_tree() {
  local ver=${1#v} tmp
  if git -C "$FSTACK_SELF" rev-parse -q --verify "refs/tags/v$ver" >/dev/null 2>&1; then
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/fstack-src.XXXXXX")
    git -C "$FSTACK_SELF" archive "v$ver" | tar -x -C "$tmp" || die "could not export v$ver"
    printf '%s\n' "$tmp"
  elif [ "$(self_version)" = "$ver" ]; then
    printf '%s\n' "$FSTACK_SELF"
  else
    die "fstack $ver is not available here (installed: $(self_version)); run: fstack install --ref v$ver"
  fi
}

# Markers for managed blocks: comment syntax differs between .gitignore and markdown.
block_begin() { case $1 in *.md) echo "<!-- fstack:$2 begin (managed) -->" ;; *) echo "# >>> fstack $2 (managed) >>>" ;; esac; }
block_end() { case $1 in *.md) echo "<!-- fstack:$2 end -->" ;; *) echo "# <<< fstack $2 <<<" ;; esac; }

# replace_block <file> <name> <content-file>: rewrite only the fstack-managed block,
# keeping whatever the repo added around it.
replace_block() {
  local file=$1 name=$2 content=$3 begin end tmp
  begin=$(block_begin "$file" "$name")
  end=$(block_end "$file" "$name")
  [ -f "$file" ] || : >"$file"
  tmp=$(mktemp)
  awk -v b="$begin" -v e="$end" '$0==b{skip=1; next} $0==e{skip=0; next} !skip' "$file" >"$tmp"
  {
    echo "$begin"
    cat "$content"
    echo "$end"
    # Repo-owned lines go after the block; strip leading blanks so syncs stay idempotent.
    if grep -q '[^[:space:]]' "$tmp"; then
      echo
      awk 'NF{p=1} p' "$tmp"
    fi
  } >"$file"
  rm -f "$tmp"
}

read_block() {
  local file=$1 name=$2
  [ -f "$file" ] || return 0
  awk -v b="$(block_begin "$file" "$name")" -v e="$(block_end "$file" "$name")" \
    '$0==b{on=1; next} $0==e{on=0} on' "$file"
}

harness_paths() {
  case $1 in
    claude-code) printf '%s\n' CLAUDE.md .claude/skills .claude/settings.json ;;
    codex) printf '%s\n' .codex/hooks.json ;;
    cursor) printf '%s\n' .cursor/hooks.json ;;
    t3) ;;
    *) return 1 ;;
  esac
}
