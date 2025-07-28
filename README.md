# APL: Agentic Programming Language

APL is a high-level, declarative language designed to direct AI agents in complex software engineering and data analysis tasks. It provides a structured, predictable, and transparent way to orchestrate agent workflows, ensuring that tasks are executed reliably and deterministically.

The core value proposition of APL is **predictability**. While natural language is powerful, it can be ambiguous for an AI agent, leading to inconsistent results. APL replaces ambiguity with a clear, machine-readable program, transforming the agent from a creative assistant into a reliable, high-fidelity interpreter.

## The "Why": From Ambiguity to Determinism

The idea for APL was born out of a simple need: to get a deterministic result from an AI agent. Initially, I tried using a detailed set of natural language instructions to guide an agent through a task.

For example, to find the "best" pull requests in a repository, the instructions looked like this:

**Before APL (Natural Language Instructions)**
```markdown
### **Instruction Set: Finding and Ranking High-Quality Pull Requests**

**Objective:** To analyze a list of pull requests, identify the top 5 examples of "beautiful, clean, and elegant" code, and present them in a ranked list...

**Phase 1: Initialization and Data Gathering**
1.  **Ingest PR List:** Read the list of pull request URLs from the specified file...
2.  **Prepare Workspace:** Create a temporary directory...
3.  **Gather PR Metadata:** For each PR URL in the list...

**Phase 2: Code and Context Analysis**
For each pull request, perform the following analysis steps...
...
```
*[./examples/best_prs/insructions_to_agent.md](./examples/best_prs/insructions_to_agent.md)*

While a human could follow these instructions, an AI agent might interpret them differently each time, leading to unpredictable behavior. It might skip steps, make assumptions, or "hallucinate" results.

To solve this, APL was created. It replaces the prose with a simple, structured program that the agent can execute step-by-step without deviation.

**After APL (A Structured Program)**
```yaml
# APL Program: Best Pull Request Finder
# Version: 0.1
# Description: Analyzes a list of PRs to find and rank the top 5 "masterpieces."

setup:
  - load_pr_list:
      from_file: "list_last_week_prs.txt"
      register: pr_urls
  - create_workspace:
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

    - name: "Analyze Repository Quality Standards"
      tool: analyze_repo
      register: repo_quality
      using:
        - "build_files:pom.xml,package.json"
        - "static_analysis_tools:checkstyle,eslint,ruff"
...
```
*[./examples/best_prs/program_to_agent.apl](./examples/best_prs/program_to_agent.apl)*

This APL program achieves the same goal but in a way that is completely deterministic and verifiable.

## Quick Start

Executing an APL program is straightforward. You instruct the agent to run a program file and provide any necessary inputs.

**Instruction Format:**
> execute @/path/to/my_program.apl with input_name=value

**Example:**
> execute @examples/best_prs2/main.apl with repos_list=@examples/best_prs2/repos_to_scan.txt final_report=final_report.md

The agent will then act as an interpreter, executing the program's `setup`, `main`, and `finalize` phases sequentially.

## Key Ideas of APL

APL is built on a few core concepts that make it both powerful and easy to understand.

*   **The Agent as a Computer**: APL uses the metaphor of the agent as a computer.
    *   **CPU (Logic)**: The agent's core reasoning and planning engine. You don't program the logic; you direct it.
    *   **RAM (Memory)**: The `register` keyword allows you to store the output of a step into a variable for use in later steps.
    *   **Disk (I/O)**: **Tools** are the agent's connection to the outside world, allowing it to run shell commands, read/write files, and more.

*   **Declarative and Sequential**: APL programs are written in simple, readable YAML. You declare a sequence of goals (steps), and the agent executes them in order. You focus on *what* you want to achieve, not *how*.

*   **Deterministic Execution**: This is the most important principle of APL. The APL runtime enforces a strict execution model:
    *   **No Improvisation**: The agent is forbidden from deviating from the program. It cannot skip, reorder, or add steps.
    *   **Guaranteed Full Loop Execution**: `foreach` loops are always executed completely, from the first item to the last. The agent is not allowed to summarize or process a "representative sample."
    *   **Fact-Based Execution**: The agent cannot assume the state of the system (e.g., that a file exists). It must use tools to verify facts before acting on them.

## Tools: The Agent's Capabilities

Tools are the fundamental "verbs" of APL. They represent the actions the agent can take. APL has a clear hierarchy for how tools are defined and used.

1.  **Standard Built-in Tools**: These are low-level, essential tools that are always available, such as `shell`, `read_file`, and `write_file`.
2.  **Agent-Native Tools (The Standard Tool Library)**: APL comes with a rich Standard Tool Library (STL) of high-level, agent-native tools defined in `APL_STL.yml`. These tools leverage the agent's reasoning capabilities to perform complex tasks. Examples include:
    *   `split`: Splits a string into a list.
    *   `rank_items`: Ranks a list of complex objects based on natural language criteria.
    *   `analyze_repo`: Performs a quality analysis on a code repository.
    *   `analyze_pr_diff`: Analyzes the changes within a pull request.
3.  **Custom Tools**: You can extend APL by creating your own tools. This allows you to build reusable libraries of agent capabilities, abstracting complex logic into a single, callable unit.

## Roadmap

APL is actively evolving. The goal is to enhance it with concepts from traditional programming languages to make it even more powerful and robust. Key ideas on the roadmap include:

*   **Typed Variables**: Introducing types to make programs clearer and enable more intelligent operations.
*   **Enhanced Control Flow**: Adding `while` loops and `switch` blocks for more complex logic.
*   **Functions and Modules**: Creating reusable, importable libraries of APL steps.
*   **Error Handling**: Implementing `try...catch` blocks for more graceful error handling.
*   **Concurrency**: Providing a managed way to execute tasks in parallel.

For more details, see the full [roadmap.md](roadmap.md).

## Contributing

Everyone is welcome to contribute to the APL project. If you have ideas for improvements or new features, please open a Pull Request for review.