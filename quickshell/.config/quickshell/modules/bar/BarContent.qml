import QtQuick
import QtQuick.Layouts
import "../../theme"

ColumnLayout {
    id: root


    // The space below the workspaces is a column of nodes, counted from the bottom. Icons are
    // dragged onto any node, an occupied node swaps. Places are saved in BarState.
    readonly property var components: ({
            search: searchComponent,
            clock: clockComponent,
            network: networkComponent,
            bluetooth: bluetoothComponent,
            battery: batteryComponent,
            volume: volumeComponent,
            notifications: notificationsComponent,
            caffeine: caffeineComponent,
            power: powerComponent,
            tray: trayComponent
        })
    readonly property real nodeHeight: 44 * Theme.scale
    readonly property int nodeCount: Math.max(0, Math.floor(area.height / nodeHeight))
    // key to node, for the icons that take space right now
    property var nodes: ({})
    // key to true while the icon is visible, filled by the slots
    property var present: ({})

    Component {
        id: searchComponent
        SearchIcon {}
    }
    Component {
        id: clockComponent
        Clock {}
    }
    Component {
        id: networkComponent
        NetworkModule {}
    }
    Component {
        id: bluetoothComponent
        Bluetooth {}
    }
    Component {
        id: batteryComponent
        Battery {}
    }
    Component {
        id: volumeComponent
        VolumeIcon {}
    }
    Component {
        id: notificationsComponent
        NotificationBell {}
    }
    Component {
        id: caffeineComponent
        IdleInhibit {}
    }
    Component {
        id: powerComponent
        PowerMenu {}
    }
    Component {
        id: trayComponent
        SysTray {}
    }

    // Saved nodes first, everything else (new, hidden before, no room) takes the free node
    // nearest to the bottom, in the default order
    function assign() {
        const used = {};
        const result = {};
        const visibleKeys = BarState.keys.filter(k => present[k]);
        for (const k of visibleKeys) {
            const n = BarState.positions[k];
            if (n !== undefined && n >= 0 && n < nodeCount && !used[n]) {
                used[n] = true;
                result[k] = n;
            }
        }
        let n = 0;
        for (const k of visibleKeys.slice().reverse()) {
            if (result[k] !== undefined)
                continue;
            while (used[n])
                n++;
            used[n] = true;
            result[k] = n;
        }
        nodes = result;
    }

    function scheduleAssign() {
        Qt.callLater(assign);
    }

    onNodeCountChanged: scheduleAssign()

    Connections {
        target: BarState

        function onPositionsChanged() {
            root.scheduleAssign();
        }
        function onKeysChanged() {
            root.scheduleAssign();
        }
    }

    Workspaces {
        Layout.alignment: Qt.AlignHCenter
    }

    Item {
        id: area

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Target node while dragging
        Rectangle {
            id: dropBox

            property int node: -1

            visible: node >= 0
            width: area.width
            height: root.nodeHeight
            y: area.height - (node + 1) * root.nodeHeight
            radius: Theme.rounding / 2 * Theme.scale
            color: Qt.alpha(Theme.colors.selection, Theme.focusFill)
            border.width: 2 * Theme.scale
            border.color: Theme.colors.accent
        }

        Repeater {
            model: BarState.keys

            Item {
                id: slot

                required property string modelData

                readonly property string kind: modelData.startsWith("tray:") ? "tray" : modelData
                readonly property int node: root.nodes[modelData] ?? -1
                // Hidden icons (no battery, no tray apps) take no node
                readonly property bool present: content.item !== null && content.item.visible

                width: area.width
                height: present ? root.nodeHeight : 0
                y: node >= 0 ? area.height - (node + 1) * root.nodeHeight : 0
                z: drag.active ? 10 : 0

                onPresentChanged: {
                    const next = Object.assign({}, root.present);
                    next[modelData] = present;
                    root.present = next;
                    root.scheduleAssign();
                }

                Loader {
                    id: content

                    anchors.centerIn: parent
                    sourceComponent: root.components[slot.kind]
                    onLoaded: {
                        if (slot.kind === "tray")
                            item.only = slot.modelData.slice(5);
                    }
                    transform: Translate {
                        y: drag.active ? drag.activeTranslation.y : 0
                    }
                }

                DragHandler {
                    id: drag

                    target: null
                    xAxis.enabled: false

                    function targetNode() {
                        const center = slot.y + root.nodeHeight / 2 + drag.activeTranslation.y;
                        return Math.max(0, Math.min(root.nodeCount - 1, Math.floor((area.height - center) / root.nodeHeight)));
                    }

                    onActiveTranslationChanged: {
                        if (active)
                            dropBox.node = targetNode();
                    }

                    onActiveChanged: {
                        if (active)
                            return;
                        // the translation is already reset here, the box holds the last target
                        const target = dropBox.node >= 0 ? dropBox.node : slot.node;
                        dropBox.node = -1;
                        const map = Object.assign({}, root.nodes);
                        const old = map[slot.modelData];
                        for (const k in map) {
                            if (map[k] === target && k !== slot.modelData)
                                map[k] = old;
                        }
                        map[slot.modelData] = target;
                        BarState.setPositions(map);
                    }
                }
            }
        }
    }
}
