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