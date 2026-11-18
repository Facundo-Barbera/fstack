---
name: ui
description: Mandatory before editing any UI file in Facundo's repos - .tsx, .jsx, .vue, .svelte, .css/.scss, Tailwind classes or config, theme or token files - and for mockups, prototypes and screenshots, even when the brief already describes the design. Six gated steps with evidence - inventory the real design system, intent, clickable prototypes in the app, build rules (colour-blind safe, dark first), checks, visual capture - and a UI evidence block at the end of the report or PR.
user-invocable: false
---

# ui

Facundo hates: HTML mockups that ignore the repo, static pictures he cannot
click or reuse, "a couple of tweaks" when he asked for something new, and
meaning carried by colour alone (he is colour-blind and works in dark mode).
Each gate ends in evidence for the final report. A gate without evidence is
NOT VERIFIED, never silently skipped. A brief can add requirements but only
waives a gate by naming it ("skip G3").

`scripts/` is next to this file. Everything in it is read-only and runs on
bash 3.2 with git, grep and awk; `cvd` also needs python3.

## G1. Inventory (before the first edit)

Run `scripts/ui-check.sh inventory` and read what it lists: token and theme
files, the theme's colour names, component folders, prototype or story
routes. Write down:

- Tokens: the files and the 5-10 tokens you will use.
- Components: the existing ones you will reuse (paths).
- Gaps: a missing token or component goes into the token file or component
  folder as its own change, never inline in a view.

No inventory, no UI edits.

## G2. Intent (new screens, redesigns, "make it feel new")

Polish is not a redesign. In 5 lines: who looks at the screen, the 1-3 things
they do or decide there, and what it shows first, second and on demand. If the
result would be the old screen with nicer spacing, say so and propose a
structural change.

## G3. Prototypes in the real app (new screens and redesigns)

- 2-3 directions that differ in structure (list, board, split, timeline), not
  in colour, on a prototype route, story or `?proto=` flag, built with the
  repo's real components, tokens and data hooks fed by fixtures: long names,
  empty, error, loading, many items.
- Interactive with fixtures: navigation, selection and the main action work.
- Never a standalone HTML file or an image.
- Facundo picks one. The winner moves to the real route as is; the others
  are deleted in the same PR.
- "Decide on your own" means you pick the winner, and the other directions
  still ship behind the prototype route for him to see.

## G4. Build rules

- Tokens only: no hex, rgb(), hsl(), oklch(), raw px or default palette
  classes (`bg-red-500`) outside token files. Classes the theme defines or the
  base branch already uses are the repo's convention and are fine.
- Meaning never by colour alone: every status, threshold or diff state also
  has an icon or shape and a word. Red/green is never the only contrast.
- Dark mode first unless the repo already decided otherwise.
- Copy through i18n if the repo has it.
- Calm: no boxes in boxes, gratuitous gradients, glows or decorative icons.
  Affordances visible without hover; every control has focus and a name.
- A replacement deletes what it replaces in the same PR.

## G5. Checks (worker, no server)

- `scripts/ui-check.sh diff [base]`: committed, uncommitted and untracked
  changes since base. Exit 0, or each finding justified in the report.
- `scripts/ui-check.sh cvd BG HEX HEX...` (background first) for every set
  of status colours you added or changed: ΔE under deutan, protan and tritan
  and WCAG contrast against BG. ΔE under 20 or contrast under 4.5 (3 for icons
  and shapes) is fixed, or justified because shape and text carry the meaning.
  Without python3, CVD is NOT VERIFIED.
- Typecheck, lint and component tests with the G3 fixtures (if the repo has
  no tests, say so and list the fixtures).
- Hand the orchestrator the exact routes, fixture flags and viewports to
  capture, and write "Visual: pending orchestrator", never "done".

## G6. Visual verification (orchestrator)

On the one locked dev server (`fstack:verify`): screenshots at 360, 768 and
1280, dark first, of every direction and changed route, plus one greyscale
capture (`filter: grayscale(1)`) proving meaning survives without colour.
Attach them to the PR or digest. If nobody captured, the first line of the
report says NOT VISUALLY VERIFIED. At most 2 rounds of visual patches; then
stop, diagnose the layout and propose a new direction.

## UI evidence (last block of every UI report or PR body)

```text
UI evidence
- Inventory: <token files> | reused: <components> | added: <tokens/components or none>
- Intent: <one line, or "polish only">
- Prototypes: <route/flag per direction, or "n/a: no new screen">
- Raw values (ui-check diff): <0 | each with reason>
- CVD: <colours checked, worst ΔE and contrast | no colour change | NOT VERIFIED: why>
- Visual: <screenshot links | pending orchestrator: routes + flags + viewports | NOT VISUALLY VERIFIED>
```

## Review (own diff or a PR)

Flag with file:line and ⛔ Blocks / ⚠ Review / ℹ Note: a missing UI evidence
block, raw values, a component that duplicates an existing one, spacing off
the token scale, contrast under WCAG AA, colour-only meaning, controls without
focus or name, a mockup outside the app.
