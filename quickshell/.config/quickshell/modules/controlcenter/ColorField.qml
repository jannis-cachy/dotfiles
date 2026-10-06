import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../theme/OkColor.js" as OkColor

// Swatch, label and a hex or oklch(L C H) field (stored as hex). The row is a keyboard stop (white label while
// focused), Enter or a click on the swatch asks for the picker, Space enters the field, Enter there applies.
Item {
    id: root

    property string label: ""
    property string value: ""
    // Group index for PageFrame's Right-arrow group-jump, -1 means ungrouped
    property int navGroup: -1

    signal committed(string hex)
    signal released
    signal activated

    activeFocusOnTab: true

    // Enter opens the picker, Space types into the hex field (Enter there applies)
    Keys.onReturnPressed: activated()
    Keys.onSpacePressed: {
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

        Rectangle {
            implicitWidth: 18 * Theme.scale
            implicitHeight: implicitWidth
            radius: 3 * Theme.scale
            color: root.value
            border.width: root.activeFocus ? 2 : 1
            border.color: root.activeFocus ? Theme.colors.focus : Theme.colors.border

            MouseArea {
                anchors.fill: parent
                onClicked: root.activated()
            }
        }

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

            readonly property bool valid: OkColor.toHex(text) !== null

            activeFocusOnTab: false
            implicitWidth: (activeFocus ? 190 : 84) * Theme.scale
            implicitHeight: 26 * Theme.scale
            maximumLength: 40
            selectByMouse: true
            color: valid ? Theme.colors.text : Theme.colors.error
            font.family: Theme.font.uiFamily
            font.pixelSize: 12 * Theme.scale * Theme.font.scale
            leftPadding: 8 * Theme.scale
            verticalAlignment: TextInput.AlignVCenter

            background: Rectangle {
                radius: 3 * Theme.scale
                color: Theme.colors.surface
                border.width: field.activeFocus ? 1 : 0
                border.color: field.valid ? Theme.colors.focus : Theme.colors.error
            }

            Component.onCompleted: text = root.value

            Keys.onEscapePressed: root.forceActiveFocus()

            // Handled here so the Enter that applies does not also reach the row and open the picker
            Keys.onReturnPressed: event => {
                event.accepted = true;
                if (valid) {
                    const hex = OkColor.toHex(text);
                    root.committed(hex);
                    text = hex;
                    root.forceActiveFocus();
                }
            }
            onActiveFocusChanged: {
                if (!activeFocus)
                    text = root.value;
            }
        }

        Connections {
            target: root

            function onValueChanged() {
                field.text = root.value;
            }
        }
    }
}
