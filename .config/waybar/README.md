# Waybar Configuration

This directory contains the configuration files for the Waybar status bar.

## Files

### `config.jsonc`

This is the main configuration file for Waybar. It defines the modules that are displayed on the bar, their position, and their configuration.

### `style.css`

This file contains the stylesheet for the Waybar. It controls the appearance of the bar and its modules, including colors, fonts, and spacing.

### `scripts/`

This directory contains various scripts that are used by the modules in the `config.jsonc` file.

*   `bluetooth-manager.sh`: Displays the status of Bluetooth and the number of connected devices.
*   `mic-control.sh`: Controls the microphone volume.
*   `network-manager.sh`: Displays the network status, including Ethernet and Wi-Fi connections.
*   `power-menu.sh`: Displays a power menu using `rofi` for shutting down, rebooting, sleeping, locking the screen, and logging out.
*   `toggle-bluetooth.sh`: Toggles Bluetooth on and off. **Requires `sudo`**.
*   `toggle-wifi.sh`: Toggles Wi-Fi on and off. **Requires `sudo`**.
*   `volume-control.sh`: Controls the speaker volume.
*   `waybar-wttr.py`: A Python script that fetches and displays weather information from `wttr.in`.
*   `wifi-menu.sh`: Displays a menu of available Wi-Fi networks using `rofi` and allows you to connect to them.

## Dependencies

This Waybar configuration relies on several external packages to function correctly.

*   **`rofi`**: Used for the power menu and the interactive Wi-Fi menu.
*   **`network-manager`**: Provides the `nmcli` tool to manage network connections.
*   **`network-manager-applet`**: A graphical applet for managing network connections, which will appear in the system tray.
*   **`rfkill`**: Used to toggle Wi-Fi and Bluetooth on and off.
*   **`playerctl`**: Controls media players (e.g., Spotify, VLC) for the media module.
*   **`brightnessctl`**: Adjusts screen brightness.
*   **`pamixer`**: Controls audio volume for both speakers and microphone.
*   **`hyprlock`**: The screen locker used in the power menu (specific to the Hyprland compositor).
*   **`blueberry`**: A Bluetooth configuration utility.

### Installation

You can install these dependencies using your distribution's package manager.

**Arch Linux:**
```bash
sudo pacman -S rofi networkmanager network-manager-applet rfkill playerctl brightnessctl pamixer hyprlock blueberry
```

**Ubuntu / Debian:**
```bash
sudo apt-get install rofi network-manager network-manager-gnome rfkill playerctl brightnessctl pamixer hyprlock
```

*Note: `hyprlock` may not be available in the default Ubuntu/Debian repositories. You may need to install it from another source if you are using Hyprland.*

**Installing Hyprlock on Ubuntu from Source:**

If `hyprlock` is not available in your repository, you can build and install it from source:

```bash
git clone https://github.com/hyprwm/hyprlock.git
cd hyprlock
make all
sudo make install
```

**Installing Blueberry on Ubuntu from Source:**

If `blueberry` is not available in your repository, you can build and install it from source:

```bash
# 1. Install general build dependencies
sudo apt update
sudo apt install -y git build-essential devscripts fakeroot \
  python3 python3-gi python3-dbus python3-gi-cairo \
  gir1.2-gtk-3.0 gir1.2-glib-2.0 gir1.2-notify-0.7

# 2. Clone the Blueberry repository
git clone https://github.com/linuxmint/blueberry.git
cd blueberry

# 3. Build the package using dpkg-buildpackage
dpkg-buildpackage -b -us -uc

# 4. Install the resulting .deb package
cd ..
sudo dpkg -i blueberry*.deb
sudo apt -f install
```

## Autostarting `nm-applet`

To have the NetworkManager Applet (`nm-applet`) appear in your Waybar tray, you need to autostart it with your Hyprland session.

1.  **Open your Hyprland configuration file:**
    This is typically located at `~/.config/hypr/hyprland.conf`.

2.  **Add the following line to your Hyprland configuration:**
    ```
    exec-once = nm-applet --indicator &
    ```
    The `--indicator` flag ensures it starts as a tray icon. The `&` runs it in the background, allowing Hyprland to continue loading.

3.  **Reload Hyprland:**
    After saving the Hyprland configuration, reload it (e.g., by running `hyprctl reload` in a terminal, or logging out and back in).

Once `nm-applet` is running, its icon should appear in the `tray` module of your Waybar, allowing you to manage your Wi-Fi connections graphically.

## Sudo Configuration

The `toggle-bluetooth.sh` and `toggle-wifi.sh` scripts use `rfkill` and require `sudo` to execute. To avoid entering your password every time, you can add rules to your `sudoers` file.

There might be two different `rfkill` executables on your system, one in your user's path and another in the `sudo` secure path. You should add rules for both.

**Warning:** Editing the `sudoers` file can have serious consequences if done incorrectly. Always use `sudo visudo` to edit this file, as it will validate the syntax before saving.

1.  **Find your username:**
    ```bash
    whoami
    ```

2.  **Find the paths to the `rfkill` executables:**
    ```bash
    which rfkill
    sudo which rfkill
    ```

3.  **Open the `sudoers` file for editing:**
    ```bash
    sudo visudo
    ```

4.  **Add the following lines to the end of the file.** Replace `<username>` with your username and the paths with the output from the commands above.

    ```
    <username> ALL=(ALL) NOPASSWD: <path_to_rfkill_from_which>
    <username> ALL=(ALL) NOPASSWD: <path_to_rfkill_from_sudo_which>
    ```

    For example, if your username is `enigma`, `which rfkill` returns `/home/linuxbrew/.linuxbrew/sbin/rfkill`, and `sudo which rfkill` returns `/usr/sbin/rfkill`, you would add:

    ```
    enigma ALL=(ALL) NOPASSWD: /home/linuxbrew/.linuxbrew/sbin/rfkill
    enigma ALL=(ALL) NOPASSWD: /usr/sbin/rfkill
    ```

## Script Permissions

Before the scripts in the `scripts/` directory can be used, they need to be made executable. You can do this by running the following command:

```bash
chmod +x ~/.config/waybar/scripts/*.sh
chmod +x ~/.config/waybar/scripts/*.py
```
