import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

// The whole frame of one monitor plus the bar in a single window, so edges, corners and bar
// always change and fade in the same frame. Full screen and click-through except the edges,
// the space is reserved by four empty FrameReserve windows (one exclusive zone per window).
PanelWindow {
    id: root

    property real leftThickness: BarState.frameSize
    property bool expanded: false
    readonly property real edge: BarState.frameSize
    readonly property real radius: Math.round(Theme.frameRounding * Theme.scale)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "frame"
    color: "transparent"
    // Corners stay click-through like the workspace they cut into
    mask: Region {
        Region {
            item: topBand
        }
        Region {
            item: bottomBand
        }
        Region {
            item: leftBand
        }
        Region {
            item: rightBand
        }
    }

    Rectangle {
        id: topBand
        width: parent.width
        height: root.edge
        color: Theme.colors.bg
    }

    Rectangle {
        id: bottomBand
        y: parent.height - root.edge
        width: parent.width
        height: root.edge
        color: Theme.colors.bg
    }

    Rectangle {
        id: rightBand
        x: parent.width - root.edge
        width: root.edge
        height: parent.height
        color: Theme.colors.bg
    }

    // Grows with the same curve and duration as windowsMove in Motion.hyprLeaves, so the bar
    // slides out exactly as fast as Hyprland moves the windows out of the reserved space
    Rectangle {
        id: leftBand
        width: root.leftThickness
        height: parent.height
        color: Theme.colors.bg
        clip: true

        Behavior on width {
            Anim {
                type: "standard"
            }
        }

        // Full bar width from the start, the growing band reveals it
        Loader {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                topMargin: 12 * Theme.scale
                bottomMargin: 12 * Theme.scale
            }
            width: BarState.barSize
            active: root.expanded
            sourceComponent: BarContent {}
        }
    }

    InverseCorner {
        corner: "topLeft"
        size: root.radius
        color: Theme.colors.bg
        x: Math.round(leftBand.width)
        y: root.edge
    }

    InverseCorner {
        corner: "topRight"
        size: root.radius
        color: Theme.colors.bg
        x: Math.round(root.width - root.edge - size)
        y: root.edge
    }

    InverseCorner {
        corner: "bottomLeft"
        size: root.radius
        color: Theme.colors.bg
        x: Math.round(leftBand.width)
        y: root.height - root.edge - size
    }

    InverseCorner {
        corner: "bottomRight"
        size: root.radius
        color: Theme.colors.bg
        x: Math.round(root.width - root.edge - size)
        y: root.height - root.edge - size
    }
}
