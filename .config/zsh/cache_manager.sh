#!/bin/zsh

CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$CACHE_DIR" # Ensure cache directory exists

_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MALIAS_PY_SCRIPT="$HOME/.config/zsh/python/malias.py"
_MFUNC_PY_SCRIPT="$HOME/.config/zsh/python/mfunc.py"
_MENV_PY_SCRIPT="$HOME/.config/zsh/python/menv.py"

_generate_cache() {
    # Generate aliases cache
    "$_PYTHON_VENV_EXECUTABLE" "$_MALIAS_PY_SCRIPT" load > "$CACHE_DIR/aliases.zsh"
    # # Generate functions cache
    "$_PYTHON_VENV_EXECUTABLE" "$_MFUNC_PY_SCRIPT" load > "$CACHE_DIR/functions.zsh"
    # # Generate exports cache
    "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" load > "$CACHE_DIR/exports.zsh"
}

_load_cache() {
    if [[ ! -f "$CACHE_DIR/aliases.zsh" || ! -f "$CACHE_DIR/functions.zsh" || ! -f "$CACHE_DIR/exports.zsh" ]]; then
        _generate_cache
    fi
    source "$CACHE_DIR/aliases.zsh"
    source "$CACHE_DIR/functions.zsh"
    source "$CACHE_DIR/exports.zsh"
}
