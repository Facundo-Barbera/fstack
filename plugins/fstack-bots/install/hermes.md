# Hermes Agent

1. Clone at a tag (pin): `git clone --branch <tag> https://github.com/Facundo-Barbera/fstack.git ~/fstack`
2. Add the skills dir in `~/.hermes/config.yaml`:
   ```yaml
   skills:
     external_dirs:
       - ~/fstack/plugins/fstack-bots/skills
   ```
3. Paste the list from `../always-on/rules.md` into `~/.hermes/SOUL.md`.
4. Update: `git -C ~/fstack fetch --tags && git -C ~/fstack checkout <new-tag>`.

NOT VERIFIED: not installed on a real Hermes. Hermes lists `version` as a
frontmatter field for its own skills; this skill ships only `name` and
`description` for portability. `hermes skills tap add` expects skills under
`skills/`, so a tap would need its path edited in `~/.hermes/skills/.hub/taps.json`.
