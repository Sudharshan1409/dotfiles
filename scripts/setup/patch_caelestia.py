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
        if "Qt.Key_L" not in c:
            c = c.replace(
                "if (event.key === Qt.Key_J || event.key === Qt.Key_N) {",
                "if (event.key === Qt.Key_J || event.key === Qt.Key_L || event.key === Qt.Key_N) {",
                1,
            )
            c = c.replace(
                "} else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {",
                "} else if (event.key === Qt.Key_K || event.key === Qt.Key_H || event.key === Qt.Key_P) {",
                1,
            )
            cont_changed = True
        if cont_changed:
            cont_p.write_text(c)
            changed = True

    # 9. Hybrid Workspace Hover Preview (Mini-Desktop on workspace shape, Single-Window on app icon)
    wsp_src = assets_dir / "WorkspacePopout.qml"
    wsp_dst = cael_dir / "modules/bar/popouts/WorkspacePopout.qml"
    if wsp_src.exists() and wsp_dst.parent.is_dir():
        src_text = wsp_src.read_text()
        if not wsp_dst.exists() or wsp_dst.read_text() != src_text:
            shutil.copyfile(wsp_src, wsp_dst)
            changed = True

    pstate_p = cael_dir / "modules/bar/popouts/PopoutState.qml"
    if pstate_p.exists():
        ps = pstate_p.read_text()
        if "hoveredWorkspace" not in ps:
            ps = ps.replace(
                "    property bool hasCurrent\n",
                "    property bool hasCurrent\n    property int hoveredWorkspace: 1\n    property var hoveredToplevel: null\n    property var detachToplevel: null\n",
                1,
            )
            pstate_p.write_text(ps)
            changed = True

    wrap_p = cael_dir / "modules/bar/popouts/Wrapper.qml"
    if wrap_p.exists():
        wr = wrap_p.read_text()
        wr_changed = False
        if "hoveredWorkspace" not in wr:
            wr = wr.replace(
                "    property alias hasCurrent: popoutState.hasCurrent\n",
                "    property alias hasCurrent: popoutState.hasCurrent\n    property alias hoveredWorkspace: popoutState.hoveredWorkspace\n    property alias hoveredToplevel: popoutState.hoveredToplevel\n",
                1,
            )
            wr_changed = True
        if "detachToplevel = null" not in wr:
            wr = wr.replace(
                '        detachedMode = "";\n',
                '        detachedMode = "";\n        popoutState.detachToplevel = null;\n',
                1,
            )
            wr = wr.replace(
                "            client: Hypr.activeToplevel",
                "            client: popoutState.detachToplevel ?? Hypr.activeToplevel",
                1,
            )
            wr_changed = True
        if wr_changed:
            wrap_p.write_text(wr)
            changed = True

    if pop_p.exists():
        p = pop_p.read_text()
        if 'name: "workspace"' not in p:
            target = """        Popout {
            name: "calendar"
            sourceComponent: CalendarPopout {}
        }"""
            replacement = target + """

        Popout {
            name: "workspace"
            sourceComponent: WorkspacePopout {
                popouts: root.popouts
                screen: QsWindow.window?.screen ?? null
            }
        }"""
            if target in p:
                pop_p.write_text(p.replace(target, replacement, 1))
                changed = True

    ws_item_p = cael_dir / "modules/bar/components/workspaces/Workspace.qml"
    if ws_item_p.exists():
        wi = ws_item_p.read_text()
        if "function hitTest(" not in wi:
            wi = wi.replace(
                """        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }""",
                """        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    function hitTest(barItem: Item, barY: real): var {
        if (!isOccupied)
            return null;
        const winList = windows.item as LazyListView;
        if (hasWindows && winList) {
            const localY = barItem.mapToItem(winList, 0, barY).y;
            if (localY >= 0 && localY <= winList.height) {
                const winIcon = winList.itemAt(winList.width / 2, localY) as WinIcon;
                if (winIcon && winIcon.modelData) {
                    return {
                        ws: root.ws,
                        toplevel: winIcon.modelData,
                        targetItem: winIcon
                    };
                }
            }
        }
        return {
            ws: root.ws,
            toplevel: null,
            targetItem: indicator
        };
    }""",
                1,
            )
            old_del = """                delegate: MaterialIcon {
                    id: win

                    required property var modelData
                    required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    grade: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                    opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on y {
                        Anim {}
                    }
                }
            }
        }
    }"""
            new_del = """                delegate: WinIcon {}
            }
        }
    }

    component WinIcon: MaterialIcon {
        id: win

        required property var modelData
        required property int index // Needed, LazyListView will fail to set it if it doesn't exist

        grade: 0
        horizontalAlignment: Text.AlignHCenter
        text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
        color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

        opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on y {
            Anim {}
        }
    }"""
            wi = wi.replace(old_del, new_del, 1)
            ws_item_p.write_text(wi)
            changed = True

    ws_list_p = cael_dir / "modules/bar/components/workspaces/Workspaces.qml"
    if ws_list_p.exists():
        wl = ws_list_p.read_text()
        if "function hitTest(" not in wl:
            wl = wl.replace(
                "        return index % shown;\n    }",
                """        return index % shown;
    }

    function hitTest(barItem: Item, barY: real): var {
        if (onSpecial)
            return null;
        const listY = barItem.mapToItem(workspaces, 0, barY).y;
        const wsItem = workspaces.itemAt(workspaces.width / 2, listY) as Workspace;
        return wsItem ? wsItem.hitTest(barItem, barY) : null;
    }""",
                1,
            )
            ws_list_p.write_text(wl)
            changed = True

    if bar_p.exists():
        b = bar_p.read_text()
        if 'popouts.currentName = "workspace"' not in b:
            b = b.replace(
                '        } else if (id === "clock") {',
                """        } else if (id === "workspaces") {
            const hit = (ch.item as Workspaces).hitTest(root, y);
            if (hit) {
                const target = hit.targetItem as Item;
                popouts.hoveredWorkspace = hit.ws;
                popouts.hoveredToplevel = hit.toplevel;
                popouts.currentName = "workspace";
                popouts.currentCenter = Qt.binding(() => target ? target.mapToItem(root, 0, target.height / 2).y : 0);
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "clock") {""",
                1,
            )
            bar_p.write_text(b)
            changed = True

    # 10. AreaPicker (Picker.qml): prefer Satty (Ubuntu/Arch) with fallback to Swappy or direct save+copy
    picker_p = cael_dir / "modules/areapicker/Picker.qml"
    if picker_p.exists():
        pk = picker_p.read_text()
        old_swappy = '                Quickshell.execDetached(["swappy", "-f", path]);'
        new_satty = """                Quickshell.execDetached(["sh", "-c", 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; OUT="$HOME/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"; mkdir -p "$HOME/Pictures/Screenshots"; if command -v satty >/dev/null 2>&1; then satty --filename "$1" --output-filename "$OUT" --early-exit --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy; elif command -v swappy >/dev/null 2>&1; then swappy -f "$1" -o "$OUT"; else cp "$1" "$OUT" && wl-copy --type image/png < "$OUT" && notify-send -a caelestia-cli -i "$OUT" "Screenshot Captured" "Saved to $OUT and copied to clipboard"; fi; rm -f "$1"', "sh", path]);"""
        if old_swappy in pk:
            picker_p.write_text(pk.replace(old_swappy, new_satty, 1))
            changed = True

    # 11. Live Visual Alt+Tab WindowSwitcher, Mission Control WorkspaceOverview, Visual Clipboard & NightLight
    custom_modules = [
        ("WindowSwitcher.qml", "modules/windowswitcher/WindowSwitcher.qml"),
        ("WorkspaceOverview.qml", "modules/workspaceoverview/WorkspaceOverview.qml"),
        ("ClipboardModal.qml", "modules/clipboard/ClipboardModal.qml"),
        ("NightLight.qml", "services/NightLight.qml"),
        ("ProfilePic.qml", "modules/lock/center/ProfilePic.qml"),
    ]
    for src_name, rel_dst in custom_modules:
        src_p = assets_dir / src_name
        dst_p = cael_dir / rel_dst
        if src_p.exists():
            dst_p.parent.mkdir(parents=True, exist_ok=True)
            src_text = src_p.read_text()
            if not dst_p.exists() or dst_p.read_text() != src_text:
                shutil.copyfile(src_p, dst_p)
                changed = True

    # Wire NightLight toggle button into Quick Utilities (modules/utilities/cards/Toggles.qml)
    util_tog_p = cael_dir / "modules/utilities/cards/Toggles.qml"
    if util_tog_p.exists():
        ut = util_tog_p.read_text()
        ut_orig = ut
        if '"nightLight"' not in ut:
            old_filter = """            seenIds.add(item.id);
            return true;
        });"""
            new_filter = """            seenIds.add(item.id);
            return true;
        }).concat([{ id: "nightLight", enabled: true }]);"""
            ut = ut.replace(old_filter, new_filter, 1)

            old_choice = """                DelegateChoice {
                    roleValue: "dnd" """
            # Match exact dnd DelegateChoice header
            ut = ut.replace(
                '                DelegateChoice {\n                    roleValue: "dnd"',
                """                DelegateChoice {
                    roleValue: "nightLight"
                    delegate: Toggle {
                        icon: "bedtime"
                        checked: NightLight.active
                        onClicked: NightLight.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "dnd\"""",
                1,
            )
        if ut != ut_orig:
            util_tog_p.write_text(ut)
            changed = True

    shell_p = cael_dir / "shell.qml"
    if shell_p.exists():
        sh = shell_p.read_text()
        sh_orig = sh
        for mod_imp in (
            "import qs.modules.windowswitcher",
            "import qs.modules.workspaceoverview",
            "import qs.modules.clipboard",
        ):
            if mod_imp not in sh:
                sh = sh.replace("import qs.modules.lock", f"import qs.modules.lock\n{mod_imp}", 1)
        if "NightLight;" not in sh:
            sh = sh.replace("        Brightness;", "        Brightness;\n        NightLight;", 1)
        for mod_inst in ("WindowSwitcher {}", "WorkspaceOverview {}", "ClipboardModal {}"):
            if mod_inst not in sh:
                sh = sh.replace("    AreaPicker {}", f"    AreaPicker {{}}\n    {mod_inst}", 1)
        if sh != sh_orig:
            shell_p.write_text(sh)
            changed = True

    # 12. Balance Lock Screen Center.qml margins for taller portrait ProfilePic & top-align Dashboard User.qml avatar
    lock_center_p = cael_dir / "modules/lock/Center.qml"
    if lock_center_p.exists():
        lc = lock_center_p.read_text()
        old_lc = """    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraExtraLarge * root.centerScale
        Layout.bottomMargin: Tokens.spacing.extraLarge * root.centerScale
        centerWidth: root.centerWidth
    }"""
        new_lc = """    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.large * root.centerScale
        Layout.bottomMargin: Tokens.spacing.medium * root.centerScale
        centerWidth: root.centerWidth
    }"""
        if old_lc in lc:
            lock_center_p.write_text(lc.replace(old_lc, new_lc, 1))
            changed = True

    dash_user_p = cael_dir / "modules/dashboard/dash/User.qml"
    if dash_user_p.exists():
        du = dash_user_p.read_text()
        old_du_1 = """            Visual {
                id: pfp

                anchors.fill: parent
                source: `${Paths.home}/.face`
            }"""
        old_du_2 = """            VisualSource {
                id: pfpVis

                source: `${Paths.home}/.face`
                fillMode: VisualSource.PreserveAspectCrop
                sizeSource: pfp
            }

            Image {
                id: pfp

                readonly property bool ready: status === Image.Ready

                anchors.fill: parent
                source: pfpVis.imagePath
                sourceSize: pfpVis.sourceSize
                asynchronous: true
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: Image.AlignTop
            }"""
        new_du = """            Image {
                id: pfp

                readonly property bool ready: status === Image.Ready

                anchors.fill: parent
                source: `file://${Paths.home}/.face`
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: Image.AlignTop
            }"""
        if old_du_1 in du:
            dash_user_p.write_text(du.replace(old_du_1, new_du, 1))
            changed = True
        elif old_du_2 in du:
            dash_user_p.write_text(du.replace(old_du_2, new_du, 1))
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
