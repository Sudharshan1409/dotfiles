# Tmux Configuration

This is a custom `tmux.conf` configuration file designed to enhance your tmux experience with a variety of plugins, keybindings, and settings. This README.md will guide you through the installation and configuration process.

## Installation

### Prerequisites

Make sure you have `tmux` installed on your system. You can install `tmux` using the package manager of your choice. For example:

```sh
# On Debian/Ubuntu
sudo apt-get install tmux

# On macOS
brew install tmux

# On Arch Linux
sudo pacman -S tmux
```

### Clone the Repository

Clone this repository to your local machine:

For HTTPS

```sh
git clone https://github.com/Sudharshan1409/tmux-config.git ~/.config/tmux
```

For SSH

```sh
git clone git@github.com:Sudharshan1409/tmux-config.git ~/.config/tmux
```

### TPM (Tmux Plugin Manager)

This configuration uses TPM to manage plugins. You can install TPM by running the following command:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

### Plugin Installation

After installing TPM, you can install the plugins by pressing `prefix` + <kbd>I</kbd> (capital `i`) to fetch the plugins.
