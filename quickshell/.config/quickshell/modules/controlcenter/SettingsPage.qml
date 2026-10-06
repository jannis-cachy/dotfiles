import "../../theme"
import QtQuick
import QtQuick.Layouts

PageFrame {
    title: "Settings"

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
            spacing: 12 * Theme.scale

            SettingToggle {
                Layout.fillWidth: true
                label: "Autostart apps"
                checked: Theme.autostart.enabled
                onToggled: (value) => {
                    return Theme.autostart.enabled = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Animations"
                checked: Theme.animations.enabled
                onToggled: (value) => {
                    return Theme.animations.enabled = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Start shell at login"
                checked: Theme.autostart.quickshell
                onToggled: (value) => {
                    return Theme.autostart.quickshell = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Bar toggle hides frame"
                checked: Theme.bar.toggleFrame
                onToggled: (value) => {
                    return Theme.bar.toggleFrame = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Screenshot all screens"
                checked: Theme.screenshot.allScreens
                onToggled: (value) => {
                    return Theme.screenshot.allScreens = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Control center blur"
                checked: Theme.controlcenter.blur
                onToggled: (value) => {
                    return Theme.controlcenter.blur = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Control center dark layer"
                checked: Theme.controlcenter.dim
                onToggled: (value) => {
                    return Theme.controlcenter.dim = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Launcher blur"
                checked: Theme.launcher.blur
                onToggled: (value) => {
                    return Theme.launcher.blur = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Launcher dark layer"
                checked: Theme.launcher.dim
                onToggled: (value) => {
                    return Theme.launcher.dim = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "More apps in launcher"
                checked: Theme.launcher.showMore
                onToggled: (value) => {
                    return Theme.launcher.showMore = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Search dot files"
                checked: Theme.finder.showHidden
                onToggled: (value) => {
                    return Theme.finder.showHidden = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Search system folders"
                checked: Theme.finder.searchSystem
                onToggled: (value) => {
                    return Theme.finder.searchSystem = value;
                }
            }

            SettingToggle {
                Layout.fillWidth: true
                label: "Search all folders and types"
                checked: Theme.finder.searchAll
                onToggled: (value) => {
                    return Theme.finder.searchAll = value;
                }
            }

            SettingSlider {
                Layout.fillWidth: true
                label: "Mouse sensitivity"
                from: -1
                to: 1
                stepSize: 0.05
                decimals: 2
                value: Theme.mouse.sensitivity
                onCommitted: (v) => {
                    return Theme.mouse.sensitivity = v;
                }
            }

            SettingSlider {
                Layout.fillWidth: true
                label: "Scroll speed"
                from: 0.1
                to: 3
                stepSize: 0.1
                decimals: 1
                value: Theme.mouse.scrollFactor
                onCommitted: (v) => {
                    return Theme.mouse.scrollFactor = v;
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
