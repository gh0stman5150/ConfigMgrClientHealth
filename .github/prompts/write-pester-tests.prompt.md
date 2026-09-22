Write or update Pester tests for the specified function or module.

Determine which repository the target code belongs to and apply that repo's safety invariants.

Universal focus areas (all repos)
- Report-only is default behavior; Apply requires explicit switch
- Structured result objects are returned, not Write-Host output
- No interactive prompts in automated or remote paths
- Functions use Set-StrictMode -Version Latest and $ErrorActionPreference = 'Stop'

Repo-specific focus areas (apply when working in that repo)
- NetworkShare-Permissions: SID-based comparison, break glass protection, NTFS inheritance unchanged, backup before Apply
- AD_and_Policy: Credential security, AD object validation, PSLog patterns
- Endpoint-Management: WMI operations mocked, service restart safety, MECM client state
- SharePoint-Management: PnP operations mocked, tenant safety
- WindowsAdmin.Core: Shared module unit tests, cross-repo import validation

Shared module testing
- If the function under test is in WindowsAdmin.Core, also verify consuming repos can import and call it
- If duplicate test helpers exist across repos, propose extraction to WindowsAdmin.Core

Output
- New or updated Pester test file content
- Any required test helper functions or mocks
- Which repo the tests belong to
- How to run the tests from VS Code

Assume PowerShell 7 and Pester 6.2 unless the repo indicates otherwise.

