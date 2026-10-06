pragma Singleton
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../theme"
import "../modules"

// Notification daemon: popups for new notifications and a center with the history.
// Only one daemon can own the bus name, so dunst must not run.
Singleton {
    id: root

    property bool centerOpen: false
    // Do not disturb: new non-critical notifications go to the history only, no popup
    property bool dnd: false
    readonly property int count: history.count
    // Monitor the center opened on, it stays there while the focus moves to another monitor
    property var centerScreen: null

    function setCenter(open) {
        if (open && !centerOpen)
            centerScreen = targetScreen;
        centerOpen = open;
    }

    readonly property var targetScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // Popups come from server.trackedNotifications, the history stays until cleared
    ListModel {
        id: history
    }

    function clearAll() {
        history.clear();
        server.trackedNotifications.values.forEach(n => n.dismiss());
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: n => {
            history.insert(0, {
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                critical: n.urgency === NotificationUrgency.Critical,
                time: Qt.formatDateTime(new Date(), "HH:mm")
            });
            if (history.count > Theme.notification.maxHistory)
                history.remove(Theme.notification.maxHistory, history.count - Theme.notification.maxHistory);
            n.tracked = !root.dnd || n.urgency === NotificationUrgency.Critical;
        }
    }

    // qs ipc call notification toggle
    IpcHandler {
        target: "notification"

        function toggle(): void {
            root.setCenter(!root.centerOpen);
        }

        function open(): void {
            root.setCenter(true);
        }

        function close(): void {
            root.centerOpen = false;
        }

        function clear(): void {
            root.clearAll();
        }
    }

    // Popups, hidden while the center is open
    PanelWindow {
        screen: root.targetScreen
        visible: server.trackedNotifications.values.length > 0 && !root.centerOpen

        anchors {
            top: true
            right: true
        }
        margins {
            top: BarState.frameSize + 12 * Theme.scale
            right: BarState.frameSize + 12 * Theme.scale
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notification-popup"

        implicitWidth: Theme.notification.width * Theme.scale
        implicitHeight: Math.max(1, column.implicitHeight)
        color: "transparent"

        ColumnLayout {
            id: column

            anchors.fill: parent
            spacing: 10 * Theme.scale

            Repeater {
                model: server.trackedNotifications

                NotificationCard {
                    id: card

                    required property var modelData

                    summary: modelData.summary
                    body: modelData.body
                    appName: modelData.appName
                    image: modelData.image
                    appIcon: modelData.appIcon
                    critical: modelData.urgency === NotificationUrgency.Critical
                    onDismissed: modelData.dismiss()

                    Reveal {
                        target: card
                        type: "defaultSpatial"
                    }

                    // Critical notifications stay until dismissed
                    Timer {
                        running: !card.critical
                        interval: Theme.notification.timeout
                        onTriggered: card.modelData.dismiss()
                    }
                }
            }
        }
    }

    // Notification center
    LazyLoader {
        active: root.centerOpen

        ClickAway {
            screen: root.centerScreen
            onClicked: root.centerOpen = false
        }
    }

    LazyLoader {
        active: root.centerOpen

        PanelWindow {
            id: center

            screen: root.centerScreen

            Reveal {
                target: center.contentItem
            }

            anchors {
                top: true
                right: true
                bottom: true
            }
            margins {
                top: BarState.frameSize + 12 * Theme.scale
                right: BarState.frameSize + 12 * Theme.scale
                bottom: BarState.frameSize + 12 * Theme.scale
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "notification-center"
            // Exclusive would keep pointer and keyboard on this layer while the other monitor is used
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            implicitWidth: Theme.notification.width * Theme.scale
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.bg
                radius: Theme.rounding * Theme.scale
                border.width: 2 * Theme.scale
                border.color: Theme.colors.border
                focus: true

                Keys.onEscapePressed: root.centerOpen = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14 * Theme.scale
                    spacing: 12 * Theme.scale

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Notifications"
                            color: Theme.colors.accent
                            font.family: Theme.font.uiFamily
                            font.pixelSize: (Theme.font.fontSize + 5) * Theme.scale * Theme.font.scale
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: history.count > 0
                            text: "Clear all"
                            color: clearArea.containsMouse ? Theme.colors.accent : Theme.colors.text
                            font.family: Theme.font.uiFamily
                            font.pixelSize: Theme.font.fontSize * Theme.scale * Theme.font.scale

                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.clearAll()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8 * Theme.scale
                        model: history

                        delegate: NotificationCard {
                            id: entry

                            required property int index
                            required property var model

                            width: ListView.view.width
                            summary: model.summary
                            body: model.body
                            appName: model.appName
                            time: model.time
                            critical: model.critical
                            clickToDismiss: false
                            onDismissed: history.remove(index)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: history.count === 0
                            text: "No notifications"
                            color: Theme.colors.textMuted
                            font.family: Theme.font.uiFamily
                            font.pixelSize: Theme.font.fontSize * Theme.scale * Theme.font.scale
                        }
                    }
                }
            }
        }
    }
}
