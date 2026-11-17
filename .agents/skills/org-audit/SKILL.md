---
name: org-audit
description: Step 0 for an existing (brownfield) repo - audit structure, stray docs, duplicated agent configs, oversized files, hard-coded values, design inventory and test reality, then propose a cleanup PR and an AGENTS.md draft. Use before adopting fstack in a repo that already has code.
---

# org-audit

Read-only until the owner approves. The report goes in a PR body, never a file.

## Steps

1. Run `scripts/scan.sh` from the repo root for the mechanical part.
2. Structure: monorepo or single app, stacks per folder, package managers.
3. Loose docs: stray markdown that should be code, a README, an ADR or deleted.
4. Agent and tool configs: duplicates (CLAUDE.md, .cursorrules, copilot
   instructions...) to fold into one AGENTS.md.
5. Files over 400 lines: list them; they become the gate baseline, not a rewrite.
6. Hard-coded values: hex colours, pixel values, URLs, IDs, paths.
7. Design inventory: run `ui-adopt`.
8. Test reality: what runs, what is skipped, whether data tests hit a real dev
   database or only mocks.

## Output

- A proposed cleanup PR (branch + description), **not applied** without the
  owner's OK. Body: findings ranked ⛔/⚠/ℹ, what it removes, what it defers.
- A draft AGENTS.md of 150 lines or less from `fstack`'s template, with the
  slots filled from what you found and NOT VERIFIED where you guessed.
