# shellcheck shell=bash
# fstack sync: bring a repo to its pinned fstack version. Sourced by bin/fstack.

# Copies skills, never a submodule: the repo must work for agents with no fstack installed.
sync_skills() {
  local root=$1 tree=$2 dest=$1/.agents/skills manifest=$1/.fstack/managed-skills name old
  mkdir -p "$dest" "$root/.fstack"
  local new_list d
  # A glob, not find -printf: BSD find (macOS) has no -printf.
  new_list=$(for d in "$tree"/.agents/skills/*/; do [ -d "$d" ] && basename "$d"; done | sort)
  [ -n "$new_list" ] || die "no skills found in $tree/.agents/skills"
  # A skill dropped upstream is deleted here too, so v1 never lingers next to v2.
  if [ -f "$manifest" ]; then
    while IFS= read -r old; do
      [ -n "$old" ] || continue
      printf '%s\n' "$new_list" | grep -Fxq -- "$old" || rm -rf "${dest:?}/$old"
    done <"$manifest"
  fi
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    rm -rf "${dest:?}/$name"
    cp -R "$tree/.agents/skills/$name" "$dest/$name"
  done <<<"$new_list"
  printf '%s\n' "$new_list" >"$manifest"
  replace_block "$dest/INDEX.md" index "$tree/.agents/skills/INDEX.md"
}

sync_gates() {
  local root=$1 tree=$2
  rm -rf "$root/.fstack/gates"
  cp -R "$tree/gates" "$root/.fstack/gates"
  chmod +x "$root/.fstack/gates/run.sh"
  [ -f "$root/.fstack/config" ] || cp "$tree/templates/fstack.config" "$root/.fstack/config"
}

# Starter files are created once and then belong to the repo.
sync_starters() {
  local root=$1 tree=$2
  [ -f "$root/AGENTS.md" ] || { cp "$tree/templates/AGENTS.md" "$root/AGENTS.md" && info "created AGENTS.md from template; fill in the <...> slots"; }
  if [ ! -f "$root/lefthook.yml" ]; then
    cp "$tree/templates/lefthook.yml" "$root/lefthook.yml"
  elif ! grep -q '.fstack/gates/run.sh' "$root/lefthook.yml"; then
    info "lefthook.yml exists without fstack gates; merge $tree/templates/lefthook.yml by hand"
  fi
}

# Generated per-tool files are gitignored; post-checkout regenerates them per worktree.
sync_adapters() {
  local root=$1 tree=$2 h list tmp prev
  prev=$(read_block "$root/.gitignore" generated | sed 's|^/||')
  tmp=$(mktemp)
  for h in $(repo_cfg "$root" harnesses "claude-code codex cursor"); do
    if [ "$h" = t3 ]; then continue; fi
    [ -x "$tree/adapters/$h/generate.sh" ] || { info "unknown harness '$h' in .fstack/config; skipped"; continue; }
    FSTACK_PREV_GENERATED=$prev "$tree/adapters/$h/generate.sh" "$root" >>"$tmp" || info "adapter $h failed"
  done
  list=$(sort -u "$tmp")
  printf '%s\n' "$list" | sed '/^$/d' | sed 's|^|/|' >"$tmp"
  replace_block "$root/.gitignore" generated "$tmp"
  rm -f "$tmp"
}

install_hooks() {
  local root=$1
  if command -v lefthook >/dev/null 2>&1; then
    (cd "$root" && lefthook install >/dev/null) || info "lefthook install failed"
  else
    info "lefthook not found: git hooks NOT installed (gates still run in CI)"
  fi
}

cmd_sync() {
  local adapters_only=0 root ver tree
  [ "${1:-}" = --adapters-only ] && adapters_only=1
  root=$(repo_root)
  if ! ver=$(lock_version "$root"); then
    [ "$adapters_only" = 1 ] && return 0
    ver=$(self_version)
    write_lock "$root" "$ver"
    info "pinned fstack $ver in fstack.lock"
  fi
  tree=$(source_tree "$ver") || exit 1
  if [ "$adapters_only" = 0 ]; then
    sync_skills "$root" "$tree"
    sync_gates "$root" "$tree"
    sync_starters "$root" "$tree"
  fi
  sync_adapters "$root" "$tree"
  [ "$adapters_only" = 1 ] || install_hooks "$root"
  [ "$tree" = "$FSTACK_SELF" ] || rm -rf "$tree"
  info "synced $root to fstack $ver"
}

cmd_update() {
  local to="" root ver branch
  while [ $# -gt 0 ]; do
    case $1 in
      --to) to=${2:-}; shift 2 ;;
      --to=*) to=${1#--to=}; shift ;;
      *) die "unknown option $1" ;;
    esac
  done
  [ -n "$to" ] || die "usage: fstack update --to vX.Y.Z"
  ver=${to#v}
  root=$(repo_root)
  [ -z "$(git -C "$root" status --porcelain)" ] || die "worktree has uncommitted changes; commit or stash first"
  git -C "$FSTACK_SELF" remote get-url origin >/dev/null 2>&1 && git -C "$FSTACK_SELF" fetch --tags --quiet origin
  source_tree "$ver" >/dev/null
  branch="fstack/update-v$ver"
  git -C "$root" switch -c "$branch" || die "could not create branch $branch"
  write_lock "$root" "$ver"
  (cd "$root" && cmd_sync)
  if (cd "$root" && cmd_doctor >/dev/null); then
    git -C "$root" add -A -- fstack.lock .fstack .agents AGENTS.md lefthook.yml .gitignore
    git -C "$root" commit -q -m "chore: update fstack to v$ver" -m "Removed: skills and gates from the previous fstack version that v$ver no longer ships." -m "Verified: fstack-doctor pass" ||
      die "commit failed"
    info "branch $branch is ready. Next: git push -u origin $branch && gh pr create --fill"
  else
    die "fstack doctor failed after sync; nothing committed. Run 'fstack doctor' on branch $branch"
  fi
}
