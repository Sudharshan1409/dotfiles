-- Keyboard, Touchpad, Mouse and Universal Shortcuts
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        natural_scroll = true,
        repeat_rate = 40,
        repeat_delay = 500,

        touchpad = {
            natural_scroll = true,
        },

        sensitivity = 0,
    },
})

-- Per-device config
hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Universal copy, paste, and cut keybinds
hl.bind("SUPER + C", hl.dsp.exec_cmd("wtype -M ctrl -k Insert -m ctrl 2>/dev/null || hyprctl dispatch sendshortcut 'CTRL, Insert,'"), { desc = "Universal copy" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("wtype -M shift -k Insert -m shift 2>/dev/null || hyprctl dispatch sendshortcut 'SHIFT, Insert,'"), { desc = "Universal paste" })
hl.bind("SUPER + X", hl.dsp.exec_cmd("wtype -M ctrl -k x -m ctrl 2>/dev/null || hyprctl dispatch sendshortcut 'CTRL, X,'"), { desc = "Universal cut" })
