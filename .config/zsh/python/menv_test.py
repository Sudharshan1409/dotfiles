#!/usr/bin/env python3
import os
import platform
import time

EXPORTS_JSON_PATH = os.path.expanduser("~/.config/zsh/data/exports.json")

def read_registry(path):
    import json
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def get_current_os():
    return platform.system()

def build_shell_command(entry_obj):
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

def load_for_shell(args):
    start_time = time.time()
    data = read_registry(EXPORTS_JSON_PATH)
    read_time = time.time()
    print(f"Time to read registry: {read_time - start_time:.4f}s", file=sys.stderr)

    current_os = get_current_os()
    os_time = time.time()
    print(f"Time to get OS: {os_time - read_time:.4f}s", file=sys.stderr)

    for entries in data.values():
        for entry_obj in entries.values():
            if entry_obj.get("os", "any") in ("any", current_os):
                print(build_shell_command(entry_obj))
    
    end_time = time.time()
    print(f"Total time: {end_time - start_time:.4f}s", file=sys.stderr)

if __name__ == "__main__":
    import sys
    load_for_shell(None)
