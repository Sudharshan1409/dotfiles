# WezTerm Configuration

This repository contains my custom configuration for [WezTerm](https://wezfurlong.org/wezterm/), a GPU-accelerated cross-platform terminal emulator and multiplexer.

## Installation

### Prerequisites
Make sure you have `wezterm` installed on your system. You can install `wezterm` using the package manager of your choice. For example:

```sh
# On Debian/Ubuntu
sudo apt install flatpak -y && flatpak install flathub org.wezfurlong.wezterm   
flatpak run org.wezfurlong.wezterm
```

```sh
# On macOS
brew install --cask wezterm
```

### Clone the Repository

Clone this repository to your local machine:

For HTTPS

```sh
git clone https://github.com/Sudharshan1409/wezterm-config.git ~/.config/wezterm
```

For SSH

```sh
git clone git@github.com:Sudharshan1409/wezterm-config.git ~/.config/wezterm
```

## Starting WezTerm

Create a wallpaper directory in your home directory with name `wezterm-wallpapers` and copy the wallpapers to the directory.

After copying the configuration files, you can start WezTerm with your custom configuration, feel free to modify the configuration to suit your needs.
