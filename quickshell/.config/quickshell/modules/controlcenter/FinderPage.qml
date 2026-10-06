import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"
import "../../theme"
import "Finder.js" as Finder

PageFrame {
    id: page

    title: "Search"
    implicitWidth: 640 * Theme.scale
    implicitHeight: 560 * Theme.scale

    signal close

    readonly property string home: Quickshell.env("HOME")
    property var entries: []
    property var results: []
    // Folder being browsed (absolute path, home when empty), selection remembered per folder
    property string dir: ""
    property var lastSelected: ({})

    // Open counts live outside settings.json, which would trigger a hyprctl reload on every write
    FileView {
        id: usageFile
        path: Quickshell.statePath("finder-usage.json")
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

    function usageOf(path) {
        return usage.counts[path] || 0;
    }

    function refresh() {
        const rel = dir === "" ? "" : (dir.startsWith(home + "/") ? dir.slice(home.length + 1) : dir).toLowerCase();
        results = Finder.search(entries, input.text, usageOf, 60, rel);
        const remembered = results.findIndex(e => e.path === lastSelected[dir]);
        list.currentIndex = remembered >= 0 ? remembered : 0;
    }

    function remember() {
        const e = results[list.currentIndex];
        if (e)
            lastSelected[dir] = e.path;
    }

    // Right on a folder shows its content, Left goes up and selects the folder again
    function enter() {
        const e = results[list.currentIndex];
        if (!e || !e.isDir)
            return;
        remember();
        dir = e.path;
        input.text = "";
        refresh();
    }

    function leave() {
        if (dir === "")
            return;
        remember();
        const from = dir;
        const up = dir.replace(/\/[^\/]*$/, "");
        dir = (up === home || up === "") ? "" : up;
        lastSelected[dir] = from;
        input.text = "";
        refresh();
    }

    function open(entry, parentDir) {
        if (!entry)
            return;
        const counts = Object.assign({}, usage.counts);
        counts[entry.path] = (counts[entry.path] || 0) + 1;
        usage.counts = counts;
        usageFile.writeAdapter();
        // open-file falls back to nvim when no default app is set for the type
        Quickshell.execDetached([home + "/Binaries/open-file", parentDir ? entry.path.replace(/\/[^\/]*$/, "") : entry.path]);
        close();
    }

    function iconFor(e) {
        if (e.isDir)
            return "folder";
        if (["pdf"].includes(e.ext))
            return "picture_as_pdf";
        if (["png", "jpg", "jpeg", "webp", "gif", "svg"].includes(e.ext))
            return "image";
        if (["mp4", "mkv", "webm", "mov"].includes(e.ext))
            return "movie";
        if (["mp3", "flac", "ogg", "wav", "m4a"].includes(e.ext))
            return "music_note";
        if (["py", "lua", "qml", "sh", "c", "cpp", "rs", "js", "tex", "typ"].includes(e.ext))
            return "code";
        return "description";
    }

    // fd lists every file and folder under home, hidden ones and the configured excludes left out
    Process {
        id: indexer

        command: {
            const cmd = ["fd", "--type", "f", "--type", "d", "--no-ignore", "--color", "never"];
            if (Theme.finder.searchAll) {
                cmd.push("--hidden");
            } else {
                if (Theme.finder.showHidden) {
                    cmd.push("--hidden");
                    for (const d of Theme.finder.excludeHiddenDirs)
                        cmd.push("-E", d);
                }
                for (const d of Theme.finder.excludeDirs)
                    cmd.push("-E", d);
                for (const x of Theme.finder.excludeExts)
                    cmd.push("-E", "*." + x);
            }
            cmd.push(".", page.home);
            if (Theme.finder.searchSystem)
                cmd.push(...Theme.finder.systemDirs);
            return cmd;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const prefix = page.home + "/";
                page.entries = text.split("\n").filter(l => l.length > 1).map(l => {
                    const isDir = l.endsWith("/");
                    const path = isDir ? l.slice(0, -1) : l;
                    // outside home the absolute path is the key
                    const rel = path.startsWith(prefix) ? path.slice(prefix.length) : path;
                    const name = rel.split("/").pop();
                    const dot = name.lastIndexOf(".");
                    return {
                        path: path,
                        rel: rel.toLowerCase(),
                        relDisplay: rel,
                        name: name.toLowerCase(),
                        display: name,
                        isDir: isDir,
                        ext: !isDir && dot > 0 ? name.slice(dot + 1).toLowerCase() : "",
                        depth: rel.split("/").length - 1
                    };
                });
                page.refresh();
            }
        }
    }

    Component.onCompleted: {
        indexer.running = true;
        Qt.callLater(() => input.forceActiveFocus());
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: page.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Theme.scale

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40 * Theme.scale
            radius: Theme.rounding / 2 * Theme.scale
            color: Theme.colors.surface
            border.width: 2 * Theme.scale
            border.color: input.activeFocus ? Theme.colors.focus : "transparent"

            MaterialIcon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 10 * Theme.scale
                anchors.verticalCenter: parent.verticalCenter
                icon: "search"
                size: 20 * Theme.scale
                iconColor: Theme.colors.textMuted
            }

            TextInput {
                id: input
                anchors.left: searchIcon.right
                anchors.leftMargin: 8 * Theme.scale
                anchors.right: parent.right
                anchors.rightMargin: 10 * Theme.scale
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.colors.text
                selectionColor: Theme.colors.selection
                font.family: Theme.font.uiFamily
                font.pixelSize: 16 * Theme.scale * Theme.font.scale
                clip: true
                activeFocusOnTab: true

                onTextChanged: debounce.restart()

                // Arrows edit the text first, at its ends they browse folders
                Keys.onRightPressed: event => {
                    if (cursorPosition === text.length && page.results[list.currentIndex]?.isDir)
                        page.enter();
                    else
                        event.accepted = false;
                }
                Keys.onLeftPressed: event => {
                    if (cursorPosition === 0 && page.dir !== "")
                        page.leave();
                    else
                        event.accepted = false;
                }
                Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
                Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                // Shift opens the containing folder instead
                Keys.onReturnPressed: event => page.open(page.results[list.currentIndex], event.modifiers & Qt.ShiftModifier)
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: page.results
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0

            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: ListView.isCurrentItem

                width: ListView.view.width
                height: 40 * Theme.scale
                radius: Theme.rounding / 2 * Theme.scale
                color: selected ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : "transparent"
                border.width: selected ? 2 * Theme.scale : 0
                border.color: Theme.colors.focus

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10 * Theme.scale
                    anchors.rightMargin: 10 * Theme.scale
                    spacing: 10 * Theme.scale

                    MaterialIcon {
                        icon: page.iconFor(row.modelData)
                        size: 18 * Theme.scale
                        iconColor: row.selected ? Theme.colors.text : Theme.colors.textMuted
                    }

                    Text {
                        text: row.modelData.display
                        color: row.selected ? Theme.colors.text : Theme.colors.textMuted
                        font.bold: true
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 14 * Theme.scale * Theme.font.scale
                        elide: Text.ElideRight
                        Layout.maximumWidth: parent.width * 0.55
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.relDisplay.slice(0, Math.max(0, row.modelData.relDisplay.length - row.modelData.display.length - 1))
                        horizontalAlignment: Text.AlignRight
                        color: Theme.colors.textMuted
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 12 * Theme.scale * Theme.font.scale
                        elide: Text.ElideLeft
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        list.currentIndex = row.index;
                        page.open(row.modelData, false);
                    }
                }
            }
        }
    }
}
