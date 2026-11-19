pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

Scope {
    id: root

    property bool isOpen: false
    property bool closing: false
    property int selectedWs: 1
    property int refreshTick: 0

    // Drag-and-drop state for moving windows across workspaces
    property HyprlandToplevel draggingClient: null
    property real dragX: 0
    property real dragY: 0
    property int hoveredDropWs: -1

    function normAddr(addr: string): string {
        if (!addr)
            return "";
        return addr.startsWith("0x") ? addr.toLowerCase() : `0x${addr.toLowerCase()}`;
    }

    function open(): void {
        if (isOpen && !closing)
            return;
        Hyprland.refreshToplevels();
        selectedWs = Math.max(1, Math.min(10, Hypr.activeWsId));
        draggingClient = null;
        hoveredDropWs = -1;
        closing = false;
        isOpen = true;
        refreshTick++;
        loader.activeAsync = true;
    }

    function close(): void {
        if (!isOpen || closing)
            return;
        draggingClient = null;
        hoveredDropWs = -1;
        closing = true;
        isOpen = false;
        closeTimer.restart();
    }

    function toggle(): void {
        if (isOpen && !closing)
            close();
        else
            open();
    }

    function activateWorkspace(wsId: int): void {
        Hypr.focusWorkspace(wsId);
        close();
    }

    function activateClient(client: HyprlandToplevel): void {
        const addr = normAddr(client?.lastIpcObject?.address ?? client?.address ?? "");
        if (addr) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:${addr}" })` : `focuswindow address:${addr}`);
        }
        close();
    }

    function moveClientToWorkspace(client: HyprlandToplevel, targetWs: int): void {
        const addr = normAddr(client?.lastIpcObject?.address ?? client?.address ?? "");
        if (!addr || targetWs < 1 || targetWs > 10)
            return;
        const curWs = client?.workspace?.id ?? client?.lastIpcObject?.workspace?.id ?? -1;
        if (curWs === targetWs)
            return;

        if (Hypr.usingLua) {
            Hypr.dispatch(`hl.dsp.window.move({ window = "address:${addr}", workspace = "${targetWs}", follow = false })`);
        } else {
            Hypr.dispatch(`movetoworkspacesilent ${targetWs},address:${addr}`);
        }
        refreshDelay.restart();
    }

    Timer {
        id: refreshDelay

        interval: 90
        onTriggered: {
            Hyprland.refreshToplevels();
            root.refreshTick++;
        }
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

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (root.isOpen && (event.name === "movewindow" || event.name === "movewindowv2" || event.name === "openwindow" || event.name === "closewindow")) {
                Hyprland.refreshToplevels();
                root.refreshTick++;
            }
        }

        target: Hyprland
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "workspaceOverviewToggle"
        description: "Toggle Mission Control workspace overview"
        onPressed: root.toggle()
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        target: "workspaceOverview"
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            readonly property var monIpc: Hypr.monitorFor(screen)?.lastIpcObject ?? Hypr.focusedMonitor?.lastIpcObject ?? null
            readonly property real monAspect: {
                const w = (monIpc?.width ?? 1920) / (monIpc?.scale || 1);
                const h = (monIpc?.height ?? 1080) / (monIpc?.scale || 1);
                return Math.max(1.2, w / Math.max(1, h));
            }

            readonly property int cols: 5
            readonly property int rows: 2
            readonly property int gridSpacing: 18

            function wsAtGlobalPos(gx: real, gy: real): int {
                for (let i = 0; i < wsRepeater.count; i++) {
                    const item = wsRepeater.itemAt(i) as Item;
                    if (!item)
                        continue;
                    const p = overlayRoot.mapToItem(item, gx, gy);
                    if (p.x >= 0 && p.x <= item.width && p.y >= 0 && p.y <= item.height)
                        return i + 1;
                }
                return -1;
            }

            name: "workspace-overview"
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
                id: overlayRoot

                readonly property int cardWidth: Math.floor((Math.min(win.screen.width * 0.90, 1720) - win.gridSpacing * (win.cols - 1) - Tokens.padding.extraLarge * 2) / win.cols)
                readonly property int canvasHeight: Math.round(cardWidth / win.monAspect)
                readonly property int cardHeight: canvasHeight + 44

                anchors.fill: parent
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_QuoteLeft) {
                        root.close();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.activateWorkspace(root.selectedWs);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        root.selectedWs = (root.selectedWs % 10) + 1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        root.selectedWs = ((root.selectedWs + 8) % 10) + 1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.selectedWs = root.selectedWs <= 5 ? root.selectedWs + 5 : root.selectedWs - 5;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.selectedWs = root.selectedWs > 5 ? root.selectedWs - 5 : root.selectedWs + 5;
                        event.accepted = true;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        root.activateWorkspace(event.key - Qt.Key_0);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_0) {
                        root.activateWorkspace(10);
                        event.accepted = true;
                    }
                }

                // Frosted dim backdrop
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, root.isOpen && !root.closing ? 0.42 : 0)

                    Behavior on color {
                        CAnim {}
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.close()
                    }
                }

                // Centered Mission Control Container
                StyledRect {
                    id: container

                    anchors.centerIn: parent
                    implicitWidth: mainLayout.implicitWidth + Tokens.padding.extraLarge * 2
                    implicitHeight: mainLayout.implicitHeight + Tokens.padding.extraLarge * 2

                    color: Colours.tPalette.m3surface
                    radius: Tokens.rounding.extraLarge
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    opacity: root.isOpen && !root.closing ? 1 : 0
                    scale: root.isOpen && !root.closing ? 1 : 0.94

                    Component.onCompleted: {
                        opacity = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0);
                        scale = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0.94);
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

                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: mainLayout

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.large

                        // Header bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: "grid_view"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                            }

                            StyledText {
                                text: Tr.tr("Workspace Overview")
                                font: Tokens.font.body.large
                                color: Colours.palette.m3onSurface
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: Tr.tr("Click window/workspace to jump  •  Drag window between workspaces  •  1–0 / HJKL  •  Esc")
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        // 2x5 Spatial Workspace Grid
                        GridLayout {
                            id: wsGrid

                            columns: win.cols
                            rowSpacing: win.gridSpacing
                            columnSpacing: win.gridSpacing

                            Repeater {
                                id: wsRepeater

                                model: 10

                                delegate: StyledRect {
                                    id: wsCard

                                    required property int index

                                    readonly property int wsId: index + 1
                                    readonly property bool isActiveWs: Hypr.activeWsId === wsId
                                    readonly property bool isSelected: root.selectedWs === wsId
                                    readonly property bool isDropTarget: root.draggingClient !== null && root.hoveredDropWs === wsId

                                    readonly property var wsClients: {
                                        void root.refreshTick;
                                        const list = Hypr.toplevelsForWs(wsId, GlobalConfig.bar.workspaces.ignoredTags);
                                        return [...list].sort((a, b) => ((a.lastIpcObject?.floating ? 1 : 0) - (b.lastIpcObject?.floating ? 1 : 0)));
                                    }

                                    readonly property var wsMonIpc: {
                                        const wObj = Hypr.workspaces.values.find(w => w.id === wsCard.wsId);
                                        if (wObj?.monitor?.lastIpcObject)
                                            return wObj.monitor.lastIpcObject;
                                        if (wsClients.length > 0) {
                                            const mId = wsClients[0].lastIpcObject?.monitor;
                                            const m = Hypr.monitors.values.find(mon => mon.id === mId);
                                            if (m?.lastIpcObject)
                                                return m.lastIpcObject;
                                        }
                                        return win.monIpc;
                                    }
                                    readonly property real mX: wsMonIpc?.x ?? 0
                                    readonly property real mY: wsMonIpc?.y ?? 0
                                    readonly property real mW: Math.max(1, (wsMonIpc?.width ?? 1920) / (wsMonIpc?.scale || 1))
                                    readonly property real mH: Math.max(1, (wsMonIpc?.height ?? 1080) / (wsMonIpc?.scale || 1))

                                    Layout.preferredWidth: overlayRoot.cardWidth
                                    Layout.preferredHeight: overlayRoot.cardHeight
                                    radius: Tokens.rounding.large

                                    color: isDropTarget
                                        ? Qt.alpha(Colours.palette.m3primaryContainer, 0.85)
                                        : isSelected
                                            ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.72)
                                            : Colours.tPalette.m3surfaceContainer
                                    border.width: (isDropTarget || isSelected || isActiveWs) ? 2 : 1
                                    border.color: isDropTarget
                                        ? Colours.palette.m3tertiary
                                        : isSelected
                                            ? Colours.palette.m3primary
                                            : isActiveWs
                                                ? Colours.palette.m3secondary
                                                : Qt.alpha(Colours.palette.m3outlineVariant, 0.45)

                                    scale: isDropTarget ? 1.03 : (isSelected ? 1.015 : 1.0)

                                    Behavior on scale {
                                        Anim {
                                            type: Anim.FastSpatial
                                        }
                                    }

                                    Behavior on color {
                                        CAnim {}
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Tokens.padding.small
                                        spacing: Tokens.spacing.extraSmall

                                        // Workspace card header
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Tokens.spacing.small

                                            StyledRect {
                                                implicitWidth: 22
                                                implicitHeight: 22
                                                radius: Tokens.rounding.small
                                                color: wsCard.isActiveWs ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: String(wsCard.wsId)
                                                    font: Tokens.font.body.small
                                                    color: wsCard.isActiveWs ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                                }
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: wsCard.isActiveWs ? Tr.tr("Current") : (wsCard.wsClients.length > 0 ? Tr.tr("%1 window(s)").arg(wsCard.wsClients.length) : Tr.tr("Empty"))
                                                font: Tokens.font.body.small
                                                color: wsCard.wsClients.length > 0 || wsCard.isActiveWs ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                                elide: Text.ElideRight
                                            }
                                        }

                                        // Spatial Mini-Desktop Canvas
                                        StyledRect {
                                            id: desktopCanvas

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Tokens.rounding.medium
                                            color: Colours.tPalette.m3surfaceContainerLowest
                                            clip: true

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: root.selectedWs = wsCard.wsId
                                                onClicked: root.activateWorkspace(wsCard.wsId)
                                            }

                                            // Empty workspace watermark
                                            MaterialIcon {
                                                visible: wsCard.wsClients.length === 0
                                                anchors.centerIn: parent
                                                text: "space_dashboard"
                                                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
                                                fontStyle: Tokens.font.icon.extraLarge
                                            }

                                            // Spatial Live Windows
                                            Repeater {
                                                model: wsCard.wsClients

                                                delegate: Item {
                                                    id: miniWin

                                                    required property HyprlandToplevel modelData
                                                    required property int index

                                                    readonly property var ipc: modelData?.lastIpcObject ?? null
                                                    readonly property real rawX: ((ipc?.at?.[0] ?? 0) - wsCard.mX) / wsCard.mW
                                                    readonly property real rawY: ((ipc?.at?.[1] ?? 0) - wsCard.mY) / wsCard.mH
                                                    readonly property real rawW: Math.max(0.14, (ipc?.size?.[0] ?? 400) / wsCard.mW)
                                                    readonly property real rawH: Math.max(0.16, (ipc?.size?.[1] ?? 300) / wsCard.mH)

                                                    x: Math.max(2, Math.min(desktopCanvas.width - width - 2, Math.round(rawX * desktopCanvas.width)))
                                                    y: Math.max(2, Math.min(desktopCanvas.height - height - 2, Math.round(rawY * desktopCanvas.height)))
                                                    width: Math.max(36, Math.min(desktopCanvas.width - 4, Math.round(rawW * desktopCanvas.width) - 2))
                                                    height: Math.max(28, Math.min(desktopCanvas.height - 4, Math.round(rawH * desktopCanvas.height) - 2))

                                                    opacity: root.draggingClient === modelData ? 0.35 : 1.0

                                                    StyledRect {
                                                        anchors.fill: parent
                                                        radius: Tokens.rounding.extraSmall
                                                        color: Colours.tPalette.m3surfaceContainerHigh
                                                        border.width: winMouse.containsMouse ? 2 : 1
                                                        border.color: winMouse.containsMouse ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.6)
                                                        clip: true

                                                        ScreencopyView {
                                                            anchors.centerIn: parent
                                                            captureSource: miniWin.modelData?.wayland ?? null
                                                            live: visible
                                                            constraintSize.width: Math.max(16, miniWin.width - 2)
                                                            constraintSize.height: Math.max(16, miniWin.height - 2)
                                                        }

                                                        // Subtle app icon badge in corner
                                                        StyledRect {
                                                            anchors.left: parent.left
                                                            anchors.bottom: parent.bottom
                                                            anchors.margins: 4
                                                            implicitWidth: 20
                                                            implicitHeight: 20
                                                            radius: 6
                                                            color: Qt.alpha(Colours.palette.m3surface, 0.85)

                                                            IconImage {
                                                                anchors.centerIn: parent
                                                                asynchronous: true
                                                                implicitSize: 14
                                                                source: Icons.getAppIcon(miniWin.ipc?.class ?? "", "application-x-executable")
                                                            }
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: winMouse

                                                        property real startX: 0
                                                        property real startY: 0
                                                        property bool moved: false

                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: root.draggingClient === miniWin.modelData ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                                        onEntered: root.selectedWs = wsCard.wsId

                                                        onPressed: event => {
                                                            const gp = miniWin.mapToItem(overlayRoot, event.x, event.y);
                                                            startX = gp.x;
                                                            startY = gp.y;
                                                            moved = false;
                                                        }

                                                        onPositionChanged: event => {
                                                            if (!pressed)
                                                                return;
                                                            const gp = miniWin.mapToItem(overlayRoot, event.x, event.y);
                                                            if (!moved && Math.hypot(gp.x - startX, gp.y - startY) > 8) {
                                                                moved = true;
                                                                root.draggingClient = miniWin.modelData;
                                                            }
                                                            if (moved) {
                                                                root.dragX = gp.x;
                                                                root.dragY = gp.y;
                                                                root.hoveredDropWs = win.wsAtGlobalPos(gp.x, gp.y);
                                                            }
                                                        }

                                                        onReleased: {
                                                            if (moved) {
                                                                const target = root.hoveredDropWs;
                                                                const client = root.draggingClient;
                                                                root.draggingClient = null;
                                                                root.hoveredDropWs = -1;
                                                                if (client && target >= 1 && target <= 10)
                                                                    root.moveClientToWorkspace(client, target);
                                                            } else {
                                                                root.activateClient(miniWin.modelData);
                                                            }
                                                            moved = false;
                                                        }

                                                        onCanceled: {
                                                            root.draggingClient = null;
                                                            root.hoveredDropWs = -1;
                                                            moved = false;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Floating Drag Ghost Pill when dragging a window across workspaces
                StyledRect {
                    visible: root.draggingClient !== null
                    x: root.dragX - width / 2
                    y: root.dragY - height / 2
                    implicitWidth: 200
                    implicitHeight: 42
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3primaryContainer
                    border.width: 2
                    border.color: Colours.palette.m3primary

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        IconImage {
                            asynchronous: true
                            implicitSize: 20
                            source: Icons.getAppIcon(root.draggingClient?.lastIpcObject?.class ?? "", "application-x-executable")
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.draggingClient?.title || (root.draggingClient?.lastIpcObject?.class ?? "")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onPrimaryContainer
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
