#!/usr/bin/env python3
import argparse
import json
import os
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from rich import box
from rich.console import Console
from rich.prompt import Confirm, Prompt
from rich.table import Table

# Define the path to the JSON registry file
ALIAS_JSON_PATH = os.path.expanduser("~/.config/zsh/aliases.json")
CONSOLE = Console(stderr=True)


def read_registry():
    """Reads the JSON registry file and returns it as a dictionary."""
    if not os.path.exists(ALIAS_JSON_PATH):
        return {}
    try:
        with open(ALIAS_JSON_PATH, "r") as f:
            data = json.load(f)
            return data if data else {}
    except (json.JSONDecodeError, IOError):
        return {}


def write_registry(data):
    """Writes the dictionary back to the JSON registry file with pretty printing."""
    with open(ALIAS_JSON_PATH, "w") as f:
        json.dump(data, f, indent=4, sort_keys=True)


def find_alias(data, alias_name):
    """Finds which group an alias belongs to."""
    for group, aliases in data.items():
        if alias_name in aliases:
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


def list_aliases(args):
    """Handler for the 'ls' command, using rich for beautiful table output."""
    data = read_registry()
    if not data:
        CONSOLE.print("[yellow]Alias registry is empty.[/yellow]")
        return
    groups_to_display = {}
    if args.group:
        canonical_group = next(
            (g for g in data if g.lower() == args.group.lower()), None
        )
        if canonical_group:
            groups_to_display = {canonical_group: data[canonical_group]}
        else:
            CONSOLE.print(
                f"[red]❌ Error:[/red] Group '[b]{args.group}[/b]' not found."
            )
            return
    else:
        groups_to_display = data
    for group_name, aliases in sorted(groups_to_display.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_blue",
            title_style="bold bright_blue",
            show_lines=True,
        )
        table.add_column("Alias", style="cyan", no_wrap=True, min_width=5)
        table.add_column("Command", style="white")
        if not aliases:
            table.add_row("[dim]...empty...", "")
        else:
            for name, command in sorted(aliases.items()):
                table.add_row(name, command)
        CONSOLE.print(table)


def add_alias(args):
    """Handler for the interactive 'add' command."""
    data = read_registry()
    alias_name = args.name
    if find_alias(data, alias_name):
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' already exists. Use 'edit'."
        )
        return 1

    alias_command = Prompt.ask(
        f"Enter the command for the alias '[bold cyan]{alias_name}[/bold cyan]'"
    )

    group_name = _get_group_selection(data)

    if group_name not in data:
        data[group_name] = {}
    data[group_name][alias_name] = alias_command
    write_registry(data)
    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' added to group '[blue]{group_name}[/blue]'."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = alias_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def edit_alias(args):
    """Handler for the 'edit' command."""
    data = read_registry()
    alias_name = args.name
    group = find_alias(data, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    new_command = Prompt.ask(
        f"Enter the new command for '[bold cyan]{alias_name}[/bold cyan]'"
    )
    data[group][alias_name] = new_command
    write_registry(data)
    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' updated successfully."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = new_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def remove_alias(args):
    """Handler for the 'rm' command."""
    data = read_registry()
    alias_name = args.name
    group = find_alias(data, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    if not Confirm.ask(
        f"Are you sure you want to remove the alias '[bold cyan]{alias_name}[/bold cyan]'?"
    ):
        CONSOLE.print("Deletion cancelled.")
        return
    del data[group][alias_name]
    if not data[group]:
        del data[group]
    write_registry(data)
    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' removed successfully."
    )

    if args.outfile:
        with open(args.outfile, "w") as f:
            f.write(f"unalias {alias_name}\n")


def load_for_shell(args):
    """Handler for the 'load' command. Prints aliases for shell to eval."""
    data = read_registry()
    for group, aliases in data.items():
        for name, command in aliases.items():
            command_quoted = command.replace("'", "'\\''")
            print(f"alias {name}='{command_quoted}'")
    print(f"alias getrepo='{os.path.expanduser('~/.config/zsh/getrepo.sh')}'")


def main():
    parser = argparse.ArgumentParser(
        description="A group-aware alias manager using a JSON registry."
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Available commands"
    )

    # --- vvv THIS IS THE CHANGED LINE vvv ---
    parser_ls = subparsers.add_parser(
        "ls", help="Show all aliases, optionally filtered by group"
    )
    # --- ^^^ THIS IS THE CHANGED LINE ^^^ ---
    parser_ls.add_argument("group", nargs="?", help="The group to filter by")
    parser_ls.set_defaults(func=list_aliases)

    parser_add = subparsers.add_parser("add", help="Interactively create a new alias")
    parser_add.add_argument("name", help="The name of the alias to create")
    parser_add.set_defaults(func=add_alias)

    parser_edit = subparsers.add_parser(
        "edit", help="Interactively edit an existing alias"
    )
    parser_edit.add_argument("name", help="The name of the alias to edit")
    parser_edit.set_defaults(func=edit_alias)

    parser_rm = subparsers.add_parser("rm", help="Interactively remove an alias")
    parser_rm.add_argument("name", help="The name of the alias to remove")
    parser_rm.set_defaults(func=remove_alias)

    parser_load = subparsers.add_parser(
        "load", help="(Internal) Generates alias commands for the shell"
    )
    parser_load.set_defaults(func=load_for_shell)

    args = parser.parse_args()
    sys.exit(args.func(args) or 0)


if __name__ == "__main__":
    main()
