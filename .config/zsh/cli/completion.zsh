#!/bin/zsh
# zsh tab completion for the `enigma` CLI and its `en` alias.

_enigma_names() {
    local -a names
    names=(${(f)"$("$_PYTHON_VENV_EXECUTABLE" "$_PYTHON_DIR/mcompl.py" names $1 2>/dev/null)"})
    _describe -t items 'item' names
}

_enigma_groups() {
    local -a groups
    groups=(${(f)"$("$_PYTHON_VENV_EXECUTABLE" "$_PYTHON_DIR/mcompl.py" groups $1 2>/dev/null)"})
    _describe -t groups 'group' groups
}

_enigma_manager() {
    local mgr="$1"
    local -a actions
    actions=(ls add edit rm mv scope help)
    [[ "$mgr" == "functions" ]] && actions+=(run)

    _arguments -C \
        '1:action:->action' \
        '2:name:->name'

    case "$state" in
        action) _values 'action' $actions ;;
        name)
            case "${words[2]}" in
                edit|rm|mv|scope|run) _enigma_names "$mgr" ;;
                ls)                    _enigma_groups "$mgr" ;;
            esac
            ;;
    esac
}

_enigma_proj() {
    _arguments -C \
        '1:action:->action' \
        '2:name:->name'

    case "$state" in
        action) _values 'action' ls add edit rm mv scope launch help ;;
        name)
            case "${words[2]}" in
                edit|rm|mv|scope) _enigma_names projects ;;
                ls)               _enigma_groups projects ;;
            esac
            ;;
    esac
}

_enigma_gh() {
    _values 'gh action' repos create delete
}

_enigma() {
    _arguments -C \
        '1:subcommand:->cmd' \
        '*::arg:->args'

    case "$state" in
        cmd) _values 'enigma subcommand' alias func env proj gh ;;
        args)
            case "${words[1]}" in
                alias) _enigma_manager aliases ;;
                func)  _enigma_manager functions ;;
                env)   _enigma_manager env ;;
                proj)  _enigma_proj ;;
                gh)    _enigma_gh ;;
            esac
            ;;
    esac
}

# Ensure compinit has run before registering completions. In normal
# interactive shells fzf.sh has already triggered compinit; this guard
# only fires in `zsh -c` invocations or environments where no other
# tool ran compinit yet.
if ! (( $+functions[compdef] )); then
    autoload -Uz compinit
    compinit -u 2>/dev/null
fi

compdef _enigma enigma en
