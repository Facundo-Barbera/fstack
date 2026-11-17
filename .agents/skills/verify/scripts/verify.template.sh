#!/usr/bin/env bash
# Template for a repo's verify script. Copy, then replace each TODO with the real command.
# Usage: verify worker | verify orchestrator
set -euo pipefail

level=${1:-worker}

worker() {
  echo "== types";       : TODO typecheck command
  echo "== lint";        : TODO lint command
  echo "== unit";        : TODO unit test command
  echo "== properties";  : TODO property test command, e.g. fast-check or Hypothesis
  echo "== contracts";   : TODO contract test command
}

orchestrator() {
  worker
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  lock="$here/devserver-lock.sh"
  # The lock guarantees one server per repo even if several orchestrators run.
  "$lock" start -- TODO_dev_server_command
  trap '"$lock" stop' EXIT
  echo "== e2e";         : TODO e2e command against the locked port
  echo "== screenshots"; : TODO capture 360 768 1280 and diff against baseline
}

case $level in
  worker) worker ;;
  orchestrator) orchestrator ;;
  *) echo "usage: verify worker|orchestrator" >&2; exit 2 ;;
esac
