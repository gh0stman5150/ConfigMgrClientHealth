# CI and Copilot Setup Pattern

This note describes the checked-in workflows. Repository-local workflow files and
Copilot instructions control standalone checkouts; this is not a new workflow template.

## Before editing

Identify whether the failure is setup, compilation, tests, analysis, or reporting. Read
that repo's workflow and invoke the failing command with its shell and working directory.
Reuse the existing pattern; do not regenerate CI for unrelated script changes.

## Copilot environment

- Keep job `copilot-setup-steps`, the Ubuntu runner, read-only contents permission,
  repository checkout, and the existing `github/gh-aw-actions/setup-cli` action.
- Preserve `workflow_dispatch`, scoped push triggers, existing concurrency controls,
  and `persist-credentials: false` where present.
- The setup action revision and its `with.version` CLI input are separate settings.
  Preserve both unless compatibility evidence or an upgrade task requires changing them.
- Limit setup to environment preparation. Do not broaden permissions or add interactive
  authentication to repair a test failure.

## Windows validation

- Keep the Windows runner and `pwsh` shell. Install Pester/PSScriptAnalyzer with the
  owning workflow's version constraint and CurrentUser scope.
- Discover concrete test paths; use `New-PesterConfiguration` with pass-through results.
  Create `TestResults` and write `JUnitXml` to `TestResults/PesterResults.xml`.
- Preserve failure handling, analyzer settings/scope, annotations, and the reporter's
  result-file condition. A missing file or skipped platform test is not a pass.
- Mock infrastructure. Linux setup cannot validate Windows registry, WinRM, ACL, COM,
  or package behavior; state any platform coverage that remains unverified.

## Repository differences

- Modern_PowerShell_ISEv2 pins Pester with `-RequiredVersion`; other current CI files
  use `-MinimumVersion`. Read the actual value from the owning workflow.
- Endpoint-Management uses `java-junit`; other current CI files use `jest-junit`.
  Validate report parsing before changing that choice.
- Tools analyzes recursively; other repos enumerate production files with exclusions.
  Preserve the owning repo's scope.
- Setup action revisions and installed gh-aw CLI versions vary independently across repos.
  A neighboring repo or version comment does not prove they should be synchronized.
- Data-Migration has Copilot setup but no `ci.yml` in this checkout; do not invent a gate.

## Agentic workflows

Where the repo uses gh-aw, edit authored workflow `.md` sources and regenerate with its
configured `gh aw compile` command. Do not hand-edit generated `.lock.yml` or
`agentic_commands.yml`. Preserve repo-local dispatcher/skill paths. Upgrade only for an
upgrade task or demonstrated compatibility need, then validate generated changes.

## Completion evidence

For workflow changes, validate YAML, the failing command, test discovery, failure exit
status, report generation, and analyzer scope as applicable. Distinguish local validation
from GitHub runs. For documentation-only work, check links, contradictions, and the diff;
do not run live administrative scripts.
