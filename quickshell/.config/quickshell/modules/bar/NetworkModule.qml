import QtQuick
import Quickshell
import Quickshell.Networking
import "../../"
import "../../theme"

Item {
    id: root
    property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi)
    property var wiredDevice: Networking.devices.values.find(device => device.type === DeviceType.Wired)
    property var wifiNetwork: wifiDevice ? wifiDevice.networks.values.find(network => network.connected) : null
    property bool ethernetConnected: wiredDevice ? wiredDevice.connected : false
    property bool connected: wifiDevice ? wifiDevice.connected : true
    property real signalStrength: wifiNetwork ? wifiNetwork.signalStrength : 0

    property bool iconHovered: false
    property bool popupHovered: false

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    MaterialIcon {
        id: networkIcon
        anchors.fill: parent

        icon: {
            if (root.ethernetConnected)
                return "lan";

            if (!root.connected)
                return "signal_wifi_off";

            if (root.signalStrength >= 0.8)
                return "network_wifi";

            if (root.signalStrength >= 0.6)
                return "network_wifi_3_bar";

            if (root.signalStrength >= 0.4)
                return "network_wifi_2_bar";

            return "network_wifi_1_bar";
        }
        color: Theme.colors.text
        size: 20 * Theme.scale
    }

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
            Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "goto", "network"]);
        }
    }

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

        anchor.item: networkIcon
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
                text: root.ethernetConnected ? "Ethernet\nConnected" : root.connected && wifiNetwork ? wifiNetwork.name + "\n" + Math.round(root.signalStrength * 100) + "%" : "Disconnected"
            }
        }
    }

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
