#!/usr/bin/env python3
import argparse
import os
import platform
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from lib.common import (
    CONSOLE,
    StyledArgumentParser,
    print_help_panel,
    prompt_with_interrupt_handler,
    read_registry,
    write_registry,
)
from rich import box
from rich.table import Table

EXPORTS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/exports.json")


def show_help(args):
    title = "Environment Manager"
    command_name = "enigma env"
    commands = {
        "ls": "Lists all environment entries.",
        "add": "Interactively adds a new entry.",
        "edit": "Interactively edits an existing entry.",
        "rm": "Removes an environment entry.",
    }
    print_help_panel(title, command_name, commands)


def get_current_os():
    return platform.system()


def build_shell_command(entry_obj):
    entry_type, var_name, value = (
        entry_obj.get("type"),
        entry_obj.get("var_name"),
        entry_obj.get("value"),
    )
    if entry_type == "variable":
        return f'export {var_name}="{value}"'
    if entry_type == "dynamic":
        return f"export {var_name}=$({value})"
    if entry_type == "path":
        return f'export PATH="{value}:$PATH"'
    if entry_type == "eval":
        return f'eval "$({value})"'
    if entry_type == "run":
        return value
    return ""


def load_for_shell(args):
    data = read_registry(EXPORTS_JSON_PATH)
    current_os = get_current_os()
    for entries in data.values():
        for entry_obj in entries.values():
            if entry_obj.get("os", "any") in ("any", current_os):
                print(build_shell_command(entry_obj))


def list_exports(args):
    data = read_registry(EXPORTS_JSON_PATH)
    if not data:
        CONSOLE.print("[yellow]Environment registry is empty.[/yellow]")
        return
    for group_name, entries in sorted(data.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_cyan",
            title_style="bold bright_cyan",
            show_lines=True,
        )
        table.add_column("Name", style="cyan", no_wrap=True)
        table.add_column("Type", style="yellow")
        table.add_column("OS", style="green")
        table.add_column("Variable Name")
        table.add_column("Value")
        for name, entry_obj in sorted(entries.items()):
            var_name = entry_obj.get("var_name")
            var_name_display = (
                f"[bright_blue]{var_name}[/bright_blue]"
                if var_name
                else "[dim red]N/A[/dim red]"
            )
            table.add_row(
                name,
                entry_obj.get("type", "N/A"),
                entry_obj.get("os", "N/A"),
                var_name_display,
                entry_obj.get("value", ""),
            )
        CONSOLE.print(table)


def add_or_edit_export(args, entry_to_edit=None):
    data = read_registry(EXPORTS_JSON_PATH)
    original_obj, original_group = {}, None
    if entry_to_edit:
        for group, entries in data.items():
            if entry_to_edit in entries:
                original_group, original_obj = group, entries[entry_to_edit]
                break
    else:
        prompt = inquirer.text(
            message="What is the unique name for this entry?",
            validate=lambda r: len(r) > 0 and " " not in r,
            invalid_message="Name cannot be empty or contain spaces.",
        )
        entry_to_edit = prompt_with_interrupt_handler(prompt)

    prompt = inquirer.select(
        message="What type of entry is this?",
        choices=[
            Choice("variable", "Static variable (export KEY=VALUE)"),
            Choice("dynamic", "Dynamic variable (export KEY=$(...))"),
            Choice("path", "Prepend to PATH (export PATH=...:$PATH)"),
            Choice("eval", 'Command to run inside eval "$(...)"'),
            Choice("run", "Simple command to execute"),
        ],
        default=original_obj.get("type"),
    )
    entry_type = prompt_with_interrupt_handler(prompt)

    value, var_name, default_val = "", "", original_obj.get("value", "")
    if entry_type in ["variable", "dynamic"]:
        prompt = inquirer.text(
            message="What is the variable's name (e.g., FOO)?",
            default=original_obj.get("var_name", ""),
        )
        var_name = prompt_with_interrupt_handler(prompt).upper()

        prompt_msg = (
            "What is the value?" if entry_type == "variable" else "What is the command?"
        )
        prompt = inquirer.text(
            message=f"{prompt_msg} for {var_name}", default=default_val
        )
        value = prompt_with_interrupt_handler(prompt)
    elif entry_type == "path":
        var_name = "PATH"
        prompt = inquirer.text(
            message="What is the directory to prepend?", default=default_val
        )
        value = prompt_with_interrupt_handler(prompt)
    else:
        prompt = inquirer.text(
            message="What is the command to run?", default=default_val
        )
        value = prompt_with_interrupt_handler(prompt)

    prompt = inquirer.select(
        message="Which OS should this apply to?",
        choices=["any", "Darwin", "Linux"],
        default=original_obj.get("os", "any"),
    )
    entry_os = prompt_with_interrupt_handler(prompt)

    if original_group:
        group_name = original_group
    else:
        existing_groups = sorted(list(data.keys()))
        choices = [Choice(g, g) for g in existing_groups]
        choices.extend([Separator(), Choice("NEW", "Create a new group...")])
        prompt = inquirer.select(message="Select a group:", choices=choices)
        group_choice = prompt_with_interrupt_handler(prompt)
        group_name = (
            prompt_with_interrupt_handler(
                inquirer.text(message="Enter the new group name:")
            )
            if group_choice == "NEW"
            else group_choice
        )

    if original_group and entry_to_edit in data[original_group]:
        del data[original_group][entry_to_edit]
        if not data[original_group]:
            del data[original_group]

    if group_name not in data:
        data[group_name] = {}
    new_entry = {
        "type": entry_type,
        "os": entry_os,
        "var_name": var_name,
        "value": value,
    }
    data[group_name][entry_to_edit] = new_entry
    write_registry(data, EXPORTS_JSON_PATH)
    action = "updated" if original_group else "added"
    CONSOLE.print(
        f"✅ Entry '[cyan]{entry_to_edit}[/cyan]' {action} in group '[cyan]{group_name}[/cyan]'."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            original_var_name = original_obj.get("var_name")
            if original_var_name and original_var_name != var_name:
                f.write(f"unset {original_var_name}\n")
            f.write(f"{build_shell_command(new_entry)}\n")


def edit_export(args):
    data = read_registry(EXPORTS_JSON_PATH)
    all_entries = [name for group in data.values() for name in group]
    if not all_entries:
        CONSOLE.print("[yellow]No entries to edit.[/yellow]")
        return
    prompt = inquirer.select(
        message="Which entry do you want to edit?", choices=sorted(all_entries)
    )
    entry_to_edit = prompt_with_interrupt_handler(prompt)
    add_or_edit_export(args, entry_to_edit=entry_to_edit)


def remove_export(args):
    data = read_registry(EXPORTS_JSON_PATH)
    all_entries = {
        name: (group, obj)
        for group, entries in data.items()
        for name, obj in entries.items()
    }
    if not all_entries:
        CONSOLE.print("[yellow]No entries to remove.[/yellow]")
        return
    prompt = inquirer.select(
        message="Which entry do you want to remove?",
        choices=sorted(list(all_entries.keys())),
    )
    entry_to_remove = prompt_with_interrupt_handler(prompt)

    prompt = inquirer.confirm(
        message=f"Are you sure you want to remove '{entry_to_remove}'?", default=False
    )
    if prompt_with_interrupt_handler(prompt):
        group, entry_obj = all_entries[entry_to_remove]
        del data[group][entry_to_remove]
        if not data[group]:
            del data[group]
        write_registry(data, EXPORTS_JSON_PATH)
        CONSOLE.print(f"✅ Entry '[cyan]{entry_to_remove}[/cyan]' removed.")
        if args.outfile:
            var_name = entry_obj.get("var_name")
            if var_name:
                with open(args.outfile, "w") as f:
                    f.write(f"unset {var_name}\n")


def main():
    parser = StyledArgumentParser(
        prog="enigma env", add_help=False, usage="<command> [options]"
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("ls", add_help=False).set_defaults(func=list_exports)
    subparsers.add_parser("add", add_help=False).set_defaults(func=add_or_edit_export)
    subparsers.add_parser("edit", add_help=False).set_defaults(func=edit_export)
    subparsers.add_parser("rm", add_help=False).set_defaults(func=remove_export)
    subparsers.add_parser("help", add_help=False).set_defaults(func=show_help)
    subparsers.add_parser("load", help=argparse.SUPPRESS, add_help=False).set_defaults(
        func=load_for_shell
    )

    parser.set_defaults(func=show_help)

    if len(sys.argv) == 1:
        show_help(None)
        sys.exit(0)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
