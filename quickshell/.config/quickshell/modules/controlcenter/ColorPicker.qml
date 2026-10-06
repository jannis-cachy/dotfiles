import QtQuick
import "../../theme"
import "Nav.js" as Nav

// Popup with a fixed list of colors. Arrows move, Enter picks, Esc closes.
FocusScope {
    id: root

    readonly property int columns: 8
    // One row per hue family, edit freely
    readonly property var colors: [
        "#fff59d", "#fff176", "#ffee58", "#ffeb3b", "#fdd835", "#fbc02d", "#f9a825", "#ff8f00",
        "#c8e6c9", "#a5d6a7", "#81c784", "#66bb6a", "#4caf50", "#43a047", "#2e7d32", "#1b5e20",
        "#ffcdd2", "#ef9a9a", "#e57373", "#ef5350", "#e53935", "#c62828", "#8e0000", "#5c1010",
        "#bbdefb", "#90caf9", "#64b5f6", "#42a5f5", "#1e88e5", "#1565c0", "#0d3c8a", "#0a2a5e",
        "#e1bee7", "#ba68c8", "#8e24aa", "#4a148c", "#bdbdbd", "#757575", "#313244", "#0d0d0d"
    ]
    property int cursor: 0

    signal picked(string hex)
    signal closed

    function open() {
        cursor = 0;
        visible = true;
        forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    function move(delta) {
        const next = cursor + delta;
        if (next >= 0 && next < colors.length)
            cursor = next;
    }

    visible: false

    Keys.onLeftPressed: move(-1)
    Keys.onRightPressed: move(1)
    Keys.onUpPressed: move(-columns)
    Keys.onDownPressed: move(columns)
    Keys.onReturnPressed: {
        picked(colors[cursor]);
        close();
    }
    Keys.onEscapePressed: close()
    Keys.onPressed: event => {
        const step = {
            left: -1,
            right: 1,
            up: -columns,
            down: columns
        }[Nav.vim(event)];
        if (step) {
            move(step);
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
        width: grid.width + 28 * Theme.scale
        height: grid.height + label.height + 42 * Theme.scale
        radius: Theme.rounding * Theme.scale
        color: Theme.colors.bg
        border.width: 1
        border.color: Theme.colors.border

        MouseArea {
            anchors.fill: parent
        }

        Grid {
            id: grid

            x: 14 * Theme.scale
            y: 14 * Theme.scale
            columns: root.columns
            spacing: 6 * Theme.scale

            Repeater {
                model: root.colors

                Rectangle {
                    required property int index
                    required property string modelData

                    width: 30 * Theme.scale
                    height: width
                    radius: 3 * Theme.scale
                    color: modelData
                    border.width: root.cursor === index ? 2 * Theme.scale : 1
                    border.color: root.cursor === index ? Theme.colors.focus : Theme.colors.border

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.cursor = parent.index
                        onClicked: {
                            root.picked(parent.modelData);
                            root.close();
                        }
                    }
                }
            }
        }

        Text {
            id: label

            anchors.left: grid.left
            anchors.top: grid.bottom
            anchors.topMargin: 10 * Theme.scale
            text: root.colors[root.cursor]
            color: Theme.colors.textMuted
            font.family: Theme.font.uiFamily
            font.pixelSize: 12 * Theme.scale * Theme.font.scale
        }
    }
}
