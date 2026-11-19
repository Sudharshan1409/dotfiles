# Hyprland Configuration (0.57+ Lua + Caelestia Shell)

Modular **Hyprland 0.57+ Lua** configuration paired with **Caelestia Shell (Quickshell)** for a unified Material You Wayland desktop on Ubuntu 26.04+ and Arch Linux.

---

## Directory Layout

- `hyprland.lua`: Entrypoint loading modules, `monitors_gen.lua`, and preserving docked clamshell panel state across reloads.
- `scheme/current.lua`: Auto-generated dynamic Material You palette from `caelestia`.
- `lua/`
  - `autostart.lua`: Session environment export + `systemd --user` watchdog startup (`caelestia-shell.service` & `cliphist.service`), cursor setup, Polkit agent, and multi-monitor hotplug listener.
  - `envs.lua`: Wayland/Qt/GTK/Electron environment variables, cursor theme, and Caelestia library paths.
  - `input.lua`: Keyboard repeat, touchpad natural scroll, and 3-finger / 4-finger `hl.gesture` touchpad swipes.
  - `looknfeel.lua`: Gaps, dynamic Material You active/inactive borders, frosted glass blur (`size = 6, passes = 3`), animations, and `caelestia-*` layer rules.
  - `windows.lua` & `apps/`: Floating/centering rules (including Caelestia Nexus & GNOME Settings) and per-application rules.
  - `bindings/`: Modular Lua shortcut definitions (`apps.lua`, `system.lua`, `tiling.lua`, `workspaces.lua`, `groups.lua`, `media.lua`, `mouse.lua`).
- `monitors/`: Multi-monitor Lua profiles managed automatically by `monitor_profile_manager.sh` and `monitor_wizard.sh`.
- `scripts/`: Helper utilities (`lid_switch.sh`, `keybinding_menu.sh`, `emoji_picker.sh`, `calculator.sh`, `focus_mode.sh`, `ocr.sh`, `toggle_keep_awake.sh`, `toggle_pip.sh`, `quick_fzf_finder.sh`, `scratchpad_terminal.sh`, `screenshot_screen_edit.sh`, `monitor_profile_manager.sh`, `monitor_wizard.sh`).

---

## Custom Caelestia QML Modules (`scripts/setup/caelestia/`)

Applied idempotently by `scripts/setup/patch_caelestia.py` on both Ubuntu and Arch:

1. **`WindowSwitcher.qml` (`Alt + Tab` / `Alt + Shift + Tab`)**: OS-style live 60fps `ScreencopyView` MRU window switcher with spatial spring animations and `Alt`-release confirmation.
2. **`WorkspaceOverview.qml` (`Super + \``)**: macOS Mission Control / GNOME spatial 2×5 workspace grid with live window previews and drag-and-drop window movement across workspaces.
3. **`ClipboardModal.qml` (`Super + Ctrl + V`)**: Searchable clipboard history modal with inline decoded image thumbnails (`cliphist`), `Ctrl+J/K` navigation, and single/bulk deletion.
4. **`WorkspacePopout.qml`**: Hybrid taskbar workspace hover preview (spatial mini-desktop when hovering workspace shape, single-window preview when hovering app icon).
5. **`CalendarPopout.qml`**: Interactive monthly calendar popout on taskbar clock hover.
6. **`NightLight.qml` (`Super + Alt + N` & Quick Utilities toggle)**: `wlsunset` 4200K eye-comfort blue-light filter integrated into Caelestia's Quick Utilities card.

---

## Smart Laptop Clamshell Mode (`scripts/lid_switch.sh`)

- **Docked (`HDMI` / `DP` / `DVI` active):** Closing the laptop lid disables the internal `eDP` panel, migrates workspaces to the external monitor, and persists across `hyprctl reload`; opening the lid restores your multi-monitor profile automatically.
- **Undocked (laptop panel only):** Closing the lid triggers `caelestia shell lock lock` cleanly before suspend.

---

## Diagnostics

```bash
Hyprland --verify-config          # Validate full Hyprland Lua config
~/dotfiles/setup.sh --check       # Run Dotfiles Doctor health check
systemctl --user status caelestia-shell.service cliphist.service
```
