#!/usr/bin/env python3
import argparse
import os
import sys

# Import our custom parser and other helpers
from lib.common import (
    CONSOLE,
    StyledArgumentParser,
    find_item,
    get_group_selection,
    print_help_panel,
    read_registry,
    write_registry,
)
from rich import box
from rich.prompt import Confirm, Prompt
from rich.table import Table

ALIAS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/aliases.json")


def show_help(args):
    """Displays the custom help panel for the alias manager."""
    title = "Alias Manager"
    command_name = "enigma alias"
    commands = {
        "ls": "Lists all aliases, grouped by category.",
        "add": "Interactively adds a new alias.",
        "edit": "Interactively edits an existing alias.",
        "rm": "Removes an alias.",
        "mv": "Moves an alias to a different group.",
    }
    print_help_panel(title, command_name, commands)


def list_aliases(args):
    data = read_registry(ALIAS_JSON_PATH)
    if not data:
        CONSOLE.print("[yellow]Alias registry is empty.[/yellow]")
        return
    groups_to_display = data
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
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = args.name
    if find_item(data, alias_name)[0]:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' already exists. Use 'edit'."
        )
        return 1
    alias_command = Prompt.ask(
        f"Enter the command for the alias '[bold cyan]{alias_name}[/bold cyan]'"
    )
    group_name = get_group_selection(data)
    if group_name not in data:
        data[group_name] = {}
    data[group_name][alias_name] = alias_command
    write_registry(data, ALIAS_JSON_PATH)
    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' added to group '[blue]{group_name}[/blue]'."
    )
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = alias_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def edit_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = args.name
    group, _ = find_item(data, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    new_command = Prompt.ask(
        f"Enter the new command for '[bold cyan]{alias_name}[/bold cyan]'"
    )
    data[group][alias_name] = new_command
    write_registry(data, ALIAS_JSON_PATH)
    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' updated successfully."
    )
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = new_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def move_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = args.name
    original_group, alias_body = find_item(data, alias_name)
    if not original_group:
        CONSOLE.print(f"[red]Error: Alias '[cyan]{alias_name}[/cyan]' not found.[/red]")
        return 1
    CONSOLE.print(
        f"Moving alias '[cyan]{alias_name}[/cyan]' from group '[blue]{original_group}[/blue]'."
    )
    new_group = get_group_selection(data)
    if new_group == original_group:
        CONSOLE.print(
            "[yellow]New group is the same as the old group. No changes made.[/yellow]"
        )
        return
    del data[original_group][alias_name]
    if not data[original_group]:
        del data[original_group]
    if new_group not in data:
        data[new_group] = {}
    data[new_group][alias_name] = alias_body
    write_registry(data, ALIAS_JSON_PATH)
    CONSOLE.print(
        f"✅ Alias '[cyan]{alias_name}[/cyan]' successfully moved to group '[blue]{new_group}[/blue]'."
    )


def remove_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = args.name
    group, _ = find_item(data, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1
    if Confirm.ask(
        f"Are you sure you want to remove the alias '[bold cyan]{alias_name}[/bold cyan]'?"
    ):
        del data[group][alias_name]
        if not data[group]:
            del data[group]
        write_registry(data, ALIAS_JSON_PATH)
        CONSOLE.print(
            f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' removed successfully."
        )
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unalias {alias_name}\n")


def load_for_shell(args):
    data = read_registry(ALIAS_JSON_PATH)
    for group, aliases in data.items():
        for name, command in aliases.items():
            command_quoted = command.replace("'", "'\\''")
            print(f"alias {name}='{command_quoted}'")
    print(f"alias getrepo='{os.path.expanduser('~/.config/zsh/getrepo.sh')}'")


def main():
    # Use our new StyledArgumentParser
    parser = StyledArgumentParser(
        description="A group-aware alias manager.",
        add_help=False,
        usage="<command> [options]",
    )
    parser.add_argument("--outfile", help=argparse.SUPPRESS)
    subparsers = parser.add_subparsers(dest="command")

    parser_ls = subparsers.add_parser("ls", help="Show all aliases.", add_help=False)
    parser_ls.add_argument("group", nargs="?")

    parser_add = subparsers.add_parser(
        "add", help="Create a new alias.", add_help=False
    )
    parser_add.add_argument("name")

    parser_edit = subparsers.add_parser(
        "edit", help="Edit an existing alias.", add_help=False
    )
    parser_edit.add_argument("name")

    parser_rm = subparsers.add_parser("rm", help="Remove an alias.", add_help=False)
    parser_rm.add_argument("name")

    parser_mv = subparsers.add_parser("mv", help="Move an alias.", add_help=False)
    parser_mv.add_argument("name")

    subparsers.add_parser("load", help=argparse.SUPPRESS, add_help=False)
    subparsers.add_parser("help", help="Show this help message.", add_help=False)

    parser.set_defaults(func=show_help)
    parser_ls.set_defaults(func=list_aliases)
    parser_add.set_defaults(func=add_alias)
    parser_edit.set_defaults(func=edit_alias)
    parser_rm.set_defaults(func=remove_alias)
    parser_mv.set_defaults(func=move_alias)
    subparsers.choices["load"].set_defaults(func=load_for_shell)
    subparsers.choices["help"].set_defaults(func=show_help)

    if len(sys.argv) == 1:
        show_help(None)
        sys.exit(0)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
