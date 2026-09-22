---
applyTo: '.github/skills/**/SKILL.md'
description: 'Repository-local skill constraints for ConfigMgrClientHealth'
---

# Repository Skill Constraints

- Keep skills usable in a standalone checkout. Follow [repository guidance](../copilot-instructions.md).
- Describe the skill's purpose and actual activation conditions clearly; load supporting
  resources only when needed.
- Preserve the existing Windows-only, self-contained script and XML configuration contract.
  Reuse local functions where appropriate without inventing shared-module dependencies.
- Do not assume report-only behavior or an Apply parameter. Verify actual ShouldProcess
  coverage before describing an operation as preview-safe.
- Do not execute or dot-source the production entry point for analysis or test setup.
- Mock external effects in unit tests; keep credentials and production data out of fixtures.
- Preserve compatibility with the documented runtime when bundling PowerShell helpers.
- Keep generated changes scoped to this repository and report validation actually performed.
  Do not impose a commit format or cross-repository workflow absent from this repository.
