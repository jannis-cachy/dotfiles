import QtQuick
import QtQuick.Layouts
import "../../theme"

// One focusable keybind entry. scrollTarget is the Flickable to keep this row visible in.
Rectangle {
    id: root

    property string keys: ""
    property string desc: ""
    property bool disabledStyle: false
    property Flickable scrollTarget: null
    // Group index for PageFrame's Right-arrow group-jump, -1 means ungrouped
    property int navGroup: -1

    signal activated

    implicitHeight: 42 * Theme.scale
    radius: Theme.rounding / 2 * Theme.scale
    activeFocusOnTab: true
    color: root.activeFocus ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : (mouseArea.containsMouse ? Theme.colors.surface : "transparent")
    border.width: root.activeFocus ? 2 * Theme.scale : 0
    border.color: Theme.colors.focus

    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    onActiveFocusChanged: {
        if (!activeFocus || !scrollTarget)
            return;
        const p = root.mapToItem(scrollTarget, 0, 0);
        if (p.y < 0)
            scrollTarget.contentY += p.y;
        else if (p.y + root.height > scrollTarget.height)
            scrollTarget.contentY += p.y + root.height - scrollTarget.height;
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8 * Theme.scale
        spacing: 12 * Theme.scale

        Text {
            Layout.preferredWidth: 170 * Theme.scale
            text: root.keys
            color: root.disabledStyle ? Theme.colors.textMuted : (root.activeFocus ? Theme.colors.text : Theme.colors.textMuted)
            font.bold: true
            font.family: Theme.font.uiFamily
            font.pixelSize: 12 * Theme.scale * Theme.font.scale
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.desc
            color: root.disabledStyle ? Theme.colors.textMuted : Theme.colors.text
            font.family: Theme.font.uiFamily
            font.pixelSize: 13 * Theme.scale * Theme.font.scale
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.forceActiveFocus();
            root.activated();
        }
    }
}
