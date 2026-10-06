import QtQuick
import QtQuick.Layouts
import "../../theme"
import "Nav.js" as Nav

Item {
    id: page

    signal navigate(string target)
    signal close

    property bool blurBackground: true

    implicitWidth: 480 * Theme.scale
    implicitHeight: 440 * Theme.scale

    property int current: 0
    readonly property var items: [
        {
            label: "Appearance",
            target: "appearance"
        },
        {
            label: "Settings",
            target: "settings"
        },
        {
            label: "Keybinds",
            target: "keybinds"
        },
        {
            label: "Binaries",
            target: "binaries"
        },
        {
            label: "Wallpapers",
            target: "wallpapers"
        },
        {
            label: "Applications",
            target: "apps"
        },
        {
            label: "Bar",
            target: "bar"
        }
    ]

    // Up and Down wrap around
    Keys.onUpPressed: current = (current - 1 + items.length) % items.length
    Keys.onDownPressed: current = (current + 1) % items.length
    Keys.onPressed: event => {
        const dir = Nav.vim(event);
        if (!dir)
            return;
        event.accepted = true;
        if (dir === "up")
            current = (current - 1 + items.length) % items.length;
        else if (dir === "down")
            current = (current + 1) % items.length;
        else if (dir === "left")
            close();
        else
            navigate(items[current].target);
    }
    Keys.onReturnPressed: navigate(items[current].target)
    Keys.onLeftPressed: close()
    Keys.onRightPressed: navigate(items[current].target)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Theme.scale
        spacing: 8 * Theme.scale

        Repeater {
            model: page.items

            MenuButton {
                required property int index
                required property var modelData

                position: index === 0 ? -1 : (index === page.items.length - 1 ? 1 : 0)
                text: modelData.label
                current: index === page.current
                onHovered: page.current = index
                onClicked: page.navigate(modelData.target)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
