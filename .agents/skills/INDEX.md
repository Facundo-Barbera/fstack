# Skill index

Find your task type, load every skill listed, and close with the evidence shown.
Your role (worker or orchestrator) decides which half of the evidence you produce.

| Task | Load these skills | Evidence to close |
| --- | --- | --- |
| Screens, CSS, components | ui-adopt, ui-ref, ui-directions, ui-build, ui-verify, ui-review | worker: tests with fixtures; orchestrator: screenshots at 360/768/1280 |
| Endpoints, contracts | verify, review | contract test plus one real call |
| Schema, migrations | verify, review | migration run on a preview database |
| Infra, cost, deploy | review | plan or diff plus the owner's OK |
| Tests, bugs | verify | E2E or property test that failed, then passes |
| Secrets, permissions | review | clean gitleaks run |
| Open or review a PR | review, digest | `Verified:` trailer on every commit |
| Adopt an existing repo | org-audit, ui-adopt | cleanup PR proposal plus AGENTS.md draft |
| Brief another agent | delegate | brief starts with the delegate preamble |

Every commit carries `Verified: <skill> <evidence>` (or `Verified: none`).
Anything you could not check is reported as **NOT VERIFIED** with the reason.
