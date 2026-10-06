import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../"
import "../../theme"

Item {
    id: root

    // Empty shows every tray item, else only the one with this id (one bar slot per item)
    property string only: ""
    visible: shownItems.length > 0

    // id substring (lowercased) to a crisp replacement for the app's own, often low-resolution,
    // tray pixmap: "icon" is a Material symbol, "themeIcon" a scalable icon from the icon theme.
    // "exec" runs on left click instead of the item's own SNI Activate, which for nm-applet
    // does nothing useful.
    readonly property var knownApps: ({
            "nm-applet": {
                name: "Network",
                icon: "network_manage",
                exec: ["nm-connection-editor"],
                windowClass: "nm-connection-editor",
                close: ["pkill", "-x", "nm-applet"]
            },
            "steam": {
                name: "Steam",
                themeIcon: "steam",
                windowClass: "steam",
                close: ["steam", "-shutdown"]
            },
            "obs": {
                name: "OBS",
                themeIcon: "com.obsproject.Studio",
                windowClass: "com.obsproject.Studio",
                close: ["pkill", "-x", "obs"]
            }
        })

    // nm-applet first, the rest keeps its order
    readonly property var sortedItems: SystemTray.items.values.slice().sort((a, b) => rank(a) - rank(b))

    readonly property var shownItems: sortedItems.filter(i => only === "" || (i.id || i.title) === only)

    function rank(item) {
        return (item.id || "").toLowerCase().includes("nm-applet") ? 0 : 1;
    }

    function displayName(item) {
        const known = knownAppFor(item);
        return known && known.name ? known.name : (item.tooltipTitle || item.title || item.id || "app");
    }

    // Quit the app so it stops running in the background and its tray icon goes away
    function closeApp(item) {
        const known = knownAppFor(item);
        Quickshell.execDetached(known && known.close ? known.close : ["pkill", "-x", item.id]);
    }

    // Window selector for the app: known windowClass, else the tray id as class
    function selectorFor(item) {
        const known = knownAppFor(item);
        const cls = known && known.windowClass ? known.windowClass : (item.id || "");
        return `class:(?i)^(${cls})$`;
    }

    function hasWindow(item) {
        const known = knownAppFor(item);
        const cls = (known && known.windowClass ? known.windowClass : (item.id || "")).toLowerCase();
        return Hyprland.toplevels.values.some(t => ((t.lastIpcObject && t.lastIpcObject["class"]) || "").toLowerCase() === cls);
    }

    // Focus the existing window (Hyprland switches to its workspace and monitor, also from a
    // special workspace), else bring the app back from the tray and focus it once it maps
    function openApp(item) {
        const selector = selectorFor(item);
        if (hasWindow(item)) {
            Hyprland.dispatch(`hl.dsp.focus({ window = "${selector}" })`);
            return;
        }
        const known = knownAppFor(item);
        if (known && known.exec)
            Quickshell.execDetached(known.exec);
        else if (known && known.windowClass === "steam")
            // Steam ignores SNI Activate, it has to be asked directly to reopen its window
            Quickshell.execDetached(["steam", "-ifrunning", "steam://open/main"]);
        else
            item.activate();
        focusSoon(selector);
    }

    function knownAppFor(item) {
        if (!item)
            return null;
        const id = (item.id || "").toLowerCase();
        for (const key in knownApps) {
            if (id.includes(key))
                return knownApps[key];
        }
        return null;
    }

    // Steam's tray icon (libayatana appindicator) has no working SNI Activate, and a
    // reopened window (e.g. Steam restoring from tray) can take a moment to map, so a single
    // immediate focus dispatch after a click would just miss it. Retry a few times instead.
    function focusSoon(selector) {
        for (const delay of [0, 400, 1000, 2000]) {
            const timer = focusTimerComponent.createObject(root, {
                interval: Math.max(1, delay),
                selector: selector
            });
            timer.start();
        }
    }

    Component {
        id: focusTimerComponent

        Timer {
            property string selector: ""
            repeat: false
            onTriggered: {
                Hyprland.dispatch(`hl.dsp.focus({ window = "${selector}" })`);
                destroy();
            }
        }
    }

    implicitWidth: trayColumn.implicitWidth
    implicitHeight: trayColumn.implicitHeight

    Column {
        id: trayColumn
        spacing: 22 * Theme.scale

        Repeater {
            model: root.shownItems

            delegate: Item {
                id: trayIcon

                readonly property var item: modelData
                readonly property var known: root.knownAppFor(modelData)

                width: 20 * Theme.scale
                height: 20 * Theme.scale

                Image {
                    anchors.fill: parent
                    visible: !trayIcon.known || !!trayIcon.known.themeIcon
                    source: trayIcon.known && trayIcon.known.themeIcon ? Quickshell.iconPath(trayIcon.known.themeIcon, true) : modelData.icon
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectFit
                }

                MaterialIcon {
                    anchors.fill: parent
                    visible: !!trayIcon.known && !!trayIcon.known.icon
                    icon: trayIcon.known && trayIcon.known.icon ? trayIcon.known.icon : ""
                    iconColor: Theme.colors.text
                    size: 20 * Theme.scale
                }

                HoverTip {
                    text: root.displayName(modelData)
                    active: !actionPopup.visible
                }

                PopupWindow {
                    id: actionPopup

                    Reveal {
                        target: actionPopup.contentItem
                        when: actionPopup.visible
                    }

                    visible: false
                    implicitWidth: 150 * Theme.scale
                    implicitHeight: 84 * Theme.scale
                    color: "transparent"
                    grabFocus: true

                    anchor.item: trayIcon
                    anchor.edges: Edges.Top | Edges.Right
                    anchor.gravity: Edges.Right | Edges.Bottom
                    anchor.margins.top: 4 * Theme.scale

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.colors.bg
                        radius: Theme.rounding * Theme.scale
                        border.width: 2 * Theme.scale
                        border.color: Theme.colors.border

                        Column {
                            anchors.fill: parent
                            anchors.margins: 6 * Theme.scale
                            spacing: 4 * Theme.scale

                            Repeater {
                                model: [
                                    {
                                        label: "Open",
                                        icon: "open_in_new"
                                    },
                                    {
                                        label: "Close",
                                        icon: "close"
                                    }
                                ]

                                Rectangle {
                                    required property var modelData

                                    width: parent.width
                                    height: 32 * Theme.scale
                                    radius: Theme.rounding / 2 * Theme.scale
                                    color: rowArea.containsMouse ? Theme.colors.selection : "transparent"

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10 * Theme.scale
                                        spacing: 8 * Theme.scale

                                        MaterialIcon {
                                            icon: parent.parent.modelData.icon
                                            size: 16 * Theme.scale
                                            iconColor: Theme.colors.text
                                        }

                                        Text {
                                            text: parent.parent.modelData.label
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
                                            actionPopup.visible = false;
                                            if (parent.modelData.label === "Open")
                                                root.openApp(trayIcon.item);
                                            else
                                                root.closeApp(trayIcon.item);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor.item: trayIcon
                    anchor.edges: Edges.Top | Edges.Right
                    anchor.gravity: Edges.Right | Edges.Bottom
                    anchor.margins.top: 24 * Theme.scale
                }

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            actionPopup.visible = !actionPopup.visible;
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            menuAnchor.open();
                        }
                    }
                }
            }
        }
    }
}
