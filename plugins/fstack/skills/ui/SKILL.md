---
name: ui
description: Required before editing any UI file (.tsx/.jsx/.vue/.svelte/.css, Tailwind classes, theme, tokens, components, layouts, mockups, prototypes, screenshots) in Facundo's repos. Forces design-system discovery, real-component prototypes he can click and promote, colour-blind checks and an evidence block. Load it even when the brief already describes the design.
user-invocable: false
---

# ui

Facundo hates: HTML mockups that ignore the repo, static pictures he cannot
click or reuse, "a couple of tweaks" when he asked for something new, and
meaning carried by colour (he is colour-blind). Every step below ends in
evidence that goes in the final report. A missing step is NOT VERIFIED, never
silently skipped. The brief may add requirements; it cannot waive a gate
unless it names the gate ("skip G3").

## G1. Inventory (before the first edit)

Run `scripts/ui-check.sh inventory` (read-only) and read what it finds:
token files, theme/Tailwind config, component folders, existing prototype or
story routes. Then write in your answer:

- Tokens: the files and the 5-10 tokens you will use.
- Components: the existing ones you will reuse (file paths).
- Gaps: any token or component that is missing. Add it to the token file or
  the component folder as its own change; never inline it in a view.

No inventory block, no UI edits.

## G2. Intent (new screens, redesigns, "make it feel new")

Polish is not a redesign. Before styling, write in 5 lines: who looks at the
screen, the 1-3 things they must do or decide there, and what the screen shows
first, second and on demand. If the result would look like the old screen with
nicer spacing, say so and propose a bigger structural change.

## G3. Prototypes in the real app (new screens and redesigns)

- 2-3 directions that differ in structure (list, board, split, timeline), not
  in colour. Built in the app itself, on a prototype route, story or
  `?proto=` flag, with the repo's real components, tokens and data hooks fed
  by fixtures: long names, empty, error, loading, many items.
- Interactive: navigation, selection and the main action work with fixtures.
- Never a standalone HTML file or an image.
- Facundo picks one; the winner is promoted by moving it to the real route,
  not rewritten. The losers are deleted in the same PR.
- "Decide on your own" in a brief means pick the best direction yourself and
  still ship the other directions behind the prototype route for him to see.

## G4. Build rules

- Tokens only. No hex, rgb(), hsl(), oklch(), raw px or default Tailwind
  palette classes (`bg-red-500`) outside token files, unless the repo's own
  convention uses them (cite the file that proves it).
- Meaning never by colour alone: every status, threshold or diff state also
  has an icon or shape plus a word. Red/green is never the only contrast.
- Dark mode is the default unless the repo already decided otherwise.
- Copy through i18n if the repo has it.
- Calm: no boxes in boxes, no gratuitous gradients or glows, no decorative
  icons. Affordances visible without hover; every control has focus and an
  accessible name.
- A replacement deletes what it replaces in the same PR.

## G5. Checks (worker, no server)

- `scripts/ui-check.sh diff [base]`: zero new raw colours or sizes, or each
  one justified in the report.
- `scripts/ui-check.sh cvd <hex> <hex> ...` for every pair of status colours
  you added or changed: ΔE under deutan, protan and tritan, plus WCAG contrast
  against the background. Pairs under ΔE 20 or contrast 4.5 are fixed or
  justified (shape and text already carry the meaning).
- Typecheck, lint and component tests with the fixtures above (if the repo
  forbids tests, say so and list the fixtures instead).
- Hand the orchestrator the exact routes, fixture flags and viewports to
  capture. Write "VISUAL: pending orchestrator", never "done".

## G6. Visual verification (orchestrator)

On the one locked dev server (`fstack:verify`): screenshots at 360, 768 and
1280, dark first, of every prototype direction and changed route, plus one
greyscale capture (CSS `filter: grayscale(1)`) to prove meaning survives
without colour. Attach them to the PR or the digest. If nobody captured, the
report to Facundo says NOT VISUALLY VERIFIED in its first line. At most 2
rounds of visual patches; then stop, diagnose the layout and propose a new
direction.

## Evidence block (end of every UI report or PR body)

```text
UI evidence
- Inventory: <token files> | reused: <components> | added: <tokens/components or none>
- Intent: <one line, or "polish only">
- Prototypes: <route/flag per direction, or "n/a: no new screen">
- Raw colours in diff: <0 | list with reason>
- CVD: <pairs checked and worst ΔE / contrast, or "no colour change">
- Visual: <screenshot links | pending orchestrator: routes + flags | NOT VISUALLY VERIFIED>
```

## Review (own diff or a PR)

Flag, with file:line and ⛔ Blocks / ⚠ Review / ℹ Note: a missing evidence
block, raw colours, a component that duplicates an existing one, spacing off
the token scale, contrast under WCAG AA, colour-only meaning, controls
without focus or name, a mockup outside the app.
