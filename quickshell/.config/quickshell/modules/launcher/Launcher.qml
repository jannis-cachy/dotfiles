import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../"
import "../../theme"
import "Aliases.js" as Aliases
import "Hidden.js" as Hidden

Scope {
    id: root

    property bool open: false
    property string query: ""
    property var results: []
    // workspace to return to when the launcher closes
    property string previousWorkspace: ""
    property bool arrived: false

    readonly property string deskName: "desktop"

    // qs ipc call launcher toggle
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.open)
                root.close(true);
            else
                root.openLauncher();
        }
    }

    function openLauncher() {
        previousWorkspace = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.name : "";
        arrived = false;
        query = "";
        refresh();
        open = true;
        switchTimer.restart();
    }

    // Lets the translucent background and icons draw first, so the empty workspace does not flash
    Timer {
        id: switchTimer
        interval: 120
        onTriggered: {
            if (root.open)
                Hyprland.dispatch(`hl.dsp.focus({ workspace = "name:${root.deskName}" })`);
        }
    }

    function close(restore) {
        switchTimer.stop();
        open = false;
        arrived = false;
        if (restore && previousWorkspace !== "" && previousWorkspace !== deskName)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${previousWorkspace}" })`);
    }

    // Leaving the desktop workspace by hand (SUPER + number) closes the launcher without jumping back
    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (!root.open)
                return;
            const name = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.name : "";
            if (name === root.deskName)
                root.arrived = true;
            else if (root.arrived)
                root.close(false);
        }
    }

    // Launch counts live outside settings.json, which would trigger a hyprctl reload on every write
    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        blockLoading: true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: usage
            property var counts: ({})
        }
    }

    function usageOf(entry) {
        return usage.counts[entry.id] || 0;
    }

    function launch(entry) {
        if (!entry)
            return;
        const counts = Object.assign({}, usage.counts);
        counts[entry.id] = (counts[entry.id] || 0) + 1;
        usage.counts = counts;
        usageFile.writeAdapter();
        close(true);
        entry.execute();
    }

    // Strict search: every query token must start a word of the name, id, executable, alias or
    // keyword. Name hits rank above the rest, a plain substring only counts in the name.
    function words(text) {
        return text.toLowerCase().split(/[\s\-_.]+/).filter(w => w.length > 0);
    }

    function scoreEntry(entry, tokens) {
        const name = entry.name.toLowerCase();
        const id = (entry.id || "").toLowerCase().replace(/\.desktop$/, "");
        const exec = entry.command && entry.command.length > 0 ? entry.command[0].split("/").pop().toLowerCase() : "";
        const extra = (Aliases.aliases[id] || []).concat(entry.keywords || [], [entry.genericName || ""]);
        const nameWords = words(name);
        let total = 0;
        for (const t of tokens) {
            let s = 0;
            if (name.startsWith(t))
                s = 100;
            else if (nameWords.some(w => w.startsWith(t)))
                s = 80;
            else if (id.startsWith(t) || exec.startsWith(t))
                s = 70;
            else if (extra.some(a => a.toLowerCase().startsWith(t)))
                s = 60;
            else if (words(id + " " + exec).some(w => w.startsWith(t)))
                s = 40;
            else if (t.length >= 3 && name.includes(t))
                s = 20;
            if (s === 0)
                return 0;
            total += s;
        }
        return total;
    }

    function refresh() {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay && (Theme.launcher.showMore || !Hidden.isHidden(e)));
        const q = query.trim().toLowerCase();
        let list;
        if (q === "") {
            list = all.slice();
        } else {
            const tokens = q.split(/\s+/);
            list = all.map(e => ({
                        e: e,
                        s: scoreEntry(e, tokens)
                    })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || usageOf(b.e) - usageOf(a.e) || a.e.name.localeCompare(b.e.name)).map(x => x.e);
        }
        if (q === "")
            list.sort((a, b) => usageOf(b) - usageOf(a) || a.name.localeCompare(b.name));
        // same name twice (e.g. duplicate desktop files) shows once
        const seen = {};
        results = list.filter(e => {
            const k = e.name.toLowerCase();
            if (seen[k])
                return false;
            seen[k] = true;
            return true;
        });
    }

    onQueryChanged: refresh()

    Connections {
        target: Theme.launcher

        function onShowMoreChanged() {
            root.refresh();
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            root.refresh();
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            // The layer rule in Rules.lua blurs only the "launcher" namespace
            WlrLayershell.namespace: Theme.launcher.blur ? "launcher" : "launcher-flat"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.launcher.dim ? Qt.rgba(Theme.colors.surface.r, Theme.colors.surface.g, Theme.colors.surface.b, 0.7) : "transparent"

            // 0 to 1 on open, search box drops in and the grid rises, instant with animations off.
            // The dim layer itself fades through Hyprland's layersIn animation.
            property real enter: 1
            Anim on enter {
                from: 0
                to: 1
                type: "defaultSpatial"
            }

            // click on empty space closes
            MouseArea {
                anchors.fill: parent
                onClicked: root.close(true)
            }

            Rectangle {
                id: searchBox
                anchors.top: parent.top
                anchors.topMargin: 60 * Theme.scale
                anchors.horizontalCenter: parent.horizontalCenter
                width: 480 * Theme.scale
                height: 48 * Theme.scale
                radius: Theme.rounding * Theme.scale
                color: Theme.colors.surface
                border.width: 2 * Theme.scale
                border.color: Theme.colors.focus
                opacity: win.enter
                transform: Translate {
                    y: (1 - win.enter) * -16 * Theme.scale
                }

                MaterialIcon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * Theme.scale
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "search"
                    size: 22 * Theme.scale
                    iconColor: Theme.colors.textMuted
                }

                TextInput {
                    id: input
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10 * Theme.scale
                    anchors.right: parent.right
                    anchors.rightMargin: 14 * Theme.scale
                    anchors.verticalCenter: parent.verticalCenter
                    focus: true
                    color: Theme.colors.text
                    selectionColor: Theme.colors.selection
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 18 * Theme.scale * Theme.font.scale
                    clip: true

                    onTextChanged: {
                        root.query = text;
                        grid.currentIndex = 0;
                    }

                    Keys.onEscapePressed: root.close(true)
                    Keys.onReturnPressed: root.launch(root.results[grid.currentIndex])
                    Keys.onEnterPressed: root.launch(root.results[grid.currentIndex])
                    Keys.onLeftPressed: event => {
                        if (grid.count > 0)
                            grid.moveCurrentIndexLeft();
                        else
                            event.accepted = false;
                    }
                    Keys.onRightPressed: event => {
                        if (grid.count > 0)
                            grid.moveCurrentIndexRight();
                        else
                            event.accepted = false;
                    }
                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                    Keys.onTabPressed: grid.moveCurrentIndexRight()
                }
            }

            GridView {
                id: grid
                anchors.top: searchBox.bottom
                anchors.topMargin: 40 * Theme.scale
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60 * Theme.scale
                anchors.horizontalCenter: parent.horizontalCenter

                readonly property real cell: 150 * Theme.scale
                readonly property int cols: Math.max(1, Math.floor((win.width - 240 * Theme.scale) / cell))
                width: cols * cell
                cellWidth: cell
                cellHeight: cell * 1.1
                clip: true
                interactive: true
                keyNavigationEnabled: false
                highlightMoveDuration: 0
                model: root.results
                opacity: win.enter
                transform: Translate {
                    y: (1 - win.enter) * 24 * Theme.scale
                }

                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool current: GridView.isCurrentItem

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6 * Theme.scale
                        radius: Theme.rounding * Theme.scale
                        color: tile.current ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : "transparent"
                        border.width: tile.current ? 2 * Theme.scale : 0
                        border.color: Theme.colors.focus

                        Image {
                            id: icon
                            anchors.top: parent.top
                            anchors.topMargin: 14 * Theme.scale
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 80 * Theme.scale
                            height: width
                            sourceSize: Qt.size(width * 2, height * 2)
                            fillMode: Image.PreserveAspectFit
                            source: Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
                        }

                        Text {
                            anchors.top: icon.bottom
                            anchors.topMargin: 8 * Theme.scale
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6 * Theme.scale
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: tile.modelData.name
                            color: tile.current ? Theme.colors.text : Theme.colors.textMuted
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 13 * Theme.scale * Theme.font.scale
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: grid.currentIndex = tile.index
                            onClicked: root.launch(tile.modelData)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: "No match"
                color: Theme.colors.textMuted
                font.family: Theme.font.uiFamily
                font.pixelSize: 16 * Theme.scale * Theme.font.scale
            }
        }
    }
}
