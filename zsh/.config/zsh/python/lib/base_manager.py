#!/usr/bin/env python3
import argparse
import os
import sys

from InquirerPy import inquirer
from rich.table import Table

from .common import (
    CONSOLE,
    STYLE,
    StyledArgumentParser,
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


class BaseManager:
    def __init__(self, item_type, json_path, help_title, help_command, table_box_style):
        self.item_type = item_type
        self.item_type_plural = f"{item_type}s"
        self.json_path = os.path.expanduser(json_path)
        self.help_title = help_title
        self.help_command = help_command
        self.table_box_style = table_box_style

    def show_help(self, args):
        print_help_panel(self.help_title, self.help_command, self._get_commands())

    def _get_commands(self):
        return {
            "ls": f"Lists all {self.item_type_plural}, grouped by category.",
            "add": f"Interactively adds a new {self.item_type}.",
            "edit": f"Interactively edits an existing {self.item_type}.",
            "rm": f"Removes a {self.item_type}.",
            "mv": f"Moves a {self.item_type} to a different group.",
            "scope": f"Move a {self.item_type} between global and local scopes.",
        }

    def _get_item_name_from_dropdown(self, data, message):
        all_items = [name for group in data.values() for name in group]
        if not all_items:
            CONSOLE.print(f"[yellow]No {self.item_type_plural} found.[/yellow]")
            return None
        return fuzzy_select(sorted(all_items), message)

    def list_items(self, args):
        data = self._read_registry()
        if not data:
            CONSOLE.print(
                f"[yellow]{self.item_type.capitalize()} registry is empty.[/yellow]"
            )
            return

        global_data = read_registry(self.json_path, read_local=False)

        groups_to_display = data
        if hasattr(args, "group") and args.group:
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

        for group_name, items in sorted(groups_to_display.items()):
            table = Table(
                title=group_name,
                box=self.table_box_style,
                border_style="bright_blue",
                title_style="bold bright_blue",
                show_lines=True,
            )
            self._add_list_table_columns(table)
            table.add_column("Scope", style="yellow")

            if not items:
                table.add_row(
                    *(["[dim]...empty...[/dim]"] * (len(table.columns) - 1)), ""
                )
            else:
                for name, item_obj in sorted(items.items()):
                    scope = (
                        "local"
                        if name not in global_data.get(group_name, {})
                        else "global"
                    )
                    row = self._get_list_table_row(name, item_obj)
                    table.add_row(*row, scope)
            CONSOLE.print(table)

    def _read_registry(self):
        return read_registry(self.json_path)

    def _add_list_table_columns(self, table):
        raise NotImplementedError

    def _get_list_table_row(self, name, item_obj):
        raise NotImplementedError

    def add_item(self, args):
        data = self._read_registry()
        item_name = args.name

        group, _, _ = find_item_and_scope(self.json_path, item_name)
        if group:
            CONSOLE.print(
                f"[red]❌ Error:[/red] {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' already exists. Use 'edit'."
            )
            return 1

        new_item_obj = self._get_new_item_details(item_name, args)
        if new_item_obj is None:
            return 1  # Operation cancelled or failed

        group_name = get_group_selection(data)
        scope = get_scope_selection()

        registry_to_write = (
            read_registry(self.json_path, read_local=False)
            if scope == "global"
            else read_registry(f"{self.json_path}.local", read_local=False)
        )

        if group_name not in registry_to_write:
            registry_to_write[group_name] = {}
        registry_to_write[group_name][item_name] = new_item_obj
        write_registry(registry_to_write, self.json_path, scope)

        CONSOLE.print(
            f"✅ {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' added to group '[blue]{group_name}[/blue]' in {scope} scope."
        )
        self._post_add_hook(args, item_name, new_item_obj)

    def _get_new_item_details(self, item_name, args):
        raise NotImplementedError

    def _post_add_hook(self, args, item_name, item_obj):
        pass

    def edit_item(self, args):
        data = self._read_registry()
        item_name = self._get_item_name_from_dropdown(
            data, f"Select a {self.item_type} to edit"
        )
        if not item_name:
            return 1

        group, old_item_obj, scope = find_item_and_scope(self.json_path, item_name)
        if not group:
            CONSOLE.print(
                f"[red]❌ Error:[/red] {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' not found."
            )
            return 1

        new_item_obj = self._get_edited_item_details(item_name, old_item_obj)
        if new_item_obj is None:
            return 1  # Operation cancelled

        registry_to_write = (
            read_registry(self.json_path, read_local=False)
            if scope == "global"
            else read_registry(f"{self.json_path}.local", read_local=False)
        )
        registry_to_write[group][item_name] = new_item_obj
        write_registry(registry_to_write, self.json_path, scope)

        CONSOLE.print(
            f"✅ {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' updated successfully in {scope} scope."
        )
        self._post_edit_hook(args, item_name, new_item_obj, old_item_obj)

    def _get_edited_item_details(self, item_name, old_item_obj):
        raise NotImplementedError

    def _post_edit_hook(self, args, item_name, new_item_obj, old_item_obj):
        pass

    def remove_item(self, args):
        data = self._read_registry()
        item_name = self._get_item_name_from_dropdown(
            data, f"Select a {self.item_type} to remove"
        )
        if not item_name:
            return 1

        group, item, scope = find_item_and_scope(self.json_path, item_name)
        if not group:
            CONSOLE.print(
                f"[red]❌ Error:[/red] {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' not found."
            )
            return 1

        prompt = inquirer.confirm(
            message=f"Are you sure you want to remove the {self.item_type} '[bold cyan]{item_name}[/bold cyan]' from the {scope} config?",
            default=False,
            style=STYLE,
            vi_mode=True,
        )
        if prompt_with_interrupt_handler(prompt):
            registry_to_write = (
                read_registry(self.json_path, read_local=False)
                if scope == "global"
                else read_registry(f"{self.json_path}.local", read_local=False)
            )
            del registry_to_write[group][item_name]
            if not registry_to_write[group]:
                del registry_to_write[group]
            write_registry(registry_to_write, self.json_path, scope)
            CONSOLE.print(
                f"✅ {self.item_type.capitalize()} '[bold cyan]{item_name}[/bold cyan]' removed successfully from {scope} scope."
            )
            self._post_remove_hook(args, item_name, item)

    def _post_remove_hook(self, args, item_name, item_obj):
        pass

    def move_item(self, args):
        data = self._read_registry()
        item_name = self._get_item_name_from_dropdown(
            data, f"Select a {self.item_type} to move"
        )
        if not item_name:
            return 1

        original_group, item_body, scope = find_item_and_scope(
            self.json_path, item_name
        )
        if not original_group:
            CONSOLE.print(
                f"[red]Error: {self.item_type.capitalize()} '[cyan]{item_name}[/cyan]' not found.[/red]"
            )
            return 1

        CONSOLE.print(
            f"Moving {self.item_type} '[cyan]{item_name}[/cyan]' from group '[blue]{original_group}[/blue]'."
        )
        new_group = get_group_selection(data)
        if new_group == original_group:
            CONSOLE.print(
                "[yellow]New group is the same as the old group. No changes made.[/yellow]"
            )
            return

        registry_to_write = (
            read_registry(self.json_path, read_local=False)
            if scope == "global"
            else read_registry(f"{self.json_path}.local", read_local=False)
        )
        del registry_to_write[original_group][item_name]
        if not registry_to_write[original_group]:
            del registry_to_write[original_group]
        if new_group not in registry_to_write:
            registry_to_write[new_group] = {}
        registry_to_write[new_group][item_name] = item_body
        write_registry(registry_to_write, self.json_path, scope)
        CONSOLE.print(
            f"✅ {self.item_type.capitalize()} '[cyan]{item_name}[/cyan]' successfully moved to group '[blue]{new_group}[/blue]' in {scope} scope."
        )

    def scope_item(self, args):
        scope_item(
            self.item_type.capitalize(),
            self.json_path,
            self._get_item_name_from_dropdown,
        )

    def load_for_shell(self, args):
        pass  # To be implemented by subclasses if needed

    def _add_extra_parsers(self, subparsers):
        pass  # To be implemented by subclasses if needed

    def run(self):
        parser = StyledArgumentParser(
            prog=self.help_command,
            description=f"A group-aware {self.item_type} manager.",
            add_help=False,
            usage="<command> [options]",
        )
        parser.add_argument("--outfile", help=argparse.SUPPRESS)
        subparsers = parser.add_subparsers(dest="command")

        parser_ls = subparsers.add_parser(
            "ls", help=f"Show all {self.item_type_plural}.", add_help=False
        )
        parser_ls.add_argument("group", nargs="?")
        parser_ls.set_defaults(func=self.list_items)

        parser_add = subparsers.add_parser(
            "add", help=f"Create a new {self.item_type}.", add_help=False
        )
        parser_add.add_argument("name")
        parser_add.set_defaults(func=self.add_item)

        subparsers.add_parser(
            "edit", help=f"Edit an existing {self.item_type}.", add_help=False
        ).set_defaults(func=self.edit_item)
        subparsers.add_parser(
            "rm", help=f"Remove a {self.item_type}.", add_help=False
        ).set_defaults(func=self.remove_item)
        subparsers.add_parser(
            "mv", help=f"Move a {self.item_type}.", add_help=False
        ).set_defaults(func=self.move_item)
        subparsers.add_parser(
            "scope", help=f"Move a {self.item_type} between scopes.", add_help=False
        ).set_defaults(func=self.scope_item)
        subparsers.add_parser(
            "load", help=argparse.SUPPRESS, add_help=False
        ).set_defaults(func=self.load_for_shell)
        subparsers.add_parser(
            "help", help="Show this help message.", add_help=False
        ).set_defaults(func=self.show_help)

        self._add_extra_parsers(subparsers)

        parser.set_defaults(func=self.show_help)

        # Handle 'add' command for managers that need extra args
        if "add" in sys.argv and hasattr(self, "_get_add_extra_args"):
            extra_args_spec = self._get_add_extra_args()
            for arg_name, arg_help in extra_args_spec.items():
                parser_add.add_argument(arg_name, help=arg_help)

        if len(sys.argv) == 1:
            self.show_help(None)
            sys.exit(0)
        args = parser.parse_args()
        args.func(args)
