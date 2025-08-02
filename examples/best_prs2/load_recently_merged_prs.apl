# APL Program: Load Recently Merged PRs
# Version: 0.4
# Description: Analyzes a list of repositories to find the last 10 merged pull requests from each.

inputs:
  - name: repos_to_scan_file
    description: "Absolute path to the text file containing repository URLs."
    required: true
  - name: workspace_path
    description: "Absolute path to the directory for creating the workspace."
    required: true
  - name: recent_prs_output_file
    description: "Absolute path for the final output file of PR URLs."
    required: true
  - name: max_prs_per_repo
    description: "The maximum number of PRs to fetch from each repository."
    required: false
    default: 10

setup:
  - name: "Load repository URLs from file"
    tool: read_file
    path: "{{ repos_to_scan_file }}"
    register: repo_urls_string
  - name: "Split repository URLs into a list"
    tool: split
    from: repo_urls_string
    register: repo_urls
  - name: "Create a workspace for analysis"
    tool: create_directory
    path: "{{ workspace_path }}"
  - name: "Initialize list for all PRs"
    tool: initialize_list
    name: all_pr_urls

main:
  foreach:
    in: repo_urls
    loop_var: repo_url
    directives: [FORCE_FULL_LOOP_EXECUTION]
  run:
    - name: "Fetch last N merged PRs as a clean list"
      tool: shell
      command: "gh pr list --repo {{repo_url}} --state merged --limit {{max_prs_per_repo}} --json url --template '{{range .}}{{.url}}
{{end}}'"
      register: pr_urls_string_for_repo

    - name: "Split PR URLs into a list"
      tool: split
      from: pr_urls_string_for_repo
      register: pr_urls_list_for_repo

    - name: "Append PR URLs to a global list"
      tool: append_to_list
      list: all_pr_urls
      items: "{{pr_urls_list_for_repo}}"

finalize:
  - name: "Generate PR list text file"
    tool: write_file
    to_file: "{{ recent_prs_output_file }}"
    content_template: |
      {% for pr_url in all_pr_urls %}{{ pr_url }}
      {% endfor %}