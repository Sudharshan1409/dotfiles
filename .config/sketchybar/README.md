# SketchyBar Configuration

This is a basic configuration for SketchyBar, a customizable status bar for macOS. This configuration is intentionally kept simple to allow for easy customization and extension.

## Overview

- **Bar Appearance**: The bar is positioned at the top with a height of 30 and a blur radius of 30. The background color is set to a semi-transparent black.
- **Defaults**: Default item properties include padding, font settings, and color configurations.
- **Mission Control Space Indicators**: Dynamically adds items to represent active and available mission control spaces.
- **Left Items**: Includes items like `chevron` and `front_app` with specific icon and script settings.
- **Right Items**: Includes items like `clock`, `volume`, and `battery`, each with update frequencies and event subscriptions.

## Setup

1. **Install SketchyBar**: Follow the installation instructions on the [SketchyBar GitHub page](https://github.com/FelixKratz/SketchyBar).
2. **Clone or Copy Configuration**: Place this configuration in your SketchyBar config directory, typically `~/.config/sketchybar/`.
3. **Customize**: Modify the configuration to suit your preferences. Refer to the [SketchyBar documentation](https://felixkratz.github.io/SketchyBar/) for more options and customization tips.
4. **Run SketchyBar**: Start or restart SketchyBar to apply the configuration.

## Resources

- [SketchyBar Documentation](https://felixkratz.github.io/SketchyBar/)
- [Color Picker](https://felixkratz.github.io/SketchyBar/config/tricks#color-picker)
- [FelixKratz's Dotfiles](https://github.com/FelixKratz/dotfiles) for advanced configuration examples.

## Notes

- This configuration is a starting point. Feel free to explore and modify it to create a personalized status bar.
- Ensure all scripts referenced in the configuration are executable and located in the specified directories.

Enjoy your customized SketchyBar setup!
