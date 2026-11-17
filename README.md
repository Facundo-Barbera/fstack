# fstack

Rules, skills and gates for AI coding agents that live **in each repo** and work
the same in Claude Code, Codex, Cursor and anything that reads `AGENTS.md`.

- `AGENTS.md`: the repo's rules (150 lines max), from `templates/AGENTS.md`.
- `.agents/skills/`: [Agent Skills](https://agentskills.io) for UI, verify,
  review, audit, digest and delegation, plus `INDEX.md` mapping task to skills
  to evidence.
- Gates via Lefthook and CI: file size cap, docs ratio, stray markdown and
  agent configs, `Removed:` in PRs, gitleaks, a `Verified:` trailer on every
  commit. All start in **observe** mode (print only); set each to `enforce` in
  `.fstack/config` when ready.
- Adapters generate the per-tool files (gitignored) so the core stays neutral.

## Install (per machine)

Needs bash, git and coreutils. No sudo. Without `--ref` it pins the latest tag
(or the default branch while there are no tags yet).

```sh
git clone https://github.com/Facundo-Barbera/fstack.git ~/.fstack
~/.fstack/bin/fstack install --ref vX.Y.Z   # pins ~/.fstack to a tag, links ~/.local/bin/fstack
```

Optional: [Lefthook](https://lefthook.dev) for local hooks, gitleaks for the
secrets gate, jq. Machine roles and models go in `~/.config/fstack/fleet.toml`
(copy `templates/fleet.example.toml`); it is never committed.

## Adopt (per repo)

```sh
cd your-repo
fstack sync      # writes fstack.lock, AGENTS.md (once), skills, .fstack/, lefthook.yml
fstack doctor    # checks the setup; read-only
```

Fill the `<...>` slots in `AGENTS.md` and commit. For an existing codebase, run
the `org-audit` skill first. To run the gates in CI, copy
`templates/ci-gates.yml` to `.github/workflows/fstack-gates.yml`.

Generated per harness (all gitignored, rebuilt by `post-checkout` in every
worktree):

| Harness | Files |
| --- | --- |
| Claude Code | `CLAUDE.md` (`@AGENTS.md`), `.claude/skills` symlink, `.claude/settings.json` hooks |
| Codex | `.codex/hooks.json` (AGENTS.md and `.agents/skills` are read natively; project hooks need a trusted project) |
| Cursor | `.cursor/hooks.json` (AGENTS.md and `.agents/skills` are read natively) |
| T3 Code | nothing: it runs Claude Code or Codex, which use the files above |

Hooks re-inject the skill index at session start and remind the agent to commit
with a `Verified:` trailer before it stops. Pick harnesses with `harnesses=` in
`.fstack/config`.

**T3 Code and other launchers:** start each thread's prompt with the preamble in
`.agents/skills/delegate/SKILL.md` (role and machine slots filled in). Repos
without fstack still get the minimal rules from that preamble.

## Update

```sh
fstack install --ref vX.Y.Z    # update the CLI on the machine
fstack update --to vX.Y.Z      # in a repo: new branch, bumped lock, synced, committed
git push -u origin fstack/update-vX.Y.Z && gh pr create --fill
```

Skills are copied, not linked, so a repo works for agents that never installed
fstack. Skills an update drops are deleted; files the repo owns (`AGENTS.md`,
`.fstack/config`, tracked tool configs) are never overwritten.

## Develop

```sh
tests/run.sh                                         # no server, temp repos under .tmp/
shellcheck bin/fstack gates/run.sh adapters/*/generate.sh
```

MIT licensed.
