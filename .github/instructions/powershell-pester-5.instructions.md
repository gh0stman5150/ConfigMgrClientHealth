---
applyTo: '**/*.Tests.ps1'
description: 'PowerShell Pester 6.2 testing standards for NetworkShare Permissions'
---

# PowerShell Pester 6.2 Testing Standards

This repository enforces strict desired state for SMB share and NTFS permissions. Tests must validate safety, identity handling, and enforcement correctness.

Follow general PowerShell guidelines from powershell.instructions.md.

## 1. File Naming and Structure

1. Use the *.Tests.ps1 naming convention.
2. Place test files next to the tested code or under a dedicated Tests directory.
3. Import tested functions using BeforeAll and dot sourcing or module import.
4. Do not place executable code outside Pester blocks.

## 2. Test Structure

Use the following hierarchy:

1. BeforeAll for module import and shared setup.
2. Describe named after the function under test.
3. Context blocks for logical scenarios.
4. It blocks for individual assertions.
5. Use AfterAll or AfterEach for cleanup if required.

Example structure:

BeforeAll  
Describe  
Context  
It  

## 3. Mandatory Test Coverage for This Repository

Every change affecting permission logic must include tests covering the following areas.

### 3.1 Strict Enforcement Logic

1. Entries not present in the profile must appear in the removal list.
2. Entries present in the profile must not appear in the removal list.
3. Entries missing from the system must appear in the add list.
4. Comparison must be based on SID values, not string identity.

### 3.2 Break Glass Behavior

1. BUILTIN\Administrators must never appear in removal lists.
2. NT AUTHORITY\SYSTEM must never appear in removal lists.
3. Break glass principals must remain protected even if not defined in the profile.

### 3.3 Identity Resolution

1. Desired profile identities must resolve to SIDs.
2. If a desired identity cannot resolve, the function must throw before Apply.
3. Current ACL identities that cannot resolve must not cause failure in report mode.
4. Orphaned SIDs must be treated as removable drift.

### 3.4 NTFS Enforcement Scope

1. Only explicit ACEs at the share root may be modified.
2. Inherited ACEs must never appear in removal operations.
3. Inheritance state must remain unchanged.

### 3.5 Share Layer Behavior

1. Share removals must be planned when not in profile.
2. Failed share revoke operations must be captured in NeedsManual.
3. A single revoke failure must not terminate the entire operation.

## 4. Mocking Standards

1. Mock external dependencies such as Get-SmbShareAccess, Grant-SmbShareAccess, Revoke-SmbShareAccess, and Get-Acl.
2. Use ParameterFilter to scope mocks precisely.
3. Use Should -Invoke to verify command invocation counts.
4. Use -Verifiable and Should -InvokeVerifiable when required.

Do not allow real file system or share changes during unit tests.

## 5. Data Driven Tests

1. Use -ForEach or -TestCases for multiple profile scenarios.
2. Include at least one test case with orphaned SID entries.
3. Include at least one test case with unresolved desired identity to validate failure behavior.
4. Use descriptive test names with variable substitution.

## 6. Assertions

Use explicit Should assertions.

1. Use -Be or -BeExactly for exact comparisons.
2. Use -Contain or -HaveCount for collection validation.
3. Use -Throw for expected terminating behavior.
4. Avoid multiple unrelated assertions in a single It block.

## 7. Error Handling Tests

1. Validate that desired identity resolution failure throws.
2. Validate that report mode does not throw for orphaned current entries.
3. Validate that Apply mode requires Force in remote execution.
4. Validate that backup creation failure prevents changes.

## 8. Test Isolation

1. Each test must be independent.
2. Do not rely on execution order.
3. Do not depend on external AD or file server connectivity.
4. Use mocks to simulate identity resolution outcomes.

## 9. Configuration

Use Pester 6.2 configuration externally when running tests.

Example:

1. Create a New-PesterConfiguration object.
2. Set Run.Path to the Tests folder.
3. Enable detailed output and test results.
4. Enable Should.ErrorAction Continue for full failure reporting when appropriate.

Invoke-Pester using the configuration object.


