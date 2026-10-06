import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

PageFrame {
    id: page

    title: "Bar"

    signal close

    // Row that last had focus, ControlCenter stores it and focuses it again on return
    property int current: 0

    function focusRow(i) {
        const row = rows.itemAt(i);
        if (row)
            row.forceActiveFocus();
    }

    readonly property var items: [
        {
            label: "Audio",
            target: "audio"
        },
        {
            label: "Internet",
            target: "network"
        },
        {
            label: "Search",
            target: "finder"
        },
        {
            label: "Date & time",
            target: "datetime"
        },
        {
            label: "Notifications",
            target: "notifications"
        },
        {
            label: "Power",
            target: "power"
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 8 * Theme.scale

        Repeater {
            id: rows

            model: page.items

            MenuButton {
                required property var modelData
                required property int index

                position: index === 0 ? -1 : (index === page.items.length - 1 ? 1 : 0)
                text: modelData.label
                activeFocusOnTab: true
                current: activeFocus
                onHovered: forceActiveFocus()
                onClicked: {
                    forceActiveFocus();
                    if (modelData.target === "notifications") {
                        page.close();
                        Notification.setCenter(true);
                    } else {
                        page.navigate(modelData.target);
                    }
                }
                onActiveFocusChanged: {
                    if (activeFocus)
                        page.current = index;
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
