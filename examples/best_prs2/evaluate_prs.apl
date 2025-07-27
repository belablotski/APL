# APL Program: Evaluate and Rank Pull Requests
# Version: 0.2
# Description: Analyzes a list of PRs to find and rank the top N "masterpieces."

inputs:
  - name: pr_list_file
    description: "Absolute path to the text file containing PR URLs."
    required: true
  - name: workspace_path
    description: "Absolute path to the directory for cloning repos."
    required: true
  - name: report_output_file
    description: "Absolute path for the final markdown report."
    required: true
  - name: top_n
    description: "The number of top PRs to rank."
    required: false
    default: 5

setup:
  - name: "Load PR list from file"
    tool: read_file
    path: "{{ pr_list_file }}"
    register: pr_urls_string
  - name: "Split PR list into an array"
    tool: split
    from: pr_urls_string
    register: pr_urls
  - name: "Initialize list for analysis results"
    tool: initialize_list
    name: pr_analysis_results

main:
  foreach:
    in: pr_urls
    loop_var: pr_url
  run:
    - name: "Fetch PR Metadata"
      tool: shell
      command: "gh pr view {{pr_url}} --json author,title,mergeCommit,url,headRepository"
      register: pr_metadata

    - name: "Get repo URL from PR URL"
      tool: shell
      command: "echo {{pr_url}} | cut -d'/' -f1-5"
      register: repo_url

    - name: "Clone or Update Repository"
      tool: ensure_repo_is_cloned
      with_inputs:
        repo_url: "{{ repo_url.stdout }}"
        workspace_path: "{{ workspace_path }}"
      register: repo_info

    - name: "Log repository cloning"
      tool: log
      message: "Repo is ready. Path={{ repo_info.repo_local_path }}, Status={{ repo_info.status }}"

    - name: "Set relative path for checkout"
      tool: set_vars
      vars:
        relative_repo_path: "{{ repo_info.repo_local_path | remove_prefix: '/home/beloblotskiy/apl/' }}"

    - name: "Checkout Merge Commit"
      tool: shell
      command: "git checkout {{ pr_metadata.mergeCommit.oid }}"
      working_directory: "{{ relative_repo_path }}"

    - name: "Analyze Repository Quality Standards"
      tool: analyze_repo
      path: "{{ repo_info.repo_local_path }}"
      register: repo_quality
      using:
        - "build_files:pom.xml,package.json,build.gradle"
        - "static_analysis_tools:checkstyle,eslint,ruff,spotless"

    - name: "Log repo_quality result"
      tool: log
      message: "repo_quality result: {{repo_quality.result}}"
