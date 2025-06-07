#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import tempfile

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from rich import box
from rich.console import Console
from rich.prompt import Confirm
from rich.syntax import Syntax
from rich.table import Table

# Define the path to the JSON registry file
FUNCTION_JSON_PATH = os.path.expanduser("~/.config/zsh/functions.json")
CONSOLE = Console()


def read_registry():
    """Reads the JSON registry file and returns it as a dictionary."""
    if not os.path.exists(FUNCTION_JSON_PATH):
        with open(FUNCTION_JSON_PATH, "w") as f:
            json.dump({}, f)
        return {}
    try:
        with open(FUNCTION_JSON_PATH, "r") as f:
            data = json.load(f)
            return data if data else {}
    except (json.JSONDecodeError, IOError):
        CONSOLE.print("[red]Error: Could not read or parse functions.json.[/red]")
        return {}


def write_registry(data):
    """Writes the dictionary back to the JSON registry file with pretty printing."""
    try:
        with open(FUNCTION_JSON_PATH, "w") as f:
            json.dump(data, f, indent=4, sort_keys=True)
    except IOError:
        CONSOLE.print("[red]Error: Could not write to functions.json.[/red]")


def find_function(data, func_name):
    """Finds which group a function belongs to."""
    for group, functions in data.items():
        if func_name in functions:
            return group
    return None


def _get_group_selection(data):
    """
    Presents an interactive dropdown menu for group selection.
    """
    existing_groups = sorted(list(data.keys()))
    CREATE_NEW = "[Create New Group]"

    choices = [Choice(value=group, name=group) for group in existing_groups]
    choices.extend(
        [
            Separator(),
            Choice(value=CREATE_NEW, name="Create a new group..."),
        ]
    )

    selection = inquirer.select(
        message="Select a group:",
        choices=choices,
        default=choices[0].value if existing_groups else CREATE_NEW,
    ).execute()

    if selection == CREATE_NEW:
        new_group = inquirer.text(
            message="Enter the new group name:",
            validate=lambda result: len(result) > 0,
            invalid_message="Group name cannot be empty.",
        ).execute()

        while new_group in existing_groups:
            CONSOLE.print(
                f"[yellow]Group '[bold]{new_group}[/bold]' already exists.[/yellow]"
            )
            new_group = inquirer.text(
                message="Enter a different group name:",
                validate=lambda result: len(result) > 0,
                invalid_message="Group name cannot be empty.",
            ).execute()
        return new_group
    else:
        return selection


def invoke_editor(initial_content=""):
    """Opens the user's default editor to edit content."""
    editor = os.environ.get("EDITOR", "vim")
    with tempfile.NamedTemporaryFile(suffix=".sh", mode="w+", delete=False) as tf:
        tf.write(initial_content)
        temp_path = tf.name

    header = "#\n# Please enter the function body below. Save and exit to accept.\n# Lines starting with # will be preserved as comments.\n#\n"
    with open(temp_path, "r+") as f:
        content = f.read()
        f.seek(0, 0)
        f.write(header + content)

    try:
        subprocess.run([editor, temp_path], check=True)
        with open(temp_path, "r") as f:
            lines = f.readlines()
            user_content_lines = [
                line for line in lines if not line.startswith("# Please enter")
            ]
            user_content_lines = user_content_lines[3:]
            return "".join(user_content_lines).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        CONSOLE.print(f"[red]Error: Failed to open editor '{editor}'.[/red]")
        return None
    finally:
        os.remove(temp_path)


def list_functions(args):
    """Handler for the 'list' command with syntax highlighting."""
    data = read_registry()
    if not data:
        CONSOLE.print(
            "[yellow]Function registry is empty. Use 'mfunc add' to create one.[/yellow]"
        )
        return

    for group_name, functions in sorted(data.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_green",
            title_style="bold bright_green",
            show_lines=True,
        )
        table.add_column("Function", style="cyan", no_wrap=True)
        table.add_column("Body")

        if not functions:
            table.add_row("[dim]...empty...", "")
        else:
            for name, body in sorted(functions.items()):
                syntax = Syntax(
                    body,
                    "bash",
                    theme="monokai",
                    line_numbers=True,
                    word_wrap=True,
                )
                table.add_row(name, syntax)
        CONSOLE.print(table)


def add_function(args):
    """Handler for the 'add' command."""
    data = read_registry()
    func_name = args.name

    if find_function(data, func_name):
        CONSOLE.print(
            f"[red]❌ Error:[/red] Function '[bold cyan]{func_name}[/bold cyan]' already exists. Use 'edit'."
        )
        return 1

    CONSOLE.print(
        f"Preparing to add new function '[bold cyan]{func_name}[/bold cyan]'. Opening your editor..."
    )
    func_body = invoke_editor()

    if func_body is None or not func_body.strip():
        CONSOLE.print("Function creation cancelled or empty body provided.")
        return 1

    group_name = _get_group_selection(data)

    if group_name not in data:
        data[group_name] = {}

    data[group_name][func_name] = func_body
    write_registry(data)
    CONSOLE.print(
        f"✅ Function '[bold cyan]{func_name}[/bold cyan]' added to group '[green]{group_name}[/green]'."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"{func_name}() {{\n{func_body}\n}}\n")


def edit_function(args):
    """Handler for the 'edit' command."""
    data = read_registry()
    func_name = args.name
    group = find_function(data, func_name)

    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Function '[bold cyan]{func_name}[/bold cyan]' not found."
        )
        return 1

    existing_body = data[group][func_name]
    CONSOLE.print(
        f"Preparing to edit function '[bold cyan]{func_name}[/bold cyan]'. Opening your editor..."
    )
    new_body = invoke_editor(existing_body)

    if new_body is None:
        CONSOLE.print("Function edit cancelled.")
        return 1

    data[group][func_name] = new_body
    write_registry(data)
    CONSOLE.print(
        f"✅ Function '[bold cyan]{func_name}[/bold cyan]' updated successfully."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"unset -f {func_name}\n")
            f.write(f"{func_name}() {{\n{new_body}\n}}\n")


def remove_function(args):
    """Handler for the 'rm' command."""
    data = read_registry()
    func_name = args.name
    group = find_function(data, func_name)

    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Function '[bold cyan]{func_name}[/bold cyan]' not found."
        )
        return 1

    if not Confirm.ask(
        f"Are you sure you want to remove the function '[bold cyan]{func_name}[/bold cyan]'?"
    ):
        CONSOLE.print("Deletion cancelled.")
        return

    del data[group][func_name]
    if not data[group]:
        del data[group]

    write_registry(data)
    CONSOLE.print(
        f"✅ Function '[bold cyan]{func_name}[/bold cyan]' removed successfully."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"unset -f {func_name}\n")


def load_for_shell(args):
    """Prints all functions in a format the shell can `eval`."""
    data = read_registry()
    for group, functions in data.items():
        for name, body in functions.items():
            print(f"{name}() {{\n{body}\n}}")


def main():
    parser = argparse.ArgumentParser(
        description="A group-aware shell function manager."
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Available commands"
    )

    parser_list = subparsers.add_parser(
        "list", help="Show all functions, grouped by category."
    )
    parser_list.set_defaults(func=list_functions)

    parser_add = subparsers.add_parser(
        "add", help="Create a new function via your $EDITOR."
    )
    parser_add.add_argument("name", help="The name of the function to create.")
    parser_add.set_defaults(func=add_function)

    parser_edit = subparsers.add_parser(
        "edit", help="Edit an existing function via your $EDITOR."
    )
    parser_edit.add_argument("name", help="The name of the function to edit.")
    parser_edit.set_defaults(func=edit_function)

    parser_rm = subparsers.add_parser("rm", help="Remove an existing function.")
    parser_rm.add_argument("name", help="The name of the function to remove.")
    parser_rm.set_defaults(func=remove_function)

    parser_load = subparsers.add_parser(
        "load", help="(Internal) Generates function definitions for the shell."
    )
    parser_load.set_defaults(func=load_for_shell)

    args = parser.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
