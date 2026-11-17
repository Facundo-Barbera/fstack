---
name: ui-ref
description: Open and cite the visual reference the user sent (screenshot or URL) and extract measurements, density and hierarchy from it. Use whenever a UI task comes with a reference image, link or "make it look like X".
---

# ui-ref

The user's reference outranks your taste and the AGENTS.md density line.

## Steps

1. Open the reference. If it is a URL and you cannot open it, say
   **NOT VERIFIED: reference not opened** and ask for a screenshot.
2. Cite it in your notes and PR body (file name or URL).
3. Extract, in numbers where possible:
   - layout: columns, max width, alignment;
   - density: row height, gaps, padding, items visible per screen;
   - hierarchy: what is largest, boldest, first;
   - type: sizes and weights relative to body text.
4. Map every value to the nearest existing token (see `ui-adopt`). When none is
   close, propose a new token instead of a raw value.

## Rules

- High fidelity to the reference, expressed only through the repo's tokens.
- If the reference conflicts with the existing system, list the conflict and ask
  which wins; do not mix both.
