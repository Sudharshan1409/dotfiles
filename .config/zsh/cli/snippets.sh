#!/bin/zsh

_PYTHON_VENV_EXECUTABLE="$HOME/.config/zsh/venv/bin/python3"
_MSNIP_PY_SCRIPT="$HOME/.config/zsh/python/msnip.py"

# Internal management function called by the 'enigma' dispatcher.
function _msnip_cmd() {
    "$_PYTHON_VENV_EXECUTABLE" "$_MSNIP_PY_SCRIPT" "$@"
}

# User-facing command to find and copy a snippet using fzf.
function snip() {
    local snippets_json
    snippets_json=$("$_PYTHON_VENV_EXECUTABLE" "$_MSNIP_PY_SCRIPT" ls --json)

    if [[ -z "$snippets_json" ]]; then
        echo "No snippets found. Use 'enigma snip add' to create one." >&2
        return 1
    fi

    local preview_command='
        export PATH="$PATH:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin"
        json_input=$(print -r -- "$1" | cut -f2-)
        
        lang=$(print -r -- "$json_input" | jq -r .language)
        body=$(print -r -- "$json_input" | jq -r .body)

        if [[ "$lang" == "text" ]]; then
            print -r -- "$body" | bat --color=always --style=numbers,plain
        else
            print -r -- "$body" | bat --language "$lang" --color=always --style=numbers,plain
        fi
    '

    local selected_line
    selected_line=$(print -r -- "$snippets_json" | \
        jq -r '.[] | "\(.name)\t\(. | @json)"' | \
        fzf --height 40% --reverse \
            --delimiter='\t' \
            --nth=1 \
            --preview="zsh -c '${preview_command}' -- {}" \
            --preview-window='right:60%:border-rounded' \
            --prompt='Find Snippet> ' \
            --header='Press Enter to copy snippet to clipboard.' \
            --color='fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9' \
            --color='info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ff79c6' \
            --border=rounded)

    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    if [[ -n "$selected_line" ]]; then
        # --- vvv THIS IS THE CORRECTED SECTION vvv ---
        local selected_snippet_json
        # Use print -r -- to safely extract the JSON part without corrupting it
        selected_snippet_json=$(print -r -- "$selected_line" | cut -f2-)
        
        local snippet_body
        # Use print -r -- here as well to pass the clean JSON to jq
        snippet_body=$(print -r -- "$selected_snippet_json" | jq -r .body)
        
        # Use print -rn to copy to clipboard without an extra newline at the end
        print -rn -- "$snippet_body" | pbcopy
        # --- ^^^ END OF CORRECTED SECTION ^^^ ---
        
        echo "✅ Snippet copied to clipboard." >&2
    fi
}
