#!/usr/bin/env bash
# fstack gate runner: called by lefthook, CI and harness hooks.
# Usage: run.sh pre-commit | commit-msg <file> | pre-push | ci | post-checkout
#        run.sh session-context [claude|codex|cursor] | stop-check [claude|codex|cursor]
set -o pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
# shellcheck source=checks.sh
. "$here/checks.sh"

# Pure bash so hooks work on machines without jq.
json_string() {
  local s
  s=$(cat)
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/}
  s=${s//$'\n'/\\n}
  printf '"%s"' "$s"
}

session_context() {
  local index=$FSTACK_ROOT/.agents/skills/INDEX.md text
  [ -f "$index" ] || return 0
  text=$(printf 'fstack: read AGENTS.md, then load the skills this index maps to your task.\n\n%s\n' "$(cat "$index")")
  case ${1:-claude} in
    cursor) printf '{"additional_context": %s}\n' "$(printf '%s' "$text" | json_string)" ;;
    *) printf '%s\n' "$text" ;;
  esac
}

# Reminds the agent to commit and stamp before ending; blocks once at most (enforce).
stop_check() {
  local harness=${1:-claude} input issues="" base unstamped=0 sha msg
  input=$(cat 2>/dev/null || true)
  if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    return 0
  fi
  [ -n "$(git status --porcelain 2>/dev/null)" ] && issues="uncommitted changes in the worktree. "
  base=$(base_commit)
  if [ "$base" != "$EMPTY_TREE" ]; then
    for sha in $(git rev-list --no-merges "$base..HEAD"); do
      git log -1 --format=%B "$sha" | grep -Eq "$STAMP_RE" || unstamped=$((unstamped + 1))
    done
  fi
  [ "$unstamped" -gt 0 ] && issues="$issues$unstamped commit(s) without a 'Verified:' trailer. "
  [ -n "$issues" ] || return 0
  msg="fstack: ${issues}Commit your work with 'Verified: <skill> <evidence>' (or 'Verified: none') and report anything NOT VERIFIED."
  local mode
  mode=$(gate_mode stamp)
  [ "$mode" = off ] && return 0
  case $harness:$mode in
    cursor:enforce) printf '{"followup_message": %s}\n' "$(printf '%s' "$msg" | json_string)" ;;
    cursor:*) printf '%s\n' "$msg" >&2; printf '{}\n' ;;
    *:enforce) printf '{"decision": "block", "reason": %s}\n' "$(printf '%s' "$msg" | json_string)" ;;
    *) printf '{"systemMessage": %s}\n' "$(printf '%s' "$msg" | json_string)" ;;
  esac
}

post_checkout() {
  # New worktrees need their per-tool files; they are gitignored so only sync makes them.
  if command -v fstack >/dev/null 2>&1; then
    fstack sync --adapters-only >/dev/null || echo "fstack: adapter sync failed; run 'fstack sync'" >&2
  else
    echo "fstack: not on PATH; run 'fstack sync' to regenerate per-tool files" >&2
  fi
}

cmd=${1:-}
shift || true
case $cmd in
  pre-commit)
    FSTACK_SCOPE=staged
    check_max_lines
    check_doc_ratio
    check_new_files
    check_secrets
    ;;
  commit-msg) check_stamp_msg "${1:-}" ;;
  pre-push | ci)
    FSTACK_SCOPE=branch
    check_max_lines
    check_doc_ratio
    check_new_files
    check_secrets
    check_stamp_range
    check_removed
    ;;
  post-checkout) post_checkout ;;
  session-context) session_context "${1:-claude}" ;;
  stop-check) stop_check "${1:-claude}" ;;
  *)
    sed -n '2,4p' "${BASH_SOURCE[0]}" >&2
    exit 2
    ;;
esac
exit "$FSTACK_FAILED"
