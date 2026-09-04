#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys

from InquirerPy import inquirer
from InquirerPy.utils import get_style
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

CONSOLE = Console(stderr=True)

STYLE = get_style(
    {
        "questionmark": "fg:#61afef",
        "answer": "fg:#98c379",
        "input": "fg:#98c379",
        "question": "",
        "instruction": "fg:#abb2bf",
        "pointer": "fg:#61afef",
        "checkbox": "fg:#98c379",
        "separator": "fg:#abb2bf",
        "skipped": "fg:#5c6370",
        "validator": "fg:#c678dd",
        "marker": "fg:#61afef",
        "patch": "fg:#c678dd",
        "fuzzy_prompt": "fg:#c678dd",
        "fuzzy_info": "fg:#abb2bf",
        "fuzzy_match": "fg:#c678dd bold",
    },
    style_override=False,
)


def prompt_with_interrupt_handler(prompt_func):
    """
    A wrapper to handle KeyboardInterrupt (Ctrl+C) for any InquirerPy prompt.
    """
    try:
        return prompt_func.execute()
    except KeyboardInterrupt:
        CONSOLE.print("\n[yellow]Operation cancelled by user.[/yellow]")
        sys.exit(1)


class StyledArgumentParser(argparse.ArgumentParser):
    """A custom ArgumentParser that uses rich to print styled error messages."""

    def error(self, message):
        error_text = Text()
        error_text.append("Usage: ", style="bold")
        error_text.append(f"{self.prog} {self.usage or ''}\n\n", style="cyan")
        error_text.append("Error: ", style="bold red")
        error_text.append(message, style="red")
        Console(stderr=True).print(error_text)
        sys.exit(2)


def read_registry(path, read_local=True):
    """Reads a JSON registry file, merging a .local file if it exists."""
    global_data = {}
    if os.path.exists(path):
        try:
            with open(path, "r") as f:
                global_data = json.load(f)
        except (json.JSONDecodeError, IOError):
            CONSOLE.print(
                f"[red]Error: Could not read or parse {os.path.basename(path)}.[/red]"
            )

    if not read_local:
        return global_data

    local_path = path + ".local"
    local_data = {}
    if os.path.exists(local_path):
        try:
            with open(local_path, "r") as f:
                local_data = json.load(f)
        except (json.JSONDecodeError, IOError):
            CONSOLE.print(
                f"[red]Error: Could not read or parse {os.path.basename(local_path)}.[/red]"
            )

    # Deep merge local_data into global_data
    for group, items in local_data.items():
        if group in global_data:
            global_data[group].update(items)
        else:
            global_data[group] = items
    return global_data


def write_registry(data, path, scope="global"):
    """Writes a dictionary back to the specified JSON registry file."""
    write_path = path if scope == "global" else path + ".local"
    os.makedirs(os.path.dirname(write_path), exist_ok=True)
    tmp_path = write_path + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=4, sort_keys=True)
        os.replace(tmp_path, write_path)
    except IOError:
        CONSOLE.print(
            f"[red]Error: Could not write to {os.path.basename(write_path)}.[/red]"
        )
        try:
            os.remove(tmp_path)
        except OSError:
            pass


def find_item(data, item_name):
    """Generic function to find which group an item belongs to."""
    for group, items in data.items():
        if item_name in items:
            return group, items[item_name]
    return None, None


def find_item_and_scope(path, item_name):
    """Finds an item and determines if it's in the global or local scope."""
    global_data = read_registry(path, read_local=False)
    group, item = find_item(global_data, item_name)
    if group:
        return group, item, "global"

    local_path = path + ".local"
    local_data = read_registry(local_path, read_local=False)
    group, item = find_item(local_data, item_name)
    if group:
        return group, item, "local"

    return None, None, None


def fuzzy_select(choices, prompt_message):
    """Uses fzf to present a fuzzy-findable list of choices."""
    choices_str = "\n".join(map(str, choices))
    try:
        fzf_process = subprocess.run(
            ["fzf", "--prompt", f"{prompt_message} ", "--height", "40%", "--reverse"],
            input=choices_str,
            text=True,
            stdout=subprocess.PIPE,
            check=True,
        )
        return fzf_process.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        CONSOLE.print("\n[yellow]Operation cancelled or fzf not found.[/yellow]")
        sys.exit(1)


def get_scope_selection():
    """Presents an interactive dropdown menu for scope selection."""
    choices = [
        "global       (recommended, tracked by git)",
        "local        (system-specific, not tracked by git)",
    ]
    selection = fuzzy_select(choices, "Select a scope: ")
    return selection.split()[0]


def get_group_selection(data):
    """Presents an interactive dropdown menu for group selection."""
    existing_groups = sorted(list(data.keys()))
    CREATE_NEW = "[Create New Group]"
    choices = existing_groups + [CREATE_NEW]

    selection = fuzzy_select(choices, "Select a group: ")

    if selection == CREATE_NEW:
        new_group_prompt = inquirer.text(
            message="Enter the new group name:",
            validate=lambda result: len(result) > 0,
            invalid_message="Group name cannot be empty.",
            style=STYLE,
            vi_mode=True,
        )
        return prompt_with_interrupt_handler(new_group_prompt)
    else:
        return selection


def print_help_panel(title, command_name, commands):
    """Prints a standardized, colorful help panel using rich."""
    help_text = Text()
    help_text.append("Usage: ", style="bold")
    help_text.append(f"{command_name} <command> [arguments]\n\n", style="cyan")
    help_text.append("Available Commands:\n", style="bold")
    for cmd, desc in commands.items():
        help_text.append(f"  {cmd:<10}", style="bold yellow")
        help_text.append(f"{desc}\n")
    panel = Panel(
        help_text, title=f"[bold white]{title}[/bold white]", border_style="dim"
    )
    CONSOLE.print(panel)


def scope_item(item_type, json_path, get_item_name_from_dropdown):
    data = read_registry(json_path)
    item_name = get_item_name_from_dropdown(
        data, f"Select an {item_type.lower()} to change scope"
    )
    if not item_name:
        return 1

    original_group, item_body, original_scope = find_item_and_scope(
        json_path, item_name
    )
    if not original_group:
        CONSOLE.print(
            f"[red]Error: {item_type} '[cyan]{item_name}[/cyan]' not found.[/red]"
        )
        return 1

    new_scope = "local" if original_scope == "global" else "global"

    CONSOLE.print(
        f"{item_type} '[cyan]{item_name}[/cyan]' is currently in the [yellow]{original_scope}[/yellow] scope."
    )
    prompt = inquirer.confirm(
        message=f"Move to {new_scope} scope?", default=True, style=STYLE, vi_mode=True
    )
    if not prompt_with_interrupt_handler(prompt):
        CONSOLE.print("[yellow]Operation cancelled.[/yellow]")
        return

    # Remove from old scope
    old_registry = (
        read_registry(json_path, read_local=False)
        if original_scope == "global"
        else read_registry(json_path + ".local", read_local=False)
    )
    del old_registry[original_group][item_name]
    if not old_registry[original_group]:
        del old_registry[original_group]
    write_registry(old_registry, json_path, original_scope)

    # Add to new scope
    new_registry = (
        read_registry(json_path, read_local=False)
        if new_scope == "global"
        else read_registry(json_path + ".local", read_local=False)
    )
    if original_group not in new_registry:
        new_registry[original_group] = {}
    new_registry[original_group][item_name] = item_body
    write_registry(new_registry, json_path, new_scope)

    CONSOLE.print(
        f"✅ {item_type} '[cyan]{item_name}[/cyan]' moved to {new_scope} scope."
    )

