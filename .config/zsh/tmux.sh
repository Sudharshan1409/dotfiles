function tmux() {
    # If no arguments are provided, simply start tmux
    if [ $# -eq 0 ]; then
        $TMUX_PATH
        return 1
    fi

    # Switch case to handle different commands
    case $1 in
        cns)
            # 'cns' command: create a new session with a given session name and optional window name
            session_name=$2
            window_name=$3

            # If only 'cns' is provided without any session name, start tmux
            if [ $# -eq 1 ]; then
                $TMUX_PATH
                return 1
            fi

            # If window name is not provided, set window name to session name
            if [ -z $window_name ]; then
                window_name=$session_name
            fi

            # Create a new tmux session with the provided session and window names
            $TMUX_PATH new-session -d -s $session_name -n $window_name
            tmux split-window -h -t $session_name
            tmux split-window -v -t $session_name
            tmux select-pane -t 1
            tmux attach -t $session_name
            ;;
        kp)
            # 'kp' command: kill pane
            pane_id=$2

            # If only 'kp' is provided without any pane id, kill active pane
            if [ $# -eq 1 ]; then
                $TMUX_PATH kill-pane
                return 1
            fi

            # Kill the specified pane
            $TMUX_PATH kill-pane -t $pane_id
            ;;
        help)
            # Display help information for user-defined commands and tmux commands
            echo "Usage:"
            echo "  cns <session_name> [window_name]"
            echo "    Create a new session with the specified session name and window name."
            echo "    If window name is not provided, it defaults to the session name."
            echo "    Example: cns mysession mywindow"
            echo ""
            echo "  new-session [-d] [-n window-name] [-s session-name] [-t group-name] [-x width] [-y height] [command]"
            echo "    Create a new session with the specified parameters."
            echo "    Options:"
            echo "      -d  Start session but don't attach to it"
            echo "      -n  Window name"
            echo "      -s  Session name"
            echo "      -t  Group name"
            echo "      -x  Width"
            echo "      -y  Height"
            echo "    Example: new-session -s mysession -n mywindow"
            echo ""
            echo "  attach-session [-dr] [-t target-session]"
            echo "    Attach to an existing session."
            echo "    Options:"
            echo "      -d  Detach any other clients attached to the session"
            echo "      -r  Resume the client that was attached to the session"
            echo "      -t  Target session"
            echo "    Example: attach-session -t mysession"
            echo ""
            echo "  list-sessions"
            echo "    List all sessions."
            echo ""
            echo "  kill-session [-a] [-t target-session]"
            echo "    Kill a session."
            echo "    Options:"
            echo "      -a  Kill all sessions"
            echo "      -t  Target session"
            echo "    Example: kill-session -t mysession"
            echo ""
            echo "  kill-server"
            echo "    Kill the server."
            ;;
        *)
            # If the command is not recognized, pass it directly to tmux
            $TMUX_PATH $@
            ;;
    esac
}

