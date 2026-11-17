# Grok Bot

Grok Bot has no plugins or hooks; it keeps a global library of SKILL.md folders
that it saves with a tool.

1. Ask the bot to save `skills/fstack-bots/SKILL.md` from tag `<tag>` of
   https://github.com/Facundo-Barbera/fstack (path `plugins/fstack-bots/`) as the
   skill `fstack-bots`, unchanged.
2. Put the list from `../always-on/rules.md` in the bot's profile or memory.
3. Update: ask it to replace the skill with the file from the new tag.

NOT VERIFIED: the save tool's exact name and behaviour; not tried on a real bot.
