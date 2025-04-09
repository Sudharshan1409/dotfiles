# AeroSpace Configuration

This configuration file, `aerospace.toml`, is used to customize the behavior of the AeroSpace window manager on macOS. Below is a detailed explanation of the configuration options available in this file.

## Configuration Options

### General Settings

- **`exec-on-workspace-change`**: Commands to execute when the workspace changes. This can be used to trigger notifications or other actions.
- **`after-startup-command`**: Commands that run after AeroSpace starts up. Useful for setting initial states or configurations.

- **`after-login-command`**: Commands that run after logging into the macOS user session. Requires `start-at-login` to be `true`.

- **`start-at-login`**: Boolean flag to start AeroSpace automatically at login.

### Normalization

- **`enable-normalization-flatten-containers`**: Enables flattening of container hierarchies for a cleaner layout.

- **`enable-normalization-opposite-orientation-for-nested-containers`**: Adjusts orientation for nested containers to optimize space usage.

### Layout and Orientation

- **`accordion-padding`**: Sets the padding size for accordion layouts. Set to `0` to disable padding.

- **`default-root-container-layout`**: Default layout for root containers. Options are `tiles` or `accordion`.

- **`default-root-container-orientation`**: Orientation for root containers. Options are `horizontal`, `vertical`, or `auto`.

### Mouse and Focus

- **`on-focused-monitor-changed`**: Commands to execute when the focused monitor changes, such as moving the mouse to the center of the monitor.

- **`on-focus-changed`**: Command to execute when focus changes, typically to center the mouse on the focused window.

### Miscellaneous

- **`automatically-unhide-macos-hidden-apps`**: Disables the macOS "Hide application" feature if set to `true`.

### Key Mapping

- **`preset`**: Keyboard layout preset, options include `qwerty` and `dvorak`.

### Gaps

- **`gaps`**: Defines the spacing between windows and monitor edges. Can be set per monitor or as a constant value.

### Binding Modes

- **`mode.main.binding`**: Defines key bindings for the main mode, including shortcuts for layout changes, focus, movement, resizing, and workspace management.

- **`mode.service.binding`**: Defines key bindings for the service mode, including commands for reloading the config, resetting layouts, and volume control.

### Window Detection

- **`on-window-detected`**: Rules for automatically moving windows to specific workspaces based on the application ID.

## Usage

1. **Copy the Configuration**: Place a copy of this configuration file at `~/.aerospace.toml`.
2. **Edit as Needed**: Customize the configuration to suit your preferences by editing `~/.aerospace.toml`.
3. **Refer to Documentation**: For a complete list of available commands and options, refer to the [AeroSpace documentation](https://nikitabobko.github.io/AeroSpace/commands).

### Cloning Configuration

To clone the configuration repository and set it up, use the following commands:

#### Using HTTPS

```bash
git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/aerospace
```

### For SSH

```bash
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/aerospace
```

## Installation

### Installing Jankyborders

To install `jankyborders`, you can use Homebrew:

```bash
brew tap FelixKratz/formulae
brew install borders
```

For more information, refer to the [Jankyborders GitHub repository](https://github.com/FelixKratz/JankyBorders).

### Installing Sketchybar

To install `sketchybar`, you can use Homebrew as well:

```bash
brew install sketchybar
```

After installation, you can start `sketchybar` using:

```bash
sketchybar --start
```

For more details, visit the [Sketchybar GitHub repository](https://github.com/FelixKratz/SketchyBar).

## Additional Resources

- [AeroSpace Guide](https://nikitabobko.github.io/AeroSpace/guide)
- [AeroSpace Commands](https://nikitabobko.github.io/AeroSpace/commands)
- [AeroSpace Goodies](https://nikitabobko.github.io/AeroSpace/goodies)

This README provides a comprehensive overview of the `aerospace.toml` configuration file, helping users to effectively customize their AeroSpace environment.

```

```
