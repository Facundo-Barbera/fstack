#!/usr/bin/env bash
# One dev server per repo: fixed port, lockfile, reuse or wait, never a second one.
# Usage: devserver-lock.sh start -- <command...> | stop | status
# Env: FSTACK_ROLE (must be orchestrator to start), FSTACK_DEV_PORT, FSTACK_LOCK_DIR,
#      FSTACK_LOCK_WAIT (seconds to wait for another holder, default 0 = fail fast).
set -euo pipefail

root=$(git rev-parse --show-toplevel)
repo=$(basename "$root")
lock_dir=${FSTACK_LOCK_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/fstack/locks}
lock="$lock_dir/$repo.lock"
pidfile="$lock_dir/$repo.pid"
mkdir -p "$lock_dir"

alive() { [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; }

case ${1:-} in
  start)
    shift
    [ "${1:-}" = "--" ] && shift
    [ $# -gt 0 ] || { echo "usage: devserver-lock.sh start -- <command>" >&2; exit 2; }
    if [ "${FSTACK_ROLE:-worker}" != orchestrator ]; then
      echo "devserver-lock: role is '${FSTACK_ROLE:-worker}'; only the orchestrator starts dev servers" >&2
      exit 3
    fi
    : "${FSTACK_DEV_PORT:?set FSTACK_DEV_PORT to the fixed port of this repo}"
    if alive; then
      echo "devserver-lock: reusing running server pid $(cat "$pidfile") on port $FSTACK_DEV_PORT"
      exit 0
    fi
    exec 9>"$lock"
    if ! flock -w "${FSTACK_LOCK_WAIT:-0}" 9; then
      echo "devserver-lock: another process holds $lock; not starting a second server" >&2
      exit 4
    fi
    # The server inherits fd 9, so the lock is held exactly as long as the server lives.
    PORT=$FSTACK_DEV_PORT setsid "$@" >"$lock_dir/$repo.log" 2>&1 &
    echo $! >"$pidfile"
    echo "devserver-lock: started pid $! on port $FSTACK_DEV_PORT (log: $lock_dir/$repo.log)"
    ;;
  stop)
    if alive; then
      # The server runs in its own session, so kill the whole group, not only the leader.
      kill -- "-$(cat "$pidfile")" 2>/dev/null || kill "$(cat "$pidfile")" 2>/dev/null || true
    fi
    rm -f "$pidfile" "$lock"
    echo "devserver-lock: stopped"
    ;;
  status)
    if alive; then echo "running pid $(cat "$pidfile")"; else echo "not running"; fi
    ;;
  *)
    sed -n '3,5p' "$0" >&2
    exit 2
    ;;
esac
