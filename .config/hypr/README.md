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

This configuration depends on a number of external packages. Here is a list of the identified dependencies and how to install them on Arch Linux.

### Core Components
- `hyprland`: The Wayland compositor itself.
- `waybar`: The status bar.
- `sway-notification-center`: The notification daemon.
- `hyprpaper`: The wallpaper daemon.
- `hypridle`: The idle daemon.
- `walker`: A custom application launcher.
- `kitty`: The terminal emulator.
- `nautilus`: The file manager.

**Installation:**
```bash
sudo pacman -S hyprland waybar sway-notification-center hyprpaper hypridle hyprlock rofi kitty nautilus
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

**Installation:**
```bash
sudo pacman -S polkit-gnome wl-clipboard cliphist network-manager-applet pipewire-pulse brightnessctl libnotify procps-ng coreutils util-linux findutils
```

### Screenshotting
- `grim`: For taking screenshots.
- `slurp`: for selecting a region to screenshot.
- `satty`: For editing screenshots.

**Installation:**
```bash
sudo pacman -S grim slurp satty
```

### Theming
- `qt5ct`: For Qt5 theme configuration.
- `kvantum`: For Qt theming.
- `catppuccin-cursors-mocha`: The cursor theme.

**Installation:**
```bash
sudo pacman -S qt5ct kvantum
yay -S catppuccin-cursors-mocha
```

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
- `elephant`, `elephant-desktopapplications`: Custom desktop applications.

**Installation:**
```bash
sudo pacman -S brave-browser spotify-launcher pavucontrol blueman gnome-calculator blueberry qemu retroarch steam vlc mpv kdenlive obs-studio pinta imv alacritty ghostty sublime-text-4 onlyoffice-desktopeditors
yay -S localsend-bin walker elephant elephant-desktopapplications
```

## Script Permissions

Before the scripts in the `scripts/` directory can be used, they need to be made executable. You can do this by running the following command:

```bash
chmod +x ~/.config/hypr/scripts/*.sh
```