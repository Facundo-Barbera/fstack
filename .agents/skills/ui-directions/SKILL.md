---
name: ui-directions
description: Produce 2-3 genuinely different UI directions as prototypes built with the repo's real tokens and components, then let the user choose before building. Use for new screens or significant redesigns, before ui-build.
---

# ui-directions

## Steps

1. Run `ui-adopt` (and `ui-ref` if there is a reference).
2. Build 2-3 directions that differ in structure, not only colour: e.g. table vs
   cards vs split view; one dense, one calm.
3. Each direction uses the repo's real tokens and components, on a prototype
   route or story (Storybook, a fixture page), so the chosen one can be promoted
   to production code instead of rewritten. No generic standalone HTML.
4. Use realistic fixture data, including long names, empty states and errors.
5. Screenshots at 360, 768 and 1280 px wide come from the orchestrator (workers
   never start servers). As a worker, hand over the routes and fixtures.
6. Present the options with one line each: what it optimises for, what it costs.

## Rules

- The user picks before anything is built for real.
- After the pick, delete the directions that lost in the same PR that builds the
  winner.
