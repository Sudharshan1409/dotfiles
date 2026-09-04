#!/usr/bin/env python3
import platform

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from lib.base_manager import BaseManager
from lib.common import STYLE, prompt_with_interrupt_handler
from rich import box


class EnvManager(BaseManager):
    def __init__(self):
        super().__init__(
            item_type="entry",
            json_path="~/.config/zsh/data/exports.json",
            help_title="Environment Manager",
            help_command="enigma env",
            table_box_style=box.ROUNDED,
        )

    def _add_list_table_columns(self, table):
        table.add_column("Name", style="cyan", no_wrap=True)
        table.add_column("Type", style="yellow")
        table.add_column("OS", style="green")
        table.add_column("Priority", style="magenta")
        table.add_column("Variable Name")
        table.add_column("Value")

    def _get_list_table_row(self, name, item_obj):
        var_name = item_obj.get("var_name")
        var_name_display = (
            f"[bright_blue]{var_name}[/bright_blue]"
            if var_name
            else "[dim red]N/A[/dim red]"
        )
        return (
            name,
            item_obj.get("type", "N/A"),
            item_obj.get("os", "N/A"),
            str(item_obj.get("priority", 10)),  # Ensure priority is displayed
            var_name_display,
            item_obj.get("value", ""),
        )

    def _get_new_item_details(self, item_name, args):
        return self._prompt_for_entry_details()

    def _get_edited_item_details(self, item_name, old_item_obj):
        return self._prompt_for_entry_details(old_item_obj)

    def _prompt_for_entry_details(self, original_obj=None):
        if original_obj is None:
            original_obj = {}

        prompt = inquirer.select(
            message="What type of entry is this?",
            choices=[
                Choice("variable", "Static variable (export KEY=VALUE)"),
                Choice("dynamic", "Dynamic variable (export KEY=$(...))"),
                Choice("path", "Prepend to PATH (export PATH=...:$PATH)"),
                Choice("eval", 'Command to run inside eval "$(...) "'),
                Choice("run", "Simple command to execute"),
            ],
            default=original_obj.get("type"),
            style=STYLE,
            vi_mode=True,
        )
        entry_type = prompt_with_interrupt_handler(prompt)

        value, var_name, default_val = "", "", original_obj.get("value", "")
        if entry_type in ["variable", "dynamic"]:
            prompt = inquirer.text(
                message="What is the variable's name (e.g., FOO)?",
                default=original_obj.get("var_name", ""),
                style=STYLE,
                vi_mode=True,
            )
            var_name = prompt_with_interrupt_handler(prompt).upper()

            prompt_msg = (
                "What is the value?"
                if entry_type == "variable"
                else "What is the command?"
            )
            prompt = inquirer.text(
                message=f"{prompt_msg} for {var_name}",
                default=default_val,
                style=STYLE,
                vi_mode=True,
            )
            value = prompt_with_interrupt_handler(prompt)
        elif entry_type == "path":
            var_name = "PATH"
            prompt = inquirer.text(
                message="What is the directory to prepend?",
                default=default_val,
                style=STYLE,
                vi_mode=True,
            )
            value = prompt_with_interrupt_handler(prompt)
        else:
            prompt = inquirer.text(
                message="What is the command to run?",
                default=default_val,
                style=STYLE,
                vi_mode=True,
            )
            value = prompt_with_interrupt_handler(prompt)

        prompt = inquirer.select(
            message="Which OS should this apply to?",
            choices=["any", "Darwin", "Linux"],
            default=original_obj.get("os", "any"),
            style=STYLE,
            vi_mode=True,
        )
        entry_os = prompt_with_interrupt_handler(prompt)

        prompt = inquirer.number(
            message="Set a priority for this entry (lower number runs first):",
            default=original_obj.get("priority", 10),
            min_allowed=1,
            validate=lambda r: r.isdigit(),
            invalid_message="Priority must be a positive integer.",
            style=STYLE,
            vi_mode=True,
        )
        priority = int(prompt_with_interrupt_handler(prompt))

        return {
            "type": entry_type,
            "os": entry_os,
            "var_name": var_name,
            "value": value,
            "priority": priority,
        }

    def _build_shell_command(self, entry_obj):
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

    def _post_add_hook(self, args, item_name, item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"{self._build_shell_command(item_obj)}\n")

    def _post_edit_hook(self, args, item_name, new_item_obj, old_item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                original_var_name = old_item_obj.get("var_name")
                if original_var_name and original_var_name != new_item_obj.get(
                    "var_name"
                ):
                    f.write(f"unset {original_var_name}\n")
                f.write(f"{self._build_shell_command(new_item_obj)}\n")

    def _post_remove_hook(self, args, item_name, item_obj):
        if args.outfile:
            var_name = item_obj.get("var_name")
            if var_name:
                with open(args.outfile, "w") as f:
                    f.write(f"unset {var_name}\n")

    def load_for_shell(self, args):
        data = self._read_registry()
        current_os = platform.system()

        all_entries = []
        for entries in data.values():
            for entry_obj in entries.values():
                if entry_obj.get("os", "any") in ("any", current_os):
                    all_entries.append(entry_obj)

        # Sort by priority, lower numbers first. Default to 10 if not set.
        all_entries.sort(key=lambda x: x.get("priority", 10))

        for entry_obj in all_entries:
            print(self._build_shell_command(entry_obj))


def main():
    manager = EnvManager()
    manager.run()


if __name__ == "__main__":
    main()

