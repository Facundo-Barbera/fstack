---
name: digest
description: Produce the one-screen HTML summary of a change for the owner from assets/digest.html - product change, decisions, what needs the owner's eye, folded technical detail. Use when opening a PR, closing a task or reporting a batch.
---

# digest

The owner reads little. One screen, product first, no file lists.

## Steps

1. Copy `assets/digest.html` to the worktree's temp folder (gitignored, e.g.
   `.tmp/digest.html`). Never commit it.
2. Fill the four blocks, in this order:
   1. **What changed** in the product: before/after screenshots when there is UI,
      otherwise one or two sentences a user would understand.
   2. **Decisions** you took on your own, each with one line of why.
   3. **Needs your eye**, at most 5 items, each with icon and word:
      ⛔ Blocks, ⚠ Review, ℹ Note. Never colour alone.
   4. **Technical detail** inside `<details>`: `Removed:`, `Verified:`, commands.
3. Link it from the PR. For a batch, also give a private URL (for example a
   tailnet-only share); never a public one.

## Always surface in block 3

Security, data and migrations, prod or deploy, money, irreversible steps, scope
changes, failed or **NOT VERIFIED** checks, new dependencies. If more than 5 apply,
merge related ones; never drop one of these.

## PR body

Same four blocks in markdown, same order, with the `Removed:` line and the
`Verified:` stamp. The PR body is the report; there is no separate report file.

## Template rules

Dark by default, colour-blind-safe palette, no external fonts, scripts or images
other than the screenshots you add. Replace every `{{...}}` slot or delete it.
