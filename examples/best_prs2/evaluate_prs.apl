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
    absolute_path: "{{ pr_list_file }}"
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
    directives: [FORCE_FULL_LOOP_EXECUTION]
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
        relative_repo_path: "{{ repo_info.repo_local_path | remove_prefix: '/home/belablotski/apl/' }}"

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
    - name: "Analyze PR Contribution"
      tool: analyze_pr_diff
      register: pr_analysis
      using:
        - "categorize_change:Architectural,Feature,API,Testing,Fix,Docs,Build"
        - "evaluate_craftsmanship:Clarity,Consistency,Thoughtful Commenting,Durability,Pattern Recognition"

    - name: "Combine PR data and analysis"
      tool: combine_objects
      into: pr_full_details
      from:
        - pr_metadata
        - repo_quality
        - pr_analysis

    - name: "Append result to global list"
      tool: append_to_list
      list: pr_analysis_results
      item: "{{pr_full_details}}"

finalize:
  - name: "Rank PRs based on analysis"
    tool: rank_items
    from: pr_analysis_results
    by:
      - "pr_analysis.craftsmanship_score"
      - "pr_analysis.category_score"
      - "repo_quality.score"
    top_n: "{{ top_n }}"
    register: top_5_prs

  - name: "Generate final report"
    tool: write_file
    to_file: "{{ report_output_file }}"
    content_template: |
      # Top {{ top_n }} Pull Requests of the Week

      {% for pr in top_5_prs %}
      ## {{loop.index}}. [{{pr.metadata.title}}]({{pr.url}})
      **Author**: {{pr.metadata.author.login}}

      **Why it's a masterpiece**: {{pr.analysis.summary}}
      * **Key Learning**: {{pr.analysis.learning_point}}
      ---
      {% endfor %}