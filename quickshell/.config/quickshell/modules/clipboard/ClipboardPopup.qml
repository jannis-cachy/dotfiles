import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../theme"
import ".."

Scope {
    id: root

    property bool open: false
    property var targetScreen: null

    // qs ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            if (!root.open)
                root.targetScreen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
            root.open = !root.open;
        }
    }

    // Lives outside the popup so the copy finishes after the window closes
    Process {
        id: copyProcess
    }

    function pick(id) {
        if (!/^\d+$/.test(id))
            return;
        copyProcess.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
        copyProcess.running = true;
        root.open = false;
    }

    LazyLoader {
        active: root.open

        ClickAway {
            screen: root.targetScreen
            onClicked: root.open = false
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: clipWin

            screen: root.targetScreen

            Reveal {
                target: clipWin.contentItem
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            implicitWidth: 480 * Theme.scale
            implicitHeight: 420 * Theme.scale
            color: "transparent"

            ListModel {
                id: entries
            }

            // Each line is "<id>\t<preview>"
            Process {
                command: ["cliphist", "list"]
                running: true
                stdout: SplitParser {
                    onRead: line => {
                        const tab = line.indexOf("\t");
                        if (tab > 0)
                            entries.append({
                                entryId: line.substring(0, tab),
                                preview: line.substring(tab + 1)
                            });
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.bg
                radius: Theme.rounding * Theme.scale
                border.width: 2 * Theme.scale
                border.color: Theme.colors.border

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: 12 * Theme.scale
                    spacing: 4 * Theme.scale
                    clip: true
                    model: entries
                    focus: true
                    keyNavigationEnabled: true

                    Keys.onEscapePressed: root.open = false
                    Keys.onReturnPressed: if (currentIndex >= 0)
                        root.pick(entries.get(currentIndex).entryId)
                    Keys.onEnterPressed: if (currentIndex >= 0)
                        root.pick(entries.get(currentIndex).entryId)

                    delegate: Rectangle {
                        id: row
                        required property int index
                        required property string entryId
                        required property string preview

                        width: ListView.view.width
                        height: 32 * Theme.scale
                        radius: Theme.rounding / 2 * Theme.scale
                        color: ListView.isCurrentItem ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : "transparent"
                        border.width: ListView.isCurrentItem ? 2 * Theme.scale : 0
                        border.color: Theme.colors.focus

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 10 * Theme.scale
                            anchors.rightMargin: 10 * Theme.scale
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: row.preview
                            color: Theme.colors.text
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 14 * Theme.scale * Theme.font.scale
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: root.pick(row.entryId)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: entries.count === 0
                    text: "Clipboard history is empty"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 14 * Theme.scale * Theme.font.scale
                }
            }
        }
    }
}
