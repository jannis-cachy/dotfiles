import QtQuick
import QtQuick.Layouts
import "../../"
import "../../theme"
import "Nav.js" as Nav

// Focusable row: optional icon, label, right-aligned detail, check mark when current, chevron
// when it opens something. scrollTarget is the Flickable to keep it visible in.
Rectangle {
    id: root

    property string label: ""
    property string detail: ""
    property string icon: ""
    property bool current: false
    property bool chevron: false
    property Flickable scrollTarget: null
    property int navGroup: -1

    signal activated

    implicitHeight: 40 * Theme.scale
    radius: Theme.rounding / 2 * Theme.scale
    activeFocusOnTab: true
    color: root.activeFocus ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : (mouseArea.containsMouse ? Theme.colors.surface : "transparent")
    border.width: root.activeFocus ? 2 * Theme.scale : 0
    border.color: Theme.colors.focus

    Keys.onReturnPressed: root.activated()
    Keys.onSpacePressed: root.activated()
    // Right enters whatever a chevron row opens, other rows leave Right to PageFrame
    Keys.onRightPressed: event => {
        event.accepted = root.chevron;
        if (root.chevron)
            root.activated();
    }
    Keys.onPressed: event => {
        if (Nav.vim(event) === "right" && root.chevron) {
            root.activated();
            event.accepted = true;
        }
    }

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
        anchors.leftMargin: 10 * Theme.scale
        anchors.rightMargin: 10 * Theme.scale
        spacing: 10 * Theme.scale

        MaterialIcon {
            visible: root.icon !== ""
            icon: root.icon
            size: 18 * Theme.scale
            iconColor: root.current || root.activeFocus ? Theme.colors.text : Theme.colors.textMuted
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.current || root.activeFocus ? Theme.colors.text : Theme.colors.textMuted
            font.bold: root.current
            font.family: Theme.font.uiFamily
            font.pixelSize: 14 * Theme.scale * Theme.font.scale
            elide: Text.ElideRight
        }

        Text {
            visible: root.detail !== ""
            text: root.detail
            color: Theme.colors.textMuted
            font.family: Theme.font.uiFamily
            font.pixelSize: 12 * Theme.scale * Theme.font.scale
        }

        MaterialIcon {
            visible: root.current
            icon: "check"
            size: 16 * Theme.scale
            iconColor: Theme.colors.accent
        }

        MaterialIcon {
            visible: root.chevron
            icon: "chevron_right"
            size: 18 * Theme.scale
            iconColor: Theme.colors.text
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
