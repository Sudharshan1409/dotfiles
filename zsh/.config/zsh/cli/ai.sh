#!/usr/bin/env zsh

# --- Paths ---
_MAI_PY_SCRIPT="$_PYTHON_DIR/mai.py"

# --- Sanity ---
if [ ! -f "$_PYTHON_VENV_EXECUTABLE" ]; then
    echo "Error: Python venv not found. Open a new shell to trigger setup." >&2
    return 1
fi
if [ ! -f "$_MAI_PY_SCRIPT" ]; then
    echo "Error: AI script not found at $_MAI_PY_SCRIPT" >&2
    return 1
fi

# _mai_cmd: entry point for `enigma ai`. Free-form prompt or interactive.
_mai_cmd() {
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        print -P "%BUsage:%b enigma ai %F{cyan}[your request | config]%f"
        print ""
        print -P "AI shell assistant. Describe what you want done; it asks if unclear,"
        print -P "proposes commands, and runs them on your confirm."
        print ""
        print -P "%BExamples:%b"
        print -P "  %F{yellow}enigma ai%f                            (interactive)"
        print -P "  %F{yellow}enigma ai \"list big files in pwd\"%f"
        print -P "  %F{yellow}enigma ai \"squash my last 3 commits\"%f"
        print -P "  %F{yellow}enigma ai config%f                     (pick provider + model)"
        print -P "  %F{yellow}enigma ai config show%f                (view current config)"
        print ""
        print -P "%BProviders & API keys:%b"
        print -P "  OpenAI      %F{cyan}OPENAI_API_KEY%f"
        print -P "  Gemini      %F{cyan}GEMINI_API_KEY%f"
        print -P "  Anthropic   %F{cyan}ANTHROPIC_API_KEY%f"
        print -P "  Store via:  %F{yellow}enigma env add ai <KEY>=<value>%f"
        print ""
        print -P "%BRuntime overrides:%b"
        print -P "  %F{cyan}AI_PROVIDER%f      openai | gemini | anthropic"
        print -P "  %F{cyan}<NAME>_MODEL%f     override the model for that provider"
        return 0
    fi
    case "$1" in
        config)
            shift
            "$_PYTHON_VENV_EXECUTABLE" "$_MAI_PY_SCRIPT" --config "$@"
            ;;
        *)
            "$_PYTHON_VENV_EXECUTABLE" "$_MAI_PY_SCRIPT" "$@"
            ;;
    esac
}
