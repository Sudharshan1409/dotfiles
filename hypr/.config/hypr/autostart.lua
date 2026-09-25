-- Autostart programs and background daemons
local home = os.getenv("HOME") or "/home/sudharshan"

hl.on("hyprland.start", function()
    -- Critical for DBus / systemd / desktop notifications
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")

    -- Core desktop UI & daemons
    hl.exec_cmd("waybar & swaync & hypridle & (which swww-daemon >/dev/null 2>&1 && swww-daemon || hyprpaper)")
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")
    hl.exec_cmd('sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"')
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("nm-applet --indicator")

    -- Custom setup scripts
    hl.exec_cmd(home .. "/.config/hypr/scripts/set_wallpaper.sh --init")
    hl.exec_cmd(home .. "/.config/hypr/scripts/launch_monitor_listener.sh")
    hl.exec_cmd(home .. "/.config/hypr/scripts/launch_battery_monitor.sh")
    hl.exec_cmd(home .. "/.config/hypr/scripts/load_monitor_config.sh")
    hl.exec_cmd(home .. "/.config/hypr/scripts/cache_lockscreen_info.sh")

    -- Initial default workspace
    hl.exec_cmd("hyprctl dispatch workspace 2")
end)
