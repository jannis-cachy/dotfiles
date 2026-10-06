import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

ColumnLayout {
    spacing: 6 * Theme.scale

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: ws

            required property var modelData

            // At most two apps, icon from the window class through its desktop entry
            readonly property var appIcons: {
                const seen = {};
                const list = [];
                for (const t of Hyprland.toplevels.values) {
                    const cls = t.lastIpcObject?.["class"] ?? "";
                    if (t.workspace?.id !== modelData.id || cls === "" || seen[cls])
                        continue;
                    seen[cls] = true;
                    const entry = DesktopEntries.heuristicLookup(cls);
                    list.push(Quickshell.iconPath(entry?.icon ?? cls.toLowerCase(), "application-x-executable"));
                }
                return list.slice(0, 2);
            }

            implicitWidth: 24 * Theme.scale
            implicitHeight: 24 * Theme.scale
            radius: Theme.rounding / 2 * Theme.scale

            color: mouseArea.pressed ? Theme.colors.accent : mouseArea.containsMouse ? Theme.colors.selection : modelData.focused ? Theme.colors.accent : "transparent"

            Text {
                anchors.centerIn: parent

                text: modelData.id

                color: modelData.focused ? Theme.colors.textOnAccent : Theme.colors.text

                font.bold: modelData.focused
                font.family: Theme.font.uiFamily
                font.pixelSize: 11 * Theme.scale * Theme.font.scale
            }

            // Dot for a workspace with an urgent window
            Rectangle {
                visible: modelData.urgent && !modelData.focused
                width: 7 * Theme.scale
                height: width
                radius: width / 2
                color: Theme.colors.error
                anchors.top: parent.top
                anchors.right: parent.right
            }

            PopupWindow {
                id: preview

                visible: hover.hovered && ws.appIcons.length > 0

                Reveal {
                    target: preview.contentItem
                    when: preview.visible
                }

                implicitWidth: iconRow.implicitWidth + 20 * Theme.scale
                implicitHeight: 48 * Theme.scale
                color: "transparent"

                anchor.item: ws
                anchor.edges: Edges.Top | Edges.Right
                anchor.gravity: Edges.Right | Edges.Bottom
                anchor.margins.top: -12 * Theme.scale

                Rectangle {
                    anchors.fill: parent
                    color: Theme.colors.bg
                    radius: Theme.rounding * Theme.scale
                    border.width: 2 * Theme.scale
                    border.color: Theme.colors.border

                    Row {
                        id: iconRow
                        anchors.centerIn: parent
                        spacing: 8 * Theme.scale

                        Repeater {
                            model: ws.appIcons

                            Image {
                                required property string modelData

                                width: 28 * Theme.scale
                                height: width
                                source: modelData
                                sourceSize: Qt.size(width * 2, height * 2)
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: hover
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.id} })`);
                }
            }
        }
    }
}
