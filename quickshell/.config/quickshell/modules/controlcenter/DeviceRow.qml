import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../"
import "../../theme"

// One selectable sink/source row. scrollTarget is the Flickable to keep this row visible in.
// The edit icon turns the label into a text field, Enter renames (emits renamed), Esc cancels.
Rectangle {
    id: root

    property string label: ""
    property bool current: false
    property Flickable scrollTarget: null
    property bool editing: false
    property int navGroup: -1

    signal activated
    signal renamed(string text)

    implicitHeight: 36 * Theme.scale
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
        spacing: 8 * Theme.scale

        Text {
            Layout.fillWidth: true
            visible: !root.editing
            text: root.label
            color: root.current ? Theme.colors.text : Theme.colors.textMuted
            font.bold: root.current
            font.family: Theme.font.uiFamily
            font.pixelSize: 13 * Theme.scale * Theme.font.scale
            elide: Text.ElideRight
        }

        TextField {
            id: editField

            Layout.fillWidth: true
            visible: root.editing
            text: root.label
            color: Theme.colors.text
            font.family: Theme.font.uiFamily
            font.pixelSize: 13 * Theme.scale * Theme.font.scale
            selectByMouse: true
            leftPadding: 6 * Theme.scale
            rightPadding: 6 * Theme.scale

            background: Rectangle {
                radius: 3 * Theme.scale
                color: Theme.colors.surface
                border.width: 1
                border.color: Theme.colors.focus
            }

            Keys.onEscapePressed: {
                root.editing = false;
                root.forceActiveFocus();
            }
            onAccepted: {
                root.renamed(text);
                root.editing = false;
                root.forceActiveFocus();
            }
            onVisibleChanged: {
                if (visible) {
                    forceActiveFocus();
                    selectAll();
                }
            }
        }

        Rectangle {
            id: editButton

            visible: !root.editing
            implicitWidth: 22 * Theme.scale
            implicitHeight: 22 * Theme.scale
            radius: Theme.rounding / 2 * Theme.scale
            color: editArea.containsMouse ? Theme.colors.surface : "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                icon: "edit"
                size: 14 * Theme.scale
                iconColor: Theme.colors.textMuted
            }

            MouseArea {
                id: editArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.editing = true
            }
        }

        MaterialIcon {
            visible: root.current && !root.editing
            icon: "check"
            size: 16 * Theme.scale
            iconColor: Theme.colors.accent
        }
    }

    // Behind the row's content so the edit icon's own MouseArea gets clicks first
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: {
            if (root.editing)
                return;
            root.forceActiveFocus();
            root.activated();
        }
    }
}
