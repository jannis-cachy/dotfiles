import QtQuick
import QtQuick.Layouts
import "../../"
import "../../theme"
import "../../services"

PageFrame {
    id: page

    title: "Date & time"
    implicitWidth: 480 * Theme.scale
    implicitHeight: 520 * Theme.scale

    readonly property date now: Time.currentTime
    // Monday-first grid of 6 weeks covering the current month
    readonly property var days: {
        const first = new Date(now.getFullYear(), now.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const list = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - offset + i);
            list.push({
                day: d.getDate(),
                inMonth: d.getMonth() === now.getMonth(),
                today: d.toDateString() === now.toDateString()
            });
        }
        return list;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14 * Theme.scale

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(page.now, Theme.clock.use24h ? "hh:mm:ss" : "h:mm:ss AP")
            color: Theme.colors.text
            font.family: Theme.font.uiFamily
            font.pixelSize: 44 * Theme.scale * Theme.font.scale
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(page.now, "dddd, d MMMM yyyy")
            color: Theme.colors.text
            font.family: Theme.font.uiFamily
            font.pixelSize: 16 * Theme.scale * Theme.font.scale
        }

        SettingToggle {
            Layout.fillWidth: true
            label: "24-hour clock"
            checked: Theme.clock.use24h
            onToggled: value => Theme.clock.use24h = value
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 4 * Theme.scale
            columnSpacing: 4 * Theme.scale

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Text {
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }
            }

            Repeater {
                model: page.days

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.rounding / 2 * Theme.scale
                    color: modelData.today ? Theme.colors.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.day
                        color: parent.modelData.today ? Theme.colors.textOnAccent : (parent.modelData.inMonth ? Theme.colors.text : Theme.colors.textMuted)
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 13 * Theme.scale * Theme.font.scale
                    }
                }
            }
        }
    }
}
