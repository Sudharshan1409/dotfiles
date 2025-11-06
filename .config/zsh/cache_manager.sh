#!/bin/zsh

CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$CACHE_DIR" # Ensure cache directory exists

_generate_cache() {
    "$2" "$3" load > "$CACHE_DIR/$1"
}

_load_cache() {
    if [[ ! -f "$CACHE_DIR/$1" ]]; then
        _generate_cache $1 $2 $3
    fi

    source "$CACHE_DIR/$1"
}
