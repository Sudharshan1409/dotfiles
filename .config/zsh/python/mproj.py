#!/usr/bin/env python3
import argparse
import os
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.utils import get_style
from lib.common import (
    CONSOLE,
    STYLE,
    StyledArgumentParser,
    find_item,
    find_item_and_scope,
    fuzzy_select,
    get_group_selection,
    get_scope_selection,
    print_help_panel,
    prompt_with_interrupt_handler,
    read_registry,
    scope_item,
    write_registry,
)
from rich import box
from rich.table import Table

PROJECTS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/projects.json")


def show_help(args):
    """Displays the custom help panel for the project manager."""
    title = "Project Manager & Launcher"
    command_name = "enigma proj"
    commands = {
        "launch": "Fuzzy-find and launch a project in a new tmux session.",
        "ls": "Lists all configured projects.",
        "add": "Interactively adds a new project by selecting a directory.",
        "edit": "Interactively edits a project's path or description.",
        "rm": "Removes a project configuration.",
        "mv": "Moves a project to a different group.",
        "scope": "Move a project between global and local scopes.",
    }
    print_help_panel(title, command_name, commands)


def list_projects(args):
    """Handler for the 'ls' command."""
    data = read_registry(PROJECTS_JSON_PATH)
    if not data:
        CONSOLE.print("[yellow]No projects configured. Use 'enigma proj add'.[/yellow]")
        return

    global_data = read_registry(PROJECTS_JSON_PATH, read_local=False)

    for group_name, projects in sorted(data.items()):
        table = Table(
            title=group_name, box=box.ROUNDED, border_style="magenta", show_lines=True
        )
        table.add_column("Project Name", style="cyan")
        table.add_column("Path", style="yellow")
        table.add_column("Description", style="white")
        table.add_column("Scope", style="yellow")

        for name, proj_obj in sorted(projects.items()):
            scope = "local" if name not in global_data.get(group_name, {}) else "global"
            table.add_row(name, proj_obj.get("path"), proj_obj.get("description", ""), scope)
        CONSOLE.print(table)


def add_project(args):
    """Handler for adding a new project. Receives name and path from the shell."""
    data = read_registry(PROJECTS_JSON_PATH)
    proj_name = args.name
    proj_path = args.path
    if find_item(data, proj_name)[0]:
        CONSOLE.print(f"[red]Error: Project '{proj_name}' already exists.[/red]")
        return 1

    CONSOLE.print(
        f"Adding new project '[cyan]{proj_name}[/cyan]' with path '[yellow]{proj_path}[/yellow]'."
    )
    prompt = inquirer.text(message="Enter a short description (optional):", style=STYLE, vi_mode=True)
    proj_desc = prompt_with_interrupt_handler(prompt)
    group_name = get_group_selection(data)
    scope = get_scope_selection()

    registry_to_write = read_registry(PROJECTS_JSON_PATH, read_local=False) if scope == "global" else read_registry(PROJECTS_JSON_PATH + ".local", read_local=False)

    if group_name not in registry_to_write:
        registry_to_write[group_name] = {}

    registry_to_write[group_name][proj_name] = {"path": proj_path, "description": proj_desc}
    write_registry(registry_to_write, PROJECTS_JSON_PATH, scope)
    CONSOLE.print(
        f"✅ Project '[cyan]{proj_name}[/cyan]' added to group '[magenta]{group_name}[/magenta]' in {scope} scope."
    )


def _get_project_name_from_dropdown(data, message="Select a project"):
    all_projects = [name for group in data.values() for name in group]
    if not all_projects:
        CONSOLE.print("[yellow]No projects found.[/yellow]")
        return None
    return fuzzy_select(sorted(all_projects), message)


def edit_project(args):
    """Handler for editing an existing project."""
    data = read_registry(PROJECTS_JSON_PATH)
    proj_name = _get_project_name_from_dropdown(data, "Select a project to edit")
    if not proj_name:
        return 1
    
    group, proj_obj, scope = find_item_and_scope(PROJECTS_JSON_PATH, proj_name)
    if not group:
        CONSOLE.print(f"[red]Error: Project '{proj_name}' not found.[/red]")
        return 1

    CONSOLE.print(
        f"Editing project '[cyan]{proj_name}[/cyan]'. Current values are defaults."
    )
    prompt = inquirer.text(message="Path:", default=proj_obj.get("path"), style=STYLE, vi_mode=True)
    new_path = prompt_with_interrupt_handler(prompt)

    prompt = inquirer.text(message="Description:", default=proj_obj.get("description"), style=STYLE, vi_mode=True)
    new_desc = prompt_with_interrupt_handler(prompt)

    registry_to_write = read_registry(PROJECTS_JSON_PATH, read_local=False) if scope == "global" else read_registry(PROJECTS_JSON_PATH + ".local", read_local=False)
    registry_to_write[group][proj_name] = {"path": new_path, "description": new_desc}
    write_registry(registry_to_write, PROJECTS_JSON_PATH, scope)
    CONSOLE.print(f"✅ Project '[cyan]{proj_name}[/cyan]' updated in {scope} scope.")


def move_project(args):
    data = read_registry(PROJECTS_JSON_PATH)
    proj_name = _get_project_name_from_dropdown(data, "Select a project to move")
    if not proj_name:
        return 1
    
    original_group, proj_data, scope = find_item_and_scope(PROJECTS_JSON_PATH, proj_name)
    if not original_group:
        CONSOLE.print(f"[red]Error: Project '[cyan]{proj_name}[/cyan]' not found.[/red]")
        return 1

    CONSOLE.print(
        f"Moving project '[cyan]{proj_name}[/cyan]' from group '[magenta]{original_group}[/magenta]'."
    )
    new_group = get_group_selection(data)
    if new_group == original_group:
        CONSOLE.print("[yellow]New group is the same. No changes made.[/yellow]")
        return

    registry_to_write = read_registry(PROJECTS_JSON_PATH, read_local=False) if scope == "global" else read_registry(PROJECTS_JSON_PATH + ".local", read_local=False)
    del registry_to_write[original_group][proj_name]
    if not registry_to_write[original_group]:
        del registry_to_write[original_group]
    if new_group not in registry_to_write:
        registry_to_write[new_group] = {}
    registry_to_write[new_group][proj_name] = proj_data
    write_registry(registry_to_write, PROJECTS_JSON_PATH, scope)
    CONSOLE.print(
        f"✅ Project '[cyan]{proj_name}[/cyan]' moved to group '[magenta]{new_group}[/magenta]' in {scope} scope."
    )


def remove_project(args):
    """Handler for removing a project configuration."""
    data = read_registry(PROJECTS_JSON_PATH)
    proj_name = _get_project_name_from_dropdown(data, "Select a project to remove")
    if not proj_name:
        return 1
    
    group, _, scope = find_item_and_scope(PROJECTS_JSON_PATH, proj_name)
    if not group:
        CONSOLE.print(f"[red]Error: Project '{proj_name}' not found.[/red]")
        return 1

    prompt = inquirer.confirm(
        message=f"Are you sure you want to remove project '{proj_name}' from the {scope} config?", default=False, style=STYLE, vi_mode=True
    )
    if prompt_with_interrupt_handler(prompt):
        registry_to_write = read_registry(PROJECTS_JSON_PATH, read_local=False) if scope == "global" else read_registry(PROJECTS_JSON_PATH + ".local", read_local=False)
        del registry_to_write[group][proj_name]
        if not registry_to_write[group]:
            del registry_to_write[group]
        write_registry(registry_to_write, PROJECTS_JSON_PATH, scope)
        CONSOLE.print(f"✅ Project '[cyan]{proj_name}[/cyan]' removed from {scope} scope.")

def scope_project(args):
    scope_item("Project", PROJECTS_JSON_PATH, _get_project_name_from_dropdown)


def launch_project(args):
    """Lets user select a project and writes shell commands to the outfile."""
    data = read_registry(PROJECTS_JSON_PATH)
    all_projects = [
        (name, obj)
        for group, projects in data.items()
        for name, obj in projects.items()
    ]
    if not all_projects:
        CONSOLE.print("[red]No projects configured to launch.[/red]")
        sys.exit(1)

    choices = [
        Choice(value=proj_data, name=f"{proj_data[0]} ({proj_data[1].get('path')})")
        for proj_data in all_projects
    ]
    prompt = inquirer.select(
        message="Select a project to launch:",
        choices=choices,
        style=STYLE,
        vi_mode=True,
    )
    selected_proj_data = prompt_with_interrupt_handler(prompt)

    proj_name, proj_obj = selected_proj_data
    proj_path = os.path.expanduser(proj_obj["path"])

    session_name = proj_name.replace(".", "_") + "_$RANDOM"
    window_name = proj_name

    script_lines = [
        f'local session_name="{session_name}"',
        f'local window_name="{window_name}"',
        f"cd '{proj_path}'",
        f'if tmux has-session -t "{proj_name}" 2>/dev/null; then',
        f'  tmux attach-session -t "{proj_name}"',
        "else",
        '  tmux cns "$session_name" "$window_name"',
        f'  tmux rename-session -t "$session_name" "{proj_name}"',
        "fi",
    ]

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write("\n".join(script_lines) + "\n")


def main():
    parser = StyledArgumentParser(
        prog="enigma proj", add_help=False, usage="<command> [options]"
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("launch", add_help=False).set_defaults(func=launch_project)
    subparsers.add_parser("ls", add_help=False).set_defaults(func=list_projects)

    # --- vvv THIS IS THE CORRECTED PARSER SETUP vvv ---
    parser_add = subparsers.add_parser("add", add_help=False)
    parser_add.add_argument("name", help="The name for the new project.")
    parser_add.add_argument("path", help="The path to the project directory.")
    parser_add.set_defaults(func=add_project)

    parser_edit = subparsers.add_parser("edit", add_help=False)
    parser_edit.set_defaults(func=edit_project)

    parser_rm = subparsers.add_parser("rm", add_help=False)
    parser_rm.set_defaults(func=remove_project)

    parser_mv = subparsers.add_parser("mv", add_help=False)
    parser_mv.set_defaults(func=move_project)
    parser_scope = subparsers.add_parser("scope", add_help=False)
    parser_scope.set_defaults(func=scope_project)
    # --- ^^^ END OF CORRECTED PARSER SETUP ^^^ ---

    subparsers.add_parser("help", add_help=False).set_defaults(func=show_help)
    parser.set_defaults(func=show_help)

    args = parser.parse_args() if len(sys.argv) > 1 else parser.parse_args(["help"])
    args.func(args)


if __name__ == "__main__":
    main()
