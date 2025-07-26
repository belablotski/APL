# APL: Agentic Programming Language - v0.1

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

### Tools

**Tools** are the fundamental "verbs" of APL. They represent the agent's capabilities. Tools can be low-level and specific, or high-level and abstract.

*   **Low-Level Tools**: These map directly to a specific action.
    *   `shell`: Execute a shell command.
    *   `read_file`: Read a file from disk.
    *   `write_file`: Write a file to disk.
    *   `git_clone`: Clone a Git repository.
    *   `log`: Print a message or variable to the console for debugging.

*   **High-Level (Abstract) Tools**: These instruct the agent to perform a complex analysis or task that leverages its core reasoning (CPU). The agent determines the necessary sub-steps on its own.
    *   `run_apl`: Execute another APL program, passing inputs to it.
    *   `analyze_repo`: Assess the quality standards of a codebase.
    *   `analyze_pr_diff`: Evaluate the craftsmanship of a pull request.
    *   `rank_items`: Sort a collection of items based on qualitative criteria.

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

### Abstract Tool Reference

The power of APL comes from its abstract tools. These tools rely on the agent's "CPU" to interpret the goal and execute it.

#### `run_apl`
Executes another APL program, enabling modular workflows.

*   **`program`**: The file path to the `.apl` program to be executed.
*   **`with_inputs`**: A dictionary mapping the `inputs` of the sub-program to variables or literal values from the current program's context.

```yaml
- name: "Run the PR evaluation module"
  tool: run_apl
  program: "examples/best_prs2/evaluate_prs.apl"
  with_inputs:
    pr_list_file: "{{ recent_prs_output_file }}"
    workspace_path: "{{ workspace_path }}"
    report_output_file: "final_report.md"
```

#### `analyze_repo`
Analyzes a software repository to assess its quality standards.

*   **`using`**: A list of principles or files to guide the analysis.
    *   `build_files`: e.g., `pom.xml`, `package.json`
    *   `static_analysis_tools`: e.g., `checkstyle`, `eslint`
    *   `code_formatters`: e.g., `prettier`, `spotless`
*   **`register`**: Saves a structured object containing the analysis results (e.g., a quality score).

```yaml
- name: "Analyze Repository Quality Standards"
  tool: analyze_repo
  register: repo_quality
  using:
    - "build_files:pom.xml,package.json"
    - "static_analysis_tools:checkstyle,eslint,ruff"
```

#### `analyze_pr_diff`
Analyzes a code diff to evaluate its quality and purpose.

*   **`using`**: A list of evaluation criteria.
    *   `categorize_change`: A list of possible change types (e.g., `Feature`, `Fix`, `Refactor`).
    *   `evaluate_craftsmanship`: A list of principles (e.g., `Clarity`, `Consistency`, `Testing`).
*   **`register`**: Saves a structured object with the analysis summary.

```yaml
- name: "Analyze PR Contribution"
  tool: analyze_pr_diff
  register: pr_analysis
  using:
    - "categorize_change:Architectural,Feature,API,Testing,Fix,Docs"
    - "evaluate_craftsmanship:Clarity,Consistency,Comments,Maintainability,Patterns"
```

## 4. Example Program: `best_pr_finder.apl`

This program directs an agent to find and rank the top 5 pull requests from a list.

```yaml
# APL Program: Best Pull Request Finder
# Version: 0.1
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
      tool: git_clone
      repo_path: "{{pr_metadata.repo_path}}"
      workspace: "{{workspace_path}}"
      if_not_exists: true

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

## 5. Conclusion

APL represents a new way of thinking about programming in the age of AI. By abstracting away the low-level implementation details and focusing on high-level goals, APL empowers developers to leverage the full reasoning power of AI agents. This is just the beginning, and we envision a future where APL and similar languages become the standard for orchestrating complex, agent-driven software development and automation.
