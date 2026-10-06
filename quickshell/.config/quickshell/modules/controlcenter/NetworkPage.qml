import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../"
import "../../theme"

PageFrame {
    id: page

    title: "Internet"
    implicitWidth: 480 * Theme.scale
    implicitHeight: 520 * Theme.scale

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired)

    function signalIcon(strength) {
        if (strength >= 0.8)
            return "network_wifi";
        if (strength >= 0.6)
            return "network_wifi_3_bar";
        if (strength >= 0.4)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    function toggleNetwork(net) {
        if (!net)
            return;
        if (net.connected)
            net.disconnect();
        else
            net.connect();
    }

    Flickable {
        id: flick

        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content

            width: flick.width
            spacing: 16 * Theme.scale

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Theme.scale
                visible: !!page.wiredDevice

                Text {
                    text: "Ethernet"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                ListRow {
                    Layout.fillWidth: true
                    navGroup: 0
                    icon: "lan"
                    label: page.wiredDevice ? page.wiredDevice.name : ""
                    detail: page.wiredDevice && page.wiredDevice.connected ? "Connected" : "Unplugged"
                    current: page.wiredDevice ? page.wiredDevice.connected : false
                    scrollTarget: flick
                    onActivated: page.toggleNetwork(page.wiredDevice ? page.wiredDevice.network : null)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Theme.scale
                visible: !!page.wifiDevice

                Text {
                    text: "Wi-Fi"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                SettingToggle {
                    Layout.fillWidth: true
                    navGroup: 1
                    label: "Wi-Fi"
                    checked: Networking.wifiEnabled
                    onToggled: value => Networking.wifiEnabled = value
                }

                Repeater {
                    model: page.wifiDevice ? page.wifiDevice.networks : null

                    ListRow {
                        required property var modelData

                        Layout.fillWidth: true
                        navGroup: 1
                        icon: page.signalIcon(modelData.signalStrength)
                        label: modelData.name
                        detail: Math.round(modelData.signalStrength * 100) + "%"
                        current: modelData.connected
                        scrollTarget: flick
                        onActivated: page.toggleNetwork(modelData)
                    }
                }
            }

            ListRow {
                Layout.fillWidth: true
                icon: "settings_ethernet"
                navGroup: 2
                label: "Advanced"
                chevron: true
                scrollTarget: flick
                onActivated: Quickshell.execDetached(["nm-connection-editor"])
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
