# APL Enhancement Ideas: Borrowing from Traditional Languages

This document outlines a roadmap for evolving APL from a simple scripting notation into a robust programming language. By systematically borrowing core concepts from traditional programming languages, we can make APL more powerful, reusable, and familiar to developers.

---

### 1. Variables and Data Types

*   **Concept:** Traditional languages use typed variables (`integer`, `string`, `object`) to define what kind of data is being stored and what operations are valid.
*   **Current APL:** APL has an untyped `register` keyword that stores raw tool output.
*   **Enhancement Opportunity:** Introduce **Typed Registers** and **Constants**. This would enable more intelligent operations and make programs clearer.

#### Proposed Syntax:

```yaml
# Define fixed values at the top of the program
setup:
  - define_constants:
      MAX_RETRIES: 3
      REPORT_FILENAME: "final_report.md"

main:
  - name: "Fetch PR Metadata"
    tool: shell
    command: "gh pr view {{pr_url}} --json author,title"
    register: pr_metadata
    as_type: json # <-- New: The agent now knows this is structured JSON, not just text.
```

### 2. Control Flow

*   **Concept:** Traditional languages use structures like `if/else`, `switch`, `for`, and `while` to control the order of execution.
*   **Current APL:** APL has `foreach` (a `for` loop) and a basic `if` on steps.
*   **Enhancement Opportunity:** Add **`while` loops** for polling or iterative tasks, and **`switch` blocks** for cleaner branching logic.

#### Proposed Syntax:

```yaml
# A 'while' loop for polling
- name: "Wait for build to complete"
  tool: check_build_status
  register: build.status
  as_type: string

- while: "{{build.status}} != 'SUCCESS'"
  run:
    - name: "Wait 5 seconds"
      tool: shell
      command: "sleep 5"
    - name: "Re-check build status"
      tool: check_build_status
      register: build.status
      as_type: string

# A 'switch' block for conditional logic
- switch: on: "{{pr_analysis.category}}"
  cases:
    - case: "Feature"
      run:
        - name: "Add 'feature' label"
          tool: add_github_label
          label: "feature"
    - case: "BugFix"
      run:
        - name: "Add 'bug' label"
          tool: add_github_label
          label: "bug"
    - default:
      run:
        - name: "Log unknown category"
          tool: log_message
          message: "Unknown PR category: {{pr_analysis.category}}"
```

### 3. Structure & Abstraction (Functions and Modules)

*   **Concept:** Functions, classes, and modules allow grouping code into reusable, logical blocks. This is the foundation of the DRY (Don't Repeat Yourself) principle.
*   **Current APL:** APL has no concept of reusability. Logic must be copied and pasted.
*   **Enhancement Opportunity:** Introduce **Definable Steps (`def_step`)** to act as functions and an **`import`** mechanism to create reusable libraries of steps. This would be a game-changer for writing complex APL programs.

#### Proposed Syntax:

```yaml
# Define a reusable step (a function)
definitions:
  - def_step: analyze_and_checkout
    params: [pr_url] # <-- Function parameters
    run:
      - name: "Fetch PR Metadata"
        tool: shell
        command: "gh pr view {{pr_url}} --json mergeCommit"
        register: pr_metadata
        as_type: json
      - name: "Checkout Merge Commit"
        tool: git_checkout
        commit: "{{pr_metadata.mergeCommit.oid}}"

# Import a library of pre-defined steps
import:
  - "common_git_ops.apl"

main:
  foreach:
    in: pr_urls
    loop_var: current_pr
  run:
    # Call the defined step
    - run_step: analyze_and_checkout
      with:
        pr_url: "{{current_pr}}"
```

### 4. Error Handling

*   **Concept:** Traditional languages use `try...catch...finally` blocks to gracefully handle runtime errors, preventing the entire program from crashing.
*   **Current APL:** APL has a rigid "halt and report" protocol, which is equivalent to a global, unhandled exception.
*   **Enhancement Opportunity:** Implement **`try...catch` blocks**. This would allow for much more robust programs that can handle expected failures, perform cleanup actions, and continue execution when appropriate.

#### Proposed Syntax:

```yaml
# A try/catch block for handling failures gracefully
- try:
    - name: "Attempt to publish to CDN"
      tool: cdn_publish
      register: publish_result
- catch:
    - name: "Log publish failure"
      tool: log_message
      level: "error"
      message: "Failed to publish to CDN. See logs."
    - name: "Rollback deployment"
      tool: run_rollback_script
```

### 5. Concurrency and Parallelism (Multi-Processing)

*   **Concept:** Modern applications often perform tasks in parallel to improve performance. Languages and frameworks provide mechanisms for creating and managing multiple processes or threads.
*   **Current APL:** APL execution is strictly sequential. A program must finish one step before starting the next, making it inefficient for tasks that can be parallelized (e.g., analyzing 100 independent PRs).
*   **Enhancement Opportunity:** Formalize a pattern for **Multi-Process Execution**. While it's possible to use the `shell` tool with backgrounding (`&`), APL could provide a more integrated and managed way to handle parallel workflows. This involves an "Orchestrator" process launching multiple "Worker" processes.

#### Proposed Pattern & Syntax:

This pattern uses two types of `.apl` files: an orchestrator and a worker.

**`orchestrator.apl`:**

```yaml
# The main orchestrator process
main:
  # The 'parallel_foreach' block could be a new APL feature
  parallel_foreach:
    in: repo_urls
    loop_var: repo_url
  run:
    # This step would be executed in parallel for each item.
    # The APL runtime would manage launching background processes.
    - name: "Launch analyzer for {{repo_url}}"
      tool: run_apl_process # <-- A new, high-level tool for this
      program: "worker.apl"
      input:
        url: "{{repo_url}}"
      register: job_id

finalize:
  - name: "Wait for all jobs to complete"
    tool: await_processes # <-- New tool to wait for background jobs
    from: job_ids
  - name: "Aggregate results"
    tool: read_directory
    path: "./results"
    register: result_files
```

**`worker.apl`:**

```yaml
# The worker program, designed to run one task
setup:
  # The runtime would automatically register 'apl_input'
  - name: "Get input URL"
    tool: set_variable
    from: "{{apl_input.url}}"
    register: target_repo_url

main:
  - name: "Analyze the repository"
    tool: analyze_repo
    # ... analysis steps ...
    register: analysis_result

finalize:
  - name: "Write result to a unique file"
    tool: write_file
    # The runtime could provide a unique ID for the worker process
    to_file: "./results/{{apl_process_id}}.json"
    content: "{{analysis_result}}"
```

#### 6. Import tool from library

We'll need some sort of construct

```
import custom_tool from library
```