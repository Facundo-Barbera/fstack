# fstack

Facundo Barbera's Claude Code plugin: his working rules for coding agents (evidence
before done, worker/orchestrator roles, clean repos, UI with the repo's real design
system, one-screen digests). Installed per user; it writes nothing into your repos.
Entry point: `/fstack`. A short SessionStart hook says which skill to load.

```sh
claude plugin marketplace add Facundo-Barbera/fstack   # install
claude plugin install fstack@fstack --scope user
claude plugin marketplace update fstack && claude plugin update fstack@fstack --scope user   # update
claude plugin marketplace add https://github.com/Facundo-Barbera/fstack.git#v0.2.0   # pin to a tag
```

For long-lived bots (Hermes Agent, OpenClaw, Grok Bot): `plugins/fstack-bots`, a portable
`SKILL.md` plus always-on rules; install steps in `plugins/fstack-bots/install/`.

Optional machine config: `~/.config/fstack/config` (`role=`, `machine=`). Tests: `tests/test.sh`. MIT.
