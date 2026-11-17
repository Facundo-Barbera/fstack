---
name: ui-adopt
description: Inventory the repo's existing design tokens, components, navigation and vocabulary before any UI work. Use first on any task that touches screens, CSS or components, and when adopting an existing repo.
---

# ui-adopt

What already exists is the norm. The design system lives in code (tokens and
components), never in a separate design document.

## Steps

1. Find the tokens: colour, spacing, radius, type scale, shadows, breakpoints
   (CSS variables, theme files, Tailwind config, design-token JSON).
2. List the components in use and where they live. Note the ones used most.
3. Map navigation: routes, layouts, how screens link to each other.
4. Collect vocabulary: what the product calls its things (labels, entity names).
   One concept, one name; reuse the existing one.
5. Note dark-mode support and i18n setup (where strings live).

## Output

A short inventory in your working notes or the PR body (never a committed file):

- Tokens: file paths and the token families available.
- Components: the ones you will reuse for this task.
- Gaps: anything missing that the task needs. Propose adding it as a token or
  component; do not inline a one-off value.

## Rules

- Never introduce a parallel token set or a second button/card component.
- If the repo has no tokens yet, the first UI PR creates them; nothing else.
