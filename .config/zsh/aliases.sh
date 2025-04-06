#!/bin/bash
# Basic aliases
alias ls="lsd"
alias vim="nvim"
alias vi="nvim"
alias refresh="source ~/.zshrc"
alias src="source ~/.zshrc"
alias la="lsd -a"
alias ll="lsd -l"
alias lla="lsd -la"
alias zshconf="vim ~/.zshrc"
alias pyglobalenv="source ~/venv/bin/activate"
alias sudo="sudo -E -s"
alias cl="clear;clear"
alias time="sh ~/.config/zsh/time.sh"
alias memory="sh ~/.config/zsh/memory.sh"

# Navigation aliases
alias desk="cd ~/Desktop"
alias down="cd ~/Downloads"
alias ohmyzsh="cd ~/.oh-my-zsh"
alias vimconf="cd ~/.config/nvim"
alias tmuxconf="cd ~/.config/tmux"
alias gitconf="cd ~/.config/git"
alias home="cd ~"
alias proj="cd ~/projects"
alias shellconf="cd ~/.config/zsh"
alias wezconf="cd ~/.config/wezterm"
alias yaziconf="cd ~/.config/yazi"
alias y="yazi"
alias credconf="cd ~/.config/creds"
alias aeroconf="cd ~/.config/aerospace"
alias sketchyconf="cd ~/.config/sketchybar"
alias dotfiles="cd ~/dotfiles"

# Git aliases
alias g="git"
alias gi="git init"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gpl="git pull"
alias gl="git log"
alias gls="git log --show-signature"
alias gd="git diff"
alias gds="git diff --staged"

# Git Worktree aliases

alias gw="git worktree"
alias gwa="git worktree add"
alias gwl="git worktree list"
alias gwr="git worktree remove"

gwc() {
    cd "$(git worktree list | grep "\[$1\]" | awk '{print $1}')"
}

alias getrepo="~/.config/zsh/getrepo.sh"

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
            echo "ohmyzsh --> cd ~/.oh-my-zsh"
            echo "vimconf --> cd ~/.config/nvim"
            echo "tmuxconf --> cd ~/.config/tmux"
            echo "gitconf --> cd ~/.config/git"
            echo "home --> cd ~"
            echo "proj --> cd ~/projects"
            echo "shellconf --> cd ~/.config/zsh"
            echo "wezconf --> cd ~/.config/wezterm"
            echo "yaziconf --> cd ~/.config/yazi"
            echo "y --> yazi"
            echo "credconf --> cd ~/.config/creds"
            echo "aerospace --> cd ~/.config/aerospace"
            echo "sketchyconf --> cd ~/.config/sketchybar"
            echo "dotfiles --> cd ~/dotfiles"
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
            echo "ls --> exa"
            echo "vim --> nvim"
            echo "vi --> nvim"
            echo "refresh --> source ~/.zshrc"
            echo "la --> exa -a"
            echo "ll --> exa -l"
            echo "lla --> exa -la"
            echo "zshconf --> vim ~/.zshrc"
            echo "pyglobalenv --> source ~/venv/bin/activate"
            echo "sudo --> sudo -E -s"
            echo "cl --> clear"
            echo "time --> display time"
            echo "memory --> display memory allocation"
            ;;
        *)
            echo "Usage: aliases"
            echo "Options:"
            echo "git --> Git aliases"
            echo "nav --> Navigation aliases"
            echo "gwt --> Git Worktree aliases"
            echo "basic --> Basic aliases"
            ;;
    esac
}

function ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}
