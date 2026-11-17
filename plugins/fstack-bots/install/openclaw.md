# OpenClaw

1. Clone at a tag (pin): `git clone --branch <tag> https://github.com/Facundo-Barbera/fstack.git ~/fstack`
2. Either copy it into the shared skills (`~/.openclaw/skills`):
   `openclaw skills install ~/fstack/plugins/fstack-bots/skills/fstack-bots --global`
   or load it in place from `~/.openclaw/openclaw.json`:
   `{ skills: { load: { extraDirs: ["~/fstack/plugins/fstack-bots/skills"] } } }`
3. Paste the list from `../always-on/rules.md` into `~/.openclaw/workspace/SOUL.md`
   and add to `AGENTS.md`: `Load the skill fstack-bots before delegating, closing work or reporting.`
4. Update: check out the new tag in `~/fstack`; with `install`, run it again
   (install copies, it does not link).

Do not use `git:Facundo-Barbera/fstack`: it needs SKILL.md at the repo root.

NOT VERIFIED: not installed on a real OpenClaw.
