#!/bin/zsh

function enigma() {
    local sub_command="$1"
    local action="$2"

    if [[ -z "$sub_command" ]]; then
        print -P "%BUsage:%b enigma %F{cyan}<command>%f [options]"
        print ""
        print -P "A unified tool to manage your personal Zsh environment."
        print ""
        print -P "%BAvailable Commands:%b"
        print -P "  %F{yellow}alias%f     Manage shell aliases"
        print -P "  %F{yellow}func%f      Manage shell functions"
        print -P "  %F{yellow}env%f       Manage environment variables"
        print ""
        print -P "Run 'enigma %F{cyan}<command>%f help' for more information on a specific command."
        return 1
    fi

    case "$sub_command" in
        alias)
            _malias_cmd "${@:2}"
            ;;
        func)
            _mfunc_cmd "${@:2}"
            ;;
        env)
            _menv_cmd "${@:2}"
            ;;
        *)
            echo "Error: Unknown command '$sub_command'." >&2
            enigma
            return 1
            ;;
    esac
}
