pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Installed font families (fc-list), icon themes (any dir with an index.theme),
// GTK themes (any dir with a gtk-3.0 subdir) and cursor themes (any dir with a cursors
// subdir), fetched once so AppearancePage's pickers have something to list.
Singleton {
    id: root

    property var fontFamilies: []
    property var iconThemes: []
    property var gtkThemes: []
    property var cursorThemes: []

    Component.onCompleted: {
        fontsProcess.running = true;
        iconsProcess.running = true;
        gtkThemesProcess.running = true;
        cursorThemesProcess.running = true;
    }

    Process {
        id: fontsProcess
        command: ["fc-list", ":", "family"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = new Set();
                for (const line of text.split("\n")) {
                    const name = line.split(",")[0].trim();
                    if (name)
                        set.add(name);
                }
                root.fontFamilies = Array.from(set).sort();
            }
        }
    }

    Process {
        id: iconsProcess
        command: ["bash", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do [ -f \"$d/index.theme\" ] && basename \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = new Set();
                for (const line of text.split("\n")) {
                    const name = line.trim();
                    if (name)
                        set.add(name);
                }
                root.iconThemes = Array.from(set).sort();
            }
        }
    }

    Process {
        id: gtkThemesProcess
        command: ["bash", "-c", "find /usr/share/themes ~/.themes ~/.local/share/themes -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do [ -d \"$d/gtk-3.0\" ] && basename \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = new Set();
                for (const line of text.split("\n")) {
                    const name = line.trim();
                    if (name)
                        set.add(name);
                }
                root.gtkThemes = Array.from(set).sort();
            }
        }
    }

    Process {
        id: cursorThemesProcess
        command: ["bash", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do [ -d \"$d/cursors\" ] && basename \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = new Set();
                for (const line of text.split("\n")) {
                    const name = line.trim();
                    if (name)
                        set.add(name);
                }
                root.cursorThemes = Array.from(set).sort();
            }
        }
    }
}
