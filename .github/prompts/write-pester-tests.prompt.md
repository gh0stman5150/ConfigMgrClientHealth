Write or update focused Pester regression tests for the requested ConfigMgrClientHealth behavior.

1. Read [repository guidance](../copilot-instructions.md), [Pester standards](../instructions/powershell-pester.instructions.md),
   and [the existing test suite](../../Tests/ConfigMgrClientHealth.Tests.ps1).
2. Inspect the affected production functions and their XML-controlled defaults.
3. Load isolated functions; never dot-source or execute the whole remediation script.
4. Mock endpoint and external effects. Cover the relevant success, failure, and disabled-remediation paths.
5. Preserve actual semantics; do not invent an Apply switch or report-only default.
6. Use the Pester version configured by [CI](../workflows/workspace-tests.yml).
7. Run focused tests and report changed files, commands, runtime versions, results, and coverage gaps.

Keep changes to tests and fixtures. Refer implementation defects to cm-client-health-maintainer.
