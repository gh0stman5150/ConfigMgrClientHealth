---
name: refactor
description: 'Refactor ConfigMgrClientHealth.ps1 without changing behavior: remove duplication, split large functions, and delete dead code in small tested steps. Use for gradual cleanup of existing script functions, not rewrites or feature work.'
license: MIT
---

# Refactor

Improve the structure of [ConfigMgrClientHealth.ps1](../../../ConfigMgrClientHealth.ps1) without changing what it does. Follow [repository guidance](../../copilot-instructions.md), especially the safety and test-architecture sections.

## Rules

1. **Behavior is preserved.** Keep `$Log` property names, XML element names, return values, console and log output, and remediation side effects unchanged unless the user asks otherwise.
2. **Tests come first.** If the function has no test, add one that pins its current behavior before changing it. Without a test, you are editing, not refactoring.
3. **Small steps.** Change one function or one pattern per step, and run the Pester suite after each.
4. **Don't mix refactoring with fixes.** If you find a bug, report it or fix it as a separate change.
5. **Stay self-contained.** New helpers are local functions in the script, not modules or external files.

## Refactors that fit this script

- **CIM/WMI duplication:** replace an `if ($PowerShellVersion -ge 6) { Get-CimInstance ... } else { Get-WmiObject ... }` pair with `Get-CimOrWmiInstance` only when both branches pass the same class, namespace, filter, and properties. Leave `Get-Hotfix` fallbacks, `Invoke-CimMethod` / `Invoke-WmiMethod` calls, and DMTF date conversions (`ConvertToDateTime`) alone, because they really differ by version.
- **Large functions:** split long `Test-*` functions (for example `Test-Service`) into a detection function and a remediation function. Keep the original function name as the entry point that the Process block calls.
- **Dead code:** delete commented-out code; git history keeps it. Keep comments that explain why something is deliberately disabled.
- **Repeated literals:** when the same class name, registry path, or message appears in several functions, a local variable in the Begin block is fine if it doesn't change the config contract.

## Layout constraints

- Keep every function in the form `Function Name {` at the start of a line, with its closing brace followed by the next `Function`. The test extractor depends on this.
- Put a function's comments inside its body, not between functions.
- When a refactored function calls a new helper, update its tests to extract or mock that helper.

## Checks after each step

1. Parse the script with the command in repository guidance and confirm there are no errors.
2. Run the full Pester suite and report the counts.
3. Review the diff for any change in output text, `$Log` values, or remediation calls.
4. Never run or dot-source the script itself to check a refactor.
