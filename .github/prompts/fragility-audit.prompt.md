---
description: 'Audit a selected PowerShell workflow for fragility under reruns, partial failure, reboot, and remoting loss; report before patching.'
argument-hint: 'Repository or script, failure trigger, and optional observed error or failing test'
agent: 'agent'
---

# Fragility Audit

Identify evidence-backed causes of fragility in the requested PowerShell workflow
without changing its architecture, public interfaces, or operational safety contract.
This invocation is an audit, not authorization to modify files or production state.
Report findings and wait for explicit approval before implementing fixes.

## 1. Establish Scope and Authority

- Use the supplied repository, script, symbol, failing command, or test as the anchor.
  If none is supplied, use relevant selected code or the active implementation file.
  If the only context is this prompt or the workspace root, ask for a target and
  failure trigger; do not launch an unbounded workspace audit.
- Resolve the owning checkout from the selected target, not from this prompt's location.
  Read that repository's AGENTS.md, `.github/copilot-instructions.md`, and applicable
  subtree instructions. Use enclosing workspace guidance when available, but do not
  require a parent workspace or sibling checkouts. Repository and subtree contracts
  take precedence over workspace defaults.
- Run Git commands only in the owning checkout; do not assume an enclosing workspace
  directory is a Git checkout. Preserve all unrelated working-tree changes.
  Cross-repository changes require explicit scope approval.
- Record the entrypoint, failure trigger, expected behavior, and required execution
  context. Establish the supported PowerShell version, OS, privileges, dependencies,
  and interactive or unattended mode from code and local guidance, not assumptions.
- Inspect nearby implementation and tests before broad searches. State a falsifiable
  local hypothesis and the cheapest safe check that could disconfirm it. Follow
  forwarding code to the function that actually controls the behavior.

## 2. Trace the Actual Failure Path

Trace only dependencies relevant to the selected failure: module imports, configuration,
files, credentials, sessions, services, jobs, scheduled tasks, and external APIs.
Read nearby manifests, README or design documentation, and CI only as needed to verify
the contract and validation commands. Do not assume every repository has the same layout.

For each relevant dependency, establish:

- What must already be true at invocation, and what happens when it is absent, stale,
  inaccessible, or changed out of band.
- Which state is process/session-local, temporary, or durable; where it is actually
  stored; and what survives rerun, disconnect, reboot, or partial completion.
- Which endpoint performs discovery, prerequisite checks, mutation, and verification.
  Remoting failures must never silently fall back to the controlling host.
- How failures propagate through terminating errors, native exit codes, job results,
  returned objects, and logs. Check for swallowed errors or false success reports.
- Whether module resolution works in the documented execution context, including
  standalone checkouts when supported. When the target depends on WindowsAdmin.Core,
  inspect its actual available exports and consumer call sites before recommending
  shared helpers. If the dependency is unavailable, report that limitation rather
  than assuming a sibling checkout; do not invent APIs or copy shared implementations
  into consumers.

Do not execute administrative entrypoints, contact live infrastructure, or collect
credentials to reproduce a defect. Prefer static inspection and isolated mocked tests.
Inspect test setup before running it; tests and imports can also have side effects.
Do not assume that invoking a script with -WhatIf makes all its operations harmless.

## 3. Check Recovery and Safety Where Applicable

Use the following as failure probes, not requirements to add absent mechanisms:

- Reruns after success and after partial failure: duplicate work, destructive retries,
  skipped incomplete work, and whether claimed idempotency actually holds.
- Lost remoting sessions, unavailable dependencies, expired authentication, timeouts,
  and retries: bounded retry behavior and preservation of the explicit target.
- Missing, stale, or partially written state; reboot or interrupted execution between
  mutation and checkpoint; externally changed resources before the next run.
- Existing locks, jobs, temporary files, and sessions: stale ownership, concurrent runs,
  and cleanup that affects only resources owned by that invocation. Do not assume
  finally blocks run after forced process termination.
- Preview, confirmation, and apply paths: preserve the owning repository's semantics.
  Audit-only behavior here does not mean all production scripts default to report-only.
  Preserve required ShouldProcess boundaries and unattended execution constraints.
- Stable result objects, useful error records, and logs that contain no secrets.

Do not assume a reconciler, retry loop, lock, incident history, or recovery facility
exists. Mark absent or irrelevant mechanisms accordingly. If relevant runbooks,
changelogs, regression tests, or incident notes exist, compare their claims with current
code. Treat documentation and historical fixes as leads, not proof of current behavior.

## 4. Report and Stop for Approval

Lead with findings ordered by severity. For each finding include:

- Repository and file/line reference to the controlling code.
- Failure trigger, required conditions, and observable impact.
- Evidence and root cause, distinguishing confirmed behavior from an untested hypothesis.
- The smallest compatible fix, affected consumers, and any safety or interface risk.
- A focused regression test or other safe check that would demonstrate the defect and fix.

Then list checks actually run and their results, unverified environments or missing
test infrastructure, and remaining questions. If no actionable defects are found,
say so without implying that untested runtime behavior is verified.

Propose a bounded patch scope and wait for approval. Do not edit source, tests,
documentation, or workflows during this audit phase. Do not commit, push, deploy,
or perform production remediation.

## 5. After Explicit Patch Approval

- Implement only approved fixes, preserving unrelated changes and existing contracts.
  Approval to edit source does not authorize live endpoint operations or deployment.
- Extend nearby Pester 6.2 tests using existing helpers and fixtures. Mock external
  dependencies; cover the relevant rerun, partial-failure, state-loss, remoting, or
  cleanup scenario rather than adding every probe above to every repository.
- Use WindowsAdmin.Core test helpers only where actually available and appropriate.
  Do not invent a framework or treat an absent suite as a passing gate.
- Immediately after the first substantive edit, run the cheapest focused safe check.
  Repair local defects and rerun it before expanding scope. Then run the owning
  repository's required gates using its actual Pester configuration, PSScriptAnalyzer
  settings, and CI commands. Do not substitute the workspace test harness for local
  gates or run operational scripts as lint checks.
- Update affected documentation only when behavior changes warrant it. Keep runtime
  fixes out of CI/setup files unless evidence identifies a workflow defect.
- Report files changed, validation results, skipped or unavailable checks, and residual
  risks. Distinguish mocked coverage from live validation and stop within approved scope.


