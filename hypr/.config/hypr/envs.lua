-- Environment Variables for Hyprland session
local home = os.getenv("HOME") or "/home/sudharshan"

-- Cursor theme & size
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Ensure user binaries and Homebrew are in PATH for all Wayland child processes
local current_path = os.getenv("PATH") or ""
hl.env("PATH", home .. "/.local/bin:/home/linuxbrew/.linuxbrew/bin:" .. current_path)

-- Force apps to use Wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Screen sharing & Desktop portal hints
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Compose key
hl.env("XCOMPOSEFILE", home .. "/.XCompose")

-- GTK Theme
hl.env("GTK_THEME", "Adwaita:dark")

-- Ecosystem settings
hl.config({
    ecosystem = {
        no_update_news = true,
    },
})
