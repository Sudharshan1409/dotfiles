#!/usr/bin/env python3
import argparse
import json
import os
import platform

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from rich import box
from rich.console import Console
from rich.table import Table

# Define the path to the JSON registry file
EXPORTS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/exports.json")
CONSOLE = Console(stderr=True)


def read_registry():
    """Reads the JSON registry file."""
    if not os.path.exists(EXPORTS_JSON_PATH):
        with open(EXPORTS_JSON_PATH, "w") as f:
            json.dump({}, f)
        return {}
    try:
        with open(EXPORTS_JSON_PATH, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        CONSOLE.print("[red]Error: Could not read or parse exports.json.[/red]")
        return {}


def write_registry(data):
    """Writes the dictionary back to the JSON registry file."""
    try:
        with open(EXPORTS_JSON_PATH, "w") as f:
            json.dump(data, f, indent=4, sort_keys=True)
    except IOError:
        CONSOLE.print("[red]Error: Could not write to exports.json.[/red]")


def get_current_os():
    """Returns the current OS name in a consistent format ('Darwin', 'Linux')."""
    return platform.system()


def load_for_shell(args):
    """Prints all environment commands that match the current OS."""
    data = read_registry()
    current_os = get_current_os()

    for group, entries in data.items():
        for name, entry_obj in entries.items():
            entry_os = entry_obj.get("os", "any")
            if entry_os.lower() == "any" or entry_os == current_os:
                print(entry_obj.get("value", ""))


def list_exports(args):
    """Handler for the 'ls' command."""
    data = read_registry()
    if not data:
        CONSOLE.print("[yellow]Environment registry is empty.[/yellow]")
        return

    for group_name, entries in sorted(data.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_cyan",
            show_lines=True,
        )
        table.add_column("Name", style="cyan", no_wrap=True)
        table.add_column("Type", style="yellow")
        table.add_column("OS", style="green")
        table.add_column("Value")

        for name, entry_obj in sorted(entries.items()):
            table.add_row(
                name,
                entry_obj.get("type", "N/A"),
                entry_obj.get("os", "N/A"),
                entry_obj.get("value", ""),
            )
        CONSOLE.print(table)


def add_export(args):
    """Handler for the interactive 'add' command."""
    data = read_registry()

    entry_name = inquirer.text(
        message="What is the unique name for this entry (e.g., rust_backtrace)?",
        validate=lambda r: len(r) > 0 and " " not in r,
        invalid_message="Name cannot be empty or contain spaces.",
    ).execute()

    entry_type = inquirer.select(
        message="What type of entry is this?",
        choices=[
            Choice("variable", "Static variable (export KEY=VALUE)"),
            Choice("dynamic", "Dynamic variable (export KEY=$(...))"),
            Choice("path", "Prepend to PATH (export PATH=...:$PATH)"),
            Choice("eval", 'Command to run inside eval "$(...)"'),
            Choice("run", "Simple command to execute"),
        ],
    ).execute()

    value = ""
    var_name = ""
    if entry_type in ["variable", "dynamic"]:
        var_name = (
            inquirer.text(message="What is the variable's name (e.g., FOO)?")
            .execute()
            .upper()
        )
        if entry_type == "variable":
            var_val = inquirer.text(
                message=f"What is the value for {var_name}?"
            ).execute()
            value = f'export {var_name}="{var_val}"'
        else:  # dynamic
            var_cmd = inquirer.text(
                message=f"What is the command to get the value for {var_name}?"
            ).execute()
            value = f"export {var_name}=$({var_cmd})"
    elif entry_type == "path":
        path_val = inquirer.text(
            message="What is the directory to prepend to $PATH?"
        ).execute()
        value = f'export PATH="{path_val}:$PATH"'
    elif entry_type == "eval":
        cmd_val = inquirer.text(message="What is the command for eval?").execute()
        value = f'eval "$({cmd_val})"'
    else:  # run
        value = inquirer.text(message="What is the command to run?").execute()

    entry_os = inquirer.select(
        message="Which OS should this apply to?",
        choices=["any", "Darwin", "Linux"],
        default="any",
    ).execute()

    existing_groups = sorted(list(data.keys()))
    choices = [Choice(g, g) for g in existing_groups]
    choices.extend([Separator(), Choice("NEW", "Create a new group...")])
    group_choice = inquirer.select(message="Select a group:", choices=choices).execute()

    group_name = (
        inquirer.text(message="Enter the new group name:").execute()
        if group_choice == "NEW"
        else group_choice
    )

    if group_name not in data:
        data[group_name] = {}

    data[group_name][entry_name] = {
        "value": value,
        "type": entry_type,
        "os": entry_os,
        "var_name": var_name,
    }
    write_registry(data)
    CONSOLE.print(
        f"✅ Entry '[cyan]{entry_name}[/cyan]' added to group '[cyan]{group_name}[/cyan]'."
    )

    # --- THIS IS THE NEW LOGIC ---
    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"{value}\n")


def remove_export(args):
    """Handler for the 'rm' command."""
    data = read_registry()
    all_entries = {
        name: (group, obj)
        for group, entries in data.items()
        for name, obj in entries.items()
    }
    if not all_entries:
        CONSOLE.print("[yellow]No entries to remove.[/yellow]")
        return

    entry_to_remove = inquirer.select(
        message="Which entry do you want to remove?",
        choices=sorted(list(all_entries.keys())),
    ).execute()

    if inquirer.confirm(
        message=f"Are you sure you want to remove '{entry_to_remove}'?", default=False
    ).execute():
        group, entry_obj = all_entries[entry_to_remove]
        del data[group][entry_to_remove]
        if not data[group]:
            del data[group]
        write_registry(data)
        CONSOLE.print(f"✅ Entry '[cyan]{entry_to_remove}[/cyan]' removed.")

        # --- THIS IS THE NEW LOGIC ---
        if args.outfile:
            var_name = entry_obj.get("var_name")
            if var_name:  # Only unset if it's a variable type
                with open(args.outfile, "w") as f:
                    f.write(f"unset {var_name}\n")


def main():
    parser = argparse.ArgumentParser(description="An environment variable manager.")
    # --- THIS IS THE NEW LOGIC ---
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(dest="command")
    subparsers.required = True

    subparsers.add_parser(
        "ls", help="Show all environment configurations."
    ).set_defaults(func=list_exports)
    subparsers.add_parser("add", help="Interactively create a new entry.").set_defaults(
        func=add_export
    )
    subparsers.add_parser("rm", help="Interactively remove an entry.").set_defaults(
        func=remove_export
    )

    subparsers.add_parser("load", help=argparse.SUPPRESS).set_defaults(
        func=load_for_shell
    )

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
