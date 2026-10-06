import QtQuick
import "../../theme"

// Low opacity box with a border, shown behind a keyboard stop while it has focus
Rectangle {
    property Item stop: parent
    property color borderColor: Theme.colors.focus

    anchors.fill: parent
    z: -1
    visible: stop.activeFocus
    radius: Theme.rounding / 2 * Theme.scale
    color: Qt.alpha(Theme.colors.selection, Theme.focusFill)
    border.width: 2 * Theme.scale
    border.color: borderColor
}
