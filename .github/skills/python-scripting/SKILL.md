---
name: python-scripting
description: Design, create, review, debug, test, secure, document, and maintain Python scripts, command-line tools, modules, and automation. Use for Python code, virtual environments, packaging, argparse, subprocesses, files, APIs, typing, tests, linting, compatibility, or script reliability tasks.
---

# Purpose

Provide operational guidance for production-quality Python scripting and automation. Apply repository instructions, supported Python versions, dependency policies, and explicit user requirements before this skill. Preserve existing behavior unless a change is requested or necessary for correctness or safety.

# When to use this skill

Use this skill when working on:

- Python scripts, modules, packages, command-line tools, automation, and libraries.
- Script creation, modification, review, debugging, refactoring, testing, documentation, performance work, or security hardening.
- Filesystem, process, API, JSON, CSV, XML, configuration, logging, encoding, locale, time-zone, or cross-platform tasks.
- Type annotations, virtual environments, dependency declarations, test failures, formatter, linter, or type-checker findings.

Do not use this skill as a substitute for repository-specific rules. Repository runtime support, packaging conventions, approved dependencies, operating-system constraints, and user instructions take precedence.

# Source and version policy

1. Identify the minimum supported Python version, active interpreter, operating system, execution environment, packaging model, and dependency policy before selecting syntax or APIs.
2. Prefer applicable official Python sources:
   - Python documentation: <https://docs.python.org/3/>
   - Python Enhancement Proposals: <https://peps.python.org/>
   - Official Python releases: <https://www.python.org/downloads/>
3. Treat the Python standard library and third-party dependencies as distinct. Do not describe external packages as built-in.
4. Prefer the standard library when it meets the requirement. Add an external dependency only when repository policy or requirements justify it, and disclose the dependency and version constraints.
5. When documentation-retrieval tools are available, consult applicable official documentation before making material version, syntax, standard-library API, or compatibility claims.
6. When retrieval is unavailable, state material assumptions and do not claim current documentation was verified.
7. Mention official documentation by title and URL only when it was actually accessed. Summarize relevant guidance; do not copy large passages.
8. If permitted official sources do not establish an answer, say so, state the assumption required to proceed, and choose a conservative implementation.

# Required workflow

1. Inspect the request and relevant repository instructions, source, tests, Python-version declarations, dependency files, virtual-environment configuration, CI configuration, formatter, linter, type checker, and naming patterns before editing.
2. Identify the supported Python version range, interpreter, operating system, deployment environment, dependency policy, input trust boundaries, and compatibility requirements.
3. Check existing project utilities and dependencies before adding a package or duplicate abstraction.
4. State important assumptions if the repository does not establish them. Request clarification only when a missing detail prevents a safe or correct result.
5. Consult applicable official documentation for unfamiliar or version-sensitive behavior.
6. Design the smallest maintainable change that meets the requirement and reuse safe project patterns.
7. Implement secure defaults, explicit error handling, logging, deterministic cleanup, and actionable diagnostics.
8. Add or update relevant tests.
9. Run, or clearly recommend, repository-configured formatting, linting, type-checking, security checks, and tests.
10. Review the final change for correctness, security, compatibility, resource handling, destructive behavior, secret exposure, and maintainability.
11. Summarize changes, assumptions, validation actually performed, recommended unrun validation, limitations, dependencies, and official documentation actually consulted.

Never claim a command was run or tests passed unless they were actually executed. Clearly separate executed commands and observed results from commands recommended to run.

# Language-specific engineering standards

- Use syntax and standard-library APIs supported by the repository's minimum Python version.
- Follow applicable official PEP guidance and the repository's established formatter and linting configuration.
- Add type annotations for public interfaces and meaningful internal boundaries when appropriate. Do not add types that obscure clear code without improving the contract.
- Prefer small, cohesive, testable functions with explicit inputs and outputs. Minimize mutable global state.
- Use `pathlib.Path` for path-oriented work when appropriate.
- Use context managers for files, locks, network resources, and other deterministic cleanup.
- Use specific exception types. Do not use bare `except`, broad exception swallowing, or silent failures.
- Parse untrusted structured data with appropriate parsers. Do not use `eval()` or `exec()` on untrusted or dynamically supplied content.
- Use `subprocess.run()` with an argument sequence and explicit options. Do not use `shell=True` unless it is strictly necessary, justified, and safely controlled.
- Specify text encoding when reading or writing files where portability matters. Handle Unicode, locale, line endings, time zones, and platform differences deliberately when relevant.
- Use the `logging` module for operational diagnostics in reusable code. Avoid uncontrolled `print()` output outside a deliberately simple command-line interface.
- Use `argparse` for standard-library command-line interfaces unless the repository already uses an approved framework.
- Provide an explicit `main()` entry point for executable scripts and return meaningful exit status.
- Respect the repository's virtual environment, package manager, lock files, build metadata, and dependency workflow.
- Do not introduce a dependency simply to replace a standard-library feature that meets the requirement.

# Security requirements

- Treat files, command output, API responses, environment variables, command-line arguments, configuration, and user-provided values as untrusted.
- Validate data at trust boundaries with types, range checks, allowlists, canonical paths, schema checks, and semantic validation appropriate to the task.
- Never hard-code, commit, expose, return, or log passwords, tokens, keys, connection strings, private certificates, or other secrets.
- Use placeholders such as `<API_TOKEN>` and `https://example.invalid` in examples.
- Avoid `eval()`, `exec()`, unsafe deserialization, shell command construction, and unsafe dynamic imports.
- Do not build commands by concatenating untrusted strings. Pass a sequence of arguments to subprocess APIs.
- Make destructive operations explicit, scoped, previewable when practical, and guarded by clear authorization.
- Make automation idempotent when practical.
- Protect confidential, proprietary, private, and personal information in code, logs, examples, tests, and responses.
- Explain security-sensitive behavior and destructive effects clearly.
- Refuse requests to conceal malicious behavior, bypass access controls, steal credentials, deploy persistence, or cause unauthorized damage. Support legitimate defensive automation only within the stated scope.
- Do not infer access, identity, or authorization from protected or personal characteristics.
- Do not imply generated code is safe merely because it follows this checklist.

# Error handling and observability

- Raise or handle specific exceptions at the boundary where useful context can be added.
- Preserve exception context with `raise ... from exc` when translating exceptions.
- Emit actionable errors without logging secrets, confidential data, or full untrusted payloads.
- Use appropriately named loggers and levels. Do not configure global logging unexpectedly in reusable libraries.
- Send diagnostics to standard error when a command-line interface requires human-readable messages; preserve machine-readable standard output where applicable.
- Close resources deterministically with context managers and cleanup handlers.
- Return meaningful exit status from executable scripts and distinguish expected user errors from unexpected failures.
- Do not continue after a failed prerequisite or destructive action unless the design intentionally collects independent failures and reports them accurately.

# Testing and validation

- Follow the repository's existing test framework and conventions. Use `unittest` when no approved external framework is present.
- Test public behavior, validation, error paths, exit codes, file handling, resource cleanup, encoding, time-zone behavior, and platform boundaries where relevant.
- Mock network, process, filesystem, clock, and external-service boundaries in normal unit tests.
- Use repository-configured formatter, linter, type checker, and security tools. Do not assume tools such as Ruff, Black, mypy, pyright, Bandit, pytest, or coverage are installed.
- Run focused tests first, then the relevant repository gate when practical.
- When commands cannot run, explain why and provide exact commands to run without fabricating results.

# Documentation and maintainability

- Use clear names, focused modules, explicit contracts, and minimal mutable global state.
- Document rationale, constraints, compatibility requirements, security boundaries, error contracts, and non-obvious behavior. Do not narrate obvious syntax.
- Keep dependency declarations, version constraints, and command-line help aligned with implementation behavior.
- Include usage examples for scripts intended to be run directly.
- Update README, package documentation, command help, and operational guidance when public behavior, prerequisites, output formats, or safety controls change.
- Preserve public APIs and output contracts unless a behavior change is requested and documented.

# Review checklist

- Is the supported minimum Python version known or explicitly assumed?
- Is every syntax feature and standard-library API supported by that version?
- Are standard-library and third-party dependencies clearly distinguished and justified?
- Are public boundaries typed where useful and are functions cohesive and testable?
- Are paths, encodings, locale, Unicode, time zones, and platform differences handled where material?
- Are context managers used for resources and are exceptions specific, visible, and actionable?
- Does subprocess execution use argument sequences without unsafe shell construction?
- Are untrusted values validated and excluded from `eval()`, `exec()`, unsafe parsing, and sensitive logs?
- Are destructive actions explicit, scoped, and idempotent where practical?
- Are tests, formatter, linter, type checker, documentation, and dependency metadata updated as needed?
- Are executed validation results distinguished from recommended commands?

# Output expectations

Return or produce:

- The focused implementation or review findings, with files changed and behavioral impact.
- Supported Python version, platform, interpreter, and dependency assumptions when material.
- Security and destructive-operation implications.
- Tests added or updated and validation commands actually executed with their observed outcome.
- Recommended validation commands not run, clearly labeled as recommendations.
- Limitations, unresolved risks, added dependencies, and official documentation actually consulted, including title and URL when retrieved.

# Examples

## Typed command-line script

```python
from __future__ import annotations

import argparse
import logging
from pathlib import Path

LOGGER = logging.getLogger(__name__)


def count_lines(input_path: Path) -> int:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input file does not exist: {input_path}")

    with input_path.open("r", encoding="utf-8") as input_file:
        return sum(1 for _ in input_file)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Count UTF-8 text-file lines.")
    parser.add_argument("input_path", type=Path, help="Path to the input text file.")
    return parser.parse_args()


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    arguments = parse_args()

    try:
        line_count = count_lines(arguments.input_path)
    except FileNotFoundError as error:
        LOGGER.error("%s", error)
        return 2
    except OSError as error:
        LOGGER.error("Unable to read input file: %s", error)
        return 1

    print(line_count)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

## Review pattern

Review a script that accepts a filename and runs another program by checking whether it:

- Declares a Python version compatible with its syntax and standard-library APIs.
- Uses `Path` and a context manager for file access where appropriate.
- Validates the input before use and reports missing files with a specific exception.
- Uses a subprocess argument sequence rather than `shell=True` or a concatenated command string.
- Uses type annotations and testable functions at meaningful boundaries.
- Keeps sensitive values out of logs, exceptions, examples, and test fixtures.

## Commands to run

```sh
python -m unittest discover -s tests
python -m compileall src
```
