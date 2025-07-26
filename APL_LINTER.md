# APL Linter and Static Analyzer

## 1. Introduction

This document specifies the functionality of the APL Linter, a tool for static analysis of APL (`.apl`) programs. The linter's purpose is to detect errors, enforce best practices, and ensure the logical consistency of a program *without* executing it. This provides a critical layer of quality assurance, analogous to a compiler's syntax check or a linter for a traditional programming language.

The linter is a core component of the APL development workflow, designed to catch issues before they lead to runtime failures. It analyzes the program's structure and data flow based on the rules and definitions in the `APL_LANGUAGE_REFERENCE.md`.

## 2. How the Linter Works

The linter is invoked from the command line with a `--lint` or `--validate` flag, instructing the `APL_RUNTIME` to perform a static analysis instead of a full execution.

```bash
$ apl --lint my_program.apl
```

The process involves three main stages:

1.  **Parsing and Syntax Validation:** The linter first parses the YAML structure of the `.apl` file. It checks for basic syntax errors and ensures the program conforms to the fundamental structure defined in the language reference (e.g., presence of phases, steps with `name` and `tool` keys).

2.  **Logical Flow Analysis:** This is the core of the linting process. The linter builds a model of the program's execution flow and state management. It simulates the program's execution path step-by-step, but instead of running the tools, it validates the inputs and outputs of each step.

3.  **Reporting:** The linter generates a report detailing any errors or warnings it found, along with line numbers and clear explanations. A successful linting process will result in no output.

## 3. Linter Checks and Rules

The linter enforces the following rules, categorized by severity:

### **[ERROR] Critical Issues**

These are issues that would almost certainly cause the program to fail during execution. The linter will exit with a non-zero status code if it finds any of these.

*   **Missing Required Fields:** A step is missing a `name` or `tool` field.
*   **Unresolved Template Variable:** A step uses a variable `{{variable}}` that was not `register`ed in a preceding step.
*   **Invalid Phase Structure:** The program uses phase names not defined in the language reference (e.g., `setup`, `main`, `finalize`).
*   **Invalid `foreach` Loop:** The `in` variable for a `foreach` loop is not a known collection or is used before it's registered.

### **[WARNING] Potential Problems**

These are issues that may not cause a crash but are signs of poor practice or logical flaws.

*   **Type Mismatch:** A tool that expects a list (like `foreach`) is given a variable that likely holds a string (e.g., from `read_file`).
*   **Unused Registered Variable:** A variable is saved with `register` but is never used in a subsequent step.
*   **Use of Relative Paths:** A `read_file` or `write_file` step uses a relative path, which can be less robust than an absolute path.
*   **Potentially Dangerous Shell Command:** The linter can be configured to warn about shell commands that contain potentially destructive operations like `rm -rf`.

## 4. Example Linter Report

Given the following `bad_program.apl`:

```yaml
# bad_program.apl
setup:
  - name: "Load repo list"
    tool: read_file
    path: "./repos.txt"
    register: repo_list_string

main:
  foreach:
    in: repo_list_string # Warning: Looping over a string
    loop_var: repo_url
  run:
    - name: "Fetch PRs"
      # Error: Missing 'tool' keyword
      command: "gh pr list --repo {{repo_url}}"
      register: prs

    - name: "Analyze PRs"
      tool: analyze_pr_diff
      # Error: Using a variable that was never registered
      using: "{{undefined_variable}}"
```

The linter would produce the following report:

```
APL VALIDATION REPORT

File: /home/beloblotskiy/apl/bad_program.apl

*   [ERROR] Line 14: Missing Required Field
    *   Message: The step "Fetch PRs" is missing the required `tool` field.
*   [ERROR] Line 18: Unresolved Template Variable
    *   Message: The variable `{{undefined_variable}}` is used but has not been registered in a previous step.
*   [WARNING] Line 8: Logical Type Mismatch
    *   Message: The `foreach` loop is attempting to iterate over `repo_list_string`, which was produced by `read_file` and is likely a single string. The `split` tool should be used first to turn it into a list.

Validation Failed: 2 errors, 1 warning.
```

## 5. Integration with the APL Runtime

The linter is not a separate executable but a mode of the main `apl` runtime. The runtime will inspect the command-line arguments, and if `--lint` is present, it will invoke the linter logic instead of the standard execution engine. This ensures that the linter and the runtime are always in sync regarding the language specification.
