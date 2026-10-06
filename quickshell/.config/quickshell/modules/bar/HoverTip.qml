import QtQuick
import Quickshell
import "../../theme"

// Small text popup to the right of its parent item while the pointer is over it.
// Put it inside the item it describes, the item's own clicks are not blocked.
Item {
    id: root

    anchors.fill: parent
    property string text: ""
    property bool active: true

    HoverHandler {
        id: hover
    }

    PopupWindow {
        id: tip

        visible: root.active && hover.hovered && root.text !== ""

        Reveal {
            target: tip.contentItem
            when: tip.visible
        }

        implicitWidth: label.implicitWidth + 24 * Theme.scale
        implicitHeight: label.implicitHeight + 16 * Theme.scale
        color: "transparent"

        anchor.item: root.parent
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.top: 4 * Theme.scale

        Rectangle {
            anchors.fill: parent
            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale
            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            Text {
                id: label
                anchors.centerIn: parent
                text: root.text
                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
