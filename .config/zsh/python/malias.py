#!/usr/bin/env python3
import argparse
import json
import os
import sys

from rich import box
from rich.console import Console
from rich.prompt import Confirm, Prompt
from rich.table import Table

# Define the path to the JSON registry file
ALIAS_JSON_PATH = os.path.expanduser("~/.config/zsh/aliases.json")


def read_registry():
    """Reads the JSON registry file and returns it as a dictionary."""
    if not os.path.exists(ALIAS_JSON_PATH):
        return {}
    try:
        with open(ALIAS_JSON_PATH, "r") as f:
            return json.load(f)
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


def list_aliases(args):
    """Handler for the 'list' command, using rich for beautiful table output."""
    console = Console()
    data = read_registry()
    if not data:
        console.print("[yellow]Alias registry is empty.[/yellow]")
        return
    groups_to_display = {}
    if args.group:
        canonical_group = next(
            (g for g in data if g.lower() == args.group.lower()), None
        )
        if canonical_group:
            groups_to_display = {canonical_group: data[canonical_group]}
        else:
            console.print(
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
        )
        table.add_column("Alias", style="cyan", no_wrap=True, min_width=5)
        table.add_column("Command", style="white")
        if not aliases:
            table.add_row("[dim]...empty...", "")
        else:
            for name, command in sorted(aliases.items()):
                table.add_row(name, command)
        console.print(table)


def add_alias(args):
    """Handler for the interactive 'add' command."""
    console = Console()
    data = read_registry()
    alias_name = args.name
    if find_alias(data, alias_name):
        console.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' already exists. Use 'edit'."
        )
        return 1
    alias_command = Prompt.ask(
        f"Enter the command for the alias '[bold cyan]{alias_name}[/bold cyan]'"
    )
    group_name = Prompt.ask("Enter the group name", default="Uncategorized")
    if group_name not in data:
        data[group_name] = {}
    data[group_name][alias_name] = alias_command
    write_registry(data)
    console.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' added to group '[blue]{group_name}[/blue]'."
    )

    # If an output file is provided, write the shell command to it.
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = alias_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def edit_alias(args):
    """Handler for the 'edit' command."""
    console = Console()
    data = read_registry()
    alias_name = args.name
    group = find_alias(data, alias_name)
    if not group:
        console.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    new_command = Prompt.ask(
        f"Enter the new command for '[bold cyan]{alias_name}[/bold cyan]'"
    )
    data[group][alias_name] = new_command
    write_registry(data)
    console.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' updated successfully."
    )

    # If an output file is provided, write the shell command to it.
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = new_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def remove_alias(args):
    """Handler for the 'rm' command."""
    console = Console()
    data = read_registry()
    alias_name = args.name
    group = find_alias(data, alias_name)
    if not group:
        console.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    if not Confirm.ask(
        f"Are you sure you want to remove the alias '[bold cyan]{alias_name}[/bold cyan]'?"
    ):
        console.print("Deletion cancelled.")
        return
    del data[group][alias_name]
    if not data[group]:
        del data[group]
    write_registry(data)
    console.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' removed successfully."
    )

    # If an output file is provided, write the shell command to it.
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
    # Add a hidden argument to get the output file path from our shell wrapper
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(
        dest="command", required=True, help="Available commands"
    )

    parser_list = subparsers.add_parser(
        "list", help="Show all aliases, optionally filtered by group"
    )
    parser_list.add_argument("group", nargs="?", help="The group to filter by")
    parser_list.set_defaults(func=list_aliases)

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
