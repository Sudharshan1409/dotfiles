#!/usr/bin/env python3
"""Idempotently apply custom Caelestia Shell QML enhancements (Ubuntu & Arch)."""

from pathlib import Path
import shutil
import sys


def patch_tree(cael_dir: Path, assets_dir: Path) -> bool:
    if not (cael_dir / "shell.qml").exists():
        return False

    changed = False

    # 1. Copy CalendarPopout.qml for taskbar clock hover popout
    cal_src = assets_dir / "CalendarPopout.qml"
    cal_dst = cael_dir / "modules/bar/popouts/CalendarPopout.qml"
    if cal_src.exists() and cal_dst.parent.is_dir():
        src_text = cal_src.read_text()
        if not cal_dst.exists() or cal_dst.read_text() != src_text:
            shutil.copyfile(cal_src, cal_dst)
            changed = True

    # 2. Wire clock hover -> "calendar" popout in modules/bar/Bar.qml
    bar_p = cael_dir / "modules/bar/Bar.qml"
    if bar_p.exists():
        b = bar_p.read_text()
        if 'popouts.currentName = "calendar"' not in b:
            target = """        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = (ch.item as Item).mapToItem(root, 0, (ch.item as Item).implicitHeight / 2).y ?? 0;
            popouts.hasCurrent = true;
        }"""
            replacement = target[:-1] + """ else if (id === "clock") {
            const clockItem = ch.item as Item;
            popouts.currentName = "calendar";
            popouts.currentCenter = Qt.binding(() => clockItem.mapToItem(root, 0, clockItem.implicitHeight / 2).y);
            popouts.hasCurrent = true;
        } else {
            popouts.hasCurrent = false;
        }"""
            if target in b:
                bar_p.write_text(b.replace(target, replacement, 1))
                changed = True

    # 3. Register Popout { name: "calendar" } in modules/bar/popouts/Content.qml
    pop_p = cael_dir / "modules/bar/popouts/Content.qml"
    if pop_p.exists():
        p = pop_p.read_text()
        if 'name: "calendar"' not in p:
            target = """        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
        }"""
            replacement = target + """

        Popout {
            name: "calendar"
            sourceComponent: CalendarPopout {}
        }"""
            if target in p:
                pop_p.write_text(p.replace(target, replacement, 1))
                changed = True

    # 4. Fix Nexus ToggleRow full-row click handling so Switch toggles & persists reliably
    tog_p = cael_dir / "modules/nexus/common/ToggleRow.qml"
    if tog_p.exists():
        t = tog_p.read_text()
        if "acceptedButtons: Qt.NoButton" not in t:
            target = """        StateLayer {
            id: stateLayer

            disabled: root.disabled"""
            replacement = """        StateLayer {
            id: stateLayer

            acceptedButtons: Qt.NoButton
            disabled: root.disabled"""
            if target in t:
                tog_p.write_text(t.replace(target, replacement, 1))
                changed = True

    # 5. Match distro logo icon weight with default Caelestia logo in OsIcon.qml
    os_p = cael_dir / "modules/bar/components/OsIcon.qml"
    if os_p.exists():
        o = os_p.read_text()
        if "pointSize * 1.2)" in o and "id: distroIcon" in o:
            old_blk = """    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.2)
            colour: Colours.palette.m3tertiary
        }
    }"""
            new_blk = old_blk.replace("pointSize * 1.2)", "pointSize * 1.55)")
            if old_blk in o:
                os_p.write_text(o.replace(old_blk, new_blk, 1))
                changed = True

    # 6. Auto-resolve Ubuntu's vector Yaru distro emblem in SysInfo.qml (keeps shell.json portable across Ubuntu & Arch)
    sys_p = cael_dir / "utils/SysInfo.qml"
    if sys_p.exists():
        s = sys_p.read_text()
        target = '            const logo = Quickshell.iconPath(fd("LOGO"), true);'
        if "yaruLogo" not in s and target in s:
            replacement = (
                '            const yaruLogo = "/usr/share/icons/Yaru/scalable/places/distributor-logo-symbolic.svg";\n'
                '            const logo = Quickshell.iconPath(fd("LOGO"), true) || (root.osId === "ubuntu" ? `file://${yaruLogo}` : "");'
            )
            sys_p.write_text(s.replace(target, replacement, 1))
            changed = True

    # 7. Add direct 'caelestia shell wallpaper picker' IPC handler in services/Wallpapers.qml
    wall_p = cael_dir / "services/Wallpapers.qml"
    if wall_p.exists():
        w = wall_p.read_text()
        if "openPickerRequested" not in w:
            w = w.replace(
                "    property bool showPreview: false\n",
                "    property bool showPreview: false\n    property bool openPickerRequested: false\n",
                1,
            )
            w = w.replace(
                '        target: "wallpaper"',
                '''        function picker(): void {
            const screenState = ShellState.forActive();
            if (!screenState)
                return;
            if (screenState.launcher) {
                const search = ShellState.componentsForActive()?.find("launcherSearch", null);
                if (search && search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)) {
                    screenState.launcher = false;
                    return;
                }
                if (search) {
                    search.text = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
                    search.forceActiveFocus();
                    return;
                }
            }
            root.openPickerRequested = true;
            screenState.launcher = true;
        }

        target: "wallpaper"''',
                1,
            )
            wall_p.write_text(w)
            changed = True

    # 8. Add Left/Right arrow navigation & openPickerRequested support in modules/launcher/Content.qml
    cont_p = cael_dir / "modules/launcher/Content.qml"
    if cont_p.exists():
        c = cont_p.read_text()
        cont_changed = False
        if "onLeftPressed" not in c:
            c = c.replace(
                "        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()",
                """        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()
        Keys.onLeftPressed: event => {
            if (list.showWallpapers) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }
        Keys.onRightPressed: event => {
            if (list.showWallpapers) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }""",
                1,
            )
            cont_changed = True
        if "openPickerRequested" not in c:
            c = c.replace(
                '        objectName: "launcherSearch"',
                '        objectName: "launcherSearch"\n        text: Wallpapers.openPickerRequested ? `${GlobalConfig.launcher.actionPrefix}wallpaper ` : ""',
                1,
            )
            c = c.replace(
                """        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
            }""",
                """        Component.onCompleted: {
            if (Wallpapers.openPickerRequested) {
                text = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
                Wallpapers.openPickerRequested = false;
            }
            forceActiveFocus();
        }

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher) {
                    search.text = "";
                } else if (Wallpapers.openPickerRequested) {
                    Wallpapers.openPickerRequested = false;
                    search.text = `${GlobalConfig.launcher.actionPrefix}wallpaper `;
                }
            }""",
                1,
            )
            cont_changed = True
        if cont_changed:
            cont_p.write_text(c)
            changed = True

    return changed


def main() -> int:
    assets_dir = Path(__file__).resolve().parent / "caelestia"
    user_cael = Path.home() / ".config/quickshell/caelestia"
    if user_cael.is_dir():
        patch_tree(user_cael, assets_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
