#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import tempfile

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from lib.common import (
    CONSOLE,
    StyledArgumentParser,
    find_item,
    get_group_selection,
    print_help_panel,
    prompt_with_interrupt_handler,
    read_registry,
    write_registry,
)
from rich import box
from rich.syntax import Syntax
from rich.table import Table

FUNCTION_JSON_PATH = os.path.expanduser("~/.config/zsh/data/functions.json")


def show_help(args):
    title = "Function Manager"
    command_name = "enigma func"
    commands = {
        "ls": "Lists all functions, grouped by category.",
        "add": "Interactively adds a new function (Zsh or Python).",
        "edit": "Interactively edits an existing function.",
        "rm": "Removes a function.",
        "mv": "Moves a function to a different group.",
    }
    print_help_panel(title, command_name, commands)


def migrate_registry(data):
    if not data:
        return data, False
    first_group = data[next(iter(data))]
    if not first_group:
        return data, False
    if isinstance(first_group[next(iter(first_group))], str):
        CONSOLE.print("[yellow]Old function format detected. Migrating...[/yellow]")
        new_data = {}
        for group, functions in data.items():
            new_data[group] = {}
            for name, body in functions.items():
                new_data[group][name] = {"type": "zsh", "body": body}
        return new_data, True
    return data, False


def read_and_migrate_registry():
    data = read_registry(FUNCTION_JSON_PATH)
    migrated_data, was_migrated = migrate_registry(data)
    if was_migrated:
        write_registry(migrated_data, FUNCTION_JSON_PATH)
        return migrated_data
    return data


def _get_function_type():
    prompt = inquirer.select(
        message="What type of function is this?",
        choices=[
            Choice("zsh", "Zsh Shell Function"),
            Choice("python", "Python Script"),
        ],
        default="zsh",
    )
    return prompt_with_interrupt_handler(prompt)


def invoke_editor(initial_content="", func_type="zsh"):
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
    data = read_and_migrate_registry()
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
            func_type, body = func_obj.get("type", "zsh"), func_obj.get("body", "")
            lexer = "python" if func_type == "python" else "bash"
            syntax = Syntax(
                body, lexer, theme="monokai", line_numbers=True, word_wrap=True
            )
            table.add_row(name, func_type.capitalize(), syntax)
        CONSOLE.print(table)


def add_function(args):
    data = read_and_migrate_registry()
    func_name = args.name
    if find_item(data, func_name)[0]:
        CONSOLE.print(f"[red]Error: Function '{func_name}' already exists.[/red]")
        return 1
    func_type = _get_function_type()
    func_body = invoke_editor(func_type=func_type)
    if not func_body:
        CONSOLE.print("Cancelled or empty body provided.")
        return 1
    group_name = get_group_selection(data)
    if group_name not in data:
        data[group_name] = {}
    data[group_name][func_name] = {"type": func_type, "body": func_body}
    write_registry(data, FUNCTION_JSON_PATH)
    CONSOLE.print(f"✅ Function '{func_name}' added to group '{group_name}'.")
    if args.outfile:
        with open(args.outfile, "w") as f:
            if func_type == "zsh":
                f.write(f"{func_name}() {{\n{func_body}\n}}\n")
            else:
                f.write(f'{func_name}() {{ enigma func run {func_name} "$@" }}\n')


def edit_function(args):
    data = read_and_migrate_registry()
    func_name = args.name
    group, func_obj = find_item(data, func_name)
    if not group:
        CONSOLE.print(f"[red]Error: Function '{func_name}' not found.[/red]")
        return 1
    func_type = func_obj.get("type", "zsh")
    new_body = invoke_editor(initial_content=func_obj["body"], func_type=func_type)
    if new_body is None:
        CONSOLE.print("Edit cancelled.")
        return 1
    data[group][func_name]["body"] = new_body
    write_registry(data, FUNCTION_JSON_PATH)
    CONSOLE.print(f"✅ Function '{func_name}' updated.")
    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"unset -f {func_name}\n")
            if func_obj["type"] == "zsh":
                f.write(f"{func_name}() {{\n{new_body}\n}}\n")
            else:
                f.write(f'{func_name}() {{ enigma func run {func_name} "$@" }}\n')


def move_function(args):
    data = read_and_migrate_registry()
    func_name = args.name
    original_group, func_data = find_item(data, func_name)
    if not original_group:
        CONSOLE.print(
            f"[red]Error: Function '[cyan]{func_name}[/cyan]' not found.[/red]"
        )
        return 1
    CONSOLE.print(
        f"Moving function '[cyan]{func_name}[/cyan]' from group '[green]{original_group}[/green]'."
    )
    new_group = get_group_selection(data)
    if new_group == original_group:
        CONSOLE.print("[yellow]New group is the same. No changes made.[/yellow]")
        return
    del data[original_group][func_name]
    if not data[original_group]:
        del data[original_group]
    if new_group not in data:
        data[new_group] = {}
    data[new_group][func_name] = func_data
    write_registry(data, FUNCTION_JSON_PATH)
    CONSOLE.print(
        f"✅ Function '[cyan]{func_name}[/cyan]' moved to group '[green]{new_group}[/green]'."
    )


def remove_function(args):
    data = read_and_migrate_registry()
    func_name = args.name
    group, _ = find_item(data, func_name)
    if not group:
        CONSOLE.print(f"[red]Error: Function '{func_name}' not found.[/red]")
        return 1

    prompt = inquirer.confirm(
        message=f"Are you sure you want to remove '{func_name}'?", default=False
    )
    if prompt_with_interrupt_handler(prompt):
        del data[group][func_name]
        if not data[group]:
            del data[group]
        write_registry(data, FUNCTION_JSON_PATH)
        CONSOLE.print(f"✅ Function '{func_name}' removed.")
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unset -f {func_name}\n")


def load_for_shell(args):
    data = read_and_migrate_registry()
    for functions in data.values():
        for name, func_obj in functions.items():
            if func_obj.get("type") == "python":
                print(f'{name}() {{ enigma func run {name} "$@" }}')
            else:
                print(f"{name}() {{\n{func_obj.get('body', '')}\n}}")


def run_python_function(args):
    data = read_and_migrate_registry()
    _, func_obj = find_item(data, args.name)
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
    parser = StyledArgumentParser(
        prog="enigma func", add_help=False, usage="<command> [options]"
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(dest="command")

    parser_ls = subparsers.add_parser("ls", add_help=False)
    parser_ls.set_defaults(func=list_functions)
    parser_add = subparsers.add_parser("add", add_help=False)
    parser_add.add_argument("name")
    parser_add.set_defaults(func=add_function)
    parser_edit = subparsers.add_parser("edit", add_help=False)
    parser_edit.add_argument("name")
    parser_edit.set_defaults(func=edit_function)
    parser_rm = subparsers.add_parser("rm", add_help=False)
    parser_rm.add_argument("name")
    parser_rm.set_defaults(func=remove_function)
    parser_mv = subparsers.add_parser("mv", add_help=False)
    parser_mv.add_argument("name")
    parser_mv.set_defaults(func=move_function)
    subparsers.add_parser("help", add_help=False).set_defaults(func=show_help)
    subparsers.add_parser("load", help=argparse.SUPPRESS, add_help=False).set_defaults(
        func=load_for_shell
    )
    parser_run = subparsers.add_parser("run", help=argparse.SUPPRESS, add_help=False)
    parser_run.add_argument("name")
    parser_run.add_argument("extra_args", nargs=argparse.REMAINDER)
    parser_run.set_defaults(func=run_python_function)

    parser.set_defaults(func=show_help)

    if len(sys.argv) == 1:
        show_help(None)
        sys.exit(0)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
