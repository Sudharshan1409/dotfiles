#!/usr/bin/env python3
# Minimal completion helper for enigma. Imports only json/sys/os so it
# starts in ~50ms — fast enough for zsh tab completion. Do not import
# rich / InquirerPy here.
import json
import os
import sys

REGISTRIES = {
    "aliases":   "~/.config/zsh/data/aliases.json",
    "functions": "~/.config/zsh/data/functions.json",
    "env":       "~/.config/zsh/data/exports.json",
    "projects":  "~/.config/zsh/data/projects.json",
}


def _load(path):
    """Load <path> and deep-merge <path>.local on top. Mirrors
    lib.common.read_registry without importing it."""
    merged = {}
    full = os.path.expanduser(path)
    for p in (full, full + ".local"):
        if not os.path.exists(p):
            continue
        try:
            data = json.load(open(p))
        except (json.JSONDecodeError, OSError):
            continue
        for group, items in data.items():
            if isinstance(items, dict) and isinstance(merged.get(group), dict):
                merged[group].update(items)
            else:
                merged[group] = items
    return merged


def main():
    if len(sys.argv) < 3:
        return
    mode, manager = sys.argv[1], sys.argv[2]
    if manager not in REGISTRIES:
        return
    data = _load(REGISTRIES[manager])
    if mode == "names":
        for group, items in data.items():
            if isinstance(items, dict):
                for name in items:
                    print(name)
    elif mode == "groups":
        for group in data:
            print(group)


if __name__ == "__main__":
    main()
