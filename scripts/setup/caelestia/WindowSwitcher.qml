pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

Scope {
    id: root

    property bool isOpen: false
    property bool closing: false
    property bool altHeld: false
    property int selectedIndex: 0
    property list<HyprlandToplevel> snapshotClients: []
    property var mruAddresses: []

    readonly property HyprlandToplevel selectedClient: (selectedIndex >= 0 && selectedIndex < snapshotClients.length) ? snapshotClients[selectedIndex] : null

    function normAddr(addr: string): string {
        if (!addr)
            return "";
        return addr.startsWith("0x") ? addr.toLowerCase() : `0x${addr.toLowerCase()}`;
    }

    function clientAddr(t: HyprlandToplevel): string {
        return normAddr(t?.lastIpcObject?.address ?? t?.address ?? "");
    }

    function seedMruFromIpc(): void {
        const list = [...Hypr.toplevels.values].filter(t => t?.lastIpcObject?.mapped && t?.lastIpcObject?.class);
        list.sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 9999) - (b.lastIpcObject?.focusHistoryID ?? 9999));
        const addrs = list.map(t => root.clientAddr(t)).filter(a => a.length > 0);
        if (addrs.length > 0)
            root.mruAddresses = addrs;
    }

    function recordActive(t: HyprlandToplevel): void {
        if (!t || root.isOpen)
            return;
        const addr = root.clientAddr(t);
        if (!addr)
            return;
        const next = [addr, ...root.mruAddresses.filter(a => a !== addr)];
        root.mruAddresses = next.slice(0, 64);
    }

    function collectOrderedClients(): list<HyprlandToplevel> {
        const valid = [...Hypr.toplevels.values].filter(t => {
            const ipc = t?.lastIpcObject;
            return ipc?.mapped && ipc?.class;
        });

        const activeAddr = root.clientAddr(Hypr.activeToplevel);
        valid.sort((a, b) => {
            const addrA = root.clientAddr(a);
            const addrB = root.clientAddr(b);
            if (addrA === activeAddr && addrB !== activeAddr)
                return -1;
            if (addrB === activeAddr && addrA !== activeAddr)
                return 1;
            const idxA = root.mruAddresses.indexOf(addrA);
            const idxB = root.mruAddresses.indexOf(addrB);
            if (idxA !== -1 && idxB !== -1)
                return idxA - idxB;
            if (idxA !== -1)
                return -1;
            if (idxB !== -1)
                return 1;
            return (a.lastIpcObject?.focusHistoryID ?? 9999) - (b.lastIpcObject?.focusHistoryID ?? 9999);
        });

        return valid;
    }

    function stepSelection(delta: int, holdAlt: bool): void {
        if (!root.isOpen || root.closing) {
            const list = collectOrderedClients();
            if (list.length === 0)
                return;

            root.snapshotClients = list;
            root.altHeld = holdAlt;
            root.closing = false;

            if (list.length === 1) {
                root.selectedIndex = 0;
            } else if (delta >= 0) {
                root.selectedIndex = 1;
            } else {
                root.selectedIndex = list.length - 1;
            }

            root.isOpen = true;
            loader.activeAsync = true;
            Hyprland.refreshToplevels();
        } else {
            const len = root.snapshotClients.length;
            if (len > 0)
                root.selectedIndex = (root.selectedIndex + delta + len) % len;
        }
    }

    function focusClient(client: HyprlandToplevel): void {
        const addr = root.clientAddr(client);
        if (!addr)
            return;
        root.mruAddresses = [addr, ...root.mruAddresses.filter(a => a !== addr)].slice(0, 64);
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:${addr}" })` : `focuswindow address:${addr}`);
    }

    function confirm(): void {
        if (!root.isOpen || root.closing)
            return;
        const target = root.selectedClient;
        root.closing = true;
        root.isOpen = false;
        root.altHeld = false;
        if (target)
            root.focusClient(target);
        closeTimer.restart();
    }

    function cancel(): void {
        if (!root.isOpen || root.closing)
            return;
        root.closing = true;
        root.isOpen = false;
        root.altHeld = false;
        closeTimer.restart();
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        seedMruFromIpc();
    }

    Connections {
        function onActiveToplevelChanged(): void {
            root.recordActive(Hypr.activeToplevel);
        }

        target: Hypr
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "openwindow" || event.name === "closewindow") {
                Hyprland.refreshToplevels();
                if (root.isOpen && !root.closing) {
                    const updated = root.collectOrderedClients();
                    if (updated.length === 0) {
                        root.cancel();
                    } else {
                        root.snapshotClients = updated;
                        if (root.selectedIndex >= updated.length)
                            root.selectedIndex = updated.length - 1;
                    }
                }
            }
        }

        target: Hyprland
    }

    Timer {
        id: closeTimer

        interval: 180
        onTriggered: {
            if (!root.isOpen) {
                root.closing = false;
                loader.activeAsync = false;
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherNext"
        description: "Switch to next window (MRU)"
        onPressed: root.stepSelection(1, true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherPrev"
        description: "Switch to previous window (MRU)"
        onPressed: root.stepSelection(-1, true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherConfirm"
        description: "Confirm window switcher selection on Alt release"
        onPressed: {
            if (root.isOpen && root.altHeld && !root.closing)
                root.confirm();
        }
    }

    IpcHandler {
        function open(): void {
            root.stepSelection(1, false);
        }

        function next(): void {
            root.stepSelection(1, false);
        }

        function prev(): void {
            root.stepSelection(-1, false);
        }

        function confirm(): void {
            root.confirm();
        }

        function cancel(): void {
            root.cancel();
        }

        target: "windowSwitcher"
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            readonly property int cardWidth: 276
            readonly property int cardHeight: 196
            readonly property int cardSpacing: 14
            readonly property int maxVisibleCards: Math.max(2, Math.min(5, Math.floor((screen.width * 0.86) / (cardWidth + cardSpacing))))
            readonly property int visibleCards: Math.max(1, Math.min(root.snapshotClients.length, maxVisibleCards))
            readonly property int stripWidth: visibleCards * cardWidth + Math.max(0, visibleCards - 1) * cardSpacing

            name: "window-switcher"
            screen: Screens.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Screens.screens[0]

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.isOpen && !root.closing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: root.closing ? emptyRegion : null

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Region {
                id: emptyRegion
            }

            Item {
                id: keyReceiver

                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.confirm();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab) {
                        root.stepSelection((event.modifiers & Qt.ShiftModifier) ? -1 : 1, root.altHeld);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab) {
                        root.stepSelection(-1, root.altHeld);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_J) {
                        root.stepSelection(1, root.altHeld);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_K) {
                        root.stepSelection(-1, root.altHeld);
                        event.accepted = true;
                    }
                }

                Keys.onReleased: event => {
                    if (root.altHeld && (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr)) {
                        root.confirm();
                        event.accepted = true;
                    }
                }

                // Subtle dim scrim; clicking outside cancels switcher
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, root.isOpen && !root.closing ? 0.22 : 0)

                    Behavior on color {
                        CAnim {}
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.cancel()
                    }
                }

                // Centered Frosted-Glass Switcher Dock
                StyledRect {
                    id: switcherPanel

                    anchors.centerIn: parent
                    implicitWidth: win.stripWidth + Tokens.padding.extraLarge * 2
                    implicitHeight: panelCol.implicitHeight + Tokens.padding.largeIncreased * 2

                    color: Colours.tPalette.m3surface
                    radius: Tokens.rounding.extraLarge
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    opacity: root.isOpen && !root.closing ? 1 : 0
                    scale: root.isOpen && !root.closing ? 1 : 0.92

                    Component.onCompleted: {
                        opacity = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0);
                        scale = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0.92);
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    // Absorb background clicks inside the dock
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: panelCol

                        anchors.centerIn: parent
                        width: win.stripWidth
                        spacing: Tokens.spacing.medium

                        ListView {
                            id: cardsList

                            Layout.preferredWidth: win.stripWidth
                            Layout.preferredHeight: win.cardHeight + 12
                            orientation: ListView.Horizontal
                            spacing: win.cardSpacing
                            clip: root.snapshotClients.length > win.maxVisibleCards
                            interactive: root.snapshotClients.length > win.maxVisibleCards
                            boundsBehavior: Flickable.StopAtBounds
                            currentIndex: root.selectedIndex
                            highlightFollowsCurrentItem: true
                            highlightRangeMode: ListView.ApplyRange
                            preferredHighlightBegin: 0
                            preferredHighlightEnd: width - win.cardWidth
                            highlightMoveDuration: 220

                            model: root.snapshotClients

                            delegate: Item {
                                id: cardWrapper

                                required property HyprlandToplevel modelData
                                required property int index

                                readonly property bool isSelected: index === root.selectedIndex
                                readonly property var ipc: modelData?.lastIpcObject ?? null
                                readonly property string appClass: ipc?.class ?? ""
                                readonly property string wsName: {
                                    const raw = modelData?.workspace?.name ?? String(ipc?.workspace?.id ?? "");
                                    if (raw.startsWith("special:"))
                                        return raw.slice(8);
                                    return raw ? `WS ${raw}` : "";
                                }

                                width: win.cardWidth
                                height: cardsList.height

                                StyledRect {
                                    id: cardBg

                                    anchors.centerIn: parent
                                    width: win.cardWidth
                                    height: win.cardHeight
                                    radius: Tokens.rounding.largeIncreased

                                    color: cardWrapper.isSelected
                                        ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.88)
                                        : cardHover.containsMouse
                                            ? Colours.tPalette.m3surfaceContainerHigh
                                            : Colours.tPalette.m3surfaceContainer
                                    border.width: cardWrapper.isSelected ? 2 : 1
                                    border.color: cardWrapper.isSelected ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)

                                    scale: cardWrapper.isSelected ? 1.03 : (cardHover.containsMouse ? 0.99 : 0.96)
                                    opacity: cardWrapper.isSelected ? 1.0 : (cardHover.containsMouse ? 0.92 : 0.76)

                                    Behavior on scale {
                                        Anim {
                                            type: Anim.FastSpatial
                                        }
                                    }

                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }

                                    Behavior on color {
                                        CAnim {}
                                    }

                                    Behavior on border.color {
                                        CAnim {}
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.medium
                                        spacing: Tokens.spacing.small

                                        // Card Header: App Icon + Title + Workspace Pill
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Tokens.spacing.small

                                            IconImage {
                                                asynchronous: true
                                                implicitSize: 20
                                                Layout.alignment: Qt.AlignVCenter
                                                source: Icons.getAppIcon(cardWrapper.appClass, "application-x-executable")
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: cardWrapper.modelData?.title || cardWrapper.appClass
                                                font: Tokens.font.body.small
                                                color: cardWrapper.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                                elide: Text.ElideRight
                                            }

                                            StyledRect {
                                                visible: cardWrapper.wsName.length > 0
                                                implicitWidth: wsLabel.implicitWidth + Tokens.padding.small * 2
                                                implicitHeight: wsLabel.implicitHeight + 4
                                                radius: Tokens.rounding.small
                                                color: cardWrapper.isSelected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest

                                                StyledText {
                                                    id: wsLabel

                                                    anchors.centerIn: parent
                                                    text: cardWrapper.wsName
                                                    font: Tokens.font.body.small
                                                    color: cardWrapper.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                                }
                                            }
                                        }

                                        // Live 60fps Window Preview Thumbnail
                                        StyledRect {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Tokens.rounding.medium
                                            color: Colours.tPalette.m3surfaceContainerLowest

                                            ClippingWrapperRectangle {
                                                anchors.centerIn: parent
                                                color: "transparent"
                                                radius: Tokens.rounding.small

                                                ScreencopyView {
                                                    captureSource: cardWrapper.modelData?.wayland ?? null
                                                    live: visible
                                                    constraintSize.width: win.cardWidth - Tokens.padding.medium * 2 - 4
                                                    constraintSize.height: win.cardHeight - 54
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: cardHover

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedIndex = cardWrapper.index;
                                            root.confirm();
                                        }
                                    }
                                }
                            }
                        }

                        // Selected Window Full Title Caption
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: root.selectedClient?.title || (root.selectedClient?.lastIpcObject?.class ?? "")
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideMiddle
                            animate: true
                        }
                    }
                }
            }
        }
    }
}
