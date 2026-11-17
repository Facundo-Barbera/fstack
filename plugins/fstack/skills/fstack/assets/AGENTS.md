# AGENTS.md

Rules for any coding agent in this repo. Keep it short; delete slots that do not apply.

## Project

- What it is: <one line: the product and who uses it>
- Stack and layout: <languages, package manager, top-level folders>
- Design system: <where tokens and components live>

## Commands

- Install: `<command>`
- Typecheck and lint: `<command>`
- Tests: `<command>`
- E2E (needs the dev server): `<command>`

## Rules

1. Nothing is done without evidence; anything unchecked is NOT VERIFIED, with why.
2. Reuse existing tokens, components and names before creating new ones.
3. No hard-coded colours, sizes, paths or IDs; they come from tokens or config.
4. Files stay under 400 lines. Comments explain why. Fix causes, not symptoms.
5. No stray markdown or report files; reports go in the PR body.
6. Never print secrets or `.env` contents.
7. Data work is done only against the real dev database, never mocks alone.

## Local rules

<What this repo needs that is not above.>
