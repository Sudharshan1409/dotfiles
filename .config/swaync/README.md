# Sway Notification Center (swaync)

Configuration for `swaync`, a notification daemon for Wayland compositors like Sway and Hyprland.

## Configuration Files

*   `config.json`: Main configuration for swaync's behavior and layout.
*   `style.css`: CSS for styling the notification center.

## Ubuntu Configuration

For `swaync` to display icons correctly on Ubuntu, you may need to modify the `style.css` file.

Run the following command to apply the necessary changes:

```bash
sed -i "s/-gtk-icon-size: /min-width: /g; s/rem;/rem; min-height: 1.8rem;/g" ~/.config/swaync/style.css
```

This command adjusts the CSS to ensure icons have a minimum width and height, which fixes a rendering issue on Ubuntu.
