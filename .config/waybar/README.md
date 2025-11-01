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

## Sudo Configuration

The `toggle-bluetooth.sh` and `toggle-wifi.sh` scripts now use `rfkill` from your system's `PATH`. They require `sudo` to execute the `rfkill` command. To avoid entering your password every time you toggle Wi-Fi or Bluetooth, you can add a rule to your `sudoers` file.

**Warning:** Editing the `sudoers` file can have serious consequences if done incorrectly. Always use `sudo visudo` to edit this file, as it will validate the syntax before saving.

1.  **Find your username by running this command:**
    ```bash
    whoami
    ```

2.  **Find the path to the `rfkill` executable by running this command:**
    ```bash
    which rfkill
    ```

3.  **Open the `sudoers` file for editing:**
    ```bash
    sudo visudo
    ```

4.  **Add the following line to the end of the file.** Replace `<username>` with the output from step 1 and `<path_to_rfkill>` with the output from step 2.

    ```
    <username> ALL=(ALL) NOPASSWD: <path_to_rfkill>
    ```

    For example, if your username is `enigma` and `rfkill` is located at `/usr/sbin/rfkill`, the line would look like this:

    ```
    enigma ALL=(ALL) NOPASSWD: /usr/sbin/rfkill
    ```
