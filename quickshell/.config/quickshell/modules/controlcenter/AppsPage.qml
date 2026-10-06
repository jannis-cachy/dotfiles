import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "Nav.js" as Nav
import "FileTypes.js" as FileTypes

PageFrame {
    id: page

    title: "Applications"
    implicitWidth: 520 * Theme.scale
    implicitHeight: 560 * Theme.scale

    // type label to the desktop id that is the default now
    property var current: ({})

    function installed(app) {
        return DesktopEntries.byId(app.id.replace(/\.desktop$/, "")) !== null;
    }

    function focusItem(item) {
        if (!item)
            return;
        item.forceActiveFocus();
        scrollIntoView(item);
    }

    function appsOf(type) {
        return type.apps.filter(a => installed(a)).slice(0, 3);
    }

    // xdg-mime writes ~/.config/mimeapps.list, which xdg-open, yazi and the finder all follow
    function choose(type, app) {
        Quickshell.execDetached(["xdg-mime", "default", app.id].concat(type.mimes));
        const next = Object.assign({}, current);
        next[type.label] = app.id;
        current = next;
    }

    Process {
        id: reader

        command: ["bash", "-c", FileTypes.types.map(t => `echo "${t.label}|$(xdg-mime query default ${t.mimes[0]})"`).join("; ")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("|");
                    if (i > 0)
                        map[line.slice(0, i)] = line.slice(i + 1);
                }
                page.current = map;
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
            spacing: 14 * Theme.scale

            Repeater {
                id: blocks

                model: FileTypes.types.filter(t => page.appsOf(t).length > 0)

                ColumnLayout {
                    id: block

                    required property var modelData
                    required property int index
                    readonly property var apps: page.appsOf(modelData)

                    Layout.fillWidth: true
                    spacing: 6 * Theme.scale

                    // Chosen option, else the first one
                    function focusOption() {
                        let target = null;
                        for (let i = 0; i < slots.count; i++) {
                            const b = slots.itemAt(i).button;
                            if (b.visible && (target === null || b.chosen))
                                target = b;
                        }
                        page.focusItem(target);
                    }

                    function focusHeader() {
                        page.focusItem(header);
                    }

                    // The file type is a stop of its own: Right/Left step through the types,
                    // Down enters the options
                    Rectangle {
                        id: header

                        implicitWidth: headerText.implicitWidth + 20 * Theme.scale
                        implicitHeight: 26 * Theme.scale
                        radius: Theme.rounding / 2 * Theme.scale
                        color: "transparent"
                        activeFocusOnTab: true

                        FocusBox {}

                        Text {
                            id: headerText
                            anchors.centerIn: parent
                            text: block.modelData.label
                            color: header.activeFocus ? Theme.colors.text : Theme.colors.textMuted
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 12 * Theme.scale * Theme.font.scale
                            font.bold: true
                        }

                        Keys.onReturnPressed: block.focusOption()
                        Keys.onSpacePressed: block.focusOption()
                        Keys.onDownPressed: block.focusOption()
                        // Returns false at an edge so PageFrame takes the key
                        function step(dir) {
                            if (dir === "down") {
                                block.focusOption();
                                return true;
                            }
                            const prev = blocks.itemAt(block.index - 1);
                            const next = blocks.itemAt(block.index + 1);
                            if (dir === "right" && next)
                                next.focusHeader();
                            else if (dir === "left" && prev)
                                prev.focusHeader();
                            else if (dir === "up" && prev)
                                prev.focusOption();
                            else
                                return false;
                            return true;
                        }
                        Keys.onRightPressed: event => event.accepted = step("right")
                        Keys.onLeftPressed: event => event.accepted = step("left")
                        Keys.onUpPressed: event => event.accepted = step("up")
                        Keys.onPressed: event => {
                            const dir = Nav.vim(event);
                            if (dir)
                                event.accepted = step(dir);
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: block.focusOption()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * Theme.scale

                        // Always three slots so the buttons keep their width, unused ones stay empty
                        Repeater {
                            id: slots

                            model: 3

                            Item {
                                id: slot

                                required property int index
                                readonly property var app: block.apps[index] ?? null
                                readonly property alias button: choice

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 34 * Theme.scale

                                AppChoice {
                                    id: choice

                                    anchors.fill: parent
                                    visible: slot.app !== null
                                    text: slot.app ? slot.app.name : ""
                                    chosen: slot.app !== null && page.current[block.modelData.label] === slot.app.id
                                    onActivated: page.choose(block.modelData, slot.app)

                                    // Left/Right between the options, the ends stay put or return to the type
                                    function step(dir) {
                                        if (dir === "left") {
                                            const prev = slot.index > 0 ? slots.itemAt(slot.index - 1).button : null;
                                            if (prev && prev.visible)
                                                page.focusItem(prev);
                                            else
                                                block.focusHeader();
                                        } else if (dir === "right") {
                                            const next = slot.index < 2 ? slots.itemAt(slot.index + 1).button : null;
                                            if (next && next.visible)
                                                page.focusItem(next);
                                        } else if (dir === "up") {
                                            block.focusHeader();
                                        } else {
                                            // Last type hands Down to PageFrame, which wraps to the top
                                            const next = blocks.itemAt(block.index + 1);
                                            if (!next)
                                                return false;
                                            next.focusHeader();
                                        }
                                        return true;
                                    }
                                    Keys.onLeftPressed: event => event.accepted = step("left")
                                    Keys.onRightPressed: event => event.accepted = step("right")
                                    Keys.onUpPressed: event => event.accepted = step("up")
                                    Keys.onDownPressed: event => event.accepted = step("down")
                                    Keys.onPressed: event => {
                                        const dir = Nav.vim(event);
                                        if (dir)
                                            event.accepted = step(dir);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
