import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

// One notification, used by the popups and the notification center
Rectangle {
    id: root

    property string summary: ""
    property string body: ""
    property string appName: ""
    property string time: ""
    property string image: ""
    property string appIcon: ""
    property bool critical: false
    // true: the whole card dismisses, false: only the close button
    property bool clickToDismiss: true

    signal dismissed

    readonly property string iconSource: {
        if (image !== "")
            return image;
        if (appIcon === "")
            return "";
        return appIcon.startsWith("/") ? "file://" + appIcon : Quickshell.iconPath(appIcon, true);
    }

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 20 * Theme.scale
    radius: Theme.rounding * Theme.scale
    color: Theme.colors.bg
    border.width: 2 * Theme.scale
    border.color: critical ? Theme.colors.error : Theme.colors.border

    MouseArea {
        anchors.fill: parent
        enabled: root.clickToDismiss
        onClicked: root.dismissed()
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 10 * Theme.scale
        spacing: 10 * Theme.scale

        Image {
            Layout.preferredWidth: 36 * Theme.scale
            Layout.preferredHeight: 36 * Theme.scale
            Layout.alignment: Qt.AlignTop
            visible: root.iconSource !== ""
            source: root.iconSource
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * Theme.scale

            Text {
                Layout.fillWidth: true
                text: root.summary
                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: Theme.font.fontSize * Theme.scale * Theme.font.scale
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.body !== ""
                text: root.body
                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: (Theme.font.fontSize - 2) * Theme.scale * Theme.font.scale
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: [root.appName, root.time].filter(t => t !== "").join("  ")
                color: Theme.colors.textMuted
                font.family: Theme.font.uiFamily
                font.pixelSize: (Theme.font.fontSize - 4) * Theme.scale * Theme.font.scale
            }
        }

        Text {
            visible: !root.clickToDismiss
            Layout.alignment: Qt.AlignTop
            text: ""
            color: Theme.colors.textMuted
            font.family: Theme.font.uiFamily
            font.pixelSize: Theme.font.fontSize * Theme.scale * Theme.font.scale

            MouseArea {
                anchors.fill: parent
                onClicked: root.dismissed()
            }
        }
    }
}
