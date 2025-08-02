# APL Linter and Static Analyzer - v0.3

## 1. Introduction

This document specifies the functionality of the APL Linter, a tool for static analysis of APL (`.apl`) programs. The linter's purpose is to detect errors, enforce best practices, and ensure the logical consistency of a program *without* executing it. This provides a critical layer of quality assurance, analogous to a compiler's syntax check or a linter for a traditional programming language.

The linter is a core component of the APL development workflow, designed to catch issues before they lead to runtime failures. It analyzes the program's structure, tool usage, and data flow based on the rules and definitions in the `APL_LANGUAGE_REFERENCE.md`.

## 2. How the Linter Works

The linter is invoked from the command line with a `--lint` or `--validate` flag, instructing the `APL_RUNTIME` to perform a static analysis instead of a full execution.

```bash
$ apl --lint my_program.apl
```

The process involves five main stages:

1.  **Standard Library Loading:** The linter first looks for a file named `APL_STL.yml` in the same directory as the `APL_RUNTIME.md` file specified for the execution environment. If found, it parses this file and adds all defined tools to its internal Tool Registry as agent-native tools.
2.  **Configuration and Tool Discovery:** The linter discovers tools from both global and local scopes.
    *   **Global Tools:** It finds and parses the `.aplconfig` file to identify all global `tool_paths` and scans them for `*.tool.apl` definition files.
    *   **Local Tools:** It parses the target `.apl` file for a `local_tool_paths` list. If found, it scans those directories (relative to the `.apl` file) for `*.tool.apl` files.
    *   It adds all discovered tools to the Tool Registry. Local tools take precedence over global tools, and all custom tools override standard library tools of the same name.
3.  **Parsing and Syntax Validation:** The linter parses the YAML structure of the target `.apl` file. It checks for basic syntax errors and ensures the program conforms to the fundamental structure (e.g., presence of phases, steps with `name` and `tool` keys, valid control flow structures like `foreach` and `while`).
4.  **Logical Flow and Tool Validation:** This is the core of the linting process. The linter performs a state-aware, sequential analysis of the program. It initializes a "known variables" model with the program's `inputs` and built-in variables (e.g., `module_path`). Then, it simulates the execution path step-by-step. For each step, it first validates that all templated variables used in the step's parameters exist in the current state model. After validation, it updates the state model with any variables registered by that step (via `register` or `set_vars`) before moving to the next one.

    During this simulation, it performs two key checks for each step:
    *   **Tool Existence:** It verifies that the specified `tool` exists in the fully assembled Tool Registry.
    *   **Parameter Validation:** It validates that the parameters passed to the tool are correct. For APL-defined tools, it checks the `with_inputs` block against the tool's declared `inputs`. For Standard tools, it checks for required parameters (e.g., `path` for `read_file`). The linter also recognizes the `using` keyword as a valid parameter for passing contextual hints to agent-native tools. For the special `set_vars` tool, the linter will parse the `vars` map and add each key to its internal model of the Execution Register, making them available for subsequent template validation.

5.  **Reporting:** The linter generates a report detailing any errors or warnings it found, along with line numbers and clear explanations. A successful linting process will result in no output.

## 3. Linter Checks and Rules

The linter enforces the following rules, categorized by severity:

### **[ERROR] Critical Issues**

These are issues that would almost certainly cause the program to fail during execution. The linter will exit with a non-zero status code if it finds any of these.

*   **Unknown Tool:** A step specifies a `tool` that is not a built-in function and is not defined in any global (`tool_paths`) or local (`local_tool_paths`) `*.tool.apl` file.
*   **Missing Required Tool Input:** A step using a custom tool fails to provide a value in `with_inputs` for an input marked as `required: true` in the tool's definition file.
*   **Invalid Tool Parameter:** A step using a built-in tool is missing a required parameter (e.g., using `read_file` without a `path`).
*   **Missing Required Fields:** A step is missing a `name` or `tool` field.
*   **Unresolved Template Variable:** A step uses a variable `{{variable}}` that has not been defined in the program's `inputs` or registered by a *lexically preceding* step. The linter performs a sequential check, so a variable must be known to the state model *before* the current step is analyzed.
*   **Invalid Input Definition:** An item in the `inputs` section is missing a required field like `name` or `description`.
*   **Missing Input in `run_apl` Call:** A `run_apl` step fails to provide a value for an input that is marked as `required: true` in the sub-program.
*   **Invalid Phase Structure:** The program uses phase names not defined in the language reference (e.g., `setup`, `main`, `finalize`).
*   **Invalid `foreach` Loop:** The `in` variable for a `foreach` loop is not a known collection or is used before it's registered.
*   **Invalid `while` Loop:** The condition for a `while` loop contains a variable that is not a known variable in the state model.
*   **Unknown Directive:** A step specifies a `directive` that is not defined in the language reference.

### **[WARNING] Potential Problems**

These are issues that may not cause a crash but are signs of poor practice or logical flaws.

*   **Potential Infinite `while` Loop:** The condition of a `while` loop uses one or more variables, but none of these variables are modified (e.g., via `set_vars` or `register`) inside the `run` block of the loop. This is a strong indicator of an infinite loop.
*   **Missing Loop Execution Directive:** A `foreach` loop does not include the `FORCE_FULL_LOOP_EXECUTION` directive. While not a syntax error, its absence can lead to unreliable execution where the AI interpreter might skip iterations. It is strongly recommended to include this directive on all `foreach` loops.
*   **Type Mismatch:** A tool that expects a list (like `foreach`) is given a variable that likely holds a single string (e.g., from `read_file`).
*   **Unused Registered Variable:** A variable is saved with `register` but is never used in a subsequent step.
*   **Use of Relative Paths:** A `read_file` or `write_file` step uses a relative path, which can be less robust.
*   **Potentially Dangerous Shell Command:** The linter can be configured to warn about shell commands that contain potentially destructive operations like `rm -rf`.
*   **Misplaced Directive:** The `FORCE_FULL_LOOP_EXECUTION` directive is used on a step that is not a `foreach` loop.

## 4. Example Linter Report

Given the following `bad_program.apl`:

```yaml
# bad_program.apl
local_tool_paths:
  - ./my_tools/

setup:
  - name: "Initialize counter"
    tool: set_vars
    vars:
      counter: 10

main:
  while: "counter > 0" # Warning: counter is not modified in the loop
  run:
    - name: "Log something"
      tool: log
      message: "Looping..."

  - name: "Clone a repository"
    tool: clone_repository # Error: This tool does not exist
    with_inputs:
      repo: "https://github.com/google/gemini-cli.git"
```

The linter would produce the following report:

```
APL VALIDATION REPORT

File: /home/belablotski/apl/bad_program.apl

*   [ERROR] Line 17: Unknown Tool
    *   Message: The step "Clone a repository" uses the tool `clone_repository`, which is not a built-in tool and could not be found in any of the configured global or local `tool_paths`.
*   [WARNING] Line 11: Potential Infinite `while` Loop
    *   Message: The condition for the `while` loop depends on the variable `counter`, which is not modified inside the loop's `run` block.

Validation Finished: 1 error, 1 warning.
```

## 5. Integration with the APL Runtime

The linter is not a separate executable but a mode of the main `apl` runtime. The runtime will inspect the command-line arguments, and if `--lint` is present, it will invoke the linter logic instead of the standard execution engine. This ensures that the linter and the runtime are always in sync regarding the language specification and the available tools.
