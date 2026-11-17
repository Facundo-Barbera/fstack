#!/usr/bin/env bash
# Codex reads AGENTS.md and .agents/skills natively; only hooks are generated.
# Codex loads project hooks only once the project's .codex layer is trusted.
set -o pipefail
export TARGET=${1:?usage: generate.sh <repo root>}
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

emit .codex/hooks.json <<'JSON'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          { "type": "command", "command": "\"$(git rev-parse --show-toplevel)\"/.fstack/gates/run.sh session-context codex" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "\"$(git rev-parse --show-toplevel)\"/.fstack/gates/run.sh stop-check codex" }
        ]
      }
    ]
  }
}
JSON
