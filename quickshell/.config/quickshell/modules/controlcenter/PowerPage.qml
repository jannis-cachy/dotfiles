import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

PageFrame {
    id: page

    title: "Power"

    signal close

    // Index of the entry waiting for a second activation
    property int armed: -1

    readonly property var entries: [
        {
            label: "Lock",
            cmd: ["loginctl", "lock-session"],
            confirm: false
        },
        {
            label: "Suspend",
            cmd: ["systemctl", "suspend"],
            confirm: false
        },
        {
            label: "Log out",
            cmd: ["sh", "-c", "loginctl terminate-user $USER"],
            confirm: true
        },
        {
            label: "Restart",
            cmd: ["qs", "ipc", "call", "shutdown", "reboot"],
            confirm: true
        },
        {
            label: "Shut down",
            cmd: ["qs", "ipc", "call", "shutdown", "poweroff"],
            confirm: true
        }
    ]

    function focusDefault() {
        rows.itemAt(0).forceActiveFocus();
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: page.armed = -1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8 * Theme.scale

        Repeater {
            id: rows

            model: page.entries

            MenuButton {
                required property var modelData
                required property int index

                position: index === 0 ? -1 : (index === page.entries.length - 1 ? 1 : 0)
                text: page.armed === index ? "Sure?" : modelData.label
                activeFocusOnTab: true
                current: activeFocus
                onHovered: forceActiveFocus()
                onActiveFocusChanged: {
                    if (!activeFocus && page.armed === index)
                        page.armed = -1;
                }
                onClicked: {
                    forceActiveFocus();
                    if (modelData.confirm && page.armed !== index) {
                        page.armed = index;
                        disarm.restart();
                        return;
                    }
                    page.close();
                    Quickshell.execDetached(modelData.cmd);
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
