---
name: ui-verify
description: Verify UI changes at two levels - workers without a server (typecheck, lint, component tests with fixtures), the orchestrator with screenshots at 360/768/1280 against a baseline. Use before closing any UI task.
---

# ui-verify

## Worker (no server, ever)

1. Typecheck and lint.
2. Component tests with fixtures: empty, loading, error, long text, many items.
3. Grep your diff for raw hex and `[Npx]` values outside token files.
4. Report: "visual check pending orchestrator" plus the routes and fixtures to
   capture.

## Orchestrator

1. Use the single dev server of the batch (see the lock in the `verify` skill).
2. Capture 360, 768 and 1280 px wide, dark mode first.
3. Diff against the stored baseline. Agents never update baselines; only the
   owner approves a new baseline.
4. If you could not see it, write **NOT VISUALLY VERIFIED** and why.

## Patch cap

At most 2 rounds of visual fixes. If round 2 does not converge, stop patching:
diagnose the layout (container, flow, constraints) and propose a new mockup
through `ui-directions`.
