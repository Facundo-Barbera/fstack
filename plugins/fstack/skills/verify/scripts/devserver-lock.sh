#!/usr/bin/env bash
# Orchestrator only. One dev server per repo, and one check run at a time per machine.
# Usage: devserver-lock.sh start -- <command...> | run -- <command...> | stop | status
# Env: FSTACK_ROLE (must be orchestrator to start or run), FSTACK_DEV_PORT, FSTACK_LOCK_DIR,
#      FSTACK_LOCK_WAIT (seconds start waits for another holder, default 0 = fail fast),
#      FSTACK_RUN_WAIT (seconds run waits for the run before it, default 1800).
set -euo pipefail

root=$(git rev-parse --show-toplevel)
repo=$(basename "$root")
lock_dir=${FSTACK_LOCK_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/fstack/locks}
# The lock is a directory: mkdir is atomic everywhere, unlike flock (absent on macOS).
lock="$lock_dir/$repo.lock"
pidfile="$lock/pid"
# Check runs share one machine-wide lock: two test suites at once on the orchestrator
# fight over ports, databases and CPU, and a failure no longer has one cause.
run_lock="$lock_dir/run.lock"
mkdir -p "$lock_dir"

alive() { [ -f "$1/pid" ] && kill -0 "$(cat "$1/pid")" 2>/dev/null; }

# Takes lock $1, waiting up to $2 seconds, clearing it first if its holder died. A lock
# without a pid is still being taken by another process, so it counts as held.
acquire() {
  local waited=0
  until mkdir "$1" 2>/dev/null; do
    if [ -f "$1/pid" ] && ! alive "$1"; then
      rm -rf "$1"
      continue
    fi
    [ "$waited" -lt "$2" ] || return 1
    sleep 1
    waited=$((waited + 1))
  done
}

# Kills the check run's process group (or the command alone, if job control could not give
# it a group) and releases the run lock. set +e first: under errexit, a kill of a group that
# already exited is a failing last command, and it would end the shell before the rm and
# replace the run's exit code with 1. Processes that left the group on purpose survive.
end_run() {
  set +e
  if [ -n "$child" ]; then
    kill -- "-$child" 2>/dev/null
    # Once wait reaped it, the pid may belong to someone else: only the group is ours.
    [ -n "$reaped" ] || kill "$child" 2>/dev/null
  fi
  rm -rf "$run_lock"
}

need_orchestrator() {
  if [ "${FSTACK_ROLE:-worker}" != orchestrator ]; then
    echo "devserver-lock: role is '${FSTACK_ROLE:-worker}'; only the orchestrator runs servers and checks" >&2
    exit 3
  fi
}

case ${1:-} in
  start)
    shift
    [ "${1:-}" = "--" ] && shift
    [ $# -gt 0 ] || { echo "usage: devserver-lock.sh start -- <command>" >&2; exit 2; }
    need_orchestrator
    : "${FSTACK_DEV_PORT:?set FSTACK_DEV_PORT to the fixed port of this repo}"
    if alive "$lock"; then
      echo "devserver-lock: reusing running server pid $(cat "$pidfile") on port $FSTACK_DEV_PORT"
      exit 0
    fi
    if ! acquire "$lock" "${FSTACK_LOCK_WAIT:-0}"; then
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
  run)
    shift
    [ "${1:-}" = "--" ] && shift
    [ $# -gt 0 ] || { echo "usage: devserver-lock.sh run -- <command>" >&2; exit 2; }
    need_orchestrator
    if ! acquire "$run_lock" "${FSTACK_RUN_WAIT:-1800}"; then
      echo "devserver-lock: another check run holds $run_lock; try again when it ends" >&2
      exit 4
    fi
    echo $$ >"$run_lock/pid"
    child="" reaped=""
    # The trap covers signals and unexpected exits; the normal path cleans up itself and
    # clears the trap, so the exit code never depends on what a trap returns.
    trap end_run EXIT
    trap 'exit 130' INT TERM
    set -m
    "$@" </dev/null &
    child=$!
    rc=0
    wait "$child" || rc=$?
    reaped=1
    end_run
    trap - EXIT
    echo "devserver-lock: run finished with exit $rc: $*" >&2
    exit "$rc"
    ;;
  stop)
    if alive "$lock"; then
      kill -- "-$(cat "$pidfile")" 2>/dev/null || kill "$(cat "$pidfile")" 2>/dev/null || true
    fi
    rm -rf "$lock"
    echo "devserver-lock: stopped"
    ;;
  status)
    if alive "$lock"; then echo "server: running pid $(cat "$pidfile")"; else echo "server: not running"; fi
    if alive "$run_lock"; then echo "run: in progress pid $(cat "$run_lock/pid")"; else echo "run: none"; fi
    ;;
  *)
    sed -n '3,6p' "$0" >&2
    exit 2
    ;;
esac
