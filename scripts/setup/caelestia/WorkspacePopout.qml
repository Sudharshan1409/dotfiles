pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts
    property ShellScreen screen: null

    readonly property int wsId: popouts.hoveredWorkspace
    readonly property var singleClient: popouts.hoveredToplevel
    readonly property list<HyprlandToplevel> wsToplevels: Hypr.toplevelsForWs(wsId, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property var orderedToplevels: [...wsToplevels].sort((a, b) => ((a.lastIpcObject?.floating ? 1 : 0) - (b.lastIpcObject?.floating ? 1 : 0)))

    property var hoveredTileClient: null

    readonly property var monIpc: {
        const wsObj = Hypr.workspaces.values.find(w => w.id === root.wsId);
        if (wsObj?.monitor?.lastIpcObject)
            return wsObj.monitor.lastIpcObject;
        if (root.wsToplevels.length > 0) {
            const monId = root.wsToplevels[0].lastIpcObject?.monitor;
            const m = Hypr.monitors.values.find(mon => mon.id === monId);
            if (m?.lastIpcObject)
                return m.lastIpcObject;
        }
        const curMon = root.screen ? Hypr.monitorFor(root.screen) : Hypr.focusedMonitor;
        return curMon?.lastIpcObject ?? null;
    }

    readonly property real monX: monIpc?.x ?? 0
    readonly property real monY: monIpc?.y ?? 0
    readonly property real monW: Math.max(1, (monIpc?.width ?? 1920) / (monIpc?.scale || 1))
    readonly property real monH: Math.max(1, (monIpc?.height ?? 1080) / (monIpc?.scale || 1))

    readonly property int previewWidth: 380
    readonly property int canvasHeight: Math.round(previewWidth * (monH / monW))

    function focusClient(client: var): void {
        const addr = client?.lastIpcObject?.address;
        if (addr) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "${addr}" })` : `focuswindow address:${addr}`);
            root.popouts.hasCurrent = false;
        }
    }

    function focusWs(): void {
        Hypr.focusWorkspace(root.wsId);
        root.popouts.hasCurrent = false;
    }

    onWsIdChanged: hoveredTileClient = null
    onWsToplevelsChanged: {
        if (wsToplevels.length === 0 && popouts.currentName === "workspace")
            popouts.hasCurrent = false;
    }

    implicitWidth: previewWidth
    implicitHeight: mainLoader.item ? mainLoader.item.implicitHeight : 0

    Loader {
        id: mainLoader

        anchors.left: parent.left
        anchors.right: parent.right
        sourceComponent: root.singleClient ? singleWindowComp : miniDesktopComp
    }

    // Mode A: Single-Window Live Preview (when hovering a specific app icon under the workspace)
    Component {
        id: singleWindowComp

        ColumnLayout {
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                IconImage {
                    asynchronous: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: singleDetails.implicitHeight
                    source: Icons.getAppIcon(root.singleClient?.lastIpcObject?.class ?? "", "image-missing")
                }

                ColumnLayout {
                    id: singleDetails

                    spacing: 0
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: root.singleClient?.title || (root.singleClient?.lastIpcObject?.class ?? "")
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `Workspace ${root.wsId} • ${root.singleClient?.lastIpcObject?.class ?? ""}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }

                Item {
                    implicitWidth: winfoIcon.implicitHeight + Tokens.padding.small
                    implicitHeight: winfoIcon.implicitHeight + Tokens.padding.small
                    Layout.alignment: Qt.AlignVCenter

                    StateLayer {
                        radius: Tokens.rounding.large
                        onClicked: {
                            root.popouts.detachToplevel = root.singleClient;
                            root.popouts.detachRequested("winfo");
                        }
                    }

                    MaterialIcon {
                        id: winfoIcon

                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: font.pointSize * 0.05
                        text: "chevron_right"
                        fontStyle: Tokens.font.icon.large
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: singleClip.implicitWidth
                implicitHeight: singleClip.implicitHeight

                ClippingWrapperRectangle {
                    id: singleClip

                    color: "transparent"
                    radius: Tokens.rounding.medium

                    ScreencopyView {
                        captureSource: root.singleClient?.wayland ?? null
                        live: visible
                        constraintSize.width: root.previewWidth
                        constraintSize.height: Tokens.sizes.bar.windowPreviewSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusClient(root.singleClient)
                }
            }
        }
    }

    // Mode B: Mini-Desktop Spatial Overview (when hovering the workspace shape itself)
    Component {
        id: miniDesktopComp

        ColumnLayout {
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRect {
                    radius: Tokens.rounding.full
                    color: root.wsId === Hypr.activeWsId ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                    implicitWidth: wsBadgeText.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: wsBadgeText.implicitHeight + Tokens.padding.extraSmall * 2

                    StyledText {
                        id: wsBadgeText

                        anchors.centerIn: parent
                        text: `Workspace ${root.wsId}`
                        color: root.wsId === Hypr.activeWsId ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        animate: true
                        text: {
                            if (root.hoveredTileClient)
                                return root.hoveredTileClient.title || (root.hoveredTileClient.lastIpcObject?.class ?? "");
                            const n = root.wsToplevels.length;
                            return n === 1 ? "1 window" : `${n} windows`;
                        }
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.hoveredTileClient ? (root.hoveredTileClient.lastIpcObject?.class ?? "") : Tr.tr("Click a window to jump")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }

            // Scaled 16:9 mini-monitor canvas
            ClipRect {
                id: desktopCanvas

                Layout.fillWidth: true
                implicitWidth: root.previewWidth
                implicitHeight: root.canvasHeight

                radius: Tokens.rounding.medium
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                Image {
                    anchors.fill: parent
                    source: Wallpapers.actualCurrent ? `file://${Wallpapers.actualCurrent}` : ""
                    sourceSize: Qt.size(root.previewWidth, root.canvasHeight)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.28
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWs()
                }

                Repeater {
                    model: ScriptModel {
                        values: root.orderedToplevels
                    }

                    Item {
                        id: winTile

                        required property var modelData
                        required property int index

                        readonly property var ipc: modelData?.lastIpcObject ?? null
                        readonly property bool isFloating: ipc?.floating ?? false
                        readonly property real normX: ipc ? Math.max(0, Math.min(0.95, (ipc.at[0] - root.monX) / root.monW)) : 0
                        readonly property real normY: ipc ? Math.max(0, Math.min(0.95, (ipc.at[1] - root.monY) / root.monH)) : 0
                        readonly property real normW: ipc ? Math.max(0.08, Math.min(1 - normX, ipc.size[0] / root.monW)) : 0.5
                        readonly property real normH: ipc ? Math.max(0.08, Math.min(1 - normY, ipc.size[1] / root.monH)) : 0.5

                        x: Math.round(normX * desktopCanvas.width)
                        y: Math.round(normY * desktopCanvas.height)
                        width: Math.max(24, Math.round(normW * desktopCanvas.width))
                        height: Math.max(20, Math.round(normH * desktopCanvas.height))
                        z: tileMouse.containsMouse ? 10 : (isFloating ? 5 : 1)

                        scale: tileMouse.containsMouse ? 1.02 : 1.0

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }

                        // Fallback card background + centered app icon (visible if off-screen buffer hasn't rendered yet)
                        StyledRect {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Tokens.rounding.small
                            color: Colours.tPalette.m3surfaceContainer

                            IconImage {
                                anchors.centerIn: parent
                                asynchronous: true
                                implicitSize: Math.min(32, Math.min(parent.width, parent.height) * 0.5)
                                opacity: 0.65
                                source: Icons.getAppIcon(winTile.ipc?.class ?? "", "image-missing")
                            }
                        }

                        ClippingWrapperRectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            color: "transparent"
                            radius: Tokens.rounding.small

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: winTile.modelData?.wayland ?? null
                                live: visible
                                constraintSize.width: Math.max(64, winTile.width * 1.5)
                                constraintSize.height: Math.max(64, winTile.height * 1.5)
                            }
                        }

                        // Top-left app pill badge inside each tile
                        StyledRect {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 5
                            visible: winTile.width >= 48 && winTile.height >= 32
                            radius: Tokens.rounding.full
                            color: Qt.alpha(Colours.palette.m3surfaceContainerLowest, 0.82)
                            implicitWidth: Math.min(winTile.width - 10, badgeRow.implicitWidth + Tokens.padding.small * 2)
                            implicitHeight: badgeRow.implicitHeight + 4
                            clip: true

                            RowLayout {
                                id: badgeRow

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Tokens.padding.small
                                anchors.rightMargin: Tokens.padding.small
                                spacing: 4

                                IconImage {
                                    asynchronous: true
                                    implicitSize: 13
                                    source: Icons.getAppIcon(winTile.ipc?.class ?? "", "image-missing")
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: winTile.width >= 90
                                    text: winTile.modelData?.title || (winTile.ipc?.class ?? "")
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Highlight border on tile hover
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Tokens.rounding.small
                            color: "transparent"
                            border.width: tileMouse.containsMouse ? 2 : 1
                            border.color: tileMouse.containsMouse ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.6)

                            Behavior on border.color {
                                CAnim {}
                            }
                        }

                        MouseArea {
                            id: tileMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hoveredTileClient = winTile.modelData
                            onExited: {
                                if (root.hoveredTileClient === winTile.modelData)
                                    root.hoveredTileClient = null;
                            }
                            onClicked: root.focusClient(winTile.modelData)
                        }
                    }
                }
            }
        }
    }
}
