import QtQuick
import QtQuick.Layouts
import "../../theme"

// Label plus the current value, Enter or a click opens the caller's ListPicker
Item {
    id: root

    property string label: ""
    property string value: ""
    // Group index for PageFrame's Right-arrow group-jump, -1 means ungrouped
    property int navGroup: -1

    signal activated

    activeFocusOnTab: true

    Keys.onReturnPressed: activated()

    implicitWidth: inner.implicitWidth + 16 * Theme.scale
    implicitHeight: inner.implicitHeight + 8 * Theme.scale

    FocusBox {}

    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 8 * Theme.scale
        anchors.rightMargin: 8 * Theme.scale
        spacing: 8 * Theme.scale

        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.activeFocus ? Theme.colors.text : Theme.colors.textMuted
            font.family: Theme.font.uiFamily
            font.pixelSize: 13 * Theme.scale * Theme.font.scale
            font.bold: true
        }

        Rectangle {
            implicitWidth: valueText.implicitWidth + 16 * Theme.scale
            implicitHeight: 26 * Theme.scale
            radius: 3 * Theme.scale
            color: Theme.colors.surface
            border.width: root.activeFocus ? 1 : 0
            border.color: Theme.colors.focus

            Text {
                id: valueText
                anchors.centerIn: parent
                text: root.value
                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: 12 * Theme.scale * Theme.font.scale
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.activated()
            }
        }
    }
}
