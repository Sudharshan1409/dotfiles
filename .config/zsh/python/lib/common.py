#!/usr/bin/env python3
import argparse
import json
import os
import sys

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

CONSOLE = Console(stderr=True)


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


def read_registry(path):
    """Reads a JSON registry file from the given path."""
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump({}, f)
        return {}
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        CONSOLE.print(
            f"[red]Error: Could not read or parse {os.path.basename(path)}.[/red]"
        )
        return {}


def write_registry(data, path):
    """Writes a dictionary back to the specified JSON registry file."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=4, sort_keys=True)
    except IOError:
        CONSOLE.print(f"[red]Error: Could not write to {os.path.basename(path)}.[/red]")


def find_item(data, item_name):
    """Generic function to find which group an item belongs to."""
    for group, items in data.items():
        if item_name in items:
            return group, items[item_name]
    return None, None


def get_group_selection(data):
    """Presents an interactive dropdown menu for group selection."""
    existing_groups = sorted(list(data.keys()))
    CREATE_NEW = "[Create New Group]"
    choices = [Choice(value=group, name=group) for group in existing_groups]
    choices.extend(
        [Separator(), Choice(value=CREATE_NEW, name="Create a new group...")]
    )

    prompt = inquirer.select(
        message="Select a group:",
        choices=choices,
        default=choices[0].value if existing_groups else CREATE_NEW,
    )
    selection = prompt_with_interrupt_handler(prompt)

    if selection == CREATE_NEW:
        new_group_prompt = inquirer.text(
            message="Enter the new group name:",
            validate=lambda result: len(result) > 0,
            invalid_message="Group name cannot be empty.",
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
