#!/bin/zsh


_MENV_PY_SCRIPT="$_PYTHON_DIR/menv.py"

# On shell startup, execute the python script's 'load' command.
_load_cache "exports.sh" $_PYTHON_VENV_EXECUTABLE $_MENV_PY_SCRIPT

# --- INTERNAL MANAGEMENT FUNCTION ---
function _menv_cmd() {
    local command="$1"
    case "$command" in
        add|rm|edit)
            local tmpfile
            tmpfile=$(mktemp) || return 1
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" --outfile "$tmpfile" "$@"
            local exit_code=$?
            if [[ $exit_code -eq 0 && -s "$tmpfile" ]]; then
                source "$tmpfile"
                _generate_cache "exports.sh" $_PYTHON_VENV_EXECUTABLE $_MENV_PY_SCRIPT
            fi
            rm -f "$tmpfile"
            ;;
        ls|help|"")
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" "$@"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MENV_PY_SCRIPT" "$@"
            _generate_cache "exports.sh" $_PYTHON_VENV_EXECUTABLE $_MENV_PY_SCRIPT
            ;;
    esac
}

# Pass completion from Homebrew
# fpath+=("$(brew --prefix pass)/share/zsh/site-functions")
#
# autoload -Uz compinit
# compinit
#
source "$HOME/.config/zsh/fzf/fzf.sh"
