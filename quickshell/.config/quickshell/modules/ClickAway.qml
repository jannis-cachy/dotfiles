import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible full-screen catcher below the overlay windows. Only a click on its own screen emits
// clicked, so a menu bound to one monitor stays open while the other monitor is used.
PanelWindow {
    id: root

    signal clicked

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "clickaway"
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
