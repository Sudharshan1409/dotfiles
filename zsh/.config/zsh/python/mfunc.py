#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import tempfile

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from lib.base_manager import BaseManager
from lib.common import (
    CONSOLE,
    STYLE,
    find_item,
    prompt_with_interrupt_handler,
    read_registry,
    write_registry,
)
from rich import box
from rich.syntax import Syntax


class FunctionManager(BaseManager):
    def __init__(self):
        super().__init__(
            item_type="function",
            json_path="~/.config/zsh/data/functions.json",
            help_title="Function Manager",
            help_command="enigma func",
            table_box_style=box.ROUNDED,
        )

    def _read_registry(self):
        data = read_registry(self.json_path)
        migrated_data, was_migrated = self._migrate_registry(data)
        if was_migrated:
            write_registry(migrated_data, self.json_path)
            return migrated_data
        return data

    def _migrate_registry(self, data):
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

    def _add_list_table_columns(self, table):
        table.add_column("Function", style="cyan", no_wrap=True)
        table.add_column("Type", style="yellow")
        table.add_column("Body")

    def _get_list_table_row(self, name, item_obj):
        func_type, body = item_obj.get("type", "zsh"), item_obj.get("body", "")
        lexer = "python" if func_type == "python" else "bash"
        syntax = Syntax(body, lexer, theme="monokai", line_numbers=True, word_wrap=True)
        return name, func_type.capitalize(), syntax

    def _get_function_type(self):
        prompt = inquirer.select(
            message="What type of function is this?",
            choices=[
                Choice("zsh", "Zsh Shell Function"),
                Choice("python", "Python Script"),
            ],
            default="zsh",
            style=STYLE,
            vi_mode=True,
        )
        return prompt_with_interrupt_handler(prompt)

    def _invoke_editor(self, initial_content="", func_type="zsh"):
        editor = os.environ.get("EDITOR", "vim")
        suffix = ".py" if func_type == "python" else ".sh"
        with tempfile.NamedTemporaryFile(suffix=suffix, mode="w+", delete=False) as tf:
            tf.write(initial_content)
            temp_path = tf.name
        header = (
            "#\n# Please enter the function body below. Save and exit to accept.\n#\n"
        )
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

    def _get_new_item_details(self, item_name, args):
        func_type = self._get_function_type()
        func_body = self._invoke_editor(func_type=func_type)
        if not func_body:
            CONSOLE.print("Cancelled or empty body provided.")
            return None
        return {"type": func_type, "body": func_body}

    def _get_edited_item_details(self, item_name, old_item_obj):
        func_type = old_item_obj.get("type", "zsh")
        new_body = self._invoke_editor(
            initial_content=old_item_obj["body"], func_type=func_type
        )
        if new_body is None:
            CONSOLE.print("Edit cancelled.")
            return None
        return {"type": func_type, "body": new_body}

    def _post_add_hook(self, args, item_name, item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                if item_obj["type"] == "zsh":
                    f.write(f"{item_name}() {{\n{item_obj['body']}\n}}\n")
                else:
                    f.write(f'{item_name}() {{ enigma func run {item_name} "$@" }}\n')

    def _post_edit_hook(self, args, item_name, new_item_obj, old_item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unset -f {item_name}\n")
                if new_item_obj["type"] == "zsh":
                    f.write(f"{item_name}() {{\n{new_item_obj['body']}\n}}\n")
                else:
                    f.write(f'{item_name}() {{ enigma func run {item_name} "$@" }}\n')

    def _post_remove_hook(self, args, item_name, item_obj):
        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write(f"unset -f {item_name}\n")

    def load_for_shell(self, args):
        data = self._read_registry()
        for functions in data.values():
            for name, func_obj in functions.items():
                if func_obj.get("type") == "python":
                    print(f'{name}() {{ enigma func run {name} "$@" }}')
                else:
                    print(f"{name}() {{\n{func_obj.get('body', '')}\n}}")

    def run_python_function(self, args):
        data = self._read_registry()
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

    def _add_extra_parsers(self, subparsers):
        parser_run = subparsers.add_parser(
            "run", help=argparse.SUPPRESS, add_help=False
        )
        parser_run.add_argument("name")
        parser_run.add_argument("extra_args", nargs=argparse.REMAINDER)
        parser_run.set_defaults(func=self.run_python_function)


def main():
    manager = FunctionManager()
    manager.run()


if __name__ == "__main__":
    main()

