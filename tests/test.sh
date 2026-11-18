#!/usr/bin/env bash
# fstack tests: plugin validates, hook emits fast valid JSON, scripts never write into the
# work repo, scripts stay bash 3.2 safe for macOS. No server, temp dirs outside the repo.
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
real_home=$HOME
plugin=$root/plugins/fstack
hook=$plugin/hooks/session-start.sh
check=$plugin/skills/review/scripts/check.sh
lock=$plugin/skills/verify/scripts/devserver-lock.sh
ui=$plugin/skills/ui/scripts/ui-check.sh
scripts=("$hook" "$check" "$lock" "$ui")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/fstack-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok    $1"; }
ko() { fail=$((fail + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/      /'; }
skip() { echo "skip  $1 (NOT VERIFIED)"; }

json_ok() {
  if command -v jq >/dev/null; then jq -e '.hookSpecificOutput.hookEventName == "SessionStart" and (.hookSpecificOutput.additionalContext | length > 0)' >/dev/null
  else python3 -c 'import json,sys; d=json.load(sys.stdin)["hookSpecificOutput"]; assert d["hookEventName"]=="SessionStart" and d["additionalContext"]'
  fi
}

# 1. Manifests and skills validate.
if command -v claude >/dev/null; then
  for p in "$root" "$plugin"; do
    if out=$(claude plugin validate --strict "$p" 2>&1); then ok "validate ${p#"$root"/}"; else ko "validate ${p#"$root"/}" "$out"; fi
  done
else
  skip "claude plugin validate: claude CLI not installed"
fi

# 2. Hook: valid JSON with and without machine config, quotes escaped, under 200 ms.
mkdir -p "$tmp/home/.config/fstack"
if HOME=$tmp/home XDG_CONFIG_HOME='' "$hook" | json_ok; then ok "hook JSON without config"; else ko "hook JSON without config"; fi
printf 'role=orchestrator\nmachine=box "one"\\\n' >"$tmp/home/.config/fstack/config"
out=$(HOME=$tmp/home XDG_CONFIG_HOME='' "$hook")
if printf '%s' "$out" | json_ok && printf '%s' "$out" | grep -q 'role orchestrator' && printf '%s' "$out" | grep -q 'load fstack:ui.*UI evidence'; then ok "hook JSON with config"; else ko "hook JSON with config" "$out"; fi
# Workers only write, commit and open PRs; every check runs on the orchestrator. No text may
# tell a worker to verify by running things.
if printf '%s' "$out" | grep -q 'A worker only writes code.*It runs nothing.*one run at a time'; then ok "hook says workers run nothing"; else ko "hook worker rule" "$out"; fi
bad=$(grep -rniE 'verify (with|without a server)|Verify without a server|run the tests' "$hook" "$plugin/skills" "$root/plugins/fstack-bots")
if [ -z "$bad" ]; then ok "no text tells a worker to run checks"; else ko "worker told to run checks" "$bad"; fi
TIMEFORMAT=%R
worst=0
for _ in 1 2 3 4 5; do
  t=$({ time HOME=$tmp/home "$hook" >/dev/null; } 2>&1)
  worst=$(awk -v a="$worst" -v b="$t" 'BEGIN { print (b > a ? b : a) }')
done
if awk -v t="$worst" 'BEGIN { exit !(t < 0.2) }'; then ok "hook under 200 ms (worst of 5: ${worst}s)"; else ko "hook took ${worst}s"; fi

# 3. Nothing writes into the work repo; check.sh still finds what it should.
repo=$tmp/repo
git init -q -b main "$repo"
cd "$repo" || exit 1
git config user.email t@example.com && git config user.name t
seq 1 390 >big.txt && git add big.txt && git commit -qm init
git checkout -qb feature
seq 1 450 >big.txt && printf 'notes\n' >PLAN.md && git add -A && git commit -qm change
printf 'draft\n' >untracked.md
snap() { (find . -path ./.git/index -prune -o -type f -print | LC_ALL=C sort | xargs cksum; git status --porcelain --ignored); }
before=$(snap)
export HOME=$tmp/home XDG_CACHE_HOME=$tmp/cache
"$hook" >/dev/null
diffout=$("$check" main)
"$check" --all >/dev/null
"$lock" status >/dev/null
FSTACK_ROLE=worker "$lock" start -- true >/dev/null 2>&1
lock_rc=$?
# Check runs: orchestrator only, exit code passed through, lock released, one at a time.
locks=$tmp/locks
FSTACK_ROLE=worker FSTACK_LOCK_DIR=$locks "$lock" run -- true >/dev/null 2>&1
run_worker_rc=$?
FSTACK_ROLE=orchestrator FSTACK_LOCK_DIR=$locks "$lock" run -- sh -c 'exit 7' >/dev/null 2>&1
run_rc=$?
[ -d "$locks/run.lock" ] && run_rc="$run_rc, lock left behind"
mkdir -p "$locks/run.lock" && echo $$ >"$locks/run.lock/pid"
FSTACK_ROLE=orchestrator FSTACK_LOCK_DIR=$locks FSTACK_RUN_WAIT=0 "$lock" run -- true >/dev/null 2>&1
busy_rc=$?
rm -rf "$locks/run.lock"
if [ "$(snap)" = "$before" ]; then ok "no script writes into the work repo"; else ko "repo changed" "$(diff <(echo "$before") <(snap))"; fi
case $diffout in *"big.txt: 450"*"PLAN.md: loose"*"untracked.md: loose"*) ok "check.sh reports big file and loose markdown" ;; *) ko "check.sh findings" "$diffout" ;; esac
if [ "$lock_rc" = 3 ]; then ok "devserver lock refuses workers"; else ko "devserver lock let a worker start (rc $lock_rc)"; fi
if [ "$run_worker_rc" = 3 ]; then ok "check runs refuse workers"; else ko "a worker started a check run (rc $run_worker_rc)"; fi
if [ "$run_rc" = 7 ]; then ok "check run passes the exit code through and releases the lock"; else ko "check run (rc $run_rc)"; fi
if [ "$busy_rc" = 4 ]; then ok "a second check run waits or fails while one is in progress"; else ko "two check runs at once (rc $busy_rc)"; fi
cd "$root" || exit 1

# 4. ui-check.sh on a fixture repo: flags new raw values, respects the repo's theme and the
# classes the base branch already uses, sees untracked files and writes nothing.
ui_repo=$tmp/ui
git init -q -b main "$ui_repo"
cd "$ui_repo" || exit 1
git config user.email t@example.com && git config user.name t
mkdir -p src/components
printf '@import "tailwindcss";\n@theme {\n  --color-ember-400: hsl(24 100%% 58%%);\n}\n' >src/index.css
printf 'module.exports = { theme: { extend: { colors: {\n  tide: { 500: "#0a7" },\n} } } };\n' >tailwind.config.js
printf 'export const A = () => <div className="bg-white/60 p-4" />;\n' >src/components/A.tsx
mkdir -p apps/web && printf '{\n  "style": "new-york",\n  "aliases": {\n    "ui": "@/components/ui"\n  }\n}\n' >apps/web/components.json
git add -A && git commit -qm base
git checkout -qb feature
{
  echo '// A 2px rule and #fff in a comment are not code.'
  echo 'export const B = () => <div className="bg-white/60 bg-ember-400/15 text-tide-500 hover:bg-[#ff0000] text-rose-500 bg-white/70" />;'
} >>src/components/A.tsx
printf '.x {\n  --color-local: #123456;\n  color: #abcdef;\n}\n' >>src/index.css
git add -A && git commit -qm feature
printf 'export const C = () => <p className="border-blue-500/50" />;\n' >src/components/C.tsx
before=$(snap)
out=$("$ui" diff main); rc=$?
got=$(printf '%s\n' "$out" | sed -n 's/^src[^:]*: \([^ ]*\) .*/\1/p' | LC_ALL=C sort | tr '\n' ' ')
want='#abcdef bg-[#ff0000] bg-white/70 border-blue-500/50 text-rose-500 '
if [ "$rc" = 1 ] && [ "$got" = "$want" ]; then ok "ui-check diff flags only new raw values"; else ko "ui-check diff (rc $rc, got '$got')" "$out"; fi
out=$("$ui" inventory); rc=$?
case "$rc $out" in "0 "*"apps/web/components.json"*'"style": "new-york"'*"ember-400"*"tide"*"src/components"*) ok "ui-check inventory lists components.json, theme colours and components" ;; *) ko "ui-check inventory (rc $rc)" "$out" ;; esac
if [ "$(snap)" = "$before" ]; then ok "ui-check writes nothing into the work repo"; else ko "ui-check changed the repo" "$(diff <(echo "$before") <(snap))"; fi
rm src/components/C.tsx
if out=$("$ui" diff HEAD); then ok "ui-check diff passes when nothing changed"; else ko "ui-check diff with no changes" "$out"; fi
cd "$root" || exit 1
if command -v python3 >/dev/null; then
  out=$("$ui" cvd '#111111' '#d62728' '#2ca02c'); rc=$?
  case "$rc $out" in "1 "*"#d62728~#2ca02c"*"under 20"*) ok "ui-check cvd flags red/green" ;; *) ko "ui-check cvd red/green (rc $rc)" "$out" ;; esac
  out=$("$ui" cvd '#111' '#fff' '#ffcc00'); rc=$?
  case "$rc $out" in "0 #fff vs bg #111: contrast 18."*) ok "ui-check cvd passes distinct, contrasting colours" ;; *) ko "ui-check cvd distinct (rc $rc)" "$out" ;; esac
  if ! "$ui" cvd '#111' 'nothex' '#fff' >/dev/null 2>&1; then ok "ui-check cvd rejects a bad colour"; else ko "ui-check cvd accepted a bad colour"; fi
else
  skip "ui-check cvd: python3 not installed"
fi
# fstack:ui stays thin (more instructions did not make UI better) and keeps its gate.
uiskill=$plugin/skills/ui/SKILL.md
n=$(wc -l <"$uiskill" | tr -d ' ')
if [ "$n" -le 60 ]; then ok "fstack:ui is $n lines"; else ko "fstack:ui is $n lines (max 60)"; fi
gate=$(awk '/^UI evidence$/ { s = 1 } s && /^```$/ { exit } s' "$uiskill")
case $gate in *"ui-check diff:"*"ui-check cvd:"*"Screenshots (dark, orchestrator"*"PENDING ORCHESTRATOR"*) ok "fstack:ui gate asks for diff, cvd and dark screenshots" ;; *) ko "fstack:ui gate block" "$gate" ;; esac

# 5. Bash 3.2 (macOS): syntax, and none of the GNU or bash 4+ only constructs.
for s in "${scripts[@]}" "$root/tests/test.sh"; do
  bash -n "$s" || ko "syntax ${s#"$root"/}"
done
bad=$(grep -nE -- '-printf|mapfile|readarray|flock|setsid|declare -A|local -n|\$\{[A-Za-z_]+(,,|\^\^)\}|sed -i|readlink -f|EPOCHREALTIME|%N' "${scripts[@]}" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#')
if [ -z "$bad" ]; then ok "scripts avoid GNU-only and bash 4+ constructs"; else ko "non-portable constructs" "$bad"; fi
if command -v shellcheck >/dev/null; then
  if out=$(shellcheck "${scripts[@]}" "$root/tests/test.sh" 2>&1); then ok "shellcheck"; else ko "shellcheck" "$out"; fi
else
  skip "shellcheck not installed"
fi

# 6. fstack-bots: frontmatter other bots accept (only name and description; Hermes wants
# descriptions near 60 chars, 160 hard), short always-on rules, a preamble in sync with
# fstack's, and nothing private in a public repo.
bots=$root/plugins/fstack-bots
for f in "$bots"/skills/*/SKILL.md; do
  rel=${f#"$root"/}
  fm=$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1' "$f")
  keys=$(printf '%s\n' "$fm" | sed -n 's/^\([A-Za-z_-]*\):.*/\1/p' | LC_ALL=C sort | tr '\n' ' ')
  name=$(printf '%s\n' "$fm" | sed -n 's/^name: *//p')
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description: *//p')
  dir=$(basename "$(dirname "$f")")
  if [ "$keys" = "description name " ] && [ "$(printf '%s\n' "$fm" | wc -l | tr -d ' ')" = 2 ]; then ok "$rel frontmatter is only name and description"; else ko "$rel frontmatter" "$fm"; fi
  if [ "$name" = "$dir" ] && printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' && [ ${#name} -le 64 ]; then ok "$rel name matches folder"; else ko "$rel name '$name'"; fi
  if [ ${#desc} -gt 0 ] && [ ${#desc} -le 60 ]; then ok "$rel description ${#desc} chars"; else ko "$rel description ${#desc} chars (want 1-60)"; fi
done
n=$(grep -cv '^<!--' "$bots/always-on/rules.md")
if [ "$n" -le 15 ]; then ok "always-on rules are $n lines"; else ko "always-on rules are $n lines (max 15)"; fi
preamble() { awk '/^## Briefing another agent|^## Delegation brief/ { s = 1 } s && /^```$/ { exit } s && f; s && /^```text$/ { f = 1 }' "$1"; }
a=$(preamble "$plugin/skills/fstack/SKILL.md") b=$(preamble "$bots/skills/fstack-bots/SKILL.md")
if [ -n "$a" ] && [ "$a" = "$b" ]; then ok "fstack-bots preamble matches fstack's"; else ko "preamble drifted" "$(diff <(echo "$a") <(echo "$b"))"; fi
p=plugins/fstack/skills/digest/assets/digest.html
if grep -q "$p" "$bots/skills/fstack-bots/SKILL.md" && [ -f "$root/$p" ]; then ok "fstack-bots points at existing $p"; else ko "missing reference $p"; fi
# Host names come from this machine and its local fstack config, so the test names none.
uname -n 2>/dev/null | cut -d. -f1 >"$tmp/hosts"
cfg=$real_home/.config/fstack/config
[ -f "$cfg" ] && sed -nE 's/^(machine|orchestrator|worker)=(.+)/\2/p' "$cfg" >>"$tmp/hosts"
bad=$(grep -rnE -- '/home/[a-z]|/Users/[A-Za-z]|[A-Z]:\\Users' "$bots"; grep -rniwF -f "$tmp/hosts" "$bots")
if [ -z "$bad" ]; then ok "fstack-bots names no host or private path"; else ko "private names in fstack-bots" "$bad"; fi

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
