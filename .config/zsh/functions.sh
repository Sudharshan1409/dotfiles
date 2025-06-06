#!/bin/bash

function gwc() {
    z "$(git worktree list | grep "\[$1\]" | awk '{print $1}')"
}

function ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

tmux-all() {
  if [ -z "$1" ]; then
    echo "Usage: tmux-all '<command>'"
    return 1
  fi

  local cmd="$1"
  tmux list-panes -F '#{pane_id}' | while read -r pane; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done
}

function gwa() {
    # Check if the current directory is a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not inside a git repository."
        return 1
    fi

    # Get the bare repository path
    local bare_repo_path
    bare_repo_path=$(git worktree list | grep bare | awk '{print $1}')

    # Check if the bare repository path is empty
    if [ -z "$bare_repo_path" ]; then
        echo "Bare repository not found."
        return 1
    fi

    # Check if the worktree name is provided
    local worktree_name="$1"
    if [ -z "$worktree_name" ]; then
        echo -n "Enter the worktree name: "
        read worktree_name
    fi

    # Create a new worktree
    git worktree add "$bare_repo_path/$worktree_name"

    # Check if inside a tmux session
    if [ -n "$TMUX" ]; then
        tmux-all "$bare_repo_path/$worktree_name"
        return 1
    fi
    z "$bare_repo_path/$worktree_name"
}
