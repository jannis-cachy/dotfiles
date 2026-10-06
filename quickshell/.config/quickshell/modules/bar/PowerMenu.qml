import QtQuick
import Quickshell
import "../../"
import "../../theme"

Item {
    id: root

    // Index of the destructive entry waiting for a second click
    property int armed: -1

    readonly property var entries: [
        {
            label: "Lock",
            icon: "lock",
            cmd: ["loginctl", "lock-session"],
            confirm: false
        },
        {
            label: "Suspend",
            icon: "bedtime",
            cmd: ["systemctl", "suspend"],
            confirm: false
        },
        {
            label: "Log out",
            icon: "logout",
            cmd: ["sh", "-c", "loginctl terminate-user $USER"],
            confirm: true
        },
        {
            label: "Restart",
            icon: "restart_alt",
            cmd: ["qs", "ipc", "call", "shutdown", "reboot"],
            confirm: true
        },
        {
            label: "Shut down",
            icon: "power_settings_new",
            cmd: ["qs", "ipc", "call", "shutdown", "poweroff"],
            confirm: true
        }
    ]

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    MaterialIcon {
        id: icon
        anchors.fill: parent
        icon: "power_settings_new"
        size: 20 * Theme.scale
        iconColor: Theme.colors.text
    }

    HoverTip {
        text: "Power"
        active: !popup.visible
    }

    PopupWindow {
        id: popup

        Reveal {
            target: popup.contentItem
            when: popup.visible
        }

        visible: false
        implicitWidth: 170 * Theme.scale
        implicitHeight: (root.entries.length * 36 + 12) * Theme.scale
        color: "transparent"
        grabFocus: true

        anchor.item: icon
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.top: -(popup.implicitHeight - 20 * Theme.scale)

        onVisibleChanged: {
            if (!visible)
                root.armed = -1;
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale
            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            Column {
                anchors.fill: parent
                anchors.margins: 6 * Theme.scale
                spacing: 0

                Repeater {
                    model: root.entries

                    Rectangle {
                        id: row

                        required property int index
                        required property var modelData
                        readonly property bool isArmed: root.armed === index

                        width: parent.width
                        height: 36 * Theme.scale
                        radius: Theme.rounding / 2 * Theme.scale
                        readonly property bool lit: isArmed || rowArea.containsMouse
                        color: lit ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : "transparent"
                        border.width: lit ? 2 * Theme.scale : 0
                        border.color: Theme.colors.focus

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * Theme.scale
                            spacing: 8 * Theme.scale

                            MaterialIcon {
                                icon: row.modelData.icon
                                size: 16 * Theme.scale
                                iconColor: Theme.colors.text
                            }

                            Text {
                                text: row.isArmed ? "Sure?" : row.modelData.label
                                color: Theme.colors.text
                                font.family: Theme.font.uiFamily
                                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (row.modelData.confirm && !row.isArmed) {
                                    root.armed = row.index;
                                    disarm.restart();
                                    return;
                                }
                                popup.visible = false;
                                Quickshell.execDetached(row.modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.visible = !popup.visible
    }
}
