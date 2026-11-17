#!/usr/bin/env bash
# fstack test suite: plain bash, no server, everything in a temp dir under .tmp/.
# Usage: tests/run.sh
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d "$ROOT/.tmp/tests.XXXXXX" 2>/dev/null || { mkdir -p "$ROOT/.tmp" && mktemp -d "$ROOT/.tmp/tests.XXXXXX"; })
trap 'rm -rf "$WORK"' EXIT
export HOME=$WORK/userhome XDG_CONFIG_HOME=$WORK/userhome/.config XDG_CACHE_HOME=$WORK/userhome/.cache
export GIT_CONFIG_GLOBAL=$WORK/gitconfig GIT_CONFIG_NOSYSTEM=1
export FSTACK_HOME=$HOME/.fstack FSTACK_BIN_DIR=$HOME/.local/bin
unset FSTACK_BASE FSTACK_PR_BODY FSTACK_PR_BODY_FILE GITHUB_EVENT_PATH
mkdir -p "$HOME"
git config --global user.name test
git config --global user.email test@example.invalid
git config --global init.defaultBranch main
git config --global advice.detachedHead false

PASS=0 FAIL=0
ok() { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
no() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '     %s\n' "$2"; }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else no "$name" "command: $*"; fi; }
refute() { local name=$1; shift; if "$@" >/dev/null 2>&1; then no "$name" "expected failure: $*"; else ok "$name"; fi; }
commit() { git -C "$1" add -A && git -C "$1" commit -q -m "$2" -m "Verified: none"; }

# Snapshot the working tree as a source repo with tags v0.1.0 and v0.2.0.
SRC=$WORK/src
mkdir -p "$SRC"
(cd "$ROOT" && git ls-files -co --exclude-standard -z | tar --null -T - -cf - | tar -xf - -C "$SRC")
git -C "$SRC" init -q && commit "$SRC" "v0.1.0 snapshot" && git -C "$SRC" tag v0.1.0
printf '0.2.0\n' >"$SRC/VERSION"
git -C "$SRC" rm -rq .agents/skills/delegate
commit "$SRC" "v0.2.0 drops delegate" && git -C "$SRC" tag v0.2.0
export FSTACK_REPO=$SRC

echo "# install"
check "install pins a tag" "$SRC/bin/fstack" install --ref v0.1.0
FSTACK=$FSTACK_BIN_DIR/fstack
check "fstack linked into bin dir" test -L "$FSTACK"
check "installed version is 0.1.0" test "$("$FSTACK" version)" = 0.1.0

echo "# sync"
T=$WORK/target
git init -q "$T" && echo "app" >"$T/app.txt" && commit "$T" init
cd "$T" || exit 1
check "sync succeeds" "$FSTACK" sync
check "lock pins 0.1.0" grep -qx 'version=0.1.0' fstack.lock
check "AGENTS.md created" test -f AGENTS.md
check "skills copied" test -f .agents/skills/verify/SKILL.md
check "index wrapped in managed block" grep -q 'fstack:index begin' .agents/skills/INDEX.md
check "gates copied" test -x .fstack/gates/run.sh
check "CLAUDE.md imports AGENTS.md" grep -qx '@AGENTS.md' CLAUDE.md
check ".claude/skills is a symlink to skills" test "$(readlink .claude/skills)" = ../.agents/skills
for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json; do
  check "$f is valid JSON" jq -e . "$f"
  check "$f is gitignored" git check-ignore -q "$f"
done
check "cursor hooks have version 1" jq -e '.version == 1' .cursor/hooks.json
check "generated files stay out of git status" bash -c '! git status --porcelain | grep -E "CLAUDE.md|settings.json|hooks.json"'
check "doctor passes" "$FSTACK" doctor
before=$(cat .gitignore .agents/skills/INDEX.md | sha1sum)
"$FSTACK" sync 2>/dev/null
check "sync is idempotent" test "$before" = "$(cat .gitignore .agents/skills/INDEX.md | sha1sum)"
commit "$T" "adopt fstack"

echo "# adapters"
rm CLAUDE.md
check "adapters-only regenerates CLAUDE.md" bash -c "'$FSTACK' sync --adapters-only && test -f CLAUDE.md"
U=$WORK/owned
git init -q "$U" && echo "team rules" >"$U/CLAUDE.md" && commit "$U" init
(cd "$U" && "$FSTACK" sync 2>/dev/null)
check "tracked CLAUDE.md left untouched" grep -qx 'team rules' "$U/CLAUDE.md"

echo "# doctor"
seq 1 151 >>AGENTS.md
refute "doctor fails on AGENTS.md over 150 lines" "$FSTACK" doctor
git checkout -q AGENTS.md
mkdir -p .agents/skills/Bad && printf -- '---\nname: Bad\ndescription: x\n---\n' >.agents/skills/Bad/SKILL.md
refute "doctor fails on invalid skill name" "$FSTACK" doctor
rm -rf .agents/skills/Bad

echo "# gates: commit-msg"
G=.fstack/gates/run.sh
printf 'feat: x\n' >"$WORK/msg"
check "missing stamp passes in observe" "$G" commit-msg "$WORK/msg"
check "missing stamp is reported in observe" bash -c "'$G' commit-msg '$WORK/msg' 2>&1 | grep -q 'observe.*stamp'"
refute "missing stamp fails in enforce" env FSTACK_GATE_STAMP=enforce "$G" commit-msg "$WORK/msg"
printf 'feat: x\n\nVerified: verify unit green\n' >"$WORK/msg"
check "stamped message passes in enforce" env FSTACK_GATE_STAMP=enforce "$G" commit-msg "$WORK/msg"
printf 'feat: x\n\nVerified: none\nCo-Authored-By: Claude <bot@example.invalid>\n' >"$WORK/msg"
refute "AI co-author trailer fails in enforce" env FSTACK_GATE_STAMP=enforce "$G" commit-msg "$WORK/msg"
check "gate off ignores everything" env FSTACK_GATE_STAMP=off "$G" commit-msg "$WORK/msg"

echo "# gates: pre-commit"
seq 1 500 >big.txt && git add big.txt
refute "new 500-line file fails max-lines" env FSTACK_GATE_MAX_LINES=enforce "$G" pre-commit
git commit -q -m "debt" -m "Verified: none"
tail -n +11 big.txt >big.tmp && mv big.tmp big.txt && git add big.txt
check "shrinking an oversized file passes" env FSTACK_GATE_MAX_LINES=enforce "$G" pre-commit
git commit -q -m "shrink" -m "Verified: none"
seq 1 5 >>big.txt && git add big.txt
refute "growing an oversized file fails" env FSTACK_GATE_MAX_LINES=enforce "$G" pre-commit
git reset -q --hard
echo note >NOTES.md && git add NOTES.md
refute "stray markdown fails new-files" env FSTACK_GATE_NEW_FILES=enforce "$G" pre-commit
git rm -q --cached NOTES.md && rm NOTES.md
mkdir -p docs/adr && echo adr >docs/adr/0001-x.md && git add docs/adr
echo 'adr-dir=docs/adr' >>.fstack/config
check "ADR folder is allowed" env FSTACK_GATE_NEW_FILES=enforce FSTACK_GATE_DOC_RATIO=off "$G" pre-commit
git reset -q --hard && rm -rf docs
echo rules >.cursorrules && git add -f .cursorrules
refute "new agent config fails new-files" env FSTACK_GATE_NEW_FILES=enforce "$G" pre-commit
git rm -q --cached .cursorrules && rm .cursorrules
seq 1 30 | sed 's/^/prose line /' >guide.txt && echo 'x=1' >code.sh && git add guide.txt code.sh
refute "docs-heavy diff fails doc-ratio" env FSTACK_GATE_DOC_RATIO=enforce "$G" pre-commit
git reset -q --hard && rm -f guide.txt code.sh
if command -v gitleaks >/dev/null; then
  # Generated at runtime so no key-shaped string is ever committed.
  printf 'aws_key = "AKIA%s"\n' "$(LC_ALL=C tr -dc 'A-Z2-7' </dev/urandom | head -c16)" >leak.txt && git add leak.txt
  refute "staged secret fails secrets gate" env FSTACK_GATE_SECRETS=enforce "$G" pre-commit
  git rm -q --cached leak.txt && rm leak.txt
else
  echo "skip secrets gate test: gitleaks not installed (NOT VERIFIED)"
fi

echo "# gates: pre-push and PR body"
git switch -q -c feature && echo y >y.txt && git add y.txt && git commit -q -m "no stamp"
refute "unstamped commit fails pre-push stamp" env FSTACK_GATE_STAMP=enforce FSTACK_BASE=main "$G" pre-push
git commit -q --amend -m "stamped" -m "Verified: none"
check "stamped branch passes pre-push" env FSTACK_GATE_STAMP=enforce FSTACK_BASE=main FSTACK_GATE_SECRETS=off "$G" pre-push
refute "PR body without Removed fails" env FSTACK_GATE_REMOVED=enforce FSTACK_BASE=main FSTACK_PR_BODY="Adds y" "$G" ci
check "PR body with Removed passes" env FSTACK_GATE_REMOVED=enforce FSTACK_BASE=main FSTACK_GATE_SECRETS=off FSTACK_PR_BODY=$'Adds y\n\n**Removed:** nothing' "$G" ci
git switch -q main

echo "# harness hooks"
check "session-context prints the index" bash -c "'$G' session-context claude | grep -q 'Skill index'"
check "cursor session-context is JSON" bash -c "'$G' session-context cursor | jq -e '.additional_context | length > 0'"
echo dirty >dirty.txt
check "stop-check observe emits systemMessage" bash -c "echo '{}' | '$G' stop-check claude | jq -e '.systemMessage'"
check "stop-check enforce blocks" bash -c "echo '{}' | FSTACK_GATE_STAMP=enforce '$G' stop-check claude | jq -e '.decision == \"block\"'"
check "stop-check never blocks twice" bash -c "test -z \"\$(echo '{\"stop_hook_active\": true}' | FSTACK_GATE_STAMP=enforce '$G' stop-check claude)\""
rm dirty.txt

echo "# verify lock"
refute "workers cannot start a dev server" env FSTACK_ROLE=worker .agents/skills/verify/scripts/devserver-lock.sh start -- true
# A sleep stands in for the server: no port is opened.
LOCK=.agents/skills/verify/scripts/devserver-lock.sh
export FSTACK_LOCK_DIR=$WORK/locks FSTACK_DEV_PORT=1
check "orchestrator starts through the lock" env FSTACK_ROLE=orchestrator "$LOCK" start -- sleep 30
LOCKPID=$(cat "$FSTACK_LOCK_DIR/target.lock/pid" 2>/dev/null)
check "second start reuses the running server" bash -c "FSTACK_ROLE=orchestrator '$LOCK' start -- sleep 31 | grep -q 'reusing running server pid $LOCKPID'"
check "lock still owned by the first server" test "$(cat "$FSTACK_LOCK_DIR/target.lock/pid" 2>/dev/null)" = "$LOCKPID"
check "stop releases the lock" bash -c "'$LOCK' stop && test ! -e '$FSTACK_LOCK_DIR/target.lock'"
check "stop kills the server" bash -c "sleep 0.2; ! kill -0 '$LOCKPID' 2>/dev/null"
unset FSTACK_LOCK_DIR FSTACK_DEV_PORT

echo "# update"
check "update to v0.2.0 commits on a branch" "$FSTACK" update --to v0.2.0
check "on the update branch" test "$(git branch --show-current)" = fstack/update-v0.2.0
check "lock bumped" grep -qx 'version=0.2.0' fstack.lock
check "skill dropped upstream is removed" test ! -e .agents/skills/delegate
check "update commit is stamped" bash -c "git log -1 --format=%B | grep -q '^Verified: '"
check "worktree clean after update" test -z "$(git status --porcelain)"

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
