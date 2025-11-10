#!/usr/bin/env python3
import os

from InquirerPy import inquirer
from lib.base_manager import BaseManager
from lib.common import STYLE, prompt_with_interrupt_handler
from rich import box


class AliasManager(BaseManager):
    def __init__(self):
        super().__init__(
            item_type="alias",
            json_path="~/.config/zsh/data/aliases.json",
            help_title="Alias Manager",
            help_command="enigma alias",
            table_box_style=box.ROUNDED,
        )

    def _add_list_table_columns(self, table):
        table.add_column("Alias", style="cyan", no_wrap=True, min_width=5)
        table.add_column("Command", style="white")

    def _get_list_table_row(self, name, item_obj):
        return name, item_obj

    def _get_new_item_details(self, item_name, args):
        prompt = inquirer.text(
            message=f"Enter the command for the alias '{item_name}':",
            style=STYLE,
            vi_mode=True,
        )
        alias_command = prompt_with_interrupt_handler(prompt)
        if not alias_command:
            print("[yellow]Command cannot be empty. Alias not added.[/yellow]")
            return None
        return alias_command

    def _get_edited_item_details(self, item_name, old_item_obj):
        prompt = inquirer.text(
            message=f"Enter the new command for '{item_name}':",
            default=old_item_obj,
            style=STYLE,
            vi_mode=True,
        )
        new_command = prompt_with_interrupt_handler(prompt)
        if not new_command:
            print("[yellow]Command cannot be empty. Alias not changed.[/yellow]")
            return None
        return new_command

    def _post_add_hook(self, args, item_name, item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                command_quoted = item_obj.replace("'", "''''")
                f.write(f"alias {item_name}='{command_quoted}'\n")

    def _post_edit_hook(self, args, item_name, new_item_obj, old_item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                command_quoted = new_item_obj.replace("'", "''''")
                f.write(f"alias {item_name}='{command_quoted}'\n")

    def _post_remove_hook(self, args, item_name, item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unalias {item_name}\n")

    def load_for_shell(self, args):
        data = self._read_registry()
        for group, aliases in data.items():
            for name, command in aliases.items():
                command_quoted = command.replace("'", "''''")
                print(f"alias {name}='{command_quoted}'")
        print(f"alias getrepo='{os.path.expanduser('~/.config/zsh/getrepo.sh')}'")


def main():
    manager = AliasManager()
    manager.run()


if __name__ == "__main__":
    main()

