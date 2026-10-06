import QtQuick
import "../../"
import "../../theme"
import "Nav.js" as Nav

// Popup with a scrollable list of text items. Up/Down move, Enter picks, Esc closes.
FocusScope {
    id: root

    property var items: []
    property int cursor: 0
    // Whatever had focus before opening, restored on close so the caller doesn't have to
    property var previousFocus: null

    // deletable: Delete or X on the cursor row (or the trash icon) asks "Delete?", the same again
    // emits deleteRequested. Moving the cursor or Esc cancels the question.
    property bool deletable: false
    property int armedIndex: -1

    signal picked(string value)
    signal deleteRequested(string value)
    signal closed

    function askDelete() {
        if (!deletable || items.length === 0)
            return;
        if (armedIndex === cursor) {
            armedIndex = -1;
            deleteRequested(items[cursor]);
            cursor = Math.min(cursor, items.length - 1);
        } else {
            armedIndex = cursor;
        }
    }

    function open() {
        previousFocus = root.Window.window?.activeFocusItem ?? null;
        // Keeps the cursor the caller set (the current value), clamped to the list
        cursor = Math.max(0, Math.min(cursor, items.length - 1));
        armedIndex = -1;
        visible = true;
        list.positionViewAtIndex(cursor, ListView.Center);
        forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
        previousFocus?.forceActiveFocus();
    }

    function move(delta) {
        const next = cursor + delta;
        if (next >= 0 && next < items.length) {
            cursor = next;
            armedIndex = -1;
            list.positionViewAtIndex(cursor, ListView.Contain);
        }
    }

    visible: false

    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onReturnPressed: {
        if (items.length > 0) {
            picked(items[cursor]);
            close();
        }
    }
    Keys.onEscapePressed: {
        if (armedIndex >= 0)
            armedIndex = -1;
        else
            close();
    }
    Keys.onDeletePressed: askDelete()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_X && deletable) {
            askDelete();
            event.accepted = true;
            return;
        }
        const dir = Nav.vim(event);
        if (dir === "up" || dir === "down") {
            move(dir === "up" ? -1 : 1);
            event.accepted = true;
        }
    }

    // Click outside the panel closes
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 300 * Theme.scale
        height: 360 * Theme.scale
        radius: Theme.rounding * Theme.scale
        color: Theme.colors.bg
        border.width: 1
        border.color: Theme.colors.border

        MouseArea {
            anchors.fill: parent
        }

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: 10 * Theme.scale
            clip: true
            model: root.items
            currentIndex: root.cursor

            delegate: Rectangle {
                required property int index
                required property string modelData

                width: list.width
                height: 28 * Theme.scale
                radius: 3 * Theme.scale
                color: root.cursor === index ? Theme.colors.accent : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8 * Theme.scale
                    text: root.armedIndex === parent.index ? "Delete?" : parent.modelData
                    color: root.cursor === index ? Theme.colors.textOnAccent : Theme.colors.text
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 13 * Theme.scale * Theme.font.scale
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        if (root.cursor !== parent.index)
                            root.armedIndex = -1;
                        root.cursor = parent.index;
                    }
                    onClicked: {
                        root.picked(parent.modelData);
                        root.close();
                    }
                }

                MaterialIcon {
                    visible: root.deletable && root.cursor === parent.index
                    anchors.right: parent.right
                    anchors.rightMargin: 8 * Theme.scale
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "delete"
                    size: 16 * Theme.scale
                    iconColor: Theme.colors.textOnAccent

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6 * Theme.scale
                        onClicked: root.askDelete()
                    }
                }
            }
        }
    }
}
