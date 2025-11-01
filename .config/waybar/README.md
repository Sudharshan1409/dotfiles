# Waybar Configuration

This directory contains the configuration for Waybar, including styles, scripts, and a setup for passwordless `sudo` execution for certain actions.

## Sudo for Waybar Scripts

Some of the scripts used by this Waybar configuration require `sudo` privileges to manage network and bluetooth devices. To avoid being prompted for a password every time, you can install a custom sudoers file.

### Installation

To install the necessary sudo rules, run the following command:

```bash
sudo ~/.config/waybar/scripts/install_sudo_rules.sh
```

This script will create a new file at `/etc/sudoers.d/waybar-scripts-enigma` with the required rules.

### Sudo Rules

The script will add the following rules:

```
# Sudo rules for Waybar scripts for user enigma

enigma ALL=(ALL) NOPASSWD: /home/linuxbrew/.linuxbrew/sbin/rfkill toggle bluetooth
enigma ALL=(ALL) NOPASSWD: /home/linuxbrew/.linuxbrew/sbin/rfkill toggle wifi
enigma ALL=(ALL) NOPASSWD: /home/enigma/dotfiles/.config/waybar/scripts/wifi-menu.sh
```

This allows your user to run the specified commands with `sudo` without being asked for a password.

### Uninstallation

To remove the sudo rules, simply delete the file created by the installation script:

```bash
sudo rm /etc/sudoers.d/waybar-scripts-enigma
```
