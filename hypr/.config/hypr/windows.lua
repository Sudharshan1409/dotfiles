-- Window and Layer rules for Hyprland
local home = os.getenv("HOME") or "/home/sudharshan"

-- ----------------------------------------------------------------------------
-- Global Behavior Rules
-- ----------------------------------------------------------------------------

-- Suppress maximize requests to keep windows tiled
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Default subtle opacity
hl.window_rule({
    name = "default-opacity",
    match = { class = ".*" },
    opacity = "0.97 0.90",
})

-- Fix dragging / focus issues with XWayland ghost windows
hl.window_rule({
    name = "fix-xwayland-ghosts",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- ----------------------------------------------------------------------------
-- Dialogs, Portals & Browser Popups
-- ----------------------------------------------------------------------------

-- XDG portal dialogs (Save As / Open File)
hl.window_rule({
    name = "xdg-desktop-portal-cleanup",
    match = { class = "^(Xdg-desktop-portal-gtk)$" },
    border_size = 0,
    no_shadow = true,
    no_blur = true,
})

-- Brave browser menus & popups (XWayland floating)
hl.window_rule({
    name = "brave-popups-cleanup",
    match = {
        class = "^(Brave-browser)$",
        float = true,
        xwayland = true,
    },
    border_size = 0,
    no_shadow = true,
    no_blur = true,
})

-- ----------------------------------------------------------------------------
-- Floating Window Rules
-- ----------------------------------------------------------------------------
local floatClasses = {
    "^(Rofi)$",
    "^(pavucontrol)$",
    "^(blueman-manager)$",
    "^(org\\.gnome\\.Calculator)$",
    "^(blueberry\\.py)$",
    "^(nm-connection-editor)$",
    "^(org\\.kde\\.polkit-kde-authentication-agent-1)$",
    "^(com\\.cisco\\.secureclient\\.gui)$",
    "^(hyprland-share-picker)$",
    "^steam$",
    "^(Share|localsend)$",
}

for i, cls in ipairs(floatClasses) do
    hl.window_rule({
        name = "float-class-" .. i,
        match = { class = cls },
        float = true,
    })
end

-- Centered & sized dialogs
hl.window_rule({
    name = "pavucontrol-layout",
    match = { class = "^(pavucontrol)$" },
    size = "60% 60%",
    center = true,
})

hl.window_rule({
    name = "blueman-layout",
    match = { class = "^(blueman-manager)$" },
    size = "60% 60%",
    center = true,
})

hl.window_rule({
    name = "localsend-layout",
    match = { class = "(Share|localsend)" },
    center = true,
})

-- System monitor popups (htop, nvtop in Ghostty)
hl.window_rule({
    name = "ghostty-sysmon-float",
    match = {
        class = "^(com\\.mitchellh\\.ghostty)$",
        title = "^(htop|nvtop)$",
    },
    float = true,
    size = "1400 900",
    center = true,
})

-- Rofi dropdown animation
hl.window_rule({
    name = "rofi-anim",
    match = { class = "^Rofi$" },
    animation = "slide-down",
})

-- ----------------------------------------------------------------------------
-- App-Specific Window & Layer Rules
-- ----------------------------------------------------------------------------

-- 1Password & Bitwarden (privacy protection against screen sharing)
hl.window_rule({
    name = "1password-hide-screenshare",
    match = { class = "^(1Password)$" },
    no_screen_share = true,
})

hl.window_rule({
    name = "bitwarden-hide-screenshare",
    match = { class = "^(Bitwarden)$" },
    no_screen_share = true,
})

-- Browser Grouping, Tagging & Opacity
hl.window_rule({
    name = "chromium-browsers",
    match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)" },
    tag = "+chromium-based-browser",
})

hl.window_rule({
    name = "firefox-browsers",
    match = { class = "([fF]irefox|zen|librewolf)" },
    tag = "+firefox-based-browser",
})

hl.window_rule({
    name = "meet-float",
    match = {
        class = "^((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)$",
        title = "^([mM]eet).*$",
    },
    float = true,
})

-- Video streaming & conferencing: Never apply opacity
hl.window_rule({
    name = "video-sites-opaque",
    match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*(youtube\\.com|app\\.zoom\\.us))" },
    opacity = "1.0 override 1.0 override",
})

-- Cisco AnyConnect / Secure Client
hl.window_rule({
    name = "cisco-rules",
    match = { class = "(?i).*cisco.*" },
    float = true,
    workspace = "special:Ad-Hoc",
})

-- Hyprshot selection border cleanup
hl.layer_rule({
    name = "hyprshot-no-anim",
    match = { namespace = "selection" },
    no_anim = true,
})

-- JetBrains tweaks
hl.window_rule({
    name = "jetbrains-size",
    match = { class = "(.*jetbrains.*)$", title = "^$" },
    size = "50% 50%",
})

hl.window_rule({
    name = "jetbrains-tabs",
    match = { class = "^(.*jetbrains.*)$", title = "^\\s$" },
    no_initial_focus = true,
})

-- Picture-in-Picture
hl.window_rule({
    name = "pip-tag",
    match = { title = "(Picture.?in.?[Pp]icture)" },
    tag = "+pip",
})

hl.window_rule({
    name = "pip-behavior",
    match = { tag = "pip" },
    float = true,
    pin = true,
    size = "600 338",
    keep_aspect_ratio = true,
    decorate = false,
    opacity = "1.0 override 1.0 override",
    move = "(monitor_w-window_w-40) (monitor_h*0.04)",
})

-- QEMU & RetroArch
hl.window_rule({
    name = "qemu-opaque",
    match = { class = "^qemu$" },
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name = "retroarch-fullscreen",
    match = { class = "^com\\.libretro\\.RetroArch$" },
    fullscreen = true,
    opacity = "1.0 override 1.0 override",
    idle_inhibit = "fullscreen",
})

-- Scratchpad Terminal (Super + S)
hl.window_rule({
    name = "scratchpad-terminal",
    match = { class = "^(scratchpad-terminal)$" },
    workspace = "special:scratch",
    float = true,
    size = "100% 100%",
    center = true,
    opacity = "0.95 0.90",
})

-- Spotify
hl.window_rule({
    name = "spotify-workspace",
    match = { class = "^.*[sS]potify.*$" },
    float = true,
    workspace = "special:Entertainment",
})

-- Steam
hl.window_rule({
    name = "steam-main",
    match = { class = "^steam$", title = "^Steam$" },
    center = true,
    size = "1100 700",
})

hl.window_rule({
    name = "steam-friends",
    match = { class = "^steam$", title = "^Friends List$" },
    size = "460 800",
})

hl.window_rule({
    name = "steam-opaque",
    match = { class = "^steam$" },
    opacity = "1.0 override 1.0 override",
    idle_inhibit = "fullscreen",
})

-- System Quick FZF Finder modal
hl.window_rule({
    name = "fzf-finder-modal",
    match = { title = "^(Quick-FZF-Finder)$" },
    float = true,
    center = true,
})

-- Media applications: Always fully opaque
hl.window_rule({
    name = "media-apps-opaque",
    match = { class = "^(zoom|vlc|mpv|org\\.kde\\.kdenlive|com\\.obsproject\\.Studio|com\\.github\\.PintaProject\\.Pinta|imv|org\\.gnome\\.NautilusPreviewer)$" },
    opacity = "1.0 override 1.0 override",
})

-- Ghostty Terminal Tag
hl.window_rule({
    name = "ghostty-terminal-tag",
    match = { class = "^(com\\.mitchellh\\.ghostty)$" },
    tag = "+terminal",
})

-- Webcam Overlay
hl.window_rule({
    name = "webcam-overlay",
    match = { title = "^WebcamOverlay$" },
    float = true,
    pin = true,
    no_initial_focus = true,
    move = "(monitor_w-window_w-40) (monitor_h-window_h-40)",
})
