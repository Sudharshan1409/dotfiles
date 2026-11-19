# Dotfiles Repository

Modular, reproducible Linux (Ubuntu 26.04+ & Arch Linux) and macOS dotfiles managed with **GNU Stow**, featuring **Hyprland 0.57+ (Lua configuration)** + **Caelestia Shell (Quickshell)** with dynamic **Material You** palette synchronization across the desktop, terminal, and utilities.

---

## Packages

<details open>
<summary><b>Desktop & Window Management (Linux Wayland)</b></summary>

- **Hyprland (`hypr/`)**: Lua-configured dynamic tiling compositor (`hl.config`, `hl.window_rule`, `hl.gesture`, dynamic Material You borders, multi-monitor profile wizard).
  - [Hyprland README](hypr/.config/hypr/README.md)
- **Caelestia Shell (`caelestia/`)**: Unified Quickshell Material 3 desktop shell (`shell.json`, `cli.json`, user theme templates for Ghostty & Rofi, plus QML enhancements in `scripts/setup/patch_caelestia.py` for calendar hover popout, hybrid workspace mini-desktop + live window previews, and Satty screenshot integration).
- **Rofi (`rofi/`)**: Glassmorphic Material You themed utility menus (keybinding cheat sheet, clipboard history, emoji/glyph picker, monitor profile wizard, scientific calculator, process killer).
- **Backgrounds (`backgrounds/`)**: Curated wallpaper collection synced with Caelestia's dynamic colour generator.

</details>

<details>
<summary><b>Shell, Terminal & Multiplexers</b></summary>

- **Ghostty (`ghostty/`)**: GPU-accelerated terminal with frosted glass blur and live Caelestia Material You theme sync.
- **Zsh (`zsh/`)**: Oh-My-Zsh + Enigma CLI workflow dispatcher + Starship prompt + live ANSI palette replay.
  - [Zsh README](zsh/.config/zsh/README.md)
- **Starship (`starship/`)**: Cross-shell prompt configuration.
- **Tmux (`tmux/`)** & **Zellij (`zellij/`)**: Terminal multiplexers and session workspaces.

</details>

<details>
<summary><b>Development & CLI Tools</b></summary>

- **Neovim (`nvim/`)**: Lazy.nvim IDE configuration.
- **Git (`git/`)**: Git config, aliases, delta diffs, and GPG commit signing.
- **Lazygit (`lazygit/`)**, **Yazi (`yazi/`)**, **Bat (`bat/`)**: Terminal UI tools.

</details>

<details>
<summary><b>macOS Window Management</b></summary>

- **AeroSpace (`aerospace/`)** & **SketchyBar (`sketchybar/`)**: macOS tiling window manager and status bar configs.

</details>

---

## Quick Start (Automated Provisioning)

Clone the repository to `~/dotfiles` and run `./setup.sh` for end-to-end unattended provisioning on **Ubuntu/Debian** or **Arch Linux**:

```bash
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

`setup.sh` automatically detects your distro, installs system & Wayland packages, builds/installs **Quickshell**, **Caelestia Shell**, and **gpu-screen-recorder**, applies custom Caelestia QML patches, links all Stow packages, installs fonts & Catppuccin cursors, initializes your default wallpaper + dynamic Material You dark scheme, and configures GRUB.

### Setup Flags & Health Check

```bash
./setup.sh --os ubuntu     # Force Ubuntu / Debian provisioning
./setup.sh --os arch       # Force Arch Linux provisioning
./setup.sh --screen 2k     # Set WhiteSur GRUB theme resolution (1080p, 2k, 4k)
./setup.sh --check         # Run Dotfiles Doctor (58-point health check)
```

---

## Manual Stow Linking

To link individual packages manually via GNU Stow:

```bash
cd ~/dotfiles
stow backgrounds bat caelestia ghostty git hypr lazygit nvim rofi starship tmux yazi zellij zsh
```

---

## Key Highlights & Essential Shortcuts

| Shortcut / Gesture | Action |
| :--- | :--- |
| `Super + Space` | Open Caelestia Launcher (`Ctrl + H/J/K/L` Vim navigation, `>settings`, power actions) |
| `Super + D` / `3-Finger Swipe Down` | Toggle Caelestia Dashboard (media, CPU/GPU/RAM/battery, weather) |
| `Super + Ctrl + ,` | Open Caelestia Nexus Settings (centered floating window) |
| `Super + Ctrl + W` / `Super + Ctrl + Shift + W` | Wallpaper picker / Random wallpaper + live Material You recolouring |
| `Super + Shift + S` / `Super + Print` / `Print` | Caelestia freeze-screen AreaPicker (hover window to snap or drag region -> Satty / Clipboard) |
| `Super + Alt + R` / `Super + Alt + Shift + R` | Hardware-accelerated screen recorder (`gpu-screen-recorder` via Caelestia) |
| `Super + .` | Emoji & Nerd Font glyph picker |
| `Super + Ctrl + V` | Clipboard history |
| `Super + S` / `Super + Alt + M` / `Super + Alt + T` | Terminal, Spotify (`special:music`), and `btop` (`special:sysmon`) scratchpads |
| `Super + Alt + G` / `Super + Alt + F` | Game Mode / Focus Mode |
| `Super + /` | Searchable interactive Keybinding & Gesture Cheat Sheet |
| `3-Finger Swipe Left/Right` | Live 1:1 touchpad workspace switching |
