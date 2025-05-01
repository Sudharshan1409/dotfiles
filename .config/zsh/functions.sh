#!/bin/bash

function gwc() {
    z "$(git worktree list | grep "\[$1\]" | awk '{print $1}')"
}

function aliases() {
    case $1 in
        git)
            echo "Git aliases:"
            echo "g --> git"
            echo "gi --> git init"
            echo "gs --> git status"
            echo "ga --> git add"
            echo "gc --> git commit"
            echo "gcm --> git commit -m"
            echo "gco --> git checkout"
            echo "gcb --> git checkout -b"
            echo "gp --> git push"
            echo "gpl --> git pull"
            echo "gl --> git log"
            echo "gls --> git log --show-signature"
            echo "gd --> git diff"
            echo "gds --> git diff --staged"
            ;;
        nav)
            echo "Navigation aliases:"
            echo "desk --> cd ~/Desktop"
            echo "down --> cd ~/Downloads"
            echo "ohmyzsh --> cd ~/.oh-my-zsh"
            echo "vimconf --> cd ~/.config/nvim"
            echo "tmuxconf --> cd ~/.config/tmux"
            echo "gitconf --> cd ~/.config/git"
            echo "home --> cd ~"
            echo "proj --> cd ~/projects"
            echo "shellconf --> cd ~/.config/zsh"
            echo "wezconf --> cd ~/.config/wezterm"
            echo "yaziconf --> cd ~/.config/yazi"
            echo "credconf --> cd ~/.config/creds"
            echo "aeroconf --> cd ~/.config/aerospace"
            echo "sketchyconf --> cd ~/.config/sketchybar"
            echo "dotfiles --> cd ~/dotfiles"
            echo "config --> cd ~/.config"
            echo "batconf --> cd '$(bat --config-dir)'"
            ;;
        gwt)
            echo "Git Worktree aliases:"
            echo "gw --> git worktree"
            echo "gwa --> git worktree add"
            echo "gwl --> git worktree list"
            echo "gwr --> git worktree remove"
            echo "gwc --> git worktree change"
            ;;
        basic)
            echo "Basic aliases:"
            echo "ls --> eza --color=always --git --icons=always"
            echo "vim --> nvim"
            echo "vi --> nvim"
            echo "refresh --> source ~/.zshrc"
            echo "src --> source ~/.zshrc"
            echo "la --> lsd -a"
            echo "ll --> lsd -l"
            echo "lla --> lsd -la"
            echo "zshconf --> vim ~/.zshrc"
            echo "pyglobalenv --> source ~/venv/bin/activate"
            echo "sudo --> sudo -E -s"
            echo "cl --> clear;clear"
            echo "time --> sh ~/.config/zsh/time.sh"
            echo "memory --> sh ~/.config/zsh/memory.sh"
            echo "y --> yazi"
            echo "cd --> z"
            echo "cat --> bat"
            ;;
        *)
            echo "Usage: aliases"
            echo "Options:"
            echo "git --> Git aliases"
            echo "nav --> Navigation aliases"
            echo "gwt --> Git Worktree aliases"
            echo "basic --> Basic aliases"
            echo "ff --> Aerospace go to window"
            echo "tmux-run-all-panes --> Run a command in all the panes in a tmux window"
            ;;
    esac
}

function ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

tmux-run-all-panes() {
  if [ -z "$1" ]; then
    echo "Usage: tmux-run-all-panes '<command>'"
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
        tmux-run-all-panes "$bare_repo_path/$worktree_name"
        return 1
    fi
    z "$bare_repo_path/$worktree_name"
}
