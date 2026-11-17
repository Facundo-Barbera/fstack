#!/usr/bin/env bash
# One dev server per repo: fixed port, lockfile, reuse or wait, never a second one.
# Usage: devserver-lock.sh start -- <command...> | stop | status
# Env: FSTACK_ROLE (must be orchestrator to start), FSTACK_DEV_PORT, FSTACK_LOCK_DIR,
#      FSTACK_LOCK_WAIT (seconds to wait for another holder, default 0 = fail fast).
set -euo pipefail

root=$(git rev-parse --show-toplevel)
repo=$(basename "$root")
lock_dir=${FSTACK_LOCK_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/fstack/locks}
# The lock is a directory: mkdir is atomic everywhere, unlike flock (absent on macOS).
lock="$lock_dir/$repo.lock"
pidfile="$lock/pid"
mkdir -p "$lock_dir"

alive() { [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; }

# Takes the lock, clearing it first if its server died. A lock without a pid is
# still being taken by another start, so it counts as held.
acquire() {
  local waited=0
  until mkdir "$lock" 2>/dev/null; do
    if [ -f "$pidfile" ] && ! alive; then
      rm -rf "$lock"
      continue
    fi
    [ "$waited" -lt "${FSTACK_LOCK_WAIT:-0}" ] || return 1
    sleep 1
    waited=$((waited + 1))
  done
}

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
    if ! acquire; then
      echo "devserver-lock: another process holds $lock; not starting a second server" >&2
      exit 4
    fi
    # Job control gives the server its own process group (pgid = pid), so stop can
    # kill the whole group. setsid would do the same but is not on macOS.
    set -m
    PORT=$FSTACK_DEV_PORT "$@" </dev/null >"$lock_dir/$repo.log" 2>&1 &
    echo $! >"$pidfile"
    echo "devserver-lock: started pid $! on port $FSTACK_DEV_PORT (log: $lock_dir/$repo.log)"
    ;;
  stop)
    if alive; then
      kill -- "-$(cat "$pidfile")" 2>/dev/null || kill "$(cat "$pidfile")" 2>/dev/null || true
    fi
    rm -rf "$lock"
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
