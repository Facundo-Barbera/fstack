#!/usr/bin/env bash
# Claude Code: CLAUDE.md imports AGENTS.md, skills via symlink, hooks in settings.json.
set -o pipefail
export TARGET=${1:?usage: generate.sh <repo root>}
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

printf '@AGENTS.md\n' | emit CLAUDE.md
emit_link .claude/skills ../.agents/skills
emit .claude/settings.json <<'JSON'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.fstack/gates/run.sh session-context claude" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.fstack/gates/run.sh stop-check claude" }
        ]
      }
    ]
  }
}
JSON
