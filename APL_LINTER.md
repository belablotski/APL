# APL Linter and Static Analyzer - v0.2

## 1. Introduction

This document specifies the functionality of the APL Linter, a tool for static analysis of APL (`.apl`) programs. The linter's purpose is to detect errors, enforce best practices, and ensure the logical consistency of a program *without* executing it. This provides a critical layer of quality assurance, analogous to a compiler's syntax check or a linter for a traditional programming language.

The linter is a core component of the APL development workflow, designed to catch issues before they lead to runtime failures. It analyzes the program's structure, tool usage, and data flow based on the rules and definitions in the `APL_LANGUAGE_REFERENCE.md`.

## 2. How the Linter Works

The linter is invoked from the command line with a `--lint` or `--validate` flag, instructing the `APL_RUNTIME` to perform a static analysis instead of a full execution.

```bash
$ apl --lint my_program.apl
```

The process involves four main stages:

1.  **Configuration and Tool Discovery:** The linter begins by finding and parsing the `.aplconfig` file. It identifies all `tool_paths` and scans them for `*.tool.apl` definition files. It builds an in-memory **Tool Registry** of all available custom tools, parsing their `inputs` and `outputs` for later validation.

2.  **Parsing and Syntax Validation:** The linter parses the YAML structure of the target `.apl` file. It checks for basic syntax errors and ensures the program conforms to the fundamental structure (e.g., presence of phases, steps with `name` and `tool` keys).

3.  **Logical Flow and Tool Validation:** This is the core of the linting process. The linter builds a model of the program's execution flow and state management. It simulates the program's execution path step-by-step. For each step, it performs two key checks:
    *   **Tool Existence:** It verifies that the specified `tool` exists. It first checks against the list of **Standard Tools** (`shell`, `read_file`, etc.). If no match is found, it checks against the **Tool Registry**, which contains all discovered **Custom Tools** (both agent-native and APL-defined).
    *   **Parameter Validation:** It validates that the parameters passed to the tool are correct. For APL-defined tools, it checks the `with_inputs` block against the tool's declared `inputs`. For Standard tools, it checks for required parameters (e.g., `path` for `read_file`). The linter also recognizes the `using` keyword as a valid parameter for passing contextual hints to agent-native tools.

4.  **Reporting:** The linter generates a report detailing any errors or warnings it found, along with line numbers and clear explanations. A successful linting process will result in no output.

## 3. Linter Checks and Rules

The linter enforces the following rules, categorized by severity:

### **[ERROR] Critical Issues**

These are issues that would almost certainly cause the program to fail during execution. The linter will exit with a non-zero status code if it finds any of these.

*   **Unknown Tool:** A step specifies a `tool` that is not a built-in function and is not defined in any `*.tool.apl` file found in the `tool_paths`.
*   **Missing Required Tool Input:** A step using a custom tool fails to provide a value in `with_inputs` for an input marked as `required: true` in the tool's definition file.
*   **Invalid Tool Parameter:** A step using a built-in tool is missing a required parameter (e.g., using `read_file` without a `path`).
*   **Missing Required Fields:** A step is missing a `name` or `tool` field.
*   **Unresolved Template Variable:** A step uses a variable `{{variable}}` that was not defined in the `inputs` section, registered in a preceding step, or is a built-in variable.
*   **Invalid Input Definition:** An item in the `inputs` section is missing a required field like `name` or `description`.
*   **Missing Input in `run_apl` Call:** A `run_apl` step fails to provide a value for an input that is marked as `required: true` in the sub-program.
*   **Invalid Phase Structure:** The program uses phase names not defined in the language reference (e.g., `setup`, `main`, `finalize`).
*   **Invalid `foreach` Loop:** The `in` variable for a `foreach` loop is not a known collection or is used before it's registered.

### **[WARNING] Potential Problems**

These are issues that may not cause a crash but are signs of poor practice or logical flaws.

*   **Type Mismatch:** A tool that expects a list (like `foreach`) is given a variable that likely holds a single string (e.g., from `read_file`).
*   **Unused Registered Variable:** A variable is saved with `register` but is never used in a subsequent step.
*   **Use of Relative Paths:** A `read_file` or `write_file` step uses a relative path, which can be less robust.
*   **Potentially Dangerous Shell Command:** The linter can be configured to warn about shell commands that contain potentially destructive operations like `rm -rf`.

## 4. Example Linter Report

Given the following `bad_program.apl`:

```yaml
# bad_program.apl
setup:
  - name: "Load repo list"
    tool: read_file
    # Error: Missing 'path' parameter for built-in tool
    register: repo_list_string

main:
  - name: "Clone a repository"
    tool: clone_repository # Error: This tool does not exist
    with_inputs:
      repo: "https://github.com/google/gemini-cli.git"

  - name: "Ensure our repo is ready"
    tool: ensure_repo_is_cloned # This tool is valid
    with_inputs:
      # Error: Missing required input 'workspace_path'
      repo_url: "https://github.com/google/gemini-cli.git"
```

The linter would produce the following report:

```
APL VALIDATION REPORT

File: /home/beloblotskiy/apl/bad_program.apl

*   [ERROR] Line 5: Invalid Tool Parameter
    *   Message: The step "Load repo list" uses the built-in tool `read_file` but is missing the required `path` parameter.
*   [ERROR] Line 9: Unknown Tool
    *   Message: The step "Clone a repository" uses the tool `clone_repository`, which is not a built-in tool and could not be found in any of the configured `tool_paths`.
*   [ERROR] Line 14: Missing Required Tool Input
    *   Message: The step "Ensure our repo is ready" is missing the required input `workspace_path` for the custom tool `ensure_repo_is_cloned`.

Validation Failed: 3 errors.
```

## 5. Integration with the APL Runtime

The linter is not a separate executable but a mode of the main `apl` runtime. The runtime will inspect the command-line arguments, and if `--lint` is present, it will invoke the linter logic instead of the standard execution engine. This ensures that the linter and the runtime are always in sync regarding the language specification and the available tools.
