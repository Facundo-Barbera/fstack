# shellcheck shell=bash
# Shared helpers for fstack gates. Sourced by run.sh, never executed directly.
set -o pipefail

FSTACK_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "fstack: not inside a git repository" >&2
  exit 1
}
FSTACK_CONFIG=${FSTACK_CONFIG:-$FSTACK_ROOT/.fstack/config}
FSTACK_FAILED=0
EMPTY_TREE=$(git hash-object -t tree /dev/null)

# Config is key=value data; grep it instead of sourcing so a repo can't inject code.
cfg() {
  local key=$1 default=${2:-} val=""
  if [ -f "$FSTACK_CONFIG" ]; then
    val=$(grep -E "^${key//./\\.}=" "$FSTACK_CONFIG" | tail -n1 | cut -d= -f2-)
  fi
  printf '%s' "${val:-$default}"
}

# Env wins over config so CI or a single run can change a gate without a commit.
gate_mode() {
  local env_name mode
  env_name="FSTACK_GATE_$(printf '%s' "$1" | tr 'a-z-' 'A-Z_')"
  mode=${!env_name:-$(cfg "gate.$1" observe)}
  case $mode in
    off | observe | enforce) printf '%s' "$mode" ;;
    *) printf 'observe' ;;
  esac
}

gate_on() { [ "$(gate_mode "$1")" != off ]; }

# observe only prints; enforce prints and fails. Labels are textual, never colour-only.
report() {
  local gate=$1
  shift
  case $(gate_mode "$gate") in
    off) return 0 ;;
    observe) printf 'fstack [observe] %s: %s\n' "$gate" "$*" >&2 ;;
    enforce)
      printf 'fstack [ENFORCE] %s: %s\n' "$gate" "$*" >&2
      FSTACK_FAILED=1
      ;;
  esac
}

# The branch is compared against its merge-base with the default branch.
base_commit() {
  local ref=${FSTACK_BASE:-} c
  if [ -n "$ref" ] && ! git rev-parse -q --verify "$ref^{commit}" >/dev/null; then
    echo "fstack: FSTACK_BASE '$ref' is not a commit; comparing against the whole history" >&2
  fi
  if [ -z "$ref" ]; then
    ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  fi
  if [ -z "$ref" ]; then
    for c in origin/main origin/master main master; do
      if git rev-parse -q --verify "$c^{commit}" >/dev/null; then
        ref=$c
        break
      fi
    done
  fi
  if [ -n "$ref" ] && [ "$(git rev-parse -q --verify "$ref^{commit}")" != "$(git rev-parse HEAD)" ]; then
    git merge-base HEAD "$ref" 2>/dev/null && return 0
  fi
  printf '%s\n' "$EMPTY_TREE"
}

# FSTACK_SCOPE=staged (pre-commit) diffs the index; anything else diffs the branch.
diff_range() {
  if [ "${FSTACK_SCOPE:-branch}" = staged ]; then
    printf '%s\n' --cached
  else
    base_commit
    printf '%s\n' HEAD
  fi
}

scope_diff() {
  local args
  mapfile -t args < <(diff_range)
  git diff --no-color --no-ext-diff "${args[@]}" "$@"
}

# Content of a path on the "new" side of the diff.
new_blob() {
  if [ "${FSTACK_SCOPE:-branch}" = staged ]; then git show ":$1" 2>/dev/null; else git show "HEAD:$1" 2>/dev/null; fi
}

# Content of a path on the "old" side of the diff.
old_blob() {
  local base
  if [ "${FSTACK_SCOPE:-branch}" = staged ]; then
    git show "HEAD:$1" 2>/dev/null
  else
    base=$(base_commit)
    [ "$base" = "$EMPTY_TREE" ] && return 0
    git show "$base:$1" 2>/dev/null
  fi
}

count_lines() { wc -l | tr -d ' '; }
