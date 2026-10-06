import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string label: ""
    property bool checked: false
    property int navGroup: -1

    signal toggled(bool value)

    activeFocusOnTab: true

    Keys.onReturnPressed: toggled(!checked)
    Keys.onSpacePressed: toggled(!checked)
    // Left/Right set the toggle directly instead of navigating, so it must consume the keys itself
    Keys.onLeftPressed: {
        if (root.checked)
            root.toggled(false);
    }
    Keys.onRightPressed: {
        if (!root.checked)
            root.toggled(true);
    }

    implicitWidth: inner.implicitWidth + 16 * Theme.scale
    implicitHeight: inner.implicitHeight + 8 * Theme.scale

    FocusBox {}

    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 8 * Theme.scale
        anchors.rightMargin: 8 * Theme.scale
        spacing: 12 * Theme.scale

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

        Rectangle {
            implicitWidth: 44 * Theme.scale
            implicitHeight: 24 * Theme.scale
            radius: height / 2
            color: root.checked ? Theme.colors.accent : Theme.colors.surface
            border.width: root.activeFocus ? 2 : 0
            border.color: Theme.colors.focus

            Rectangle {
                width: parent.height - 6 * Theme.scale
                height: width
                radius: width / 2
                y: 3 * Theme.scale
                x: root.checked ? parent.width - width - 3 * Theme.scale : 3 * Theme.scale
                color: Theme.colors.textOnAccent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggled(!root.checked)
            }
        }
    }
}
