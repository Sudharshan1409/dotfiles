# Hyprland Configuration

This is a personalized Hyprland configuration. It is modular and sources several files from this directory.

## Structure

- `hyprland.conf`: The main configuration file, which sources all other `.conf` files.
- `mocha.conf`: Color scheme definition.
- `autostart.conf`: Applications and services to launch at startup.
- `bindings.conf`: Main keybindings file, which sources files from the `bindings/` directory.
- `windows.conf`: Window rules for specific applications.
- `envs.conf`: Environment variables.
- `input.conf`: Keyboard and mouse settings.
- `looknfeel.conf`: General look and feel settings, including gaps, borders, and animations.
- `monitors.conf`: Monitor configuration and workspace assignments.
- `apps/`: Directory with application-specific window rules.
- `bindings/`: Directory with categorized keybindings.
- `scripts/`: Directory with various scripts used in the configuration.

## Dependencies

This configuration depends on a number of external packages. Here is a list of the identified dependencies and how to install them on Arch Linux and Ubuntu.

### Core Components
- `hyprland`: The Wayland compositor itself.
- `waybar`: The status bar.
- `sway-notification-center`: The notification daemon.
- `hyprpaper`: The wallpaper daemon.
- `hypridle`: The idle daemon.
- `kitty`: The terminal emulator.
- `nautilus`: The file manager.

**Arch Linux Installation:**
```bash
sudo pacman -S hyprland waybar sway-notification-center hyprpaper hypridle hyprlock rofi kitty nautilus
```

**Ubuntu Installation:**
```bash
sudo add-apt-repository ppa:cppiber/hyprland -y && sudo apt update
sudo apt install hyprland waybar sway-notification-center hyprpaper hypridle rofi kitty nautilus
```

**Note:** `hyprlock` may not be available in the PPA. If it is not, you can build it from source:
```bash
git clone https://github.com/hyprwm/hyprlock.git
cd hyprlock
make all
sudo make install
```

### System Utilities
- `polkit-gnome`: For authentication.
- `wl-clipboard`: For copy/paste functionality.
- `cliphist`: For clipboard history.
- `network-manager-applet`: For graphical network management.
- `pipewire-pulse`: For audio.
- `brightnessctl`: For brightness control.
- `libnotify`: For desktop notifications.
- `procps-ng`: For system monitoring utilities.
- `coreutils`, `util-linux`, `findutils`: Basic system utilities.

**Arch Linux Installation:**
```bash
sudo pacman -S polkit-gnome wl-clipboard cliphist network-manager-applet pipewire-pulse brightnessctl libnotify procps-ng coreutils util-linux findutils
```

**Ubuntu Installation:**
```bash
sudo apt install policykit-1-gnome wl-clipboard network-manager-gnome pipewire-pulse brightnessctl libnotify4 procps coreutils util-linux findutils
```
**Note:** `cliphist` is not available in the default Ubuntu repositories. It needs to be installed from source.

### Screenshotting
- `grim`: For taking screenshots.
- `slurp`: for selecting a region to screenshot.
- `satty`: For editing screenshots.

**Arch Linux Installation:**
```bash
sudo pacman -S grim slurp satty
```

**Ubuntu Installation:**
```bash
sudo apt install grim slurp
```

### Screen Recording
- `wf-recorder`: For recording the screen (used by the screen recorder utility, `Super + Alt + R`).

**Arch Linux Installation:**
```bash
sudo pacman -S wf-recorder
```

**Ubuntu Installation:**
```bash
sudo apt install wf-recorder
```
**Note:** `wf-recorder` is available in Ubuntu 22.04+ universe repository. On older releases, build from source: https://github.com/ammen99/wf-recorder

### Power Management
- `power-profiles-daemon`: Provides the `powerprofilesctl` CLI used by the battery monitor for auto-switching between `performance` / `balanced` / `power-saver`.

**Arch Linux Installation:**
```bash
sudo pacman -S power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon
```

**Ubuntu Installation:**
```bash
sudo apt install power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon
```
For Satty, clone the repository, build from source, and copy the binary to `/usr/local/bin`:
```bash
git clone https://github.com/Satty-org/Satty.git
cd Satty
cargo build --release
sudo cp target/release/satty /usr/local/bin
```

### Theming
- `qt5ct`: For Qt5 theme configuration.
- `kvantum`: For Qt theming.
- `catppuccin-cursors-mocha`: The cursor theme.

**Arch Linux Installation:**
```bash
sudo pacman -S qt5ct kvantum
yay -S catppuccin-cursors-mocha
```

**Ubuntu Installation:**
```bash
sudo apt install qt5ct qt5-style-kvantum
```
**Note:** `catppuccin-cursors-mocha` needs to be installed manually. See the [Catppuccin Cursors GitHub page](https://github.com/catppuccin/cursors) for instructions.

### Applications
- `brave-browser`: The web browser.
- `spotify-launcher`: The Spotify client.
- `pavucontrol`: PulseAudio volume control.
- `blueman`: Bluetooth manager.
- `gnome-calculator`: The calculator.
- `blueberry`: Bluetooth configuration utility.
- `qemu`: The emulator.
- `retroarch`: The frontend for emulators.
- `steam`: The gaming platform.
- `vlc`: The media player.
- `mpv`: The media player.
- `kdenlive`: The video editor.
- `obs-studio`: The streaming/recording software.
- `pinta`: The image editor.
- `imv`: The image viewer.
- `alacritty`: An alternative terminal emulator.
- `ghostty`: An alternative terminal emulator.
- `sublime-text-4`: The text editor.
- `onlyoffice-desktopeditors`: The office suite.
- `localsend-bin`: The file sharing application.
- `rofi`: The application launcher.


**Arch Linux Installation:**
```bash
sudo pacman -S brave-browser spotify-launcher pavucontrol blueman gnome-calculator blueberry qemu retroarch steam vlc mpv kdenlive obs-studio pinta imv alacritty ghostty sublime-text-4 onlyoffice-desktopeditors
yay -S localsend-bin
```

**Ubuntu Installation:**
```bash
# Brave Browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client

# Other Applications
sudo apt install pavucontrol blueman gnome-calculator blueberry qemu-system retroarch steam vlc mpv kdenlive obs-studio pinta imv alacritty rofi

# Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-text

# OnlyOffice
sudo apt install onlyoffice-desktopeditors

# Ghostty, localsend
# These applications are not in the default repositories and need to be installed manually or from a PPA.
```

## Script Permissions

Before the scripts in the `scripts/` directory can be used, they need to be made executable. You can do this by running the following command:

```bash
chmod +x ~/.config/hypr/scripts/*.sh
```

## New Features & Utilities

### Keybinding Help Menu

A searchable, interactive menu showing all 77+ keyboard shortcuts organized by category.

**Usage:**
- Press **`Super + /`** to open the keybinding menu
- Type to search for specific keybindings
- Press Enter to execute any keybinding instantly

**Categories:**
- 📱 Apps (Spotify, file manager, clipboard, etc.)
- ⚙️ System (lock, suspend, wallpaper, monitor profiles)
- 🔧 Utils (calculator, process killer, audio switcher)
- 🪟 Windows (close, float, fullscreen, resize)
- 🧭 Navigation (focus movement, mouse drag)
- 🗂️ Workspaces (1-10, special workspaces, move windows)
- 📦 Groups (tabbed windows)
- 🎵 Media (volume, brightness, playback)
- 📸 Screenshots
- ⌨️ Input (universal copy/paste)

### Quick Calculator

A rofi-based calculator with expression history and clipboard support.

**Keybinding:** `Super + Alt + C`

**Features:**
- Math expressions (e.g., `2+2`, `130000-55000`, `sqrt(16)`)
- History of previous calculations
- Copy results to clipboard
- Supports large numbers and basic operations

### Process Killer

Kill hung or unwanted processes via an interactive rofi menu.

**Keybinding:** `Super + Alt + P`

**Features:**
- Lists all processes with CPU/Memory usage
- Search and filter processes
- Kill with TERM (graceful) or Force Kill (KILL -9)
- View process details before killing

### Audio Device Switcher

Quickly toggle between audio input/output devices.

**Keybinding:** `Super + Alt + A`

**Features:**
- Switch between output devices (speakers, headphones)
- Switch between input devices (microphones)
- Toggle mute for input/output
- Open pavucontrol for detailed control
- Menu closes automatically after any action

### Movie Mode (Solo Display)

Turn off secondary monitors and disable screen locking for an immersive movie experience.

**Keybinding:** `Super + Alt + M`

**Features:**
- Select a "Solo" monitor to stay on
- Powers off all other monitors via DPMS
- Automatically stops `hypridle` to prevent screen lock/sleep
- "Restore" option to bring back all displays and re-enable `hypridle`

### App-Specific Help

Shows keyboard shortcuts for the currently active application.

**Keybinding:** `Super + Shift + ?`

**Supported Apps:**
- Ghostty/Terminal
- Firefox/Brave/Chrome
- VS Code
- JetBrains IDEs (IntelliJ, PyCharm, etc.)
- Sublime Text
- Spotify
- GIMP/Image editors
- VLC/MPV
- Generic shortcuts for unsupported apps

### MRU Window Switcher (Alt-Tab)

A classic Alt-Tab style switcher that lists every window across every workspace, sorted by most-recently-focused. Selecting a window jumps to it (and its workspace) directly.

**Keybinding:** `Alt + Tab`

**Features:**
- MRU order via `focusHistoryID` from `hyprctl clients` — no event-tracking daemon
- Current window is excluded, so the top entry is your *previous* window (Alt-Tab feel)
- Selecting any window auto-switches to its workspace
- Type to fuzzy-search across class and title

### Move Workspace Between Monitors

Push the current workspace to a neighboring monitor in any direction — useful when reshuffling content between displays without manually moving each window.

**Keybindings:**
- `Super + Shift + Left` — move current workspace to monitor on the left
- `Super + Shift + Right` — move current workspace to monitor on the right
- `Super + Shift + Up` — move current workspace to monitor above
- `Super + Shift + Down` — move current workspace to monitor below

Uses Hyprland's built-in `movecurrentworkspacetomonitor` dispatcher; no script required. Up/Down only have effect on vertically-arranged multi-monitor setups.

### Workspace History Toggle

Ping-pong between the current workspace and the last-focused one — the workspace equivalent of Alt-Tab.

**Keybinding:** `Super + Backspace`

Uses Hyprland's built-in `workspace previous` dispatcher; press again to jump back. Lives entirely in `bindings/workspaces.conf`, no script needed.

### Battery Monitor (Auto)

A background daemon that watches battery state and automatically:

- **Notifies** on low-charge thresholds while discharging (≤20% normal, ≤10% critical, ≤5% urgent)
- **Toasts** on AC plug/unplug transitions and at full charge
- **Switches power profiles** via `powerprofilesctl`:
  - AC plugged in → `performance` (falls back to `balanced` if performance isn't available)
  - On battery, >30% → `balanced`
  - On battery, ≤30% → `power-saver`

Poll interval: 30 seconds. Battery and AC paths are auto-detected (BAT0/BAT1, AC/ADP1/ACAD).

The monitor starts automatically on Hyprland session start via `launch_battery_monitor.sh`, which kills stale instances first. Requires `power-profiles-daemon` (see Dependencies → Power Management).

### Focus Mode

A one-key toggle for distraction-free work — similar to Movie Mode but for *coding*, not entertainment (multi-monitor and idle lock are left intact).

**Keybinding:** `Super + Alt + F`

**Features:**
- Toggles swaync DND (notifications silenced and replayed on exit)
- Hides waybar (via `SIGUSR1`)
- Dims inactive windows (`decoration:dim_inactive`) so the focused window stands out
- State tracked in `/tmp/focus_mode.state`; same key reverses everything
- Pre-flight notification fires before DND so you always see the "ON" toast

### Scratchpad Terminal

A toggleable floating Ghostty terminal on a dedicated `special:scratch` workspace.

**Keybinding:** `Super + S`

**Features:**
- First press spawns a Ghostty (forced as a fresh process with `--gtk-single-instance=false`) on its own special workspace
- Subsequent presses hide/show the terminal without losing the session
- Floats, centered, sized 85% × 80% — looks like an overlay panel
- Window placement is enforced via inline dispatcher rules so it works regardless of class matching

### Screen Recorder

Toggle-based screen recorder built on `wf-recorder`.

**Keybinding:** `Super + Alt + R`

**Features:**
- When idle, opens a rofi menu: region / active window / full screen, each with optional audio
- When already recording, the same key stops and finalizes the file
- Output: `~/Videos/Recordings/screen-<timestamp>.mp4`
- Stopped recording's full path is auto-copied to the clipboard
- Audio capture uses the default PulseAudio source (mic by default — set default source to a sink monitor with `pactl set-default-source <sink>.monitor` to capture system audio)

## Utility Scripts Reference

| Script | Purpose | Keybinding |
|--------|---------|------------|
| `keybinding_menu.sh` | Searchable keybinding help | `Super + /` |
| `calculator.sh` | Quick calculator | `Super + Alt + C` |
| `process_killer.sh` | Kill processes | `Super + Alt + P` |
| `movie_mode.sh` | Solo display for movies | `Super + Alt + M` |
| `audio_switcher.sh` | Switch audio devices | `Super + Alt + A` |
| `screen_recorder.sh` | Screen recorder (toggle) | `Super + Alt + R` |
| `focus_mode.sh` | Focus mode (DND + hide bar + dim) | `Super + Alt + F` |
| `battery_monitor.sh` | Battery alerts + auto power-profile | _autostart_ |
| `window_switcher.sh` | MRU window switcher (all workspaces) | `Alt + Tab` |
| `scratchpad_terminal.sh` | Floating dropdown terminal | `Super + S` |
| `exit_hyprland.sh` | Exit Hyprland (confirmation) | `Super + Ctrl + M` |
| `app_help.sh` | App-specific shortcuts | `Super + Shift + ?` |
| `workspace_overview.sh` | Show all workspaces | `Super + Ctrl + Tab` |
| `ocr.sh` | Extract text from screen | `Super + Shift + T` |
| `set_wallpaper.sh` | Change wallpaper | `Super + Ctrl + W` |
| `monitor_profile_manager.sh` | Monitor configurations | `Super + Ctrl + D` |

---

## Monitor Profile System

An intelligent, self-learning monitor configuration system that automatically detects your monitor setup and applies the correct profile.

### Features

- **Auto-Detection**: Automatically detects monitor configurations when connecting/disconnecting monitors
- **Smart Caching**: Remembers which profile to use based on MAC address + monitor fingerprint
- **Interactive Menu**: Rofi-based profile selector with create/edit capabilities
- **Multiple Locations**: Supports unlimited monitor configurations (home, office, coffee shop, etc.)

### How It Works

The system creates a unique "fingerprint" for each monitor setup: `<MAC_ADDRESS>|<PORT1>:<MONITOR_DESC1>|<PORT2>:<MONITOR_DESC2>`

When monitors change:
1. Gets current fingerprint
2. Checks cache for matching profile
3. **If found** → Applies profile with notification
4. **If not found** → Opens profile selector menu
5. Saves association for next time

### Keyboard Shortcuts

- **`Ctrl + Super + D`**: Open monitor profile selector menu
- **`Ctrl + Super + Shift + D`**: Auto-apply cached profile

### Profile Files

Profiles are stored in `~/.config/hypr/monitors/*.conf`:

```conf
# Description: Home office setup
monitor = eDP-1, 1920x1080@120, 0x0, 1
monitor = DP-1, 2560x1440@60, 1920x0, 1

workspace=1,monitor:eDP-1
workspace=2,monitor:DP-1
workspace=3,monitor:eDP-1
```

### Commands

```bash
# Auto-detect and apply
~/.config/hypr/scripts/monitor_profile_manager.sh auto

# Show profile menu
~/.config/hypr/scripts/monitor_profile_manager.sh menu

# List all profiles
~/.config/hypr/scripts/monitor_profile_manager.sh list

# Show current fingerprint
~/.config/hypr/scripts/monitor_profile_manager.sh current

# Apply specific profile
~/.config/hypr/scripts/monitor_profile_manager.sh apply <profile_name>
```

### Troubleshooting

**Monitor changes not detected:**
```bash
# Check if listener is running
ps aux | grep monitor_event_listener

# View logs
tail -f ~/.config/hypr/.logs/monitor_listener.log
```

**Profile not auto-loading:**
```bash
# Check cache
~/.config/hypr/scripts/monitor_profile_manager.sh cache

# Clear cache from profile menu (Ctrl+Super+D → Clear Cache)
```

### Files

- **Profiles**: `~/.config/hypr/monitors/*.conf`
- **Cache**: `~/.config/hypr/.cache/monitor_profile_cache.json`
- **Logs**: `~/.config/hypr/.logs/monitor_listener.log`
- **Rofi Theme**: `~/.config/rofi/monitor-profile.rasi`
er.sh cache

# Clear cache from profile menu (Ctrl+Super+D → Clear Cache)
```

### Files

- **Profiles**: `~/.config/hypr/monitors/*.conf`
- **Cache**: `~/.config/hypr/.cache/monitor_profile_cache.json`
- **Logs**: `~/.config/hypr/.logs/monitor_listener.log`
- **Rofi Theme**: `~/.config/rofi/monitor-profile.rasi`
