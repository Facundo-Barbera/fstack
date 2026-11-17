---
name: digest
description: One-screen HTML summary of a PR or a batch for Facundo, from assets/digest.html - what changed in the product, decisions taken, at most 5 items that need him, folded technical detail. Use when opening a PR, closing a task or reporting a batch.
user-invocable: false
---

# digest

Facundo reads little. One screen, product first, no file lists.

1. Copy `assets/digest.html` outside the repo, e.g.
   `${TMPDIR:-/tmp}/fstack/<repo>-<branch>.html`. Never inside the work tree.
2. Fill the blocks in order and delete unused `{{...}}` slots:
   1. **What changed** for a user, one or two sentences; before/after
      screenshots if there is UI.
   2. **Decisions** you took alone, one line of why each.
   3. **Needs your eye**, at most 5, each as icon plus word: ⛔ Blocks,
      ⚠ Review, ℹ Note. Never colour alone; Facundo is colour-blind.
   4. **Technical detail** folded: commands run and their results.
3. Show it with the harness's HTML preview if there is one; otherwise give the
   path. The PR body carries the same blocks in markdown. No report files.

Always in block 3, merged if needed but never dropped: security, data and
migrations, production or deploy, money, irreversible steps, scope changes,
new dependencies, and every failed or NOT VERIFIED check.
