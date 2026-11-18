hl.on("hyprland.start", function()
-- -----------------------------------------------------------------------------
-- Programs and Services to Execute at Launch
-- -----------------------------------------------------------------------------

-- Critical for D-Bus / notifications
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")

-- Core desktop services
    hl.exec_cmd("caelestia shell -d & hypridle")
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")

-- Polkit authentication agent
    hl.exec_cmd(
    	'sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"'
    )

-- Clipboard history
    hl.exec_cmd("wl-paste --watch cliphist store")

-- -----------------------------------------------------------------------------
-- Custom Scripts
-- -----------------------------------------------------------------------------

-- Start monitor event listener for automatic profile switching
    hl.exec_cmd("~/.config/hypr/scripts/launch_monitor_listener.sh")

-- Start battery monitor (low-charge alerts + auto power-profile switching)
    hl.exec_cmd("~/.config/hypr/scripts/launch_battery_monitor.sh")
end)
