#!/usr/bin/env bash
# Read-only checks for the review skill. Prints findings, writes nothing, always exits 0
# so it can never block anyone's repo. Bash 3.2 safe (macOS): no mapfile, no find -printf.
# Usage: check.sh [base-ref]   the branch plus uncommitted work, against its merge-base
#        check.sh --all        every tracked file, for a first look at a repo
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "check: not in a git repo"; exit 0; }
max=${FSTACK_MAX_LINES:-400}
found=0
say() { found=1; printf '%s  %s\n' "$1" "$2"; }
count() { wc -l | tr -d ' '; }

if [ "${1:-}" = --all ]; then
  base="" files=$(git ls-files) added=$(git ls-files)
else
  ref=""
  for c in "${1:-}" "$(git symbolic-ref -q --short refs/remotes/origin/HEAD)" origin/main main origin/master master; do
    if [ -n "$c" ] && git rev-parse -q --verify "$c^{commit}" >/dev/null; then ref=$c; break; fi
  done
  base=$(git merge-base HEAD "$ref" 2>/dev/null) || { echo "check: no base branch; pass one or use --all"; exit 0; }
  untracked=$(git ls-files --others --exclude-standard)
  files=$(printf '%s\n%s\n' "$(git diff --name-only --diff-filter=ACMR "$base")" "$untracked" | sort -u)
  added=$(printf '%s\n%s\n' "$(git diff --name-only --diff-filter=A "$base")" "$untracked" | sort -u)
fi

# Existing debt is not this change's fault: in diff mode a big file is flagged only if it grew.
while IFS= read -r f; do
  if [ ! -f "$f" ] || ! grep -Iq . "$f" 2>/dev/null; then continue; fi
  n=$(count <"$f")
  [ "$n" -gt "$max" ] || continue
  if [ -z "$base" ]; then
    say "⚠ Review" "$f: $n lines (cap $max)"
  else
    old=$(git show "$base:$f" 2>/dev/null | count)
    [ "$n" -gt "$old" ] && say "⚠ Review" "$f: $n lines (cap $max, was $old); split it instead of growing it"
  fi
done < <(printf '%s\n' "$files")

while IFS= read -r f; do
  case $f in
    CLAUDE.md | */CLAUDE.md | GEMINI.md | .cursorrules | .windsurfrules | .clinerules | .github/copilot-instructions.md | .cursor/rules/*)
      say "ℹ Note" "$f: tool-specific agent config; keep the rules in one AGENTS.md" ;;
    README.md | */README.md | AGENTS.md | */AGENTS.md | */SKILL.md | CHANGELOG.md | LICENSE.md) ;;
    *.md | *.mdx) say "⚠ Review" "$f: loose markdown; make it code, README, AGENTS.md or the PR body" ;;
  esac
done < <(printf '%s\n' "$added")

if [ -n "$base" ]; then
  # Added lines only: prose is doc files plus comment lines (a shebang is code).
  read -r prose code < <(git diff -U0 --no-color "$base" | awk '
    /^\+\+\+ / { f = substr($0, 7); next }
    /^\+/ {
      l = substr($0, 2)
      if (l ~ /^[ \t]*$/) next
      if (f ~ /\.(md|mdx|rst|txt)$/ || l ~ /^[ \t]*(#($|[^!])|\/\/|\/\*|\*|<!--)/) p++; else c++
    }
    END { print p + 0, c + 0 }')
  if [ "$prose" -ge 20 ] && [ $((prose * 2)) -gt "$code" ]; then
    say "⚠ Review" "added $prose lines of docs or comments vs $code of code; keep comments to the why"
  fi
  if git log --format=%B "$base..HEAD" | grep -Eiq '^(co-authored-by|generated-by|assisted-by):.*(claude|anthropic|openai|codex|copilot|cursor|gpt|gemini)'; then
    say "⚠ Review" "a commit since $ref carries an AI co-author trailer"
  fi
fi

if command -v gitleaks >/dev/null 2>&1; then
  args=(git --redact --no-banner)
  [ -n "$base" ] && args+=("--log-opts=$base..HEAD")
  if ! out=$(gitleaks "${args[@]}" . 2>&1); then
    say "⛔ Blocks" "gitleaks found leaks or failed (redacted):"
    printf '%s\n' "$out" | grep -E 'RuleID|File|Line|Commit|ERR' | head -n 40
  fi
else
  say "ℹ Note" "secrets NOT VERIFIED: gitleaks is not installed"
fi

[ "$found" = 1 ] || echo "check: no findings"
exit 0
