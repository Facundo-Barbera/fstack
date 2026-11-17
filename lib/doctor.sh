# shellcheck shell=bash
# fstack doctor: read-only health check of a repo. Sourced by bin/fstack.

DOC_FAIL=0
ok() { printf 'ok    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() {
  printf 'FAIL  %s\n' "$*"
  DOC_FAIL=1
}

# Frontmatter rules from the Agent Skills spec: name matches the folder, description set.
check_skill() {
  local file=$1 dir name desc fm
  dir=$(basename "$(dirname "$file")")
  if [ "$(head -n1 "$file")" != "---" ]; then
    fail "skill $dir: SKILL.md has no YAML frontmatter"
    return 1
  fi
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")
  name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1 | tr -d '"'"'")
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n1)
  if [ "$name" != "$dir" ]; then
    fail "skill $dir: frontmatter name '$name' does not match folder"
  elif ! [[ $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || [ ${#name} -gt 64 ]; then
    fail "skill $dir: name must be lowercase letters, digits and single hyphens (max 64)"
  elif [ -z "$desc" ] || [ ${#desc} -gt 1024 ]; then
    fail "skill $dir: description must be 1-1024 characters and say when to use it"
  else
    return 0
  fi
  return 1
}

cmd_doctor() {
  local root harnesses="" h p n hooks_dir skills=0 bad=0 fleet
  DOC_FAIL=0
  while [ $# -gt 0 ]; do
    case $1 in
      --harness) harnesses=${2:-}; shift 2 ;;
      --harness=*) harnesses=${1#--harness=}; shift ;;
      *) die "unknown option $1" ;;
    esac
  done
  root=$(repo_root)
  [ -n "$harnesses" ] || harnesses=$(repo_cfg "$root" harnesses "claude-code codex cursor")

  if [ -f "$root/AGENTS.md" ]; then
    n=$(wc -l <"$root/AGENTS.md" | tr -d ' ')
    if [ "$n" -le 150 ]; then ok "AGENTS.md is $n lines (max 150)"; else fail "AGENTS.md is $n lines (max 150)"; fi
  else
    fail "AGENTS.md missing (run fstack sync)"
  fi

  if [ -f "$root/fstack.lock" ]; then ok "fstack.lock pins $(lock_version "$root")"; else fail "fstack.lock missing"; fi

  if [ -f "$root/.agents/skills/INDEX.md" ]; then ok "skill index present"; else fail "skill index .agents/skills/INDEX.md missing"; fi

  for p in "$root"/.agents/skills/*/SKILL.md; do
    [ -f "$p" ] || continue
    skills=$((skills + 1))
    check_skill "$p" || bad=$((bad + 1))
  done
  if [ "$skills" -eq 0 ]; then fail "no skills under .agents/skills"; elif [ "$bad" -eq 0 ]; then ok "$skills skills have valid frontmatter"; fi

  if [ -x "$root/.fstack/gates/run.sh" ]; then ok "gates present"; else fail "gates missing in .fstack/gates"; fi

  hooks_dir=$(git -C "$root" rev-parse --git-path hooks)
  case $hooks_dir in /*) ;; *) hooks_dir=$root/$hooks_dir ;; esac
  if [ ! -f "$root/lefthook.yml" ]; then
    fail "lefthook.yml missing"
  elif grep -qs lefthook "$hooks_dir/pre-commit"; then
    ok "lefthook hooks installed"
  else
    warn "lefthook.yml present but git hooks not installed (run: lefthook install)"
  fi

  for h in $harnesses; do
    harness_paths "$h" >/dev/null || { fail "unknown harness '$h'"; continue; }
    for p in $(harness_paths "$h"); do
      if [ ! -e "$root/$p" ] && [ ! -L "$root/$p" ]; then
        fail "$h: $p missing (run fstack sync)"
      elif git -C "$root" ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
        warn "$h: $p is tracked by git; fstack leaves it to you"
      elif git -C "$root" check-ignore -q -- "$p"; then
        ok "$h: $p generated and gitignored"
      else
        fail "$h: $p is not gitignored"
      fi
    done
  done

  # Presence only: the fleet config describes machines and is never printed.
  fleet=${FSTACK_FLEET:-${XDG_CONFIG_HOME:-$HOME/.config}/fstack/fleet.toml}
  if [ -f "$fleet" ] || [ -f "$root/fstack.local.toml" ]; then
    ok "local fleet config present"
  else
    warn "no local fleet config; agents default to role worker (see templates/fleet.example.toml)"
  fi

  return "$DOC_FAIL"
}
