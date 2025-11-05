# Dotfiles Repository

This repository contains configuration files for various tools and applications. Each configuration is organized into its own directory under the `.config` directory. Below is an overview of the configurations available in this repository, along with links to their respective documentation.

## Configurations

### Shell & Terminal

- **Zsh**: Configuration files for Zsh, a powerful shell for interactive use.

  - [Zsh README](.config/zsh/README.md)

- **Kitty**: Configuration files for Kitty, a fast, feature-rich, GPU-accelerated terminal emulator.

  - [Kitty README](.config/kitty/README.md)

- **WezTerm**: Configuration files for WezTerm, a GPU-accelerated terminal emulator.

  - [WezTerm README](.config/wezterm/README.md)

- **Tmux**: Configuration files for Tmux, a terminal multiplexer.

  - [Tmux README](.config/tmux/README.md)

- **Zellij**: Configuration files for Zellij, a terminal workspace and multiplexer.

  - [Zellij README](.config/zellij/README.md)

### Desktop & Window Management

- **Hypr**: Configuration files for Hyprland, a dynamic tiling Wayland compositor.

  - [Hypr README](.config/hypr/README.md)

- **Waybar**: Configuration files for Waybar, a highly customizable Wayland bar for Sway and Wlroots based compositors.

  - [Waybar README](.config/waybar/README.md)

- **Swaync**: Configuration for Swaync, a notification daemon for Wayland.

  - [Swaync README](.config/swaync/README.md)

- **Aerospace**: Configuration files for aerospace-related tools.

  - [Aerospace README](.config/aerospace/README.md)

- **SketchyBar**: Configuration files for SketchyBar, a customizable status bar for macOS.

  - [SketchyBar README](.config/sketchybar/README.md)

### Development

- **Neovim**: Configuration files for Neovim, a highly customizable text editor.

  - [Neovim README](.config/nvim/README.md)

- **Git**: Configuration files for Git version control system.

  - [Git README](.config/git/README.md)

### Command-Line Tools

- **Bat**: Configuration files for Bat, a better alternative for Cat command.
  - [Bat README](.config/bat/README.md)

- **Yazi**: Configuration files for Yazi, a terminal file manager.

  - [Yazi README](.config/yazi/README.md)

## Usage

To use these configurations, clone the repository and copy the desired configuration files to your home directory. Make sure to back up your existing configuration files before replacing them.

## Installation

To manage your dotfiles efficiently, we recommend using `stow`. Below are the installation instructions.

You can install `stow` using Homebrew:

### Install stow

```bash
brew install stow
```

### Using SSH

```bash
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
```

### Using HTTPS

```bash
git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles
```

### Refer configs

```bash
stow .
```
