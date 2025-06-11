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
CONSOLE = Console(stderr=True)


def migrate_registry(data):
    """
    Checks if the registry is in the old format (string values) and converts
    it to the new object format, assuming all old functions were 'zsh'.
    """
    if not data:
        return data, False

    first_item_key = next(iter(data))
    first_group = data[first_item_key]
    if not first_group:
        return data, False

    first_func_key = next(iter(first_group))

    if isinstance(first_group[first_func_key], str):
        CONSOLE.print(
            "[yellow]Old function format detected. Migrating to new format...[/yellow]"
        )
        new_data = {}
        for group, functions in data.items():
            new_data[group] = {}
            for name, body in functions.items():
                new_data[group][name] = {"type": "zsh", "body": body}
        return new_data, True

    return data, False


def read_registry():
    """Reads the JSON registry file, handling migration if necessary."""
    if not os.path.exists(FUNCTION_JSON_PATH):
        with open(FUNCTION_JSON_PATH, "w") as f:
            json.dump({}, f)
        return {}
    try:
        with open(FUNCTION_JSON_PATH, "r") as f:
            data = json.load(f)

        migrated_data, was_migrated = migrate_registry(data)
        if was_migrated:
            write_registry(migrated_data)
            return migrated_data

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
    """Finds which group a function belongs to, returns group and function object."""
    for group, functions in data.items():
        if func_name in functions:
            return group, functions[func_name]
    return None, None


def _get_group_selection(data):
    """Presents an interactive dropdown menu for group selection."""
    existing_groups = sorted(list(data.keys()))
    CREATE_NEW = "[Create New Group]"
    choices = [Choice(value=group, name=group) for group in existing_groups]
    choices.extend(
        [Separator(), Choice(value=CREATE_NEW, name="Create a new group...")]
    )

    selection = inquirer.select(
        message="Select a group:",
        choices=choices,
        default=choices[0].value if existing_groups else CREATE_NEW,
    ).execute()

    if selection == CREATE_NEW:
        new_group = inquirer.text(
            message="Enter the new group name:", validate=lambda r: len(r) > 0
        ).execute()
        return new_group
    else:
        return selection


def _get_function_type():
    """Asks the user for the function type."""
    return inquirer.select(
        message="What type of function is this?",
        choices=[
            Choice("zsh", "Zsh Shell Function"),
            Choice("python", "Python Script"),
        ],
        default="zsh",
    ).execute()


def invoke_editor(initial_content="", func_type="zsh"):
    """Opens the user's default editor to edit content with the correct file extension."""
    editor = os.environ.get("EDITOR", "vim")

    suffix = ".py" if func_type == "python" else ".sh"

    with tempfile.NamedTemporaryFile(suffix=suffix, mode="w+", delete=False) as tf:
        tf.write(initial_content)
        temp_path = tf.name

    header = "#\n# Please enter the function body below. Save and exit to accept.\n#\n"
    with open(temp_path, "r+") as f:
        content = f.read()
        f.seek(0, 0)
        f.write(header + content)

    try:
        subprocess.run([editor, temp_path], check=True, text=True)
        with open(temp_path, "r") as f:
            lines = f.readlines()
            user_content_lines = [
                line for line in lines if not line.startswith("# Please enter")
            ]
            return "".join(user_content_lines[2:]).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    finally:
        os.remove(temp_path)


def list_functions(args):
    """Handler for the 'ls' command with syntax highlighting."""
    data = read_registry()
    if not data:
        CONSOLE.print("[yellow]Function registry is empty.[/yellow]")
        return

    for group_name, functions in sorted(data.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_green",
            show_lines=True,
        )
        table.add_column("Function", style="cyan", no_wrap=True)
        table.add_column("Type", style="yellow")
        table.add_column("Body")

        for name, func_obj in sorted(functions.items()):
            func_type = func_obj.get("type", "zsh")
            body = func_obj.get("body", "")
            lexer = "python" if func_type == "python" else "bash"
            syntax = Syntax(
                body, lexer, theme="monokai", line_numbers=True, word_wrap=True
            )
            table.add_row(name, func_type.capitalize(), syntax)
        CONSOLE.print(table)


def add_function(args):
    """Handler for the 'add' command."""
    data = read_registry()
    func_name = args.name
    if find_function(data, func_name)[0]:
        CONSOLE.print(f"[red]Error: Function '{func_name}' already exists.[/red]")
        return 1

    func_type = _get_function_type()
    CONSOLE.print(f"Opening editor for new {func_type} function '{func_name}'...")

    func_body = invoke_editor(func_type=func_type)

    if func_body is None or not func_body.strip():
        CONSOLE.print("Cancelled or empty body provided.")
        return 1

    group_name = _get_group_selection(data)
    if group_name not in data:
        data[group_name] = {}

    data[group_name][func_name] = {"type": func_type, "body": func_body}
    write_registry(data)
    CONSOLE.print(f"✅ Function '{func_name}' added to group '{group_name}'.")

    if args.outfile:
        with open(args.outfile, "w") as f:
            if func_type == "zsh":
                f.write(f"{func_name}() {{\n{func_body}\n}}\n")
            else:  # python
                f.write(f'{func_name}() {{ mfunc run {func_name} "$@" }}\n')


def edit_function(args):
    """Handler for the 'edit' command."""
    data = read_registry()
    func_name = args.name
    group, func_obj = find_function(data, func_name)
    if not group:
        CONSOLE.print(f"[red]Error: Function '{func_name}' not found.[/red]")
        return 1

    func_type = func_obj.get("type", "zsh")
    CONSOLE.print(f"Opening editor to edit {func_type} function '{func_name}'...")

    new_body = invoke_editor(initial_content=func_obj["body"], func_type=func_type)

    if new_body is None:
        CONSOLE.print("Edit cancelled.")
        return 1

    data[group][func_name]["body"] = new_body
    write_registry(data)
    CONSOLE.print(f"✅ Function '{func_name}' updated.")

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"unset -f {func_name}\n")
            if func_obj["type"] == "zsh":
                f.write(f"{func_name}() {{\n{new_body}\n}}\n")
            else:  # python
                f.write(f'{func_name}() {{ mfunc run {func_name} "$@" }}\n')


def remove_function(args):
    """Handler for the 'rm' command."""
    data = read_registry()
    func_name = args.name
    group, _ = find_function(data, func_name)
    if not group:
        CONSOLE.print(f"[red]Error: Function '{func_name}' not found.[/red]")
        return 1

    if Confirm.ask(f"Are you sure you want to remove '{func_name}'?"):
        del data[group][func_name]
        if not data[group]:
            del data[group]
        write_registry(data)
        CONSOLE.print(f"✅ Function '{func_name}' removed.")
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unset -f {func_name}\n")


def load_for_shell(args):
    """Prints all functions in a format the shell can `eval`."""
    data = read_registry()
    for functions in data.values():
        for name, func_obj in functions.items():
            if func_obj.get("type") == "python":
                print(f'{name}() {{ mfunc run {name} "$@" }}')
            else:  # zsh
                print(f"{name}() {{\n{func_obj.get('body', '')}\n}}")


def run_python_function(args):
    """Executes the body of a Python function."""
    data = read_registry()
    _, func_obj = find_function(data, args.name)

    if not func_obj or func_obj.get("type") != "python":
        CONSOLE.print(f"[red]Error: Python function '{args.name}' not found.[/red]")
        return 1

    sys.argv = [args.name] + args.extra_args

    try:
        exec(func_obj["body"], globals())
    except Exception:
        CONSOLE.print(f"[red]Error executing python function '{args.name}':[/red]")
        CONSOLE.print_exception(show_locals=True)
        return 1


def main():
    parser = argparse.ArgumentParser(description="A polyglot shell function manager.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    parser.add_argument("--outfile", help=argparse.SUPPRESS)

    # --- vvv THIS IS THE CHANGED LINE vvv ---
    parser_ls = subparsers.add_parser("ls", help="Show all functions.")
    # --- ^^^ THIS IS THE CHANGED LINE ^^^ ---
    parser_ls.set_defaults(func=list_functions)

    parser_add = subparsers.add_parser("add", help="Create a new function.")
    parser_add.add_argument("name")
    parser_add.set_defaults(func=add_function)

    parser_edit = subparsers.add_parser("edit", help="Edit an existing function.")
    parser_edit.add_argument("name")
    parser_edit.set_defaults(func=edit_function)

    parser_rm = subparsers.add_parser("rm", help="Remove a function.")
    parser_rm.add_argument("name")
    parser_rm.set_defaults(func=remove_function)

    parser_load = subparsers.add_parser("load", help=argparse.SUPPRESS)
    parser_load.set_defaults(func=load_for_shell)

    parser_run = subparsers.add_parser("run", help=argparse.SUPPRESS)
    parser_run.add_argument("name")
    parser_run.add_argument("extra_args", nargs=argparse.REMAINDER)
    parser_run.set_defaults(func=run_python_function)

    args = parser.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
