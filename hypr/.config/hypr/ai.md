# Hyprland Config Restoration & Knowledge Base

This file contains the complete, up-to-date configuration for Hyprland V4/V5, specifically addressing the deprecation of `windowrulev2` and the old property matching syntax.

**Date:** Tue Jan 27 2026
**Reason:** Migration to Hyprland V4/V5 syntax (deprecation of `windowrulev2`).

## Key Changes

1.  **Syntax Upgrade:**
    *   **Old:** `windowrulev2 = float, class:^kitty$`
    *   **New:** `windowrule = float on, match:class ^kitty$`
    *   Properties like `class:`, `title:` are now `match:class`, `match:title`.
    *   Effects like `float`, `pin` now require explicit values (e.g., `float on`).

2.  **Deprecated Options Removed:**
    *   Removed `resize_on_border` (deprecated/moved).
    *   Removed `smart_resizing` (deprecated).
    *   Removed `force_zero_scaling` (deprecated).

3.  **Renamed Properties:**
    *   `noinitialfocus` -> `no_initial_focus`
    *   `idleinhibit` -> `idle_inhibit`
    *   `noborder` -> `decorate off` (or `border_size 0`)

## Configuration Files

To restore the configuration, overwrite the files at the specified paths with the content below.

### 1. `~/.config/hypr/windows.conf`

```ini
#######################################################################################
# WINDOW RULES (UPDATED – NEW SYNTAX)
# https://wiki.hyprland.org/Configuring/Window-Rules/
#######################################################################################

#
# --- Global behavior ---
#

# Suppress maximize requests to keep windows tiled
windowrule = suppress_event maximize, match:class .*

# Default subtle opacity
windowrule = opacity 0.97 0.9, match:class .*

# Fix dragging / focus issues with XWayland ghost windows
windowrule = no_focus on, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0, match:class ^$, match:title ^$

#
# --- Fix borders / shadows / blur on popups & dialogs ---
#

# XDG portal dialogs (Save As / Open File)
windowrule = border_size 0, match:class ^(Xdg-desktop-portal-gtk)$
windowrule = no_shadow on, match:class ^(Xdg-desktop-portal-gtk)$
windowrule = no_blur on, match:class ^(Xdg-desktop-portal-gtk)$

# Brave browser menus & popups (XWayland floating)
windowrule = border_size 0, match:class ^(Brave-browser)$, match:float 1, match:xwayland 1
windowrule = no_shadow on, match:class ^(Brave-browser)$, match:float 1, match:xwayland 1
windowrule = no_blur on, match:class ^(Brave-browser)$, match:float 1, match:xwayland 1

#
# --- Floating windows ---
#

windowrule = float on, match:class ^(Rofi)$
windowrule = float on, match:class ^(pavucontrol)$
windowrule = float on, match:class ^(blueman-manager)$
windowrule = float on, match:class ^(org.gnome.Calculator)$
windowrule = float on, match:class ^(blueberry.py)$
windowrule = float on, match:class ^(nm-connection-editor)$
windowrule = float on, match:class ^(org.kde.polkit-kde-authentication-agent-1)$
windowrule = float on, match:class ^(com.cisco.secureclient.gui)$
windowrule = float on, match:class ^(hyprland-share-picker)$

# Kitty htop popup
windowrule = float on, match:class ^(kitty)$, match:title ^(htop)$

#
# --- Size & centering for floating windows ---
#

windowrule = size 60% 60%, match:class ^(pavucontrol)$
windowrule = center on, match:class ^(pavucontrol)$

windowrule = size 60% 60%, match:class ^(blueman-manager)$
windowrule = center on, match:class ^(blueman-manager)$

# Kitty htop sizing
windowrule = size 1500 1000, match:class ^(kitty)$, match:title ^(htop)$
windowrule = center on, match:class ^(kitty)$, match:title ^(htop)$

#
# --- Animations ---
#

# Rofi dropdown animation
windowrule = animation slide-down, match:class ^Rofi$

#
# --- Catch invalid empty-class windows ---
#

windowrule = no_blur on, match:class ^$, match:title ^$

#
# --- App-specific rules ---
#

source = ~/.config/hypr/apps.conf
```

### 2. `~/.config/hypr/looknfeel.conf`

```ini
# --- General Layout Properties ---
# See https://wiki.hyprland.org/Configuring/Variables/#general

# Variables
$activeBorderColor = rgba(33ccffee) rgba(00ff99ee) 45deg
$inactiveBorderColor = rgba(595959aa)

general {
    gaps_in = 4
    gaps_out = 8
    border_size = 3
    # resize_on_border = false

    layout = dwindle
    allow_tearing = false
}

# --- Dwindle Layout Specifics ---
# See https://wiki.hyprland.org/Configuring/Dwindle-Layout/
dwindle {
    preserve_split = true
    smart_split = false
    force_split = 2
    # smart_resizing = false
    # precise_mouse_move = true
}

# --- Decorations (Rounding, Blur, Shadow) ---
# See https://wiki.hyprland.org/Configuring/Variables/#decoration
decoration {
    rounding = 6

    blur {
        enabled = true
        size = 3
        passes = 3
    }

    shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }
}

# Disable blur for swaync notifications (MOVED OUT OF decoration block)
windowrule = no_blur on, match:class ^(swaync|swaync-client)$


# --- Group Configuration ---
group {
    col.border_active = $activeBorderColor
    col.border_inactive = $inactiveBorderColor
    col.border_locked_active = -1
    col.border_locked_inactive = -1

    groupbar {
        font_size = 12
        font_family = monospace
        font_weight_active = ultraheavy
        font_weight_inactive = normal

        indicator_height = 0
        indicator_gap = 5
        height = 22
        gaps_in = 5
        gaps_out = 0

        text_color = rgb(ffffff)
        text_color_inactive = rgba(ffffff90)
        col.active = rgba(00000040)
        col.inactive = rgba(00000020)

        gradients = true
        gradient_rounding = 0
        gradient_round_only_edges = false
    }
}

# --- Animations ---
# See https://wiki.hyprland.org/Configuring/Animations/
animations {
    enabled = yes, please :)

    bezier = easeOutQuint,0.23,1,0.32,1
    bezier = easeInOutCubic,0.65,0.05,0.36,1
    bezier = linear,0,0,1,1
    bezier = almostLinear,0.5,0.5,0.75,1.0
    bezier = quick,0.15,0,0.1,1

    animation = global, 1, 10, default
    animation = border, 1, 5.39, easeOutQuint
    animation = windows, 1, 4.79, easeOutQuint
    animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
    animation = windowsOut, 1, 1.49, linear, popin 87%
    animation = fadeIn, 1, 1.73, almostLinear
    animation = fadeOut, 1, 1.46, almostLinear
    animation = fade, 1, 3.03, quick
    animation = layers, 1, 3.81, easeOutQuint
    animation = layersIn, 1, 4, easeOutQuint, fade
    animation = layersOut, 1, 1.5, linear, fade
    animation = fadeLayersIn, 1, 1.79, almostLinear
    animation = fadeLayersOut, 1, 1.39, almostLinear
    animation = workspaces, 0, 0, ease
}

#######################################################################################
# MISCELLANEOUS SETTINGS
#######################################################################################

xwayland {
    # force_zero_scaling = true
}

misc {
    # Disable the default anime wallpaper
    force_default_wallpaper = 0
    focus_on_activate = true
}
```

### 3. `~/.config/hypr/input.conf`

```ini
# --- Keyboard and Mouse Input ---
# See https://wiki.hyprland.org/Configuring/Variables/#input
input {
    kb_layout = us
    follow_mouse = 1
    natural_scroll = yes
    repeat_rate = 40
    repeat_delay =   500

    touchpad {
        natural_scroll = yes
    }

    sensitivity = 0 # -1.0 to 1.0, 0 means no modification
}

# --- Per-Device Configuration ---
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}

# -----------------------------------------------------------------------------
# Per-app scroll behavior
# -----------------------------------------------------------------------------

# NOTE: Hyprland does not support per-window scroll sensitivity rules.
# You can only set this globally or per-device.
# windowrule = scroll_touchpad 1.5, match:class ^(Alacritty|kitty)$
# windowrule = scroll_touchpad 0.2, match:class ^com\.mitchellh\.ghostty$

bindd = SUPER, C, Universal copy, sendshortcut, CTRL, Insert,
bindd = SUPER, V, Universal paste, sendshortcut, SHIFT, Insert,
bindd = SUPER, X, Universal cut, sendshortcut, CTRL, X,
```

### 4. `apps/*.conf` Files

**`~/.config/hypr/apps/1password.conf`**
```ini
windowrule = no_screen_share on, match:class ^(1Password)$
```

**`~/.config/hypr/apps/bitwarden.conf`**
```ini
windowrule = no_screen_share on, match:class ^(Bitwarden)$
```

**`~/.config/hypr/apps/browser.conf`**
```ini
# -----------------------------------------------------------------------------
# Browser types (grouping + tagging)
# -----------------------------------------------------------------------------

# Chromium-based browsers
windowrule = group set, tag +chromium-based-browser, match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)

# Firefox-based browsers
windowrule = group set, tag +firefox-based-browser, match:class ([fF]irefox|zen|librewolf)

# Google Meet windows should float (Chromium only)
windowrule = float on, match:class ^((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)$, match:title ^([mM]eet).*$


# -----------------------------------------------------------------------------
# Chromium app-mode bug workaround
# -----------------------------------------------------------------------------

# Force Chromium-based browsers to tile
windowrule = tile on, match:tag chromium-based-browser


# -----------------------------------------------------------------------------
# Opacity rules
# -----------------------------------------------------------------------------

# Subtle opacity for browsers
windowrule = opacity 1.0 0.97, match:tag chromium-based-browser
windowrule = opacity 1.0 0.97, match:tag firefox-based-browser


# -----------------------------------------------------------------------------
# Video / conferencing sites — NEVER apply opacity
# -----------------------------------------------------------------------------

windowrule = opacity 1.0 override 1.0 override, match:initial_title ((?i)(?:[a-z0-9-]+\.)*(youtube\.com|app\.zoom\.us))
```

**`~/.config/hypr/apps/cisco-secure-client.conf`**
```ini
# -----------------------------------------------------------------------------
# Cisco apps (AnyConnect, Secure Client, etc.)
# -----------------------------------------------------------------------------

windowrule = float on, match:class (?i).*cisco.*
windowrule = workspace special:Ad-Hoc, match:class (?i).*cisco.*
```

**`~/.config/hypr/apps/hyprshot.conf`**
```ini
# Remove 1px border around hyprshot screenshots
layerrule = no_anim on, match:namespace selection
```

**`~/.config/hypr/apps/jetbrains.conf`**
```ini
# -----------------------------------------------------------------------------
# JetBrains windows default size
# -----------------------------------------------------------------------------

windowrule = size 50% 50%, match:class (.*jetbrains.*)$, match:title ^$


# -----------------------------------------------------------------------------
# Fix tab dragging (tab titles are just one space)
# -----------------------------------------------------------------------------

windowrule = no_initial_focus on, match:class ^(.*jetbrains.*)$, match:title ^\s$


# -----------------------------------------------------------------------------
# Allow dialogs (e.g. "Send usage statistics") to be focusable & clickable
# -----------------------------------------------------------------------------

# Unset nofocus/noinitialfocus for these specific windows if they matched previous rules
windowrule = no_focus off, match:class ^(.*jetbrains.*)$, match:title ^$
windowrule = no_initial_focus off, match:class ^(.*jetbrains.*)$, match:title ^$
```

**`~/.config/hypr/apps/localsend.conf`**
```ini
# Float LocalSend and fzf file picker
windowrule = float on, match:class (Share|localsend)
windowrule = center on, match:class (Share|localsend)
```

**`~/.config/hypr/apps/pip.conf`**
```ini
# -----------------------------------------------------------------------------
# Picture-in-Picture overlays
# -----------------------------------------------------------------------------

# Tag PiP windows by title
windowrule = tag +pip, match:title (Picture.?in.?[Pp]icture)

# Force PiP behavior
windowrule = float on, match:tag pip
windowrule = pin on, match:tag pip

# Size & aspect ratio
windowrule = size 600 338, match:tag pip
windowrule = keep_aspect_ratio on, match:tag pip

# Visual cleanup
windowrule = decorate off, match:tag pip
windowrule = opacity 1.0 override 1.0 override, match:tag pip

# Position: top-right corner with margin
windowrule = move (monitor_w-window_w-40) (monitor_h*0.04), match:tag pip
```

**`~/.config/hypr/apps/qemu.conf`**
```ini
windowrule = opacity 1.0 override 1.0 override, match:class ^qemu$
```

**`~/.config/hypr/apps/retroarch.conf`**
```ini
# -----------------------------------------------------------------------------
# RetroArch
# -----------------------------------------------------------------------------

windowrule = fullscreen on, match:class ^com\.libretro\.RetroArch$
windowrule = opacity 1.0 override 1.0 override, match:class ^com\.libretro\.RetroArch$
windowrule = idle_inhibit fullscreen, match:class ^com\.libretro\.RetroArch$
```

**`~/.config/hypr/apps/spotify.conf`**
```ini
windowrule = workspace special:Entertainment, match:class ^Spotify$
```

**`~/.config/hypr/apps/steam.conf`**
```ini
# -----------------------------------------------------------------------------
# Steam
# -----------------------------------------------------------------------------

# Float all Steam windows
windowrule = float on, match:class ^steam$

# Center main Steam window
windowrule = center on, match:class ^steam$, match:title ^Steam$

# Ensure Steam is always fully opaque
windowrule = opacity 1.0 override 1.0 override, match:class ^steam$

# Sizes for specific Steam windows
windowrule = size 1100 700, match:class ^steam$, match:title ^Steam$
windowrule = size 460 800, match:class ^steam$, match:title ^Friends List$

# Prevent idle / screen blanking when Steam goes fullscreen (e.g. games)
windowrule = idle_inhibit fullscreen, match:class ^steam$
```

**`~/.config/hypr/apps/system.conf`**
```ini
# -----------------------------------------------------------------------------
# Floating windows (tag-driven)
# -----------------------------------------------------------------------------

windowrule = float on, match:tag floating-window
windowrule = center on, match:tag floating-window
windowrule = size 800 600, match:tag floating-window


# -----------------------------------------------------------------------------
# Tag windows that should float
# -----------------------------------------------------------------------------

windowrule = tag +floating-window, match:class (blueberry\.py|Impala|Wiremix|org\.gnome\.NautilusPreviewer|com\.gabm\.satty|Omarchy|About|TUI\.float)

windowrule = tag +floating-window, \
  match:class (xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org\.gnome\.Nautilus), \
  match:title ^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|[Cc]hoose.*)$

# Calculator always floats
windowrule = float on, match:class ^org\.gnome\.Calculator$


# -----------------------------------------------------------------------------
# Fullscreen screensaver
# -----------------------------------------------------------------------------

windowrule = fullscreen on, match:class ^Screensaver$


# -----------------------------------------------------------------------------
# Media apps should never be transparent
# -----------------------------------------------------------------------------

windowrule = opacity 1.0 override 1.0 override, \
  match:class ^(zoom|vlc|mpv|org\.kde\.kdenlive|com\.obsproject\.Studio|com\.github\.PintaProject\.Pinta|imv|org\.gnome\.NautilusPreviewer)$
```

**`~/.config/hypr/apps/terminals.conf`**
```ini
# Define terminal tag to style them uniformly
windowrule = tag +terminal, match:class ^(Alacritty|kitty|com\.mitchellh\.ghostty)$
```

**`~/.config/hypr/apps/webcam-overlay.conf`**
```ini
# -----------------------------------------------------------------------------
# Webcam overlay for screen recording
# -----------------------------------------------------------------------------

windowrule = float on, match:title ^WebcamOverlay$
windowrule = pin on, match:title ^WebcamOverlay$

# Do not steal focus when it appears
windowrule = no_initial_focus on, match:title ^WebcamOverlay$

# Do not dim background
windowrule = no_dim on, match:title ^WebcamOverlay$

# Position bottom-right with margin
windowrule = move (monitor_w-window_w-40) (monitor_h-window_h-40), match:title ^WebcamOverlay$
```
