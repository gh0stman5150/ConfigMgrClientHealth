---
name: powershell-scripting
description: Design, create, review, debug, test, secure, document, and maintain PowerShell scripts, advanced functions, modules, and command-line automation. Use for PowerShell, pwsh, Windows PowerShell, Pester, PSScriptAnalyzer, script reliability, remoting, file, process, service, API, or structured-data tasks.
---

# Purpose

Provide operational guidance for production-quality PowerShell automation. Apply repository instructions and explicit user requirements before this skill. Preserve existing behavior unless a change is requested or necessary for correctness or safety.

# When to use this skill

Use this skill when working on:

- PowerShell scripts, `.psm1` modules, `.psd1` manifests, profiles, advanced functions, and command-line tools.
- Script creation, modification, review, debugging, refactoring, testing, documentation, performance work, or security hardening.
- Automation involving files, processes, services, scheduled tasks, CIM, WMI, remoting, REST APIs, JSON, CSV, XML, or Windows administration.
- Pester tests, PSScriptAnalyzer findings, PowerShell compatibility questions, error handling, output contracts, or `ShouldProcess` behavior.

Do not use this skill as a substitute for repository-specific operational rules. Repository safety rules, supported platforms, runtime versions, shared-module policies, and user instructions take precedence.

# Source and version policy

1. Identify the target edition, version, operating system, host, and module versions when they affect correctness:
   - Distinguish Windows PowerShell 5.1 from modern cross-platform PowerShell (`pwsh`).
   - Do not assume commands, parameters, providers, remoting behavior, .NET APIs, encoding defaults, or platform facilities are identical across editions or operating systems.
   - Distinguish built-in commands from commands supplied by modules.
2. Prefer applicable official documentation for unfamiliar or version-sensitive behavior:
   - Microsoft Learn PowerShell documentation: <https://learn.microsoft.com/powershell/>
   - PowerShell documentation repository: <https://github.com/MicrosoftDocs/PowerShell-Docs>
   - Official PowerShell repository and releases: <https://github.com/PowerShell/PowerShell>
   - Official Microsoft documentation for a module that is actually used.
3. When documentation-retrieval tools are available, consult the applicable official source before making material version, parameter, compatibility, or module claims.
4. When retrieval is unavailable, state material assumptions and do not claim current documentation was verified.
5. Mention official documentation by title and URL only when it was actually accessed. Summarize relevant guidance; do not copy large passages.
6. If permitted official sources do not establish an answer, say so, state the assumption required to proceed, and choose a conservative implementation.

# Required workflow

1. Inspect the request and relevant repository instructions, source, tests, manifests, dependency declarations, CI configuration, formatter, linter, and naming patterns before editing.
2. Identify the target PowerShell edition and version, operating system, execution host, privilege model, execution environment, dependencies, and compatibility requirements.
3. Check the repository's existing functions for reusable behavior before adding duplicate helpers; preserve the self-contained script architecture.
4. State important assumptions if the repository does not establish them. Request clarification only when a missing detail prevents a safe or correct result.
5. Consult applicable official documentation for unfamiliar or version-sensitive behavior.
6. Design the smallest maintainable change that meets the requirement, reusing safe project patterns.
7. Implement secure defaults, explicit error handling, actionable diagnostics, and stable output contracts.
8. Add or update relevant tests.
9. Run, or clearly recommend, the repository's formatting, PSScriptAnalyzer, security, and Pester commands.
10. Review the final change for correctness, compatibility, idempotency, destructive behavior, secret exposure, error handling, and maintainability.
11. Summarize changes, assumptions, validation actually performed, recommended unrun validation, limitations, and official documentation actually consulted.

Never claim a command was run or tests passed unless they were actually executed. Clearly separate executed commands and observed results from commands recommended to run.

# Language-specific engineering standards

- Use approved PowerShell verbs and clear singular nouns for public commands.
- Use advanced functions and `[CmdletBinding()]` when common parameter support, streams, `ShouldProcess`, pipeline behavior, or rich error behavior is useful.
- Define explicit parameter types, mandatory state, parameter sets, validation attributes, defaults, and help messages appropriate to the public contract.
- Support pipeline input only where it is meaningful; use `begin`, `process`, and `end` deliberately.
- Return purposeful objects for programmatic consumers. Do not emit presentation-only strings as the primary success output.
- Keep presentation separate from data. Use `Write-Verbose` for diagnostics, `Write-Warning` for recoverable concerns, and appropriate error records for failures. Do not use `Write-Host` as general output.
- Handle terminating and non-terminating errors deliberately. Use `try`, `catch`, and `finally` where cleanup or error translation is needed.
- Use `$ErrorActionPreference` and `-ErrorAction` only with a defined scope and understood effect. Do not silently suppress meaningful failures.
- Use `Join-Path`, provider-aware PowerShell path commands, and relevant .NET path APIs rather than manual path concatenation.
- Do not use `Invoke-Expression`.
- Invoke native commands with explicit executable and argument boundaries; do not create a command string from untrusted input.
- Add `SupportsShouldProcess` and use `ShouldProcess()` for significant state changes when appropriate. Preserve existing `-WhatIf` and `-Confirm` behavior.
- Make repeatable automation idempotent where practical. For workspace-level automation, default to report-only behavior unless explicit authorization enables changes.
- Treat registry access, CIM/WMI, services, scheduled tasks, executable names, paths, and environment variables as platform-sensitive. Do not use Windows-only behavior in cross-platform code without a documented compatibility boundary.
- Use module-qualified command names when command-source ambiguity can change behavior.
- Do not make unapproved global preference, location, environment, module, or session-state changes.
- Add comment-based help for reusable public functions and directly runnable scripts. Include examples that cover declared script parameters.

# Security requirements

- Treat file content, command output, API responses, environment variables, pipeline input, and user-provided values as untrusted.
- Validate input at trust boundaries with types, validation attributes, allowlists, canonical paths, and semantic checks appropriate to the operation.
- Never hard-code, commit, expose, return, or log passwords, tokens, keys, connection strings, certificates with private keys, or other secrets.
- Use placeholders such as `<ApiToken>` and `https://example.invalid` in examples.
- Avoid unsafe dynamic execution and command-string construction. Prefer cmdlets, .NET APIs, parameter binding, and argument arrays.
- Make destructive operations explicit, scoped, previewable, and guarded. Require explicit authorization for apply behavior where the repository requires report-only defaults.
- Protect confidential, proprietary, private, and personal information in code, logs, examples, tests, and responses.
- Explain security-sensitive behavior and destructive effects clearly.
- Refuse requests to conceal malicious behavior, bypass access controls, steal credentials, deploy persistence, or cause unauthorized damage. Support legitimate defensive administration only within the stated scope.
- Do not infer access, identity, or authorization from protected or personal characteristics.
- Do not imply generated code is safe merely because it follows this checklist.

# Error handling and observability

- Fail predictably with actionable error messages that include safe operational context and do not disclose secrets or sensitive payloads.
- Preserve useful error details when rethrowing, including the original exception where appropriate.
- Use error categories, target objects, and stable result objects when creating public automation.
- Emit verbose diagnostics for decisions and warnings for recoverable conditions; keep successful output machine-readable.
- Use `finally` for cleanup of sessions, temporary resources, or disposable objects.
- Return meaningful exit status from executable scripts. Do not confuse informational output with failures.
- Do not continue after a failed prerequisite, remote connection, or destructive operation unless explicitly designed to collect independent failures and report them accurately.

# Testing and validation

- Follow repository test conventions. Use Pester when it is established or required.
- Test public behavior, parameter validation, pipeline behavior, error paths, idempotency, `ShouldProcess` behavior, and serialization contracts where relevant.
- Mock external systems, remoting endpoints, filesystem mutations, services, network calls, and module dependencies in normal unit tests.
- Use PSScriptAnalyzer when available or required by the repository. Address findings intentionally rather than suppressing them broadly.
- Run focused tests first, then the repository validation gate when practical.
- When commands cannot run, explain why and provide exact commands to run without fabricating results.

# Documentation and maintainability

- Use clear names, small cohesive functions, explicit contracts, and minimal mutable global state.
- Prefer existing repository abstractions and shared modules over duplicate implementations.
- Document rationale, constraints, compatibility requirements, security boundaries, and non-obvious behavior. Do not narrate obvious syntax.
- Keep public output object properties stable unless a behavior change is intended and documented.
- Add usage examples for directly executable scripts, including parameter coverage.
- Update relevant README, module help, manifest, or operational documentation when public behavior, prerequisites, or safety controls change.

# Review checklist

- Is the target PowerShell edition, version, operating system, and module source known or explicitly assumed?
- Does the implementation preserve requested behavior and repository safety invariants?
- Are command names approved, parameters typed and validated, and pipeline behavior intentional?
- Is success output structured and are informational, warning, and error streams separated?
- Are non-terminating and terminating errors handled deliberately?
- Are paths, native commands, remoting, and platform-specific features handled safely?
- Is `Invoke-Expression` avoided and is untrusted input prevented from controlling command execution?
- Are destructive actions guarded with clear scope and appropriate `ShouldProcess` support?
- Are secrets absent from source, output, logs, examples, and tests?
- Are tests, PSScriptAnalyzer, compatibility checks, and documentation updated as needed?
- Are executed validation results distinguished from recommended commands?

# Output expectations

Return or produce:

- The focused implementation or review findings, with files changed and behavioral impact.
- Target runtime, platform, module, and compatibility assumptions when material.
- Security and destructive-operation implications.
- Tests added or updated and validation commands actually executed with their observed outcome.
- Recommended validation commands not run, clearly labeled as recommendations.
- Limitations, unresolved risks, and official documentation actually consulted, including title and URL when retrieved.

# Examples

## Secure advanced function

```powershell
function Remove-ExampleArtifact {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$LiteralPath
    )

    process {
        try {
            $item = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove file')) {
                Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
                [pscustomobject]@{
                    Path      = $item.FullName
                    Removed   = $true
                    Timestamp = Get-Date
                }
            }
        }
        catch {
            $message = "Unable to remove the requested file."
            $exception = [System.InvalidOperationException]::new($message, $_.Exception)
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                'RemoveExampleArtifactFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $LiteralPath
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}