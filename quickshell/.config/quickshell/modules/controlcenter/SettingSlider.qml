import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string label: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.1
    property real value: 0
    property int decimals: 0
    // Group index for PageFrame's Right-arrow group-jump, -1 means ungrouped
    property int navGroup: -1

    // Emitted once when the handle is released, not while dragging
    signal committed(real value)

    activeFocusOnTab: true

    // Left and Right arrows adjust and commit on every press, hjkl stay navigation (PageFrame)
    Keys.onLeftPressed: {
        slider.decrease();
        root.committed(slider.value);
    }
    Keys.onRightPressed: {
        slider.increase();
        root.committed(slider.value);
    }

    implicitWidth: inner.implicitWidth + 16 * Theme.scale
    implicitHeight: inner.implicitHeight + 8 * Theme.scale

    FocusBox {}

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 8 * Theme.scale
        anchors.rightMargin: 8 * Theme.scale
        spacing: 6 * Theme.scale

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.label
                color: root.activeFocus ? Theme.colors.text : Theme.colors.textMuted
                font.family: Theme.font.uiFamily
                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: slider.value.toFixed(root.decimals)
                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: 14 * Theme.scale * Theme.font.scale
            }
        }

        Slider {
            id: slider

            Layout.fillWidth: true
            implicitHeight: 24 * Theme.scale
            // Mouse only, arrow keys must be free to leave it
            focusPolicy: Qt.NoFocus

            from: root.from
            to: root.to
            stepSize: root.stepSize
            snapMode: Slider.SnapAlways

            onPressedChanged: {
                if (!pressed)
                    root.committed(value);
            }

            Binding {
                target: slider
                property: "value"
                value: root.value
                when: !slider.pressed
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 6 * Theme.scale
                radius: height / 2
                color: Theme.colors.surface

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Theme.colors.accent
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16 * Theme.scale
                height: width
                radius: width / 2
                color: Theme.colors.textOnAccent
                border.width: root.activeFocus ? 2 * Theme.scale : 0
                border.color: Theme.colors.focus
            }
        }
    }
}
