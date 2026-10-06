import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../"
import "../../theme"

Item {
    id: root

    property var bluetoothAdapter: Bluetooth.defaultAdapter

    visible: bluetoothAdapter !== null

    property var connectedDevice: bluetoothAdapter ? bluetoothAdapter.devices.values.find(device => device.connected) : null

    property bool enabled: bluetoothAdapter ? bluetoothAdapter.enabled : false

    property bool iconHovered: false
    property bool popupHovered: false

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    // ─────────────────────────────
    // Bluetooth icon
    // ─────────────────────────────

    MaterialIcon {
        id: bluetoothIcon
        anchors.fill: parent

        icon: root.enabled ? "bluetooth" : "bluetooth_disabled"

        color: Theme.colors.text
        size: 20 * Theme.scale
    }

    // ─────────────────────────────
    // Icon interaction
    // ─────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 10

        onEntered: {
            root.iconHovered = true;
            hideTimer.stop();
            popup.visible = true;
        }

        onExited: {
            root.iconHovered = false;
            hideTimer.restart();
        }

        onClicked: {
            popup.visible = false;
            bluetoothListPopup.visible = !bluetoothListPopup.visible;
        }
    }

    // ─────────────────────────────
    // Hover popup
    // ─────────────────────────────

    PopupWindow {
        id: popup

        Reveal {
            target: popup.contentItem
            when: popup.visible
        }

        visible: false

        implicitWidth: 200 * Theme.scale
        implicitHeight: 80 * Theme.scale

        color: "transparent"

        anchor.item: bluetoothIcon
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.top: 30 * Theme.scale

        Rectangle {
            anchors.fill: parent

            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale

            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    root.popupHovered = true;
                    hideTimer.stop();
                }

                onExited: {
                    root.popupHovered = false;
                    hideTimer.restart();
                }
            }

            Text {
                anchors.centerIn: parent

                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                font.bold: true

                text: {
                    if (!root.enabled)
                        return "Bluetooth Disabled";

                    if (!root.connectedDevice)
                        return "No device connected";

                    if (root.connectedDevice.batteryAvailable) {
                        return root.connectedDevice.name + "\n" + Math.round(root.connectedDevice.battery * 100) + "%";
                    }

                    return root.connectedDevice.name + "\n" + "Battery unavailable";
                }
            }
        }
    }

    PopupWindow {
        id: bluetoothListPopup

        Reveal {
            target: bluetoothListPopup.contentItem
            when: bluetoothListPopup.visible
        }

        visible: false

        implicitWidth: 300 * Theme.scale
        implicitHeight: 400 * Theme.scale

        color: "transparent"

        anchor.item: bluetoothIcon
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.top: 30 * Theme.scale

        grabFocus: true

        Rectangle {
            anchors.fill: parent

            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale

            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            Column {
                anchors.fill: parent
                anchors.margins: 15 * Theme.scale
                spacing: 10 * Theme.scale

                // ─────────────────
                // Title
                // ─────────────────

                Text {
                    text: "Bluetooth Devices"

                    color: Theme.colors.text
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 18 * Theme.scale * Theme.font.scale
                }

                Rectangle {
                    width: parent.width
                    height: 40 * Theme.scale

                    radius: Theme.rounding * Theme.scale

                    color: scanMouseArea.pressed ? Theme.colors.accent : scanMouseArea.containsMouse ? Theme.colors.selection : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: bluetoothAdapter && bluetoothAdapter.discovering ? "Scanning..." : "Scan"

                        color: Theme.colors.text
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 15 * Theme.scale * Theme.font.scale
                    }

                    MouseArea {
                        id: scanMouseArea
                        hoverEnabled: true

                        anchors.fill: parent

                        onClicked: {
                            if (bluetoothAdapter) {
                                bluetoothAdapter.discovering = true;
                                scanTimer.restart();
                            }
                        }
                    }
                }

                // ─────────────────
                // Device list
                // ─────────────────

                Repeater {
                    model: bluetoothAdapter ? bluetoothAdapter.devices : null

                    Rectangle {
                        width: parent.width
                        height: 40 * Theme.scale

                        radius: Theme.rounding * Theme.scale

                        color: mouseArea.pressed ? Theme.colors.accent : mouseArea.containsMouse ? Theme.colors.selection : modelData.connected ? Theme.colors.selection : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * Theme.scale
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData.name

                            color: Theme.colors.text
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 15 * Theme.scale * Theme.font.scale
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10 * Theme.scale
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""

                            color: Theme.colors.text
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 13 * Theme.scale * Theme.font.scale
                        }

                        MouseArea {
                            id: mouseArea
                            hoverEnabled: true

                            anchors.fill: parent

                            onClicked: {
                                if (modelData.connected) {
                                    modelData.disconnect();
                                } else {
                                    modelData.connect();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────
    // Scan timer
    // ─────────────────────────────

    Timer {
        id: scanTimer

        interval: 10000
        repeat: false

        onTriggered: {
            if (bluetoothAdapter)
                bluetoothAdapter.discovering = false;
        }
    }

    // ─────────────────────────────
    // Hover popup timer
    // ─────────────────────────────

    Timer {
        id: hideTimer

        interval: 150
        repeat: false

        onTriggered: {
            if (!root.iconHovered && !root.popupHovered)
                popup.visible = false;
        }
    }
}
