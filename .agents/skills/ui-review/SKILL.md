---
name: ui-review
description: Review a UI diff against an "AI slop" rubric and an accessibility checklist. Use when reviewing any PR or self-reviewing before closing a UI task.
---

# ui-review

Review only the diff. Each finding cites file and line and names the rule.

## Slop rubric (flag every hit)

- Gratuitous gradients, glows or glassmorphism nobody asked for.
- Boxes inside boxes: cards in cards, borders around bordered things.
- Decorative icons that carry no meaning.
- Invented density: spacing or sizes that match neither the reference nor tokens.
- Raw hex, rgb or `[Npx]` values outside token files.
- Colour as the only signal (status dots, red/green deltas without text or icon).
- Two names for one concept; new words where the product already has one.
- A new component that duplicates an existing one.

## Accessibility checklist

- Text contrast meets WCAG AA in dark and light themes.
- Every interactive element is reachable and operable by keyboard, with a
  visible focus style.
- Images and icon-only buttons have accessible names.
- Form fields have labels; errors are announced in text, not only colour.
- Touch targets are comfortable at 360 px wide.
- Motion respects reduced-motion preferences.

## Output

Findings ranked by severity with labels: ⛔ Blocks, ⚠ Review, ℹ Note.
