---
name: shell-scripting
description: Design, create, review, debug, test, secure, document, and maintain POSIX sh, Bash, and explicitly requested shell scripts. Use for shell automation, shebangs, portability, quoting, pipelines, command invocation, file handling, ShellCheck, syntax checks, tests, reliability, or security review tasks.
---

# Purpose

Provide operational guidance for production-quality shell scripting. Apply repository instructions, the selected shell, supported shell version, deployment platform, and explicit user requirements before this skill. Preserve existing behavior unless a change is requested or necessary for correctness or safety.

# When to use this skill

Use this skill when working on:

- POSIX `sh`, Bash, or another explicitly requested shell script.
- Script creation, modification, review, debugging, refactoring, testing, documentation, performance work, or security hardening.
- Command-line automation involving files, processes, services, environment variables, APIs, text streams, structured data, temporary files, and cleanup.
- Shebang selection, portability, quoting, pipelines, redirections, globbing, exit status, ShellCheck, or shell test failures.

Do not use this skill as a substitute for repository-specific rules. Repository runtime support, shell availability, operating-system constraints, approved tools, safety rules, and user instructions take precedence.

# Source and version policy

1. Select the target shell before choosing syntax:
   - Treat POSIX `sh` as the portability baseline when portability is required.
   - Use Bash syntax only when Bash is deliberately selected.
   - Do not assume `/bin/sh` invokes Bash.
2. Identify the shell implementation, material version requirement, operating system, deployment environment, available utilities, privilege model, and compatibility requirements.
3. Prefer applicable official sources:
   - The Open Group POSIX specifications: <https://pubs.opengroup.org/onlinepubs/>
   - GNU Bash Reference Manual: <https://www.gnu.org/software/bash/manual/>
   - Official documentation from the maintainer of another explicitly selected shell.
4. Do not claim a construct is POSIX portable unless permitted official POSIX specifications support that claim.
5. When Bash is selected, state material Bash-version requirements for syntax, builtins, arrays, `mapfile`, associative arrays, or other version-dependent features.
6. When documentation-retrieval tools are available, consult applicable official documentation before making material portability, syntax, builtin, or version claims.
7. When retrieval is unavailable, state material assumptions and do not claim current documentation was verified.
8. Mention official documentation by title and URL only when it was actually accessed. Summarize relevant guidance; do not copy large passages.
9. If permitted official sources do not establish an answer, say so, state the assumption required to proceed, and choose a conservative implementation.

# Required workflow

1. Inspect the request and relevant repository instructions, source, tests, CI configuration, shell declarations, deployment scripts, lint configuration, available tools, and naming patterns before editing.
2. Identify the target shell, implementation and version, operating system, execution environment, available external utilities, privilege model, and portability requirements.
3. Check existing repository helpers and conventions before adding a utility or duplicate wrapper.
4. State important assumptions if the repository does not establish them. Request clarification only when a missing detail prevents a safe or correct result.
5. Consult applicable official documentation for unfamiliar or version-sensitive behavior.
6. Design the smallest maintainable change that meets the requirement and reuse safe project patterns.
7. Implement secure defaults, careful quoting, explicit error handling, cleanup, meaningful diagnostics, and stable exit behavior.
8. Add or update relevant tests.
9. Run, or clearly recommend, repository-configured syntax checks, ShellCheck where allowed, security checks, and tests.
10. Review the final change for correctness, shell compatibility, quoting, word splitting, command injection, cleanup, destructive behavior, secret exposure, and maintainability.
11. Summarize changes, assumptions, validation actually performed, recommended unrun validation, limitations, shell-version requirements, and official documentation actually consulted.

Never claim a command was run or tests passed unless they were actually executed. Clearly separate executed commands and observed results from commands recommended to run.

# Language-specific engineering standards

- Use an accurate shebang for the selected shell and deployment environment:
  - POSIX `sh`: `#!/bin/sh`
  - Bash where the deployment environment provides a known Bash path: `#!/usr/bin/env bash` or the repository-required absolute Bash path.
- Write POSIX-compatible syntax by default when portability is required. Do not mix Bash arrays, `[[ ... ]]`, process substitution, `pipefail`, `mapfile`, or other Bash features into a POSIX `sh` script.
- Quote parameter expansions, command substitutions, and path variables unless deliberate field splitting or pathname expansion is required and safe.
- Use `"$@"` to preserve positional-parameter boundaries. In Bash, use arrays when multiple arguments must retain boundaries.
- For POSIX `sh`, use a portable loop or a safely quoted positional-parameter strategy instead of Bash arrays.
- Do not use `eval`.
- Do not parse `ls` output. Use globbing, `find` with careful handling, or another appropriate structured interface.
- Do not construct commands by concatenating untrusted values into a string.
- Prefer `printf` over assumptions about `echo` behavior.
- Handle temporary files securely. Use `mktemp` or another officially documented safe mechanism when temporary storage is necessary.
- Use `trap` for cleanup and signal handling where resources or temporary files must be removed.
- Use pipelines, subshells, redirections, globbing, word splitting, and command substitution deliberately. Account for variable-scope and exit-status effects.
- Recognize that pipeline failure behavior differs by shell:
  - POSIX `sh` does not provide Bash `pipefail`.
  - In Bash, use `set -o pipefail` only after selecting Bash and understanding the script's failure model.
- Use `set -e` and `set -u` only with an understood control-flow model. They do not replace explicit validation or error handling.
- Send diagnostics to standard error and preserve meaningful exit codes.
- Do not assume elevated privileges are available. Check and explain privilege requirements before privileged actions.
- Make repeatable automation idempotent where practical. Make destructive actions explicit, scoped, and guarded.
- Use ShellCheck only when allowed by the task or repository. Treat it as a static-analysis tool, not as official POSIX or GNU Bash documentation.

# Security requirements

- Treat file contents, command output, API responses, environment variables, positional parameters, standard input, and user-provided values as untrusted.
- Validate values at trust boundaries with allowlists, format checks, canonical paths, explicit option parsing, and semantic validation appropriate to the operation.
- Never hard-code, commit, expose, return, or log passwords, tokens, keys, connection strings, private certificates, or other secrets.
- Use placeholders such as `<API_TOKEN>` and `https://example.invalid` in examples.
- Avoid `eval`, unquoted expansion, unsafe command construction, unsafe temporary-file patterns, and accidental glob expansion.
- Make destructive operations explicit, scoped, previewable when practical, and guarded by clear authorization.
- Protect confidential, proprietary, private, and personal information in code, logs, examples, tests, and responses.
- Explain security-sensitive behavior and destructive effects clearly.
- Refuse requests to conceal malicious behavior, bypass access controls, steal credentials, deploy persistence, or cause unauthorized damage. Support legitimate defensive automation only within the stated scope.
- Do not infer access, identity, or authorization from protected or personal characteristics.
- Do not imply generated code is safe merely because it follows this checklist.

# Error handling and observability

- Validate prerequisites, required commands, required files, shell compatibility, and permissions before attempting state changes.
- Emit concise, actionable diagnostics to standard error using `printf`.
- Return meaningful nonzero exit status for failures and preserve status intentionally when wrapping commands.
- Avoid leaking secrets, confidential paths, payloads, or environment values in diagnostics.
- Use cleanup functions and `trap` when temporary files, locks, mounts, or other resources need deterministic cleanup.
- Account for failures inside pipelines, command substitutions, conditionals, loops, and subshells according to the selected shell's semantics.
- Do not continue after a failed prerequisite or destructive action unless the design intentionally collects independent failures and reports them accurately.

# Testing and validation

- Follow the repository's established shell test framework and conventions.
- If no approved shell test framework exists, provide focused executable test cases without adding an unapproved dependency.
- Test argument handling, empty values, whitespace, glob characters, exit codes, cleanup, error paths, idempotency, and platform-specific behavior where relevant.
- Run syntax checks with the selected shell. Use ShellCheck only when permitted by the repository or task.
- Run focused tests first, then the relevant repository validation gate when practical.
- When commands cannot run, explain why and provide exact commands to run without fabricating results.

# Documentation and maintainability

- State the required shell and material shell-version requirement in the script or accompanying documentation.
- Use clear variable and function names, focused functions, explicit contracts, and minimal global mutable state.
- Document rationale, portability choices, external-command dependencies, cleanup behavior, security boundaries, and non-obvious error handling. Do not narrate obvious syntax.
- Include usage examples for directly executable scripts, including required arguments, output behavior, privilege requirements, and safe invocation.
- Update README and operational documentation when public behavior, dependencies, platform requirements, output formats, or safety controls change.
- Preserve public interfaces and exit-code contracts unless a behavior change is requested and documented.

# Review checklist

- Is the selected shell explicit, and does the shebang match the deployment environment?
- Is the script POSIX `sh` compatible where portability is required, or are Bash-specific constructs explicitly justified?
- Are all variable expansions, command substitutions, paths, and positional parameters quoted appropriately?
- Does the script avoid `eval`, parsing `ls`, unsafe temporary files, untrusted command construction, and unquoted untrusted expansion?
- Are `set -e`, `set -u`, and `pipefail` used only with an understood shell-specific failure model?
- Are pipeline, subshell, redirection, globbing, and command-substitution behaviors correct for the selected shell?
- Are cleanup and signal handling implemented with `trap` when needed?
- Are exit codes meaningful and diagnostics actionable without leaking sensitive data?
- Are destructive actions explicit, scoped, guarded, and idempotent where practical?
- Are tests, syntax checks, permitted static analysis, documentation, and compatibility requirements updated as needed?
- Are executed validation results distinguished from recommended commands?

# Output expectations

Return or produce:

- The focused implementation or review findings, with files changed and behavioral impact.
- Target shell, implementation and version, operating system, external-command, and portability assumptions when material.
- Security and destructive-operation implications.
- Tests added or updated and validation commands actually executed with their observed outcome.
- Recommended validation commands not run, clearly labeled as recommendations.
- Limitations, unresolved risks, and official documentation actually consulted, including title and URL when retrieved.

# Examples

## Portable POSIX sh example

```sh
#!/bin/sh

set -u

usage() {
    printf '%s\n' "Usage: $0 DIRECTORY" >&2
    exit 2
}

[ "$#" -eq 1 ] || usage

target_directory=$1

if [ ! -d "$target_directory" ]; then
    printf 'Directory does not exist: %s\n' "$target_directory" >&2
    exit 2
fi

count=0
for item in "$target_directory"/*; do
    [ -e "$item" ] || continue
    count=$((count + 1))
done

printf '%s\n' "$count"
```

## Bash-specific example

```bash
#!/usr/bin/env bash

set -euo pipefail

if (($# == 0)); then
    printf 'Usage: %s FILE [FILE ...]\n' "$0" >&2
    exit 2
fi

files=("$@")

for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
        printf 'Not a regular file: %s\n' "$file" >&2
        exit 2
    fi
done

printf 'Validated %d file(s).\n' "${#files[@]}"
```

## Review pattern

Review a script that deletes generated files by checking whether it:

- States whether it requires POSIX `sh` or Bash and uses a matching shebang.
- Quotes paths and positional parameters, including names containing spaces, wildcard characters, or leading dashes.
- Avoids `eval`, `ls` parsing, concatenated command strings, and insecure temporary files.
- Uses `trap` to remove temporary resources where needed.
- Handles pipeline errors according to the selected shell rather than assuming `pipefail` is portable.
- Requires explicit confirmation or dry-run behavior for destructive actions when appropriate.
- Sends diagnostics to standard error and returns meaningful exit status.

## Commands to run

```sh
sh -n ./scripts/example.sh
bash -n ./scripts/bash-example.sh
shellcheck ./scripts/example.sh
```
