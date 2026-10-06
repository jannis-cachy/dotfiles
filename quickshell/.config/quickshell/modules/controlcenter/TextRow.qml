import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

// Label and a text field, a keyboard stop like ColorField: Space enters the field, Enter there
// emits committed(text) and returns to the row, Esc cancels.
Item {
    id: root

    property string label: ""
    property string placeholder: ""
    // Group index for PageFrame's Right-arrow group-jump, -1 means ungrouped
    property int navGroup: -1

    signal committed(string text)

    activeFocusOnTab: true

    Keys.onSpacePressed: {
        field.forceActiveFocus();
        field.selectAll();
    }
    Keys.onReturnPressed: {
        field.forceActiveFocus();
        field.selectAll();
    }

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

        TextField {
            id: field

            activeFocusOnTab: false
            implicitWidth: 140 * Theme.scale
            implicitHeight: 26 * Theme.scale
            maximumLength: 40
            selectByMouse: true
            placeholderText: root.placeholder
            placeholderTextColor: Theme.colors.textMuted
            color: Theme.colors.text
            font.family: Theme.font.uiFamily
            font.pixelSize: 12 * Theme.scale * Theme.font.scale
            leftPadding: 8 * Theme.scale
            verticalAlignment: TextInput.AlignVCenter

            background: Rectangle {
                radius: 3 * Theme.scale
                color: Theme.colors.surface
                border.width: field.activeFocus ? 1 : 0
                border.color: Theme.colors.focus
            }

            Keys.onEscapePressed: {
                text = "";
                root.forceActiveFocus();
            }

            Keys.onReturnPressed: event => {
                event.accepted = true;
                const t = text.trim();
                if (t !== "") {
                    root.committed(t);
                    text = "";
                    root.forceActiveFocus();
                }
            }
        }
    }
}
