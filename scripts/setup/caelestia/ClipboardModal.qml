pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    id: root

    property bool isOpen: false
    property bool closing: false
    property string query: ""
    property int selectedIndex: 0
    property int cacheRev: 0
    property var allItems: []

    readonly property string cacheDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/caelestia-clipcache`

    readonly property var filteredItems: {
        const q = query.trim().toLowerCase();
        if (!q)
            return allItems;
        return allItems.filter(it => it.summary.toLowerCase().includes(q) || (it.isImage && "image screenshot picture".includes(q)));
    }

    function open(): void {
        if (isOpen && !closing)
            return;
        query = "";
        selectedIndex = 0;
        closing = false;
        isOpen = true;
        loader.activeAsync = true;
        reloadHistory();
    }

    function close(): void {
        if (!isOpen || closing)
            return;
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

    function reloadHistory(): void {
        listProc.running = false;
        listProc.running = true;
    }

    function selectItem(item: var): void {
        if (!item)
            return;
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", item.id]);
        close();
    }

    function deleteItem(item: var): void {
        if (!item)
            return;
        delProc.rawLine = item.raw;
        delProc.itemId = item.id;
        delProc.running = true;
    }

    function wipeAll(): void {
        wipeProc.running = true;
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

    Process {
        id: listProc

        command: ["sh", "-c", "cliphist list | head -n 80"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0);
                const parsed = [];
                const imgIds = [];

                for (const line of lines) {
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx === -1)
                        continue;
                    const id = line.slice(0, tabIdx).trim();
                    const summary = line.slice(tabIdx + 1);
                    const imgMatch = summary.match(/^\[\[ binary data (.*?) (png|jpe?g|webp|bmp) (.*?) \]\]$/i);
                    const isImage = imgMatch !== null;
                    const ext = isImage ? imgMatch[2].toLowerCase() : "";
                    const meta = isImage ? `${imgMatch[2].toUpperCase()} • ${imgMatch[1]} • ${imgMatch[3]}` : "";

                    parsed.push({
                        id: id,
                        raw: line,
                        summary: summary,
                        isImage: isImage,
                        ext: ext,
                        meta: meta
                    });

                    if (isImage)
                        imgIds.push(`${id}:${ext}`);
                }

                root.allItems = parsed;
                if (root.selectedIndex >= root.filteredItems.length)
                    root.selectedIndex = Math.max(0, root.filteredItems.length - 1);

                if (imgIds.length > 0) {
                    thumbProc.spec = imgIds.join(" ");
                    thumbProc.running = false;
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc

        property string spec: ""

        command: ["sh", "-c", 'mkdir -p -m 700 "$1"; for pair in $2; do id="${pair%%:*}"; ext="${pair#*:}"; out="$1/$id.$ext"; [ -s "$out" ] || cliphist decode "$id" > "$out" 2>/dev/null || rm -f "$out"; done', "sh", root.cacheDir, thumbProc.spec]
        onExited: root.cacheRev++
    }

    Process {
        id: delProc

        property string rawLine: ""
        property string itemId: ""

        command: ["sh", "-c", 'printf "%s\n" "$1" | cliphist delete; rm -f "$2/$3".*', "sh", delProc.rawLine, root.cacheDir, delProc.itemId]
        onExited: root.reloadHistory()
    }

    Process {
        id: wipeProc

        command: ["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", root.cacheDir]
        onExited: {
            root.allItems = [];
            root.selectedIndex = 0;
            Toaster.toast(Tr.tr("Clipboard cleared"), Tr.tr("All clipboard history has been wiped"), "delete_sweep");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clipboardToggle"
        description: "Toggle visual clipboard history"
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

        target: "clipboard"
    }

    LazyLoader {
        id: loader

        StyledWindow {
            id: win

            name: "clipboard"
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
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, root.isOpen && !root.closing ? 0.30 : 0)

                    Behavior on color {
                        CAnim {}
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.close()
                    }
                }

                StyledRect {
                    id: modalCard

                    anchors.centerIn: parent
                    width: Math.min(680, win.screen.width - 64)
                    height: Math.min(640, win.screen.height - 80)

                    color: Colours.tPalette.m3surface
                    radius: Tokens.rounding.extraLarge
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    opacity: root.isOpen && !root.closing ? 1 : 0
                    scale: root.isOpen && !root.closing ? 1 : 0.94

                    Component.onCompleted: {
                        opacity = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0);
                        scale = Qt.binding(() => root.isOpen && !root.closing ? 1 : 0.94);
                        searchInput.forceActiveFocus();
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
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.extraLarge
                        spacing: Tokens.spacing.medium

                        // Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "content_paste"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                            }

                            StyledText {
                                text: Tr.tr("Clipboard History")
                                font: Tokens.font.body.large
                                color: Colours.palette.m3onSurface
                            }

                            StyledRect {
                                implicitWidth: countText.implicitWidth + Tokens.padding.small * 2
                                implicitHeight: 22
                                radius: Tokens.rounding.small
                                color: Colours.tPalette.m3surfaceContainerHighest

                                StyledText {
                                    id: countText

                                    anchors.centerIn: parent
                                    text: String(root.filteredItems.length)
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // Clear All Button
                            StyledRect {
                                visible: root.allItems.length > 0
                                implicitWidth: clearRow.implicitWidth + Tokens.padding.medium * 2
                                implicitHeight: 32
                                radius: Tokens.rounding.medium
                                color: clearMouse.containsMouse ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainerHigh

                                RowLayout {
                                    id: clearRow

                                    anchors.centerIn: parent
                                    spacing: 6

                                    MaterialIcon {
                                        text: "delete_sweep"
                                        fontStyle: Tokens.font.icon.small
                                        color: clearMouse.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                    }

                                    StyledText {
                                        text: Tr.tr("Clear all")
                                        font: Tokens.font.body.small
                                        color: clearMouse.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                    }
                                }

                                MouseArea {
                                    id: clearMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.wipeAll()
                                }
                            }
                        }

                        // Search Bar
                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainerHigh
                            border.width: searchInput.activeFocus ? 2 : 1
                            border.color: searchInput.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.4)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.medium
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    text: "search"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.medium
                                }

                                TextInput {
                                    id: searchInput

                                    Layout.fillWidth: true
                                    focus: true
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.medium
                                    selectionColor: Colours.palette.m3primaryContainer
                                    selectedTextColor: Colours.palette.m3onPrimaryContainer
                                    clip: true

                                    onTextChanged: {
                                        root.query = text;
                                        root.selectedIndex = 0;
                                    }

                                    Keys.onPressed: event => {
                                        const count = root.filteredItems.length;
                                        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                                        const alt = (event.modifiers & Qt.AltModifier) !== 0;
                                        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;

                                        if (event.key === Qt.Key_Escape) {
                                            root.close();
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (count > 0)
                                                root.selectItem(root.filteredItems[root.selectedIndex]);
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                            if (count > 0)
                                                root.selectedIndex = (root.selectedIndex + 1) % count;
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                            if (count > 0)
                                                root.selectedIndex = (root.selectedIndex - 1 + count) % count;
                                            event.accepted = true;
                                        } else if (alt && event.key === Qt.Key_D) {
                                            if (count > 0)
                                                root.deleteItem(root.filteredItems[root.selectedIndex]);
                                            event.accepted = true;
                                        } else if (ctrl && shift && event.key === Qt.Key_Backspace) {
                                            root.wipeAll();
                                            event.accepted = true;
                                        }
                                    }

                                    StyledText {
                                        visible: searchInput.text.length === 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Tr.tr("Search text or type 'image'…  (Ctrl+J/K, Enter copy, Alt+D delete)")
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }

                        // Clipboard List
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Empty state
                            ColumnLayout {
                                visible: root.filteredItems.length === 0
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "inventory_2"
                                    color: Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.extraLarge
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.allItems.length === 0 ? Tr.tr("Clipboard history is empty") : Tr.tr("No matching clipboard items")
                                    font: Tokens.font.body.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }

                            ListView {
                                id: clipList

                                visible: root.filteredItems.length > 0
                                anchors.fill: parent
                                clip: true
                                spacing: Tokens.spacing.small
                                boundsBehavior: Flickable.StopAtBounds
                                currentIndex: root.selectedIndex
                                highlightFollowsCurrentItem: true
                                highlightMoveDuration: 150

                                model: root.filteredItems

                                delegate: StyledRect {
                                    id: rowCard

                                    required property var modelData
                                    required property int index

                                    readonly property bool isSelected: index === root.selectedIndex
                                    readonly property string imgUrl: {
                                        void root.cacheRev;
                                        if (!modelData.isImage)
                                            return "";
                                        return `file://${root.cacheDir}/${modelData.id}.${modelData.ext}`;
                                    }

                                    width: clipList.width
                                    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2
                                    radius: Tokens.rounding.medium

                                    color: isSelected
                                        ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.85)
                                        : rowMouse.containsMouse
                                            ? Colours.tPalette.m3surfaceContainerHigh
                                            : Colours.tPalette.m3surfaceContainer
                                    border.width: isSelected ? 2 : 1
                                    border.color: isSelected ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.35)

                                    MouseArea {
                                        id: rowMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.selectedIndex = rowCard.index
                                        onClicked: root.selectItem(rowCard.modelData)
                                    }

                                    RowLayout {
                                        id: rowLayout

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: Tokens.padding.medium
                                        spacing: Tokens.spacing.medium

                                        MaterialIcon {
                                            Layout.alignment: Qt.AlignTop
                                            text: rowCard.modelData.isImage ? "image" : "notes"
                                            color: rowCard.isSelected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                            fontStyle: Tokens.font.icon.medium
                                        }

                                        // Content: either inline Image thumbnail or crisp text snippet
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Tokens.spacing.extraSmall

                                            StyledText {
                                                visible: !rowCard.modelData.isImage
                                                Layout.fillWidth: true
                                                text: rowCard.modelData.summary
                                                font: Tokens.font.body.medium
                                                color: rowCard.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                                maximumLineCount: 2
                                                wrapMode: Text.WrapAnywhere
                                                elide: Text.ElideRight
                                            }

                                            // Image Badge + Inline Thumbnail
                                            RowLayout {
                                                visible: rowCard.modelData.isImage
                                                spacing: Tokens.spacing.small

                                                StyledText {
                                                    text: rowCard.modelData.meta
                                                    font: Tokens.font.body.small
                                                    color: Colours.palette.m3primary
                                                }
                                            }

                                            ClipRect {
                                                visible: rowCard.modelData.isImage
                                                implicitWidth: Math.min(340, thumbImg.implicitWidth > 0 ? Math.round(130 * (thumbImg.implicitWidth / Math.max(1, thumbImg.implicitHeight))) : 220)
                                                implicitHeight: 130
                                                radius: Tokens.rounding.small
                                                color: Colours.tPalette.m3surfaceContainerLowest

                                                Image {
                                                    id: thumbImg

                                                    anchors.fill: parent
                                                    asynchronous: true
                                                    cache: false
                                                    fillMode: Image.PreserveAspectCrop
                                                    source: rowCard.modelData.isImage && root.cacheRev >= 0 ? rowCard.imgUrl : ""
                                                }
                                            }
                                        }

                                        // Per-item Delete Button
                                        StyledRect {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            radius: Tokens.rounding.small
                                            color: delBtnMouse.containsMouse ? Colours.palette.m3errorContainer : "transparent"

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "close"
                                                fontStyle: Tokens.font.icon.small
                                                color: delBtnMouse.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
                                            }

                                            MouseArea {
                                                id: delBtnMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.deleteItem(rowCard.modelData)
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
}
