# Zellij Configuration

This directory contains configuration files for Zellij, a terminal workspace and multiplexer.

## Files

- **config.kdl**: This is the main configuration file for Zellij. It defines keybindings, plugins, and various settings to customize the behavior and appearance of Zellij.

- **config.kdl.bak**: This is a backup of the main configuration file. It can be used to restore the original settings if needed.

## Key Sections in `config.kdl`

- **Keybindings**: Customize how keys are mapped to actions in different modes such as normal, locked, resize, pane, move, tab, scroll, search, and more.

- **Plugins**: Define and configure plugins to extend the functionality of Zellij.

- **Session Management**: Configure how sessions are handled, including serialization, session metadata, and session mirroring.

- **Appearance and Behavior**: Set themes, layout preferences, mouse mode, and other visual and interactive settings.

### Cloning Configuration

To clone the configuration repository and set it up, use the following commands:

#### Using HTTPS

```bash
git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/zellij
```

### For SSH

```bash
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/zellij
```

## Usage

To apply changes made in these configuration files, restart Zellij. Ensure that any modifications are correctly formatted in KDL (KDL is a document language similar to JSON or YAML).

For more information on configuring Zellij, visit the [official documentation](https://zellij.dev/documentation/).

```

```
