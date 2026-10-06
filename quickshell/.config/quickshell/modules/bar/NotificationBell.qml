import QtQuick
import Quickshell
import "../../"
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    // Bell opens the notification center, the small corner icon toggles do not disturb
    MaterialIcon {
        anchors.fill: parent
        icon: Notification.dnd ? "notifications_off" : "notifications"
        size: 20 * Theme.scale
        color: Notification.dnd ? Theme.colors.textMuted : Theme.colors.text
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Notification.setCenter(!Notification.centerOpen)
    }

    Rectangle {
        id: badge

        readonly property real small: 11 * Theme.scale
        readonly property real big: 15 * Theme.scale

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -2 * Theme.scale
        anchors.bottomMargin: -2 * Theme.scale
        width: badgeArea.containsMouse ? big : small
        height: width
        radius: width / 2
        color: Theme.colors.bg
        border.width: Notification.dnd ? Theme.scale : 0
        border.color: Theme.colors.warning

        MaterialIcon {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            icon: "do_not_disturb_on"
            size: parent.width - 2 * Theme.scale
            fill: Notification.dnd
            iconColor: Notification.dnd ? Theme.colors.warning : Theme.colors.textMuted
        }

        MouseArea {
            id: badgeArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: Notification.dnd = !Notification.dnd
        }
    }
}
