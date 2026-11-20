pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest
    property int reloadRev: 0

    // Balanced portrait proportions: narrower overall width, taller portrait height
    implicitWidth: Math.round(centerWidth * 0.34)
    implicitHeight: Math.round(implicitWidth * 1.22)

    FileView {
        path: `${Paths.home}/.face`
        watchChanges: true
        onFileChanged: root.reloadRev++
    }

    ClipRect {
        id: frame

        anchors.fill: parent
        radius: Tokens.rounding.extraLargeIncreased

        StyledRect {
            anchors.fill: parent
            color: root.bgColour
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: "person"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size(root.implicitWidth * 0.42).build()
            visible: faceImg.status !== Image.Ready
        }

        Image {
            id: faceImg

            anchors.fill: parent
            source: {
                void root.reloadRev;
                return `file://${Paths.home}/.face`;
            }
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    // Subtle Material You primary accent border ring
    Rectangle {
        anchors.fill: parent
        radius: Tokens.rounding.extraLargeIncreased
        color: "transparent"
        border.width: 2
        border.color: Qt.alpha(Colours.palette.m3primary, 0.5)

        Behavior on border.color {
            CAnim {}
        }
    }
}
