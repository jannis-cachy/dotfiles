pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

QtObject {
    id: root

    // Kept in a state file, not settings.json, so a quickshell reload keeps the bars open
    // and the icon places without a hyprctl reload on every change
    readonly property FileView file: FileView {
        path: Quickshell.statePath("bar.json")
        blockLoading: true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: saved
            property var shown: ({})
            // Icon key to its node, counted from the bottom of the bar
            property var positions: ({})
        }
    }

    // Screen name to true while its bar was toggled on (SUPER + E, see the bar IPC handler)
    readonly property var shown: saved.shown
    readonly property var positions: saved.positions
    // Set by the control center while the Appearance page is open, applies to the main monitor
    property bool pinned: false

    // nm-applet first, the rest keeps its order
    readonly property var trayKeys: SystemTray.items.values.slice().sort((a, b) => rank(a) - rank(b)).map(i => "tray:" + (i.id || i.title))
    // Every icon, top to bottom, used to place icons that have no saved node yet (from the bottom up)
    readonly property var keys: ["search", "clock", "network", "bluetooth", "battery", "volume", "notifications", "caffeine", "power"].concat(trayKeys)

    function rank(item) {
        return (item.id || "").toLowerCase().includes("nm-applet") ? 0 : 1;
    }

    // Thin frame around every monitor and the expanded left bar on toggled monitors
    readonly property real frameSize: 8 * Theme.scale
    readonly property real barSize: 64 * Theme.scale

    function isExpanded(screenName) {
        return !!shown[screenName] || (pinned && screenName === Theme.mainMonitor);
    }

    function toggle(screenName) {
        const next = Object.assign({}, shown);
        next[screenName] = !next[screenName];
        saved.shown = next;
        file.writeAdapter();
    }

    function setPositions(map) {
        saved.positions = Object.assign({}, saved.positions, map);
        file.writeAdapter();
    }
}
