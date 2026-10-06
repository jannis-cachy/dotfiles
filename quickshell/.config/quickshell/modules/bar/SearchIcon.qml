import QtQuick
import Quickshell
import "../../"
import "../../theme"

MaterialIcon {
    icon: "search"
    size: 20 * Theme.scale
    iconColor: Theme.colors.text

    HoverTip {
        text: "Search"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "goto", "finder"])
    }
}
