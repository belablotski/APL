# main.apl
#
# This program demonstrates the use of a custom tool.

inputs:
  - name: repo_url
    description: "The URL of the git repository to clone."
    required: true
    default: "https://github.com/belablotski/apl"
  - name: workspace_name
    description: "The directory to use for the workspace."
    required: false
    default: "cloning_workspace"

setup:
  - name: "Create a workspace for cloning"
    tool: shell
    command: "mkdir -p {{ workspace_name }}"
  - name: "Get absolute path for workspace"
    tool: shell
    command: "realpath {{ workspace_name }}"
    register: ws_path

main:
  - name: "Ensure the repository is cloned"
    tool: ensure_repo_is_cloned
    with_inputs:
      repo_url: "{{ repo_url }}"
      workspace_path: "{{ ws_path.stdout }}"
    register: repo_info

  - name: "Log the result from the custom tool"
    tool: log
    message: "Custom tool finished. Status: {{ repo_info.output_object.status }}, Path: {{ repo_info.output_object.repo_local_path }}"

finalize:
  - name: "Clean up the workspace"
    tool: shell
    command: "rm -rf {{ ws_path.stdout }}"
    description: "Removing the workspace directory."