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
    except FileNotFoundError:
        print("❌ Error: 'gh' (GitHub CLI) not found. Please install it.", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing GitHub CLI output: {e}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        if "authentication required" in e.stderr.lower() or "not logged in" in e.stderr.lower():
            print("❌ You are not logged into the GitHub CLI.", file=sys.stderr)
            print("   Please run 'gh auth login' and then try again.", file=sys.stderr)
        else:
            print("❌ Error fetching GitHub repositories:", file=sys.stderr)
            print(e.stderr, file=sys.stderr)
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

def handle_create_repo():
    """Interactively creates a new GitHub repository."""
    # 1. Get Repo Name
    repo_name = inquirer.text(
        message="Enter repository name:",
        validate=EmptyInputValidator(),
    ).execute()

    # 2. Get Visibility
    visibility = inquirer.select(
        message="Select visibility:",
        choices=["public", "private", "internal"],
        default="public",
        vi_mode=True,
    ).execute()

    # 3. Optional Description
    description = inquirer.text(
        message="Enter description (optional):",
    ).execute()

    # 4. Optional Initialization
    initialize_readme = inquirer.confirm(
        message="Initialize with README?",
        default=True,
        vi_mode=True,
    ).execute()
    
    # 5. Gitignore template
    gitignore = inquirer.text(
        message="Gitignore template (e.g., Python, Node, optional):",
    ).execute()
    
    # 6. License
    license_key = inquirer.text(
        message="License key (e.g., mit, apache-2.0, optional):",
    ).execute()

    # Construct the command
    cmd = ["gh", "repo", "create", repo_name, f"--{visibility}"]
    if description:
        cmd.extend(["--description", description])
    if initialize_readme:
        cmd.append("--add-readme")
    if gitignore:
        cmd.extend(["--gitignore", gitignore])
    if license_key:
        cmd.extend(["--license", license_key])

    # Execute creation
    try:
        print(f"\nCreating repository '{repo_name}' on GitHub...")
        subprocess.run(cmd, check=True)
        print("✅ Repository created successfully.")
    except subprocess.CalledProcessError:
        print("❌ Failed to create repository.")
        return None

    # Clone offer
    should_clone = inquirer.confirm(
        message="Do you want to clone this repository now?",
        default=True,
        vi_mode=True,
    ).execute()

    if should_clone:
        # Get current username for full repo name
        try:
             username = subprocess.check_output(['gh', 'api', 'user', '-q', '.login'], text=True).strip()
             full_repo_name = f"{username}/{repo_name}"
        except:
             full_repo_name = repo_name # Fallback

        clone_cmd = handle_clone_flow(full_repo_name)
        
        if clone_cmd and clone_cmd != "cancel":
            # Extract the destination path from the clone command to register it
            # Command format: "gh repo clone <repo> <path>"
            parts = clone_cmd.split()
            if len(parts) >= 4:
                # The path is the last argument, but might contain spaces so we join whatever is after 'clone <repo>'
                # Actually handle_clone_flow returns simpler string. Let's parse carefully.
                # In handle_clone_flow: return f"gh repo clone {repo_name} {path}"
                # So we can just run this command.
                
                print(f"Cloning {full_repo_name}...")
                try:
                    subprocess.run(clone_cmd, shell=True, check=True)
                    
                    # Extract path for registration
                    # repo_name is index 3 (0-based)
                    # path starts at index 4
                    dest_path = " ".join(parts[4:])
                    
                    register_clone(full_repo_name, dest_path)
                    print(f"✅ Cloned to {dest_path}")
                    
                    return f"cd {dest_path}"
                except subprocess.CalledProcessError:
                    print("❌ Failed to clone repository.")
                    return None
    
    return None

def handle_delete_repo():
    """Interactively deletes a repository (local and/or remote)."""
    # 1. Select Repository (Local preferred, or fetch)
    local_repos_map = read_cloned_repos_db()
    fzf_input = []
    selection_map = {}
    
    FETCH_OPTION = "⬇️  Fetch/Refresh all remote repositories from GitHub..."
    fzf_input.append(FETCH_OPTION)
    selection_map[FETCH_OPTION] = "FETCH_REMOTE"

    if local_repos_map:
        for repo_name, path in local_repos_map.items():
            display_str = f"📂 {repo_name}  ({path})"
            fzf_input.append(display_str)
            selection_map[display_str] = repo_name

    try:
        fzf_process = subprocess.run(
            ['fzf', '--ansi', '--no-sort', '--reverse', '--height', '40%', 
             '--prompt', 'Select repository to DELETE: ', '--header', 'Local Repositories (or fetch remote)'],
            input='\n'.join(fzf_input),
            capture_output=True, text=True, check=True
        )
        selected_str = fzf_process.stdout.strip()
        selection_value = selection_map.get(selected_str)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None # User cancelled

    selected_repo_name = None
    local_path = None
    
    if selection_value == "FETCH_REMOTE":
        print("Fetching repositories from GitHub...", file=sys.stderr)
        repos = get_github_repos()
        repo_data = select_repo_with_fzf(repos)
        if not repo_data:
             return None
        selected_repo_name = repo_data['nameWithOwner']
    elif selection_value:
        selected_repo_name = selection_value
        local_path = local_repos_map.get(selected_repo_name)

    if not selected_repo_name:
        return None
        
    # Check again if we have a local path even if we fetched from remote
    if not local_path:
        local_path = get_local_path_from_db(selected_repo_name)

    # 2. Choose deletion scope
    options = []
    if local_path:
        options.append({"name": f"Delete LOCAL directory only ({local_path})", "value": "local"})
    options.append({"name": "Delete REMOTE GitHub repository only (Destructive!)", "value": "remote"})
    if local_path:
        options.append({"name": "Delete BOTH local and remote (Destructive!)", "value": "both"})
    options.append({"name": "Cancel", "value": "cancel"})

    scope = inquirer.select(
        message=f"Deleting '{selected_repo_name}'. What do you want to do?",
        choices=options,
        default="cancel",
        vi_mode=True,
    ).execute()

    if scope == "cancel":
        return None

    # 3. Execution & Confirmation
    
    # --- Local Deletion ---
    if scope in ["local", "both"] and local_path:
        confirm_local = inquirer.confirm(
            message=f"Are you sure you want to delete folder '{local_path}'?",
            default=False,
            vi_mode=True
        ).execute()
        
        if confirm_local:
            try:
                shutil.rmtree(local_path)
                # Update DB
                db = read_cloned_repos_db()
                if selected_repo_name in db:
                    del db[selected_repo_name]
                    write_cloned_repos_db(db)
                print(f"✅ Local directory deleted.")
            except Exception as e:
                print(f"❌ Error deleting local directory: {e}")
        else:
            print("Skipping local deletion.")

    # --- Remote Deletion ---
    if scope in ["remote", "both"]:
        print(f"\n⚠️  WARNING: You are about to permanently delete '{selected_repo_name}' from GitHub.")
        print("This action cannot be undone.")
        
        confirm_input = inquirer.text(
            message=f"Type '{selected_repo_name}' to confirm:",
            validate=lambda x: x == selected_repo_name,
            invalid_message="Repository name does not match.",
        ).execute()

        if confirm_input == selected_repo_name:
            try:
                print(f"Deleting remote repository '{selected_repo_name}'...")
                # gh repo delete <repo> --confirm
                subprocess.run(['gh', 'repo', 'delete', selected_repo_name, '--confirm'], check=True)
                print(f"✅ Remote repository deleted.")
            except subprocess.CalledProcessError:
                print(f"❌ Failed to delete remote repository.")
        else:
             print("Confirmation failed. Aborting remote deletion.")
    
    return None

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

        if args.subcommand == 'create':
            final_command = handle_create_repo()
            if final_command and args.outfile:
                with open(args.outfile, 'w') as f:
                    f.write(final_command)
            return

        if args.subcommand == 'delete':
            handle_delete_repo()
            return

        if args.subcommand == 'repos':
            # --- MODIFIED: Lazy Loading Logic ---
            local_repos_map = read_cloned_repos_db()
            
            # Prepare initial choices (Local repos + Fetch option)
            fzf_input = []
            selection_map = {}
            
            FETCH_OPTION = "⬇️  Fetch/Refresh all remote repositories from GitHub..."
            fzf_input.append(FETCH_OPTION)
            selection_map[FETCH_OPTION] = "FETCH_REMOTE"

            if local_repos_map:
                for repo_name, path in local_repos_map.items():
                    display_str = f"📂 {repo_name}  ({path})"
                    fzf_input.append(display_str)
                    selection_map[display_str] = repo_name

            # First FZF selection (Local vs Remote)
            try:
                fzf_process = subprocess.run(
                    ['fzf', '--ansi', '--no-sort', '--reverse', '--height', '40%', 
                     '--prompt', 'Select a local repo or fetch remote: ', '--header', 'Local Repositories'],
                    input='\n'.join(fzf_input),
                    capture_output=True, text=True, check=True
                )
                selected_str = fzf_process.stdout.strip()
                selection_value = selection_map.get(selected_str)
            except (subprocess.CalledProcessError, FileNotFoundError):
                return # User cancelled

            selected_repo = None
            
            if selection_value == "FETCH_REMOTE":
                # Original logic: fetch all from API
                print("Fetching repositories from GitHub...", file=sys.stderr)
                repos = get_github_repos()
                selected_repo = select_repo_with_fzf(repos)
            elif selection_value:
                # Local repo selected. Reconstruct the 'repo' dict expected by the rest of the code
                repo_name = selection_value
                selected_repo = {
                    'nameWithOwner': repo_name,
                    'url': f"https://github.com/{repo_name}",
                    'sshUrl': f"git@github.com:{repo_name}.git",
                    'description': f"Locally cloned at {local_repos_map[repo_name]}",
                }

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
