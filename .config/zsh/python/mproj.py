#!/usr/bin/env python3
import os
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from lib.base_manager import BaseManager
from lib.common import CONSOLE, STYLE, prompt_with_interrupt_handler
from rich import box


class ProjectManager(BaseManager):
    def __init__(self):
        super().__init__(
            item_type="project",
            json_path="~/.config/zsh/data/projects.json",
            help_title="Project Manager & Launcher",
            help_command="enigma proj",
            table_box_style=box.ROUNDED,
        )

    def _add_list_table_columns(self, table):
        table.add_column("Project Name", style="cyan")
        table.add_column("Path", style="yellow")
        table.add_column("Description", style="white")

    def _get_list_table_row(self, name, item_obj):
        return name, item_obj.get("path"), item_obj.get("description", "")

    def _get_add_extra_args(self):
        return {"path": "The path to the project directory."}

    def _get_new_item_details(self, item_name, args):
        proj_path = args.path
        CONSOLE.print(
            f"Adding new project '[cyan]{item_name}[/cyan]' with path '[yellow]{proj_path}[/yellow]'."
        )
        prompt = inquirer.text(
            message="Enter a short description (optional):", style=STYLE, vi_mode=True
        )
        proj_desc = prompt_with_interrupt_handler(prompt)
        return {"path": proj_path, "description": proj_desc}

    def _get_edited_item_details(self, item_name, old_item_obj):
        CONSOLE.print(
            f"Editing project '[cyan]{item_name}[/cyan]'. Current values are defaults."
        )
        prompt = inquirer.text(
            message="Path:", default=old_item_obj.get("path"), style=STYLE, vi_mode=True
        )
        new_path = prompt_with_interrupt_handler(prompt)

        prompt = inquirer.text(
            message="Description:",
            default=old_item_obj.get("description"),
            style=STYLE,
            vi_mode=True,
        )
        new_desc = prompt_with_interrupt_handler(prompt)
        return {"path": new_path, "description": new_desc}

    def launch_project(self, args):
        """Lets user select a project and writes shell commands to the outfile."""
        data = self._read_registry()
        all_projects = [
            (name, obj)
            for group, projects in data.items()
            for name, obj in projects.items()
        ]
        if not all_projects:
            CONSOLE.print("[red]No projects configured to launch.[/red]")
            sys.exit(1)

        choices = [
            Choice(value=proj_data, name=f"{proj_data[0]} ({proj_data[1].get('path')})")
            for proj_data in all_projects
        ]
        prompt = inquirer.select(
            message="Select a project to launch:",
            choices=choices,
            style=STYLE,
            vi_mode=True,
        )
        selected_proj_data = prompt_with_interrupt_handler(prompt)

        proj_name, proj_obj = selected_proj_data
        proj_path = os.path.expanduser(proj_obj["path"])

        session_name = proj_name.replace(".", "_") + "_$RANDOM"
        window_name = proj_name

        script_lines = [
            f'local session_name="{session_name}"',
            f'local window_name="{window_name}"',
            f"cd '{proj_path}'",
            f'if tmux has-session -t "{proj_name}" 2>/dev/null; then',
            f'  tmux attach-session -t "{proj_name}"',
            "else",
            '  tmux cns "$session_name" "$window_name"',
            f'  tmux rename-session -t "$session_name" "{proj_name}"',
            "fi",
        ]

        if args.outfile:
            with open(args.outfile, "w") as f:
                f.write("\n".join(script_lines) + "\n")

    def _add_extra_parsers(self, subparsers):
        subparsers.add_parser("launch", add_help=False).set_defaults(
            func=self.launch_project
        )


def main():
    manager = ProjectManager()
    manager.run()


if __name__ == "__main__":
    main()

