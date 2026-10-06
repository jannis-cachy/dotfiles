import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../"
import "../../theme"

Item {
    id: root

    property var battery: UPower.displayDevice

    visible: !!battery && battery.isLaptopBattery

    property real percentage: battery ? battery.percentage : 0

    property bool charging: battery ? battery.state === UPowerDeviceState.Charging : false

    property bool iconHovered: false
    property bool popupHovered: false

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    MaterialIcon {
        id: batteryIcon

        anchors.fill: parent

        icon: {
            if (root.charging)
                return "battery_charging_full";

            if (root.percentage >= 0.90)
                return "battery_full";

            if (root.percentage >= 0.60)
                return "battery_5_bar";

            if (root.percentage >= 0.40)
                return "battery_4_bar";

            if (root.percentage >= 0.20)
                return "battery_2_bar";

            return "battery_1_bar";
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

        anchor.item: batteryIcon
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
                    if (!root.battery)
                        return "Battery unavailable";

                    return Math.round(root.percentage * 100) + "%" + (root.charging ? "\nCharging" : "\nNot charging");
                }
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
