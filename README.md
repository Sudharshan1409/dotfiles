# Dotfiles Repository

Modular, reproducible Linux (Ubuntu 26.04+ & Arch Linux) and macOS dotfiles managed with **GNU Stow**, featuring **Hyprland 0.57+ (Lua configuration)** + **Caelestia Shell (Quickshell)** with dynamic **Material You** palette synchronization across the desktop, terminal, and TUI tools.

---

## Packages

<details open>
<summary><b>Desktop, Services & Window Management (Linux Wayland)</b></summary>

- **Hyprland (`hypr/`)**: Lua-configured dynamic tiling compositor (`hl.config`, `hl.window_rule`, `hl.gesture`, dynamic Material You borders, smart docked clamshell lid handling, multi-monitor profile wizard).
  - [Hyprland README](hypr/.config/hypr/README.md)
- **Caelestia Shell (`caelestia/`)**: Unified Quickshell Material 3 desktop shell (`shell.json`, `cli.json`, user avatar, dynamic templates for Ghostty, Rofi, Tmux, Zellij & Lazygit, plus custom QML modules in `scripts/setup/caelestia/` for live `Alt + Tab` window switcher, Mission Control workspace overview, visual image clipboard, hybrid workspace hover previews, calendar popout, Night Light toggle, and Satty screenshot integration).
- **Systemd User Units (`systemd/`)**: Self-healing `Restart=always` user watchdog services (`caelestia-shell.service` and `cliphist.service`).
- **Rofi (`rofi/`)**: Glassmorphic Material You themed utility menus (keybinding cheat sheet, emoji/glyph picker, monitor profile wizard, scientific calculator, audio switcher, process killer).
- **Backgrounds (`backgrounds/`)**: Curated wallpaper collection synced with Caelestia's dynamic colour generator.

</details>

<details>
<summary><b>Shell, Terminal & Multiplexers</b></summary>

- **Ghostty (`ghostty/`)**: GPU-accelerated terminal with frosted glass blur and live Caelestia Material You theme sync.
- **Zsh (`zsh/`)**: Oh-My-Zsh + Enigma CLI workflow dispatcher + Starship prompt + live ANSI palette replay.
  - [Zsh README](zsh/.config/zsh/README.md)
- **Fastfetch (`fastfetch/`)**: Minimal Nerd-Font system info card synced with terminal Material You colors.
- **Starship (`starship/`)**: Cross-shell prompt configuration.
- **Tmux (`tmux/`)** & **Zellij (`zellij/`)**: Terminal multiplexers dynamically synced with Caelestia's Material You palette.

</details>

<details>
<summary><b>Development & CLI Tools</b></summary>

- **Neovim (`nvim/`)**: Lazy.nvim IDE configuration.
- **Git (`git/`)**: Git config, aliases, delta diffs, and GPG commit signing.
- **Lazygit (`lazygit/`)**, **Yazi (`yazi/`)**, **Bat (`bat/`)**: Terminal UI tools (with dynamic Material You theme overlay for Lazygit).

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

`setup.sh` automatically detects your distro, installs system & Wayland packages, builds/installs **Quickshell**, **Caelestia Shell**, and **gpu-screen-recorder**, applies custom Caelestia QML modules, links all Stow packages, enables `systemd --user` watchdog units, installs fonts & Catppuccin cursors, initializes your default wallpaper + dynamic Material You dark scheme, and configures GRUB.

### Setup Flags & Health Check

```bash
./setup.sh --os ubuntu     # Force Ubuntu / Debian provisioning
./setup.sh --os arch       # Force Arch Linux provisioning
./setup.sh --screen 2k     # Set WhiteSur GRUB theme resolution (1080p, 2k, 4k)
./setup.sh --check         # Run Dotfiles Doctor health check
```

---

## Manual Stow Linking

```bash
cd ~/dotfiles
stow backgrounds bat caelestia fastfetch ghostty git hypr lazygit nvim rofi starship systemd tmux yazi zellij zsh
```

---

## Essential Shortcuts & Gestures

| Shortcut / Gesture | Action |
| :--- | :--- |
| `Alt + Tab` / `Alt + Shift + Tab` | Live 60fps visual MRU Window Switcher (hold `Alt`, release to focus) |
| `Super + \`` | Mission Control Spatial Workspace Overview (click to jump, drag windows across workspaces) |
| `Super + Ctrl + V` | Visual Clipboard Manager with inline image thumbnails (`Ctrl+J/K`, `Alt+D` delete) |
| `Super + Space` | Caelestia Launcher (`Ctrl+H/J/K/L` Vim navigation, `>settings`, power actions) |
| `Super + D` / `3-Finger Swipe Down` | Toggle Caelestia Dashboard (media, CPU/GPU/RAM/battery, weather, avatar) |
| `Super + Ctrl + ,` | Open Caelestia Nexus Settings (centered floating window) |
| `Super + Ctrl + W` / `Super + Ctrl + Shift + W` | Wallpaper picker / Random wallpaper + full desktop & TUI Material You sync |
| `Super + Shift + S` / `Super + Print` / `Print` | Caelestia freeze-screen AreaPicker (snap window or drag region -> Satty / Clipboard) |
| `Super + Alt + N` | Toggle Night Light (4200K eye-comfort filter, also in Quick Utilities) |
| `Super + Alt + R` / `Super + Alt + Shift + R` | Hardware-accelerated screen recorder (`gpu-screen-recorder`) |
| `Super + .` | Emoji & Nerd Font glyph picker |
| `Super + S` / `Super + Alt + M` / `Super + Alt + T` | Terminal, Spotify (`special:music`), and `btop` (`special:sysmon`) scratchpads |
| `Super + Alt + G` / `Super + Alt + F` | Game Mode / Focus Mode |
| `Super + /` | Searchable interactive Keybinding & Gesture Cheat Sheet |
| `3-Finger Swipe Left/Right` | Live 1:1 touchpad workspace switching |
| `Laptop Lid Close / Open` | Smart Clamshell Mode when docked to external monitor; Lock before sleep when undocked |
