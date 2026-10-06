import QtQuick

// Fades target in while it grows from fromScale, on creation and whenever `when` turns true.
// Closing stays instant, Hyprland's layersOut fades closing layer windows.
SequentialAnimation {
    id: root

    property Item target
    property bool when: true
    property real fromScale: 0.97
    property string type: "revealGrow"
    // Hidden for this long first, e.g. until Hyprland has moved windows out of the way
    property int delay: 0

    onWhenChanged: if (when)
        restart()
    Component.onCompleted: if (when)
        start()

    PropertyAction {
        target: root.target
        property: "opacity"
        value: 0
    }

    PauseAnimation {
        duration: Motion.enabled ? root.delay : 0
    }

    ParallelAnimation {
        Anim {
            target: root.target
            property: "opacity"
            from: 0
            to: 1
            type: "revealFade"
        }

        Anim {
            target: root.target
            property: "scale"
            from: root.fromScale
            to: 1
            type: root.type
        }
    }
}
