import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../theme"

PageFrame {
    id: page

    title: "Binaries"
    implicitWidth: 520 * Theme.scale
    implicitHeight: 560 * Theme.scale

    // Name to description, read from a "# desc: ..." comment near the top of each script
    property var descriptions: ({})

    // Enter/click never runs the binary directly: opens a terminal with the command
    // typed into the prompt (zsh's own "print -z") so it can be looked at first.
    function run(name) {
        Quickshell.execDetached(["kitty", "zsh", "-ic", `print -z "${name}"; exec zsh`]);
    }

    Process {
        running: true
        command: ["zsh", "-c", "for f in \"$HOME\"/Binaries/*(.N); do d=$(grep -m1 -oP '^#\\s*desc:\\s*\\K.*' \"$f\" 2>/dev/null); [ -z \"$d\" ] && d=$(basename \"$f\"); echo \"$(basename \"$f\")|$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("|");
                    if (i > 0)
                        map[line.slice(0, i)] = line.slice(i + 1);
                }
                page.descriptions = map;
            }
        }
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
            spacing: 6 * Theme.scale

            Repeater {
                model: FolderListModel {
                    folder: "file://" + Quickshell.env("HOME") + "/Binaries"
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                KeybindRow {
                    id: row

                    required property string fileName

                    Layout.fillWidth: true
                    keys: row.fileName
                    desc: page.descriptions[row.fileName] ?? row.fileName
                    scrollTarget: flick

                    onActivated: page.run(row.fileName)
                }
            }
        }
    }
}
