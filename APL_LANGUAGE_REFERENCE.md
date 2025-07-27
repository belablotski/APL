# APL: Agentic Programming Language - v0.2

## 1. Introduction

Welcome to APL, the Agentic Programming Language.

APL is a high-level, declarative language designed to direct AI agents in complex software engineering and data analysis tasks. It is built on a simple but powerful metaphor: **the agent as a computer**.

In this model:
*   **Logic (CPU)**: The agent's core reasoning, planning, and problem-solving engine. You don't program the logic; you direct it.
*   **Memory (RAM)**: The agent's short-term context and state. APL provides a simple mechanism for storing and retrieving information during a program's execution.
*   **Disk (I/O)**: The agent's ability to interact with the world, primarily through reading and writing files, running shell commands, and accessing web resources.

Unlike traditional programming languages that require you to specify the *how* (e.g., `for i in range(len(lines)): ...`), APL allows you to declare the *what* and *why*. You define a sequence of goals, and the agent uses its "CPU" to determine the best way to achieve them.

The language is designed to be readable, structured, and extensible, enabling developers to create robust, predictable, and reusable workflows for AI agents.

## 2. Core Concepts

### Project Configuration (`.aplconfig`)

For larger projects, it is recommended to create a `.aplconfig` file in the root directory. This file centralizes the project's APL configuration.

```yaml
# .aplconfig
# Defines the default APL specifications for this project.

runtime: APL_RUNTIME.md
linter: APL_LINTER.md

# Optional: List of directories where the runtime should look for custom tool definitions.
tool_paths:
  - ./apl_tools/
```

When executing a program, the APL runtime will automatically discover and use the specifications from this file, simplifying user instructions by removing the need to specify the runtime file in every command.

### Programs and Phases

An APL program is a single file (typically with a `.apl` extension) written in YAML. The program is divided into distinct **Phases**, which represent the major stages of a workflow. A typical program might have the following phases:

*   `setup`: For one-time initialization tasks like loading data, creating workspaces, or setting configuration.
*   `main`: The primary processing block, often containing a loop to work through a collection of items.
*   `finalize`: For post-processing tasks like scoring, ranking, and generating reports.

### Steps

Each phase consists of a list of **Steps**. A step is a single, discrete action for the agent to take. Each step has a `name` for clarity and specifies a `tool` to be used.

```yaml
- name: "Fetch PR Metadata"
  tool: shell
  command: "gh pr view {{pr_url}} --json author,title,mergeCommit"
  register: pr_metadata
```

### Tools and the Resolution Hierarchy

**Tools** are the fundamental "verbs" of APL. They represent the agent's capabilities. The APL runtime discovers and resolves tools according to a strict hierarchy, allowing for a powerful system of defaults and overrides.

The hierarchy is as follows:

1.  **Standard Built-in Tools**: These are the lowest-level, non-agentic primitives that are an intrinsic part of the runtime. They are always available and cannot be overridden.
    *   `set_vars`: Define one or more variables and save them to the Execution Register.
    *   `shell`: Execute a shell command.
    *   `read_file`: Read a file from disk.
    *   `write_file`: Write a file to disk.
    *   `git_clone`: Clone a Git repository.
    *   `log`: Print a message or variable to the console for debugging.
    *   `run_apl`: Execute another APL program as a sub-task.

2.  **Custom APL-Defined Tools (`*.tool.apl`)**: These are tools defined by users in `*.tool.apl` files within the project's `tool_paths`. They contain a concrete `run` block with a sequence of steps. Because they are the most specific, they are checked first among all non-standard tools and can override any agent-native tool of the same name.

3.  **Custom Agent-Native Tools (`agent_native_tools.yml`)**: This optional project-level manifest file allows developers to define project-specific abstract tools. These tools have a defined interface (inputs/outputs) but no `run` block; their execution is delegated to the agent's core intelligence. They can override tools from the Standard Library.

4.  **Standard Library Agent-Native Tools (`APL_STL.yml`)**: This is the base layer of agent-native tools that comes bundled with the APL runtime. The `APL_STL.yml` file is located alongside the `APL_RUNTIME.md` and provides a rich set of universal, abstract tools (e.g., `split`, `rank_items`) that are available in any APL program.

### State Management (`register`)

APL provides a simple mechanism for state management, representing the agent's "memory." The `register` keyword saves the output of a tool into a variable.

```yaml
- name: "Load PR URLs from file"
  tool: read_file
  path: "list_last_week_prs.txt"
  register: pr_urls # The file content is now stored in the pr_urls variable
```

### Templating

Once a variable is stored in the register, you can reference it in subsequent steps using the `{{variable_name}}` syntax. This allows you to chain steps together, passing data from one to the next.

### Providing Context to Agent-Native Tools (`using`)

Some high-level, agent-native tools (e.g., `analyze_repo`, `analyze_pr_diff`) can be guided by providing a list of contextual hints. The `using` keyword is designed for this purpose. It allows you to pass a list of strings that the agent's reasoning engine can use to focus its analysis.

The format is a YAML list of strings. While the content of each string is specific to the tool, a common convention is a `key:value` format to provide specific parameters or configurations.

**Example:**

```yaml
- name: "Analyze Repository Quality Standards"
  tool: analyze_repo
  register: repo_quality
  using:
    - "build_files:pom.xml,package.json"
    - "static_analysis_tools:checkstyle,eslint,ruff"
```

In this example, the `using` list tells the `analyze_repo` tool to specifically look for those build files and static analysis configurations when assessing the repository. This is distinct from the structured `with_inputs` used for APL-defined tools, as it provides flexible, advisory hints rather than rigid, required parameters.

```yaml
# The `pr_url` variable is defined by the `foreach` loop
- name: "Fetch PR Metadata"
  tool: shell
  command: "gh pr view {{pr_url}} --json author,title,mergeCommit"
```

## 3. Language Reference

### Top-Level Structure

An APL file is a YAML document. The top-level keys define the program's structure, including its inputs and execution phases.

```yaml
# APL Program: My Program
# Version: 0.2

inputs:
  - name: input_parameter_1
    description: "A description of the first parameter."
    required: true
  - name: input_parameter_2
    description: "A description of the second parameter."
    required: false
    default: "some_value"

setup:
  # ... list of setup steps ...

main:
  # ... main processing steps ...

finalize:
  # ... finalization steps ...
```

### Program Inputs (`inputs`)

The `inputs` section is a list of parameters the program expects. This makes the program's interface explicit and enables validation. Each input can have the following properties:

*   `name`: The variable name, which can be used via `{{name}}` templating.
*   `description`: A human-readable explanation of the input.
*   `required`: A boolean (`true`/`false`). If `true`, the APL runtime will halt if the input is not provided.
*   `default`: An optional value to use if a `required: false` input is not provided.

Input variables are considered part of the Execution Register from the start of the program.

### Built-in Variables

The APL runtime automatically makes certain variables available to a program.

*   `{{module_path}}`: The absolute path to the directory containing the currently executing `.apl` file. This variable is crucial for making modules portable, as it allows for constructing paths to internal files and sub-modules in a relative and reliable way.

### Control Flow

#### `foreach`

The most common control flow mechanism is the `foreach` loop, used within a phase. It iterates over a collection stored in the register. The `loop_var` defines the name of the variable for each item in the collection.

```yaml
main:
  foreach:
    in: pr_urls      # The collection from the register
    loop_var: pr_url # The name for each item
  run:
    # A list of steps to execute for each pr_url
    - name: "Fetch PR Metadata"
      tool: shell
      command: "gh pr view {{pr_url}} --json author,title,mergeCommit"
      register: pr_metadata
    # ... more steps ...
```

#### `if` (Conditional Execution)

A step can be executed conditionally by adding an `if` clause. The agent will evaluate the condition based on the current state in the register.

```yaml
- name: "Clone Repository"
  tool: git_clone
  repo_path: "{{pr_metadata.repo_path}}"
  if: "repo_quality.score > 0.8" # Example condition
```

### State Management

#### `set_vars`
The `set_vars` tool is the primary mechanism for defining and registering one or more variables directly. This is useful for setting up configuration, defining constants, or constructing complex variables from existing ones.

*   **`vars`**: A key-value map. Each key becomes a variable name in the Execution Register, and its corresponding value is assigned to it. Values can use templates to reference previously registered variables.

```yaml
- name: "Define workspace and file paths"
  tool: set_vars
  vars:
    workspace_path: "{{module_path}}/pr_analysis_workspace"
    report_name: "final_report.md"
    full_report_path: "{{workspace_path}}/{{report_name}}"
    is_debug_mode: false
    max_retries: 3
```

### Debugging

#### `log`
The `log` tool provides a way to inspect the program's state for debugging purposes by printing information to the console.

*   **`message`**: A string to be printed. It can contain `{{template}}` variables to display their current values.
*   **`dump_register`**: A boolean (`true`/`false`). If `true`, the entire Execution Register will be printed.

```yaml
- name: "Log the current loop item"
  tool: log
  message: "Currently processing PR: {{pr_url}}"

- name: "Dump all variables before analysis"
  tool: log
  dump_register: true
```

## 4. Custom Tools

APL can be extended by creating reusable, high-level tools. This is the equivalent of creating a library in a conventional programming language. It allows you to abstract complex logic into a single, callable unit.

### Tool Definition File (`*.tool.apl`)

A custom tool is defined in a `*.tool.apl` file. This file specifies the tool's public interface (`inputs`, `outputs`) and its private implementation (`run`).

```yaml
# /apl_tools/git_utils.tool.apl
tool_definition:
  name: ensure_repo_is_cloned
  description: "Clones a repository if it doesn't exist, or pulls latest changes if it does."

  inputs:
    - name: repo_url
      required: true
    - name: workspace_path
      required: true

  outputs:
    - name: repo_local_path
      description: "The absolute path to the repository on disk."
    - name: status
      description: "Either 'cloned' or 'updated'."

  run:
    # ... a standard APL workflow to implement the tool's logic ...
```

### Tool Discovery

The APL runtime discovers custom tools by searching in the directories specified in the `.aplconfig` file's `tool_paths` list.

```yaml
# .aplconfig
tool_paths:
  - ./apl_tools/
  - ./shared/tools/
```

### Using a Custom Tool

Once defined and discovered, a custom tool can be used in any program just like a built-in one. You use the `with_inputs` key to pass parameters to it. The `register` key saves the tool's `outputs` as a structured object.

```yaml
- name: "Get the Gemini CLI repository"
  tool: ensure_repo_is_cloned # Our new high-level tool
  with_inputs:
    repo_url: "https://github.com/google/gemini-cli.git"
    workspace_path: "{{ ws_path }}"
  register: gemini_cli_repo # The 'outputs' are saved here

- name: "Log the result"
  tool: log
  message: "Repo is ready. Path={{ gemini_cli_repo.repo_local_path }}, Status={{ gemini_cli_repo.status }}"
```

## 5. Example Program: `best_pr_finder.apl`

This program directs an agent to find and rank the top 5 pull requests from a list.

```yaml
# APL Program: Best Pull Request Finder
# Version: 0.2
# Description: Analyzes a list of PRs to find and rank the top 5 "masterpieces."

setup:
  - name: "Load PR list from file"
    tool: read_file
    path: "list_last_week_prs.txt"
    register: pr_urls
  - name: "Create a workspace for analysis"
    tool: create_workspace
    path: "./pr_analysis_workspace"
    register: workspace_path

main:
  foreach:
    in: pr_urls
    loop_var: pr_url
  run:
    - name: "Fetch PR Metadata"
      tool: shell
      command: "gh pr view {{pr_url}} --json author,title,mergeCommit"
      register: pr_metadata

    - name: "Clone or Update Repository"
      tool: ensure_repo_is_cloned # Using a custom tool
      with_inputs:
        repo_url: "{{pr_metadata.repo_path}}"
        workspace_path: "{{workspace_path}}"
      register: repo_info

    - name: "Checkout Merge Commit"
      tool: git_checkout
      commit: "{{pr_metadata.mergeCommit.oid}}"

    - name: "Analyze Repository Quality Standards"
      tool: analyze_repo
      register: repo_quality
      using:
        - "build_files:pom.xml,package.json"
        - "static_analysis_tools:checkstyle,eslint,ruff"

    - name: "Analyze PR Contribution"
      tool: analyze_pr_diff
      register: pr_analysis
      using:
        - "categorize_change:Architectural,Feature,API,Testing,Fix,Docs"
        - "evaluate_craftsmanship:Clarity,Consistency,Comments,Maintainability,Patterns"

finalize:
  - name: "Rank PRs based on analysis"
    tool: rank_items
    from: pr_analysis_results
    by:
      - "pr_analysis.category_score"
      - "pr_analysis.craftsmanship_score"
      - "repo_quality.score"
    top_n: 5
    register: top_5_prs

  - name: "Generate final report"
    tool: write_file
    to_file: "best_prs.md"
    content_template: |
      # Top 5 Pull Requests of the Week

      {% for pr in top_5_prs %}
      ## {{loop.index}}. [{{pr.metadata.title}}]({{pr.url}})
      **Author**: {{pr.metadata.author.login}}

      **Why it's a masterpiece**: {{pr.analysis.summary}}
      * **Key Learning**: {{pr.analysis.learning_point}}
      ---
      {% endfor %}
```

## 6. Executing APL Programs

The APL runtime is invoked by instructing the agent to execute a program or module, providing any necessary inputs.

### Executing a Single File

To run a specific `.apl` file, provide its path to the agent and specify its inputs.

**Instruction format:**
> Execute the program @path/to/my_program.apl using the rules in @APL_RUNTIME.md, with the following inputs:
> *   `input_name`: "value"
> *   `another_input`: "/path/to/some/file.txt"

### Executing a Module

To run a module, provide the path to its directory. The runtime will automatically find and execute the `main.apl` file within that directory.

**Instruction format:**
> Execute the module @path/to/my_module/ using the rules in @APL_RUNTIME.md, with the following inputs:
> *   `input_for_main`: "/path/to/data.txt"

### Providing Inputs

Inputs declared in the `inputs` section of a program are provided as a key-value list in the instruction to the agent. The runtime is responsible for parsing these and making them available to the program.

## 7. Conclusion

APL represents a new way of thinking about programming in the age of AI. By abstracting away the low-level implementation details and focusing on high-level goals, APL empowers developers to leverage the full reasoning power of AI agents. The addition of custom tools provides the foundation for building robust, shared libraries of agent capabilities. This is just the beginning, and we envision a future where APL and similar languages become the standard for orchestrating complex, agent-driven software development and automation.
