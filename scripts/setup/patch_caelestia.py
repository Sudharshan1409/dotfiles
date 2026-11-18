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

    return changed


def main() -> int:
    assets_dir = Path(__file__).resolve().parent / "caelestia"
    user_cael = Path.home() / ".config/quickshell/caelestia"
    if user_cael.is_dir():
        patch_tree(user_cael, assets_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
