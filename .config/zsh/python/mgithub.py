import subprocess
import json
import os
import sys
import argparse
import shutil
from InquirerPy import inquirer
from InquirerPy.validator import EmptyInputValidator
from InquirerPy.prompts.filepath import FilePathPrompt

# --- Constants ---
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECTS_DIR = os.getenv('ENIGMA_PROJECTS_DIR', os.path.expanduser('~/projects'))
CLONED_REPOS_DB = os.path.join(ROOT_DIR, 'data', 'cloned_repos.json')

# --- Utility Functions ---

def get_copy_command():
    """Determines the available copy command based on the OS."""
    if sys.platform == 'darwin':
        if shutil.which('pbcopy'):
            return 'pbcopy'
    elif sys.platform == 'linux':
        if shutil.which('wl-copy'):
            return 'wl-copy'
        if shutil.which('xclip'):
            return 'xclip -selection clipboard'
    return None

def read_cloned_repos_db():
    """Reads the cloned repos JSON database."""
    if not os.path.exists(CLONED_REPOS_DB):
        return {}
    try:
        with open(CLONED_REPOS_DB, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}

def write_cloned_repos_db(data):
    """Writes data to the cloned repos JSON database."""
    try:
        with open(CLONED_REPOS_DB, 'w') as f:
            json.dump(data, f, indent=4)
    except IOError as e:
        print(f"Error writing to DB: {e}", file=sys.stderr)

# --- Core Logic ---

def get_github_repos():
    """Fetches a list of GitHub repositories using `gh repo list`."""
    try:
        result = subprocess.run(
            ['gh', 'repo', 'list', '--json', 'nameWithOwner,url,sshUrl,description,isFork,parent,updatedAt', '--limit', '1000', '--no-archived'],
            capture_output=True, text=True, check=True
        )
        return json.loads(result.stdout)
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error fetching GitHub repositories: {e}", file=sys.stderr)
        sys.exit(1)

def select_repo_with_fzf(repos):
    """Allows user to select a repository using fzf."""
    if not repos:
        print("No repositories found.", file=sys.stderr)
        return None
    fzf_input = []
    repo_map = {}
    for repo in repos:
        full_name = repo['nameWithOwner']
        description = repo.get('description') or 'No description'
        display_name = f"{full_name} - {description}"
        fzf_input.append(display_name)
        repo_map[display_name] = repo
    try:
        fzf_process = subprocess.run(
            ['fzf', '--ansi', '--no-sort', '--reverse', '--height', '40%', '--prompt', 'Select a repository: '],
            input='\n'.join(fzf_input),
            capture_output=True, text=True, check=True
        )
        selected_display_name = fzf_process.stdout.strip()
        return repo_map.get(selected_display_name)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

def get_local_path_from_db(repo_name):
    """Gets a repo's local path from the DB and validates it."""
    db = read_cloned_repos_db()
    path = db.get(repo_name)
    if path and os.path.isdir(path):
        return path
    elif path:
        # Path in DB is invalid (e.g., user deleted folder), so remove it.
        del db[repo_name]
        write_cloned_repos_db(db)
    return None

def handle_clone_flow(repo_name):
    """Handles the multi-step process of cloning a repository."""
    default_path = os.path.join(PROJECTS_DIR, repo_name)
    choice = inquirer.select(
        message="Choose clone destination:",
        choices=[
            {"name": f"Default: {default_path}", "value": "default"},
            {"name": "Custom path...", "value": "custom"},
            {"name": "Cancel", "value": "cancel"}
        ],
        default="default",
        vi_mode=True,
    ).execute()

    if choice == "default":
        return f"gh repo clone {repo_name} {default_path}"
    elif choice == "custom":
        parent_dir = inquirer.filepath(
            message="Select a parent directory to clone into:",
            instruction="Navigate with arrows, press Enter to select.",
            default=PROJECTS_DIR,
            only_directories=True,
            vi_mode=True,
        ).execute()
        if parent_dir:
            repo_folder_name = repo_name.split('/')[1]
            final_path = os.path.join(parent_dir, repo_folder_name)
            return f"gh repo clone {repo_name} {final_path}"
    return "cancel"

def handle_remove_repo(repo_name, local_path):
    """Handles the logic for removing a local repository."""
    confirmed = inquirer.confirm(
        message=f"Are you sure you want to permanently delete '{local_path}'?",
        default=False,
        vi_mode=True,
    ).execute()

    if confirmed:
        try:
            print(f"Removing {local_path}...")
            shutil.rmtree(local_path)
            db = read_cloned_repos_db()
            if repo_name in db:
                del db[repo_name]
                write_cloned_repos_db(db)
            print(f"✅ Successfully removed '{repo_name}'.")
        except Exception as e:
            print(f"❌ Error removing repository: {e}", file=sys.stderr)
    else:
        print("Removal cancelled.")

def register_clone(repo_name, path):
    """Registers a newly cloned repository in the database."""
    db = read_cloned_repos_db()
    db[repo_name] = path
    write_cloned_repos_db(db)

def main():
    """Main function to handle command-line arguments and orchestrate actions."""
    parser = argparse.ArgumentParser(description="Enigma GitHub command backend.")
    parser.add_argument('subcommand', help="The subcommand to run (e.g., 'repos', 'register-clone')")
    parser.add_argument('--repo-name', help="Repository name (for register-clone)")
    parser.add_argument('--path', help="Filesystem path (for register-clone)")
    parser.add_argument('--outfile', help="File to write the output command to")
    args, _ = parser.parse_known_args()

    try:
        if args.subcommand == 'register-clone':
            if args.repo_name and args.path:
                register_clone(args.repo_name, args.path)
            return

        if args.subcommand == 'repos':
            repos = get_github_repos()
            selected_repo = select_repo_with_fzf(repos)
            if not selected_repo:
                return

            repo_name = selected_repo['nameWithOwner']
            repo_url_https = selected_repo['url']
            repo_url_ssh = selected_repo['sshUrl']
            local_path = get_local_path_from_db(repo_name)
            
            actions = []
            if local_path:
                actions.append({"name": f"cd into local repo ({local_path})", "value": f"cd {local_path}"})
                actions.append({"name": "Remove local repo...", "value": "remove_repo"})
            else:
                actions.append({"name": "Clone repo", "value": "clone_flow"})
            
            actions.extend([
                {"name": f"Open repo in browser ({repo_url_https})", "value": f"gh repo view --web {repo_name}"},
                {"name": f"View README in terminal", "value": f"gh repo view {repo_name} | bat --paging=always --language=markdown"},
            ])

            copy_cmd = get_copy_command()
            if copy_cmd:
                actions.extend([
                    {"name": "Copy HTTPS clone URL", "value": f"echo '{repo_url_https}.git' | {copy_cmd}"},
                    {"name": "Copy SSH clone URL", "value": f"echo '{repo_url_ssh}' | {copy_cmd}"},
                    {"name": "Copy repo name to clipboard", "value": f"echo '{repo_name}' | {copy_cmd}"},
                ])
            actions.append({"name": "Cancel", "value": "cancel"})

            selected_action_value = inquirer.select(
                message=f"Selected '{repo_name}'. What do you want to do?",
                choices=actions,
                default=actions[0]['value'] if actions else None,
                vi_mode=True,
                long_instruction="Use arrow keys to navigate, Enter to select.",
            ).execute()

            final_command = None
            if selected_action_value == 'clone_flow':
                final_command = handle_clone_flow(repo_name)
            elif selected_action_value == 'remove_repo':
                handle_remove_repo(repo_name, local_path)
                # No command to execute in the shell
            else:
                final_command = selected_action_value

            if final_command and final_command != "cancel" and args.outfile:
                with open(args.outfile, 'w') as f:
                    f.write(final_command)
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(1)

if __name__ == '__main__':
    main()
