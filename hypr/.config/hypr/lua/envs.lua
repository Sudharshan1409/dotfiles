-- -----------------------------------------------------------------------------
-- Cursor theme & size
-- -----------------------------------------------------------------------------

hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- -----------------------------------------------------------------------------
-- Ensure user binaries and Homebrew are in PATH for all Wayland child processes
-- -----------------------------------------------------------------------------

local home = os.getenv("HOME")
local currentPath = os.getenv("PATH") or ""

hl.env("PATH", home .. "/.local/bin:/home/linuxbrew/.linuxbrew/bin:" .. currentPath)

-- Point Caelestia Shell to /usr/local/lib/caelestia when compiled locally (Ubuntu)
local caelestiaLocalLib = io.open("/usr/local/lib/caelestia/version", "r")
if caelestiaLocalLib then
	caelestiaLocalLib:close()
	hl.env("CAELESTIA_LIB_DIR", "/usr/local/lib/caelestia")
end

-- -----------------------------------------------------------------------------
-- Force all apps to use Wayland
-- -----------------------------------------------------------------------------

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- -----------------------------------------------------------------------------
-- Allow better support for screen sharing (Google Meet, Discord, etc.)
-- -----------------------------------------------------------------------------

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- -----------------------------------------------------------------------------
-- Use XCompose file
-- -----------------------------------------------------------------------------

hl.env("XCOMPOSEFILE", home .. "/.XCompose")

-- -----------------------------------------------------------------------------
-- GTK theme
-- -----------------------------------------------------------------------------

hl.env("GTK_THEME", "Adwaita:dark")

-- -----------------------------------------------------------------------------
-- Ecosystem
-- -----------------------------------------------------------------------------

hl.config({
	ecosystem = {
		no_update_news = true,
	},
})
