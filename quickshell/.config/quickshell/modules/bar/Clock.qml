import QtQuick
import Quickshell
import "../../theme"
import "../../services"

Text {
    text: Time.timeString
    color: Theme.colors.text
    font.family: Theme.font.uiFamily
    font.pixelSize: 16 * Theme.scale * Theme.font.scale
    font.bold: true

    HoverTip {
        text: Qt.formatDateTime(Time.currentTime, "dddd, d MMMM yyyy\n") + Qt.formatDateTime(Time.currentTime, Theme.clock.use24h ? "hh:mm:ss" : "h:mm:ss AP")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "goto", "datetime"])
    }
}
