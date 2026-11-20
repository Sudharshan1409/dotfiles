hl.on("hyprland.start", function()
-- -----------------------------------------------------------------------------
-- Programs and Services to Execute at Launch
-- -----------------------------------------------------------------------------

-- Propagate Wayland & Hyprland session variables to D-Bus and systemd --user,
-- then launch self-healing Caelestia Shell & Cliphist watchdog services
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE ELECTRON_OZONE_PLATFORM_HINT OZONE_PLATFORM DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE CAELESTIA_WALLPAPERS_DIR CAELESTIA_LIB_DIR PATH && "
        .. "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE ELECTRON_OZONE_PLATFORM_HINT OZONE_PLATFORM DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE CAELESTIA_WALLPAPERS_DIR CAELESTIA_LIB_DIR PATH && "
        .. "systemctl --user daemon-reload && "
        .. "systemctl --user restart caelestia-shell.service cliphist.service"
    )

-- Cursor theme
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")

-- Polkit authentication agent (supports KDE & GNOME agents on Ubuntu and Arch)
    hl.exec_cmd(
    	'sh -c "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 || /usr/lib/polkit-kde-authentication-agent-1 || /usr/libexec/polkit-kde-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"'
    )

-- -----------------------------------------------------------------------------
-- Custom Scripts
-- -----------------------------------------------------------------------------

-- Start monitor event listener for automatic profile switching
    hl.exec_cmd("~/.config/hypr/scripts/launch_monitor_listener.sh")
end)
