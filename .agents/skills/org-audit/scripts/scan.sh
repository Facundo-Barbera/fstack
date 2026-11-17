#!/usr/bin/env bash
# Mechanical part of org-audit. Read-only; prints a summary to stdout.
# Usage: scan.sh [max-lines]
set -euo pipefail

max=${1:-400}
cd "$(git rev-parse --show-toplevel)"
files() { git ls-files -z | tr '\0' '\n'; }

echo "## Markdown files outside README/AGENTS/SKILL/INDEX"
files | grep -Ei '\.mdx?$' | grep -Ev '(^|/)(README|AGENTS|SKILL|INDEX)\.md$' || echo "(none)"

echo
echo "## Agent and tool configs"
files | grep -E '(^|/)(CLAUDE\.md|GEMINI\.md|AGENTS\.md|\.cursorrules|\.windsurfrules|\.clinerules|copilot-instructions\.md)$|^\.(cursor|windsurf|continue|roo|claude|codex)/' || echo "(none)"

echo
echo "## Files over $max lines"
files | while IFS= read -r f; do
  [ -f "$f" ] || continue
  grep -Iq . "$f" 2>/dev/null || continue
  n=$(wc -l <"$f")
  [ "$n" -gt "$max" ] && printf '%6d  %s\n' "$n" "$f"
done | sort -rn || true

echo
echo "## Raw colour literals (top files)"
git grep -I -c -E '#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b|rgba?\(' -- ':!*.svg' ':!*.lock' 2>/dev/null | sort -t: -k2 -rn | head -n 15 || true

echo
echo "## Arbitrary pixel values (top files)"
git grep -I -c -E '\[[0-9]+px\]|[^a-z-][0-9]{2,}px' -- '*.css' '*.scss' '*.tsx' '*.jsx' '*.vue' '*.svelte' 2>/dev/null | sort -t: -k2 -rn | head -n 15 || true

echo
echo "## Test files"
echo "count: $(files | grep -Eic '(test|spec)\.|(^|/)tests?/|__tests__' || true)"
echo "Mocked data layers (files mentioning mock + db/database/prisma/supabase):"
git grep -I -l -i -E 'mock' -- '*test*' '*spec*' 2>/dev/null | xargs -r grep -l -i -E 'db|database|prisma|supabase|sql' 2>/dev/null | head -n 15 || true
