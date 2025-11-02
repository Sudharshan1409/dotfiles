#!/usr/bin/env python3
import argparse
import os
import sys

from InquirerPy import inquirer
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
        "scope": "Move an alias between global and local scopes.",
    }
    print_help_panel(title, command_name, commands)


def list_aliases(args):
    data = read_registry(ALIAS_JSON_PATH)
    if not data:
        CONSOLE.print("[yellow]Alias registry is empty.[/yellow]")
        return

    global_data = read_registry(ALIAS_JSON_PATH, read_local=False)

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
        table.add_column("Scope", style="yellow")

        if not aliases:
            table.add_row("[dim]...empty...[/dim]", "", "")
        else:
            for name, command in sorted(aliases.items()):
                # Determine scope
                scope = "local" if name not in global_data.get(group_name, {}) else "global"
                table.add_row(name, command, scope)
        CONSOLE.print(table)


def add_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = args.name
    if find_item(data, alias_name)[0]:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' already exists. Use 'edit'."
        )
        return 1

    prompt = inquirer.text(message=f"Enter the command for the alias '{alias_name}':", style=STYLE, vi_mode=True)
    alias_command = prompt_with_interrupt_handler(prompt)
    if not alias_command:
        CONSOLE.print("[yellow]Command cannot be empty. Alias not added.[/yellow]")
        return 1

    group_name = get_group_selection(data)
    scope = get_scope_selection()

    registry_to_write = read_registry(ALIAS_JSON_PATH, read_local=False) if scope == "global" else read_registry(ALIAS_JSON_PATH + ".local", read_local=False)

    if group_name not in registry_to_write:
        registry_to_write[group_name] = {}
    registry_to_write[group_name][alias_name] = alias_command
    write_registry(registry_to_write, ALIAS_JSON_PATH, scope)

    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' added to group '[blue]{group_name}[/blue]' in {scope} scope."
    )
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = alias_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def _get_alias_name_from_dropdown(data, message="Select an alias"):
    all_aliases = [name for group in data.values() for name in group]
    if not all_aliases:
        CONSOLE.print("[yellow]No aliases found.[/yellow]")
        return None
    return fuzzy_select(sorted(all_aliases), message)


def edit_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = _get_alias_name_from_dropdown(data, "Select an alias to edit")
    if not alias_name:
        return 1
    
    group, old_command, scope = find_item_and_scope(ALIAS_JSON_PATH, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1

    prompt = inquirer.text(
        message=f"Enter the new command for '{alias_name}':", default=old_command, style=STYLE, vi_mode=True
    )
    new_command = prompt_with_interrupt_handler(prompt)
    if not new_command:
        CONSOLE.print("[yellow]Command cannot be empty. Alias not changed.[/yellow]")
        return 1

    # Read the specific registry (global or local) and update it
    registry_to_write = read_registry(ALIAS_JSON_PATH, read_local=False) if scope == "global" else read_registry(ALIAS_JSON_PATH + ".local", read_local=False)
    registry_to_write[group][alias_name] = new_command
    write_registry(registry_to_write, ALIAS_JSON_PATH, scope)

    CONSOLE.print(
        f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' updated successfully in {scope} scope."
    )
    if args.outfile:
        with open(args.outfile, "w") as f:
            command_quoted = new_command.replace("'", "'\\''")
            f.write(f"alias {alias_name}='{command_quoted}'\n")


def move_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = _get_alias_name_from_dropdown(data, "Select an alias to move")
    if not alias_name:
        return 1
    
    original_group, alias_body, scope = find_item_and_scope(ALIAS_JSON_PATH, alias_name)
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

    # Read the specific registry (global or local) and update it
    registry_to_write = read_registry(ALIAS_JSON_PATH, read_local=False) if scope == "global" else read_registry(ALIAS_JSON_PATH + ".local", read_local=False)
    del registry_to_write[original_group][alias_name]
    if not registry_to_write[original_group]:
        del registry_to_write[original_group]
    if new_group not in registry_to_write:
        registry_to_write[new_group] = {}
    registry_to_write[new_group][alias_name] = alias_body
    write_registry(registry_to_write, ALIAS_JSON_PATH, scope)

    CONSOLE.print(
        f"✅ Alias '[cyan]{alias_name}[/cyan]' successfully moved to group '[blue]{new_group}[/blue]' in {scope} scope."
    )


def remove_alias(args):
    data = read_registry(ALIAS_JSON_PATH)
    alias_name = _get_alias_name_from_dropdown(data, "Select an alias to remove")
    if not alias_name:
        return 1
    
    group, _, scope = find_item_and_scope(ALIAS_JSON_PATH, alias_name)
    if not group:
        CONSOLE.print(
            f"[red]❌ Error:[/red] Alias '[bold cyan]{alias_name}[/bold cyan]' not found."
        )
        return 1

    prompt = inquirer.confirm(
        message=f"Are you sure you want to remove the alias '[bold cyan]{alias_name}[/bold cyan]' from the {scope} config?",
        default=False,
        style=STYLE,
        vi_mode=True
    )
    if prompt_with_interrupt_handler(prompt):
        registry_to_write = read_registry(ALIAS_JSON_PATH, read_local=False) if scope == "global" else read_registry(ALIAS_JSON_PATH + ".local", read_local=False)
        del registry_to_write[group][alias_name]
        if not registry_to_write[group]:
            del registry_to_write[group]
        write_registry(registry_to_write, ALIAS_JSON_PATH, scope)
        CONSOLE.print(
            f"✅ Alias '[bold cyan]{alias_name}[/bold cyan]' removed successfully from {scope} scope."
        )
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unalias {alias_name}\n")

def scope_alias(args):
    scope_item("Alias", ALIAS_JSON_PATH, _get_alias_name_from_dropdown)


def load_for_shell(args):
    data = read_registry(ALIAS_JSON_PATH)
    for group, aliases in data.items():
        for name, command in aliases.items():
            command_quoted = command.replace("'", "'\\''")
            print(f"alias {name}='{command_quoted}'")
    print(f"alias getrepo='{os.path.expanduser('~/.config/zsh/getrepo.sh')}'")


def main():
    parser = StyledArgumentParser(
        prog="enigma alias",
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
    parser_rm = subparsers.add_parser("rm", help="Remove an alias.", add_help=False)
    parser_mv = subparsers.add_parser("mv", help="Move an alias.", add_help=False)
    parser_scope = subparsers.add_parser("scope", help="Move an alias between scopes.", add_help=False)
    subparsers.add_parser("load", help=argparse.SUPPRESS, add_help=False)
    subparsers.add_parser("help", help="Show this help message.", add_help=False)

    parser.set_defaults(func=show_help)
    parser_ls.set_defaults(func=list_aliases)
    parser_add.set_defaults(func=add_alias)
    parser_edit.set_defaults(func=edit_alias)
    parser_rm.set_defaults(func=remove_alias)
    parser_mv.set_defaults(func=move_alias)
    parser_scope.set_defaults(func=scope_alias)
    subparsers.choices["load"].set_defaults(func=load_for_shell)
    subparsers.choices["help"].set_defaults(func=show_help)

    if len(sys.argv) == 1:
        show_help(None)
        sys.exit(0)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
