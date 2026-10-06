import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

// Empty strip that only reserves `thickness` along one edge, Frame.qml draws everything
PanelWindow {
    id: root

    // "top", "bottom", "left" or "right"
    property string edge: "top"
    property real thickness: BarState.frameSize

    readonly property bool vertical: edge === "left" || edge === "right"

    anchors {
        top: root.edge === "top" || root.vertical
        bottom: root.edge === "bottom" || root.vertical
        left: root.edge === "left" || !root.vertical
        right: root.edge === "right" || !root.vertical
    }

    implicitWidth: vertical ? 1 : 0
    implicitHeight: vertical ? 0 : 1
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: thickness
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "frame-reserve"
    color: "transparent"
    mask: Region {}
}
