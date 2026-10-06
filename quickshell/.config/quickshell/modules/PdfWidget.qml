import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../theme"

Scope {
    id: pdfWidgetScope

    // Move bibData to root level or reference it correctly
    property var bibData: ({})

    // qs ipc call pdf toggle
    IpcHandler {
        target: "pdf"

        function toggle(): void {
            if (panel.expanded)
                panel.closePopup();
            else
                panel.openPopup();
        }
    }

    LazyLoader {
        active: panel.expanded

        ClickAway {
            screen: Theme.mainScreen
            onClicked: panel.closePopup()
        }
    }

    // Overlay above the bottom frame edge of the main monitor, only visible while expanded
    PanelWindow {
        id: panel
        screen: Theme.mainScreen

        property bool expanded: false
        property real expandedWidth: 900 * Theme.scale
        property real expandedHeight: 700 * Theme.scale

        anchors.bottom: true
        margins.bottom: BarState.frameSize
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        visible: expanded
        implicitWidth: expandedWidth

        Reveal {
            target: panel.contentItem
            when: panel.expanded
        }
        implicitHeight: expandedHeight

        function openPopup() {
            expanded = true;
            Qt.callLater(() => searchField.forceActiveFocus());
        }

        function closePopup() {
            expanded = false;
        }

        Timer {
            id: previewDebounceTimer
            property string targetPath: ""
            interval: 100
            onTriggered: {
                if (targetPath)
                    pdfFinder.requestThumbnail(targetPath);
                else
                    previewImage.source = "";
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: Theme.colors.bg
            border.width: 2 * Theme.scale
            border.color: Theme.colors.border
            radius: Theme.rounding * Theme.scale
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10 * Theme.scale
            spacing: 10 * Theme.scale

            ColumnLayout {
                Layout.preferredWidth: 300 * Theme.scale
                Layout.fillHeight: true
                spacing: 8 * Theme.scale

                TextField {
                    id: searchField
                    Layout.preferredWidth: 300 * Theme.scale
                    placeholderText: "Search PDFs…"
                    color: Theme.colors.bg
                    onTextChanged: pdfFinder.updateFilter(text)
                    Keys.onDownPressed: resultsList.incrementCurrentIndex()
                    Keys.onUpPressed: resultsList.decrementCurrentIndex()
                    Keys.onEscapePressed: panel.closePopup()
                    Keys.onReturnPressed: {
                        const item = pdfFinder.filtered[resultsList.currentIndex];
                        if (item)
                            pdfFinder.openFile(item.path);
                    }
                }

                ListView {
                    id: resultsList
                    Layout.fillHeight: true
                    width: 300 * Theme.scale
                    clip: true
                    model: pdfFinder.filtered
                    currentIndex: 0

                    onCurrentIndexChanged: pdfFinder.previewCurrent()
                    delegate: Rectangle {
                        id: resultDelegate
                        width: resultsList.width
                        height: 30 * Theme.scale
                        radius: Theme.rounding / 2 * Theme.scale

                        readonly property bool isCurrent: index === resultsList.currentIndex

                        color: mouseAreaList.pressed ? Theme.colors.accent : mouseAreaList.containsMouse ? Theme.colors.selection : "transparent"
                        border.width: isCurrent ? 2 : 0
                        border.color: Theme.colors.focus

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8 * Theme.scale
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            // Show title or author if available, fallback to filename
                            text: modelData.title ? modelData.title : modelData.name
                            color: Theme.colors.text
                        }

                        MouseArea {
                            id: mouseAreaList
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: resultsList.currentIndex = index
                            onClicked: {
                                resultsList.currentIndex = index;
                                pdfFinder.openFile(modelData.path);
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.rounding / 2 * Theme.scale
                color: Theme.colors.bg
                clip: true

                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.margins: 4 * Theme.scale
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    sourceSize.width: width
                    sourceSize.height: height
                }

                Text {
                    anchors.centerIn: parent
                    visible: previewImage.status !== Image.Ready
                    text: previewImage.status === Image.Loading ? "rendering…" : "no preview"
                    color: Theme.colors.text
                }
            }
        }
    }

    QtObject {
        id: pdfFinder

        property var allFiles: []
        property var filtered: []
        property string thumbnailDir: Quickshell.env("HOME") + "/.cache/pdf-widget-thumbs"
        property var generatedPaths: ({})
        property string pendingPath: ""

        function hashPath(path) {
            let hash = 5381;
            for (let i = 0; i < path.length; i++) {
                hash = ((hash << 5) + hash + path.charCodeAt(i)) >>> 0;
            }
            return hash.toString(16);
        }

        function thumbnailPathFor(path) {
            return thumbnailDir + "/" + hashPath(path) + ".png";
        }

        function requestThumbnail(path) {
            if (!path)
                return;

            if (generatedPaths[path]) {
                previewImage.source = "file://" + thumbnailPathFor(path);
                return;
            }

            if (thumbProc.running) {
                pendingPath = path;
                return;
            }

            thumbProc.sourcePath = path;
            thumbProc.command = ["pdftoppm", "-png", "-f", "1", "-singlefile", "-scale-to-x", "500", "-scale-to-y", "-1", path, thumbnailDir + "/" + hashPath(path)];
            thumbProc.running = true;
        }

        function previewCurrent() {
            const item = filtered[resultsList.currentIndex];
            previewDebounceTimer.targetPath = item ? item.path : "";
            previewDebounceTimer.restart();
        }

        onFilteredChanged: previewCurrent()

        function openFile(path) {
            if (!path)
                return;
            Quickshell.execDetached(["zathura", path]);
            panel.closePopup();
            searchField.text = "";
        }

        function addFile(name) {
            if (!name || name.length === 0)
                return;

            const meta = bibData[name] || {
                author: "",
                title: "",
                year: ""
            };

            allFiles = allFiles.concat([
                {
                    name: name,
                    path: Quickshell.env("HOME") + "/pdf/" + name,
                    author: meta.author || "",
                    title: meta.title || "",
                    year: meta.year || ""
                }
            ]);
            updateFilter(searchField.text);
        }

        // Called when bibProc finishes loading JSON metadata
        function attachBibData(data) {
            bibData = data;
            let updated = [];
            for (let i = 0; i < allFiles.length; i++) {
                let item = allFiles[i];
                let meta = bibData[item.name] || {};
                item.author = meta.author || "";
                item.title = meta.title || "";
                item.year = meta.year || "";
                updated.push(item);
            }
            allFiles = updated;
            updateFilter(searchField.text);
        }

        function fuzzyScore(query, target) {
            if (!target || target.length === 0)
                return -1;
            query = query.toLowerCase();
            target = target.toLowerCase();
            let qi = 0, score = 0, consecutive = 0;
            for (let ti = 0; ti < target.length && qi < query.length; ti++) {
                if (target[ti] === query[qi]) {
                    score += 1 + consecutive * 2;
                    consecutive++;
                    qi++;
                } else {
                    consecutive = 0;
                }
            }
            return qi === query.length ? score : -1;
        }

        property int listNumber: 27

        function updateFilter(query) {
            if (!query || query.length === 0) {
                filtered = allFiles.slice(0, listNumber);
            } else {
                let scored = [];
                for (const f of allFiles) {
                    const scoreFilename = fuzzyScore(query, f.name);
                    const scoreAuthor = fuzzyScore(query, f.author);
                    const scoreTitle = fuzzyScore(query, f.title);

                    const maxScore = Math.max(scoreFilename, scoreAuthor > 0 ? scoreAuthor * 1.2 : -1, scoreTitle);

                    if (maxScore >= 0) {
                        scored.push(Object.assign({}, f, {
                            score: maxScore
                        }));
                    }
                }
                scored.sort((a, b) => b.score - a.score);
                filtered = scored.slice(0, listNumber);
            }
            resultsList.currentIndex = 0;
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c", "find -L ~/pdf -maxdepth 1 -type f -iname '*.pdf' -printf '%T@ %f\\n' | sort -rn | cut -d' ' -f2-"]
        running: true
        stdout: SplitParser {
            onRead: data => pdfFinder.addFile(data)
        }
    }

    Process {
        command: ["mkdir", "-p", pdfFinder.thumbnailDir]
        running: true
    }

    Process {
        id: jsonProc
        command: ["cat", Quickshell.env("HOME") + "/pdf/library.json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    pdfFinder.attachBibData(parsed);
                    console.log("Loaded JSON metadata:", Object.keys(parsed).length, "entries");
                } catch (e) {
                    console.log("Failed to parse library.json:", e);
                }
            }
        }
    }
    Process {
        id: thumbProc
        property string sourcePath: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                pdfFinder.generatedPaths[sourcePath] = true;
                const current = pdfFinder.filtered[resultsList.currentIndex];
                if (current && current.path === sourcePath)
                    previewImage.source = "file://" + pdfFinder.thumbnailPathFor(sourcePath);
            }
            if (pdfFinder.pendingPath) {
                const next = pdfFinder.pendingPath;
                pdfFinder.pendingPath = "";
                pdfFinder.requestThumbnail(next);
            }
        }
    }
}
