hl.on("hyprland.start", function()
-- -----------------------------------------------------------------------------
-- Programs and Services to Execute at Launch
-- -----------------------------------------------------------------------------

-- Critical for D-Bus / notifications
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")

-- Core desktop services
    hl.exec_cmd("waybar & swaync & hypridle & (which swww-daemon >/dev/null 2>&1 && swww-daemon || hyprpaper)")
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")

-- Polkit authentication agent
    hl.exec_cmd(
    	'sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"'
    )

-- Clipboard history
    hl.exec_cmd("wl-paste --watch cliphist store")

-- Network manager applet
    hl.exec_cmd("nm-applet --indicator")

-- -----------------------------------------------------------------------------
-- Custom Scripts
-- -----------------------------------------------------------------------------

    hl.exec_cmd("~/.config/hypr/scripts/set_wallpaper.sh --init")

-- Start monitor event listener for automatic profile switching
    hl.exec_cmd("~/.config/hypr/scripts/launch_monitor_listener.sh")

-- Start battery monitor (low-charge alerts + auto power-profile switching)
    hl.exec_cmd("~/.config/hypr/scripts/launch_battery_monitor.sh")
end)
