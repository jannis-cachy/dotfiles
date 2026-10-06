import QtQuick
import QtQuick.Layouts
import "../../theme"
import "Nav.js" as Nav

Trapezoid {
    id: root

    property string text: ""
    property bool current: false
    // -1 first, 0 middle, 1 last. The ends are slanted, the middle ones are rectangles
    property int position: 0
    // Horizontal overhang of a slanted end button, the flat parts of all buttons line up
    readonly property real overhang: implicitHeight * Math.tan(Theme.menuAngle * Math.PI / 180)

    // Group index for PageFrame navigation, only used where the button takes focus
    property int navGroup: -1

    signal clicked
    signal hovered

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Keys.onRightPressed: root.clicked()
    Keys.onPressed: event => {
        if (Nav.vim(event) === "right") {
            root.clicked();
            event.accepted = true;
        }
    }

    Layout.fillWidth: true
    implicitHeight: 44 * Theme.scale
    angle: position === 0 ? 0 : Theme.menuAngle
    radius: Theme.menuRounding * Theme.scale
    Layout.leftMargin: position === 1 ? 0 : overhang
    Layout.rightMargin: position === -1 ? 0 : overhang
    color: Theme.colors.surface

    // Focus layer is toggled by visible, a Shape fill that changes color is not repainted reliably
    Trapezoid {
        anchors.fill: parent
        visible: root.current
        angle: root.angle
        radius: root.radius
        color: Qt.alpha(Theme.colors.selection, Theme.focusFill)
        borderColor: Theme.colors.focus
        borderWidth: 2 * Theme.scale
    }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: Theme.colors.text
        font.family: Theme.font.uiFamily
        font.pixelSize: 15 * Theme.scale * Theme.font.scale
    }

    MouseArea {
        anchors.fill: parent
        containmentMask: root.hitMask
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.clicked()
    }
}
