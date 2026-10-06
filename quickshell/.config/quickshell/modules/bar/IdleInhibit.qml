import QtQuick
import "../../"
import "../../theme"
import "../../services"

Item {
    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    MaterialIcon {
        anchors.fill: parent
        icon: "local_cafe"
        size: 20 * Theme.scale
        color: Caffeine.active ? Theme.colors.accent : Theme.colors.textMuted
    }

    HoverTip {
        text: Caffeine.active ? "Idle inhibitor on" : "Idle inhibitor off"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Caffeine.toggle()
    }
}
