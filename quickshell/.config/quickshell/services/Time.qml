pragma Singleton
import QtQuick
import "../theme"

QtObject {
    id: root

    property date currentTime: new Date()
    
    property string timeString: Qt.formatDateTime(currentTime, Theme.clock.use24h ? "hh:mm" : "h:mm AP")
    property string dateString: Qt.formatDateTime(currentTime, "ddd MMM d")

    property Timer _timer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }
}
