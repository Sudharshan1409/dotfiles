#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile

from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from InquirerPy.separator import Separator
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
    write_registry,
)
from rich import box
from rich.syntax import Syntax
from rich.table import Table

SNIPPETS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/snippets.json")


def show_help(args):
    title = "Snippet Manager"
    command_name = "enigma snip"
    commands = {
        "ls": "Lists all snippets, grouped by category.",
        "add": "Interactively adds a new snippet.",
        "edit": "Interactively edits an existing snippet.",
        "rm": "Removes a snippet.",
        "mv": "Moves a snippet to a different group.",
        "scope": "Move a snippet between global and local scopes.",
    }
    print_help_panel(title, command_name, commands)


def list_snippets(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    if not data:
        if not args.json:
            CONSOLE.print("[yellow]No snippets found.[/yellow]")
        return

    global_data = read_registry(SNIPPETS_JSON_PATH, read_local=False)

    if args.json:
        flat_list = []
        for group, snippets in data.items():
            for name, obj in snippets.items():
                scope = "local" if name not in global_data.get(group, {}) else "global"
                flat_list.append({"name": name, "group": group, "scope": scope, **obj})
        print(json.dumps(flat_list))
        return

    for group_name, snippets in sorted(data.items()):
        table = Table(
            title=group_name,
            box=box.ROUNDED,
            border_style="bright_green",
            title_style="bold bright_green",
            show_lines=True,
        )
        table.add_column("Snippet Name", style="cyan")
        table.add_column("Language", style="yellow")
        table.add_column("Body")
        table.add_column("Scope", style="yellow")

        for name, snip_obj in sorted(snippets.items()):
            body, lang = snip_obj.get("body", ""), snip_obj.get("language", "text")
            body_display = Syntax(body, lang, theme="monokai", word_wrap=True)
            scope = "local" if name not in global_data.get(group_name, {}) else "global"
            table.add_row(name, lang, body_display, scope)
        CONSOLE.print(table)


def invoke_editor(initial_content="", language="text"):
    editor = os.environ.get("EDITOR", "vim")
    lang_to_ext = {
        "python": ".py",
        "bash": ".sh",
        "zsh": ".zsh",
        "javascript": ".js",
        "typescript": ".ts",
        "json": ".json",
        "yaml": ".yml",
        "html": ".html",
        "css": ".css",
        "sql": ".sql",
    }
    suffix = lang_to_ext.get(language, ".txt")
    with tempfile.NamedTemporaryFile(suffix=suffix, mode="w+", delete=False) as tf:
        tf.write(initial_content)
        temp_path = tf.name
    header = "#\n# Please enter the snippet body below. Save and exit to accept.\n#\n"
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


def _get_language_selection(default="text"):
    common_languages = [
        "text",
        "python",
        "bash",
        "javascript",
        "typescript",
        "json",
        "yaml",
        "html",
        "css",
        "sql",
    ]
    OTHER_CHOICE_VAL = "OTHER"
    choices = common_languages + [
        Separator(),
        Choice(value=OTHER_CHOICE_VAL, name="Enter a different language..."),
    ]
    prompt = inquirer.select(
        message="Language for syntax highlighting:",
        choices=choices,
        default=default,
        style=STYLE,
        vi_mode=True,
    )
    selection = prompt_with_interrupt_handler(prompt)
    if selection == OTHER_CHOICE_VAL:
        prompt = inquirer.text(message="Enter custom language name:", style=STYLE, vi_mode=True)
        return prompt_with_interrupt_handler(prompt) or "text"
    return selection


def add_snippet(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    snippet_name = args.name
    if find_item(data, snippet_name)[0]:
        CONSOLE.print(f"[red]Error: Snippet '{snippet_name}' already exists.[/red]")
        return 1
    snippet_lang = _get_language_selection()
    snippet_body = invoke_editor(language=snippet_lang)
    if not snippet_body:
        CONSOLE.print("Cancelled or empty body provided.")
        return 1
    group_name = get_group_selection(data)
    scope = get_scope_selection()

    registry_to_write = read_registry(SNIPPETS_JSON_PATH, read_local=False) if scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)

    if group_name not in registry_to_write:
        registry_to_write[group_name] = {}
    registry_to_write[group_name][snippet_name] = {"language": snippet_lang, "body": snippet_body}
    write_registry(registry_to_write, SNIPPETS_JSON_PATH, scope)
    CONSOLE.print(
        f"✅ Snippet '[cyan]{snippet_name}[/cyan]' added to group '[green]{group_name}[/green]' in {scope} scope."
    )


def _get_snippet_name_from_dropdown(data, message="Select a snippet"):
    all_snippets = [name for group in data.values() for name in group]
    if not all_snippets:
        CONSOLE.print("[yellow]No snippets found.[/yellow]")
        return None
    return fuzzy_select(sorted(all_snippets), message)


def edit_snippet(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    snippet_name = _get_snippet_name_from_dropdown(data, "Select a snippet to edit")
    if not snippet_name:
        return 1
    
    group, snip_obj, scope = find_item_and_scope(SNIPPETS_JSON_PATH, snippet_name)
    if not group:
        CONSOLE.print(f"[red]Error: Snippet '{snippet_name}' not found.[/red]")
        return 1

    snippet_lang = _get_language_selection(default=snip_obj.get("language", "text"))
    new_body = invoke_editor(
        initial_content=snip_obj.get("body", ""), language=snippet_lang
    )
    if new_body is None:
        CONSOLE.print("Edit cancelled.")
        return 1

    registry_to_write = read_registry(SNIPPETS_JSON_PATH, read_local=False) if scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)
    registry_to_write[group][snippet_name] = {"language": snippet_lang, "body": new_body}
    write_registry(registry_to_write, SNIPPETS_JSON_PATH, scope)
    CONSOLE.print(f"✅ Snippet '[cyan]{snippet_name}[/cyan]' updated in {scope} scope.")


def move_snippet(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    snippet_name = _get_snippet_name_from_dropdown(data, "Select a snippet to move")
    if not snippet_name:
        return 1
    
    original_group, snip_data, scope = find_item_and_scope(SNIPPETS_JSON_PATH, snippet_name)
    if not original_group:
        CONSOLE.print(f"[red]Error: Snippet '{snippet_name}' not found.[/red]")
        return 1

    new_group = get_group_selection(data)
    if new_group == original_group:
        CONSOLE.print("[yellow]New group is the same. No changes made.[/yellow]")
        return

    registry_to_write = read_registry(SNIPPETS_JSON_PATH, read_local=False) if scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)
    del registry_to_write[original_group][snippet_name]
    if not registry_to_write[original_group]:
        del registry_to_write[original_group]
    if new_group not in registry_to_write:
        registry_to_write[new_group] = {}
    registry_to_write[new_group][snippet_name] = snip_data
    write_registry(registry_to_write, SNIPPETS_JSON_PATH, scope)
    CONSOLE.print(
        f"✅ Snippet '[cyan]{snippet_name}[/cyan]' moved to group '[green]{new_group}[/green]' in {scope} scope."
    )


def remove_snippet(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    snippet_name = _get_snippet_name_from_dropdown(data, "Select a snippet to remove")
    if not snippet_name:
        return 1
    
    group, _, scope = find_item_and_scope(SNIPPETS_JSON_PATH, snippet_name)
    if not group:
        CONSOLE.print(f"[red]Error: Snippet '{snippet_name}' not found.[/red]")
        return 1

    prompt = inquirer.confirm(
        message=f"Are you sure you want to remove snippet '{snippet_name}' from the {scope} config?",
        default=False,
        style=STYLE,
        vi_mode=True
    )
    if prompt_with_interrupt_handler(prompt):
        registry_to_write = read_registry(SNIPPETS_JSON_PATH, read_local=False) if scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)
        del registry_to_write[group][snippet_name]
        if not registry_to_write[group]:
            del registry_to_write[group]
        write_registry(registry_to_write, SNIPPETS_JSON_PATH, scope)
        CONSOLE.print(f"✅ Snippet '[cyan]{snippet_name}[/cyan]' removed from {scope} scope.")

def scope_snippet(args):
    data = read_registry(SNIPPETS_JSON_PATH)
    snippet_name = _get_snippet_name_from_dropdown(data, "Select a snippet to change scope")
    if not snippet_name:
        return 1

    original_group, snip_data, original_scope = find_item_and_scope(SNIPPETS_JSON_PATH, snippet_name)
    if not original_group:
        CONSOLE.print(f"[red]Error: Snippet '{snippet_name}' not found.[/red]")
        return 1

    new_scope = "local" if original_scope == "global" else "global"

    CONSOLE.print(f"Snippet '[cyan]{snippet_name}[/cyan]' is currently in the [yellow]{original_scope}[/yellow] scope.")
    prompt = inquirer.confirm(
        message=f"Move to {new_scope} scope?",
        default=True,
        style=STYLE,
        vi_mode=True
    )
    if not prompt_with_interrupt_handler(prompt):
        CONSOLE.print("[yellow]Operation cancelled.[/yellow]")
        return

    # Remove from old scope
    old_registry = read_registry(SNIPPETS_JSON_PATH, read_local=False) if original_scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)
    del old_registry[original_group][snippet_name]
    if not old_registry[original_group]:
        del old_registry[original_group]
    write_registry(old_registry, SNIPPETS_JSON_PATH, original_scope)

    # Add to new scope
    new_registry = read_registry(SNIPPETS_JSON_PATH, read_local=False) if new_scope == "global" else read_registry(SNIPPETS_JSON_PATH + ".local", read_local=False)
    if original_group not in new_registry:
        new_registry[original_group] = {}
    new_registry[original_group][snippet_name] = snip_data
    write_registry(new_registry, SNIPPETS_JSON_PATH, new_scope)

    CONSOLE.print(
        f"✅ Snippet '[cyan]{snippet_name}[/cyan]' moved to {new_scope} scope."
    )


def main():
    parser = StyledArgumentParser(
        prog="enigma snip", add_help=False, usage="<command> [options]"
    )
    subparsers = parser.add_subparsers(dest="command")

    parser_ls = subparsers.add_parser("ls", add_help=False)
    parser_ls.add_argument("--json", action="store_true")
    parser_ls.set_defaults(func=list_snippets)
    parser_add = subparsers.add_parser("add", add_help=False)
    parser_add.add_argument("name")
    parser_add.set_defaults(func=add_snippet)
    parser_edit = subparsers.add_parser("edit", add_help=False)
    parser_edit.set_defaults(func=edit_snippet)
    parser_rm = subparsers.add_parser("rm", add_help=False)
    parser_rm.set_defaults(func=remove_snippet)
    parser_mv = subparsers.add_parser("mv", add_help=False)
    parser_mv.set_defaults(func=move_snippet)
    parser_scope = subparsers.add_parser("scope", add_help=False)
    parser_scope.set_defaults(func=scope_snippet)
    subparsers.add_parser("help", add_help=False).set_defaults(func=show_help)

    parser.set_defaults(func=show_help)

    if len(sys.argv) == 1:
        show_help(None)
        sys.exit(0)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
