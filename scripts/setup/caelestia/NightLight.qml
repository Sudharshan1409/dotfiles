pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n
import qs.components.misc

Singleton {
    id: root

    property bool active: false
    property int temperature: 4200

    function toggle(): void {
        active = !active;
        notifyState();
    }

    function enable(): void {
        if (!active) {
            active = true;
            notifyState();
        }
    }

    function disable(): void {
        if (active) {
            active = false;
            notifyState();
        }
    }

    function notifyState(): void {
        if (active)
            Toaster.toast(Tr.tr("Night Light enabled"), Tr.tr("Warm %1K eye-comfort filter active").arg(temperature), "bedtime");
        else
            Toaster.toast(Tr.tr("Night Light disabled"), Tr.tr("Standard 6500K display colour restored"), "wb_sunny");
    }

    Process {
        id: wlsunsetProc

        running: root.active
        command: ["sh", "-c", `export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; exec wlsunset -t ${root.temperature} -T ${root.temperature + 1}`]
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "nightLightToggle"
        description: "Toggle Night Light blue-light filter"
        onPressed: root.toggle()
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enable();
        }

        function disable(): void {
            root.disable();
        }

        function isEnabled(): bool {
            return root.active;
        }

        target: "nightLight"
    }
}
