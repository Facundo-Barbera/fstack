#!/usr/bin/env bash
# Cursor reads AGENTS.md and .agents/skills natively; only hooks are generated.
set -o pipefail
export TARGET=${1:?usage: generate.sh <repo root>}
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Project hooks run from the project root, so relative paths are stable.
emit .cursor/hooks.json <<'JSON'
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": ".fstack/gates/run.sh session-context cursor" }],
    "stop": [{ "command": ".fstack/gates/run.sh stop-check cursor" }]
  }
}
JSON
