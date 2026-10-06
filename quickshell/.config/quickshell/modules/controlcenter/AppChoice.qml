import QtQuick
import "../../theme"

// One application choice. chosen marks the current default, Enter or a click picks it.
Rectangle {
    id: root

    property string text: ""
    property bool chosen: false

    signal activated

    implicitHeight: 34 * Theme.scale
    radius: Theme.rounding / 2 * Theme.scale
    activeFocusOnTab: true
    color: chosen ? Theme.colors.accent : Theme.colors.surface
    border.width: chosen ? 0 : 1
    border.color: Theme.colors.border

    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    // Above the fill, the chosen button is solid primary and the box would vanish behind it
    FocusBox {
        z: 1
        color: Qt.alpha(Theme.colors.text, 0.25)
        borderColor: Theme.colors.text
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 12 * Theme.scale
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.text
        color: root.chosen ? Theme.colors.textOnAccent : Theme.colors.text
        font.bold: root.chosen
        font.family: Theme.font.uiFamily
        font.pixelSize: 13 * Theme.scale * Theme.font.scale
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.forceActiveFocus();
            root.activated();
        }
    }
}
