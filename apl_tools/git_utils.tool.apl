

# APL Custom Tool: git_utils
# Version: 0.1
# Description: Defines a custom tool that intelligently clones or updates a repository.

tool_definition:
  name: ensure_repo_is_cloned
  description: "Clones a repository if it doesn't exist in the workspace. If it already exists, it pulls the latest changes."

  # The "API" for the tool
  inputs:
    - name: repo_url
      description: "The full URL of the repository."
      required: true
    - name: workspace_path
      description: "The parent directory where the repo should be cloned."
      required: true
    - name: repo_dir_name # Optional input to override the default repo folder name
      description: "The name of the directory for the repo, derived from the URL if not provided."
      required: false

  # Declares what variables this tool will return to the main program's register.
  outputs:
    - name: repo_local_path
      description: "The final absolute path to the repository on the local disk."
    - name: status
      description: "Either 'cloned' or 'updated', indicating the action taken."

  # The implementation. This is just a standard APL workflow.
  # It has its own internal context and cannot see the calling program's register.
  run:
    # Step 1: Determine the target directory path for the repo
    - name: "Derive repository directory name from URL"
      tool: shell
      # This is a bit of shell magic to get the repo name (e.g., "gemini-cli") from a URL
      command: "echo {{ repo_url }} | sed 's#.*/##' | sed 's/\.git$//'"
      register: derived_repo_dir_name
      if: "repo_dir_name is not defined" # Condition to run if optional input wasn't given

    - name: "Set final repository directory name"
      tool: shell
      command: "echo {{ repo_dir_name or derived_repo_dir_name.stdout }}"
      register: final_repo_dir_name

    - name: "Construct full local path"
      tool: shell
      command: "echo \"{{ workspace_path }}/{{ final_repo_dir_name.stdout }}\""
      register: final_repo_local_path


    # Step 2: Check if the repository already exists
    - name: "Check if repository directory exists"
      tool: shell
      command: "test -d {{ final_repo_local_path.stdout }}"
      register: check_dir_exists # Registers exit code

    # Step 3: Clone or Pull based on existence
    - name: "Clone repository because it does not exist"
      tool: shell
      command: "git clone {{ repo_url }} {{ final_repo_local_path.stdout }}"
      if: "check_dir_exists.exit_code != 0"
    - name: "Set status to 'cloned'"
      tool: shell
      command: "echo 'cloned'"
      register: final_status
      if: "check_dir_exists.exit_code != 0"

    - name: "Update repository because it already exists"
      tool: shell
      command: "cd {{ final_repo_local_path.stdout }} && git pull"
      if: "check_dir_exists.exit_code == 0"
    - name: "Set status to 'updated'"
      tool: shell
      command: "echo 'updated'"
      register: final_status
      if: "check_dir_exists.exit_code == 0"

    # Step 4: Register the final outputs
    # The runtime maps these to the `outputs` declared in the interface.
    - name: "Register final output variables"
      tool: shell
      command: "echo '{\"repo_local_path\": \"'{{ final_repo_local_path.stdout }}'\", \"status\": \"'{{ final_status.stdout }}'\"}'"
      register: output_object
