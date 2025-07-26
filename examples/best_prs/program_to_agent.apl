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
        - "code_formatters:prettier,spotless"

    - name: "Analyze PR Contribution"
      tool: analyze_pr_diff
      register: pr_analysis
      using:
        - "categorize_change:Architectural,Feature,API,Testing,Fix,Docs"
        - "evaluate_craftsmanship:Clarity,Consistency,Comments,Maintainability,Patterns"

finalize:
  - rank_prs:
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
