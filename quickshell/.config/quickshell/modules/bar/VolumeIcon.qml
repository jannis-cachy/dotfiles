import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "../../"
import "../../theme"

Item {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    property bool sinkMuted: (sink && sink.audio) ? sink.audio.muted : false
    property bool sourceMuted: (source && source.audio) ? source.audio.muted : false

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    // Volume feedback: a small popup drawn over the icon with a level bar to its right.
    // Ignored for a moment after the sink changes so switching devices does not trigger it.
    property bool osdArmed: false
    onSinkChanged: {
        osdArmed = false;
        armTimer.restart();
    }

    Timer {
        id: armTimer
        interval: 500
        running: true
        onTriggered: root.osdArmed = true
    }

    Timer {
        id: osdTimer
        interval: 1000
        onTriggered: osd.visible = false
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null

        function onVolumeChanged() {
            root.showOsd();
        }
        function onMutedChanged() {
            root.showOsd();
        }
    }

    // Only one bar shows it: the focused monitor's, or this one if the focused monitor has no bar open
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""

    function showOsd() {
        if (!osdArmed || !root.visible)
            return;
        const focused = Hyprland.focusedMonitor?.name ?? "";
        if (screenName !== focused && BarState.isExpanded(focused))
            return;
        osd.visible = true;
        osdTimer.restart();
    }

    property bool iconHovered: false
    property bool popupHovered: false

    implicitWidth: 20 * Theme.scale
    implicitHeight: 20 * Theme.scale

    MaterialIcon {
        id: volumeIcon
        anchors.fill: parent

        icon: {
            if (root.sinkMuted || root.volume <= 0)
                return "volume_off";
            if (root.volume < 0.5)
                return "volume_down";
            return "volume_up";
        }

        color: Theme.colors.text
        size: 20 * Theme.scale
    }

    // Output-muted subicon
    Rectangle {
        visible: root.sinkMuted
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: -2 * Theme.scale
        anchors.bottomMargin: -2 * Theme.scale
        implicitWidth: 11 * Theme.scale
        implicitHeight: 11 * Theme.scale
        radius: implicitWidth / 2
        color: Theme.colors.bg

        MaterialIcon {
            anchors.centerIn: parent
            icon: "volume_off"
            size: 9 * Theme.scale
            iconColor: Theme.colors.warning
        }
    }

    // Mic-muted subicon
    Rectangle {
        visible: root.sourceMuted
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -2 * Theme.scale
        anchors.bottomMargin: -2 * Theme.scale
        implicitWidth: 11 * Theme.scale
        implicitHeight: 11 * Theme.scale
        radius: implicitWidth / 2
        color: Theme.colors.bg

        MaterialIcon {
            anchors.centerIn: parent
            icon: "mic_off"
            size: 9 * Theme.scale
            iconColor: Theme.colors.warning
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 10

        onEntered: {
            root.iconHovered = true;
            hideTimer.stop();
            popup.visible = true;
        }

        onExited: {
            root.iconHovered = false;
            hideTimer.restart();
        }

        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "goto", "audio"])
    }

    PopupWindow {
        id: popup

        Reveal {
            target: popup.contentItem
            when: popup.visible
        }

        visible: false

        implicitWidth: 220 * Theme.scale
        implicitHeight: 80 * Theme.scale
        color: "transparent"

        anchor.item: volumeIcon
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Right | Edges.Bottom
        anchor.margins.top: 30 * Theme.scale

        Rectangle {
            anchors.fill: parent

            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale
            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    root.popupHovered = true;
                    hideTimer.stop();
                }

                onExited: {
                    root.popupHovered = false;
                    hideTimer.restart();
                }
            }

            Text {
                anchors.centerIn: parent

                color: Theme.colors.text
                font.family: Theme.font.uiFamily
                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                font.bold: true
                horizontalAlignment: Text.AlignHCenter

                text: {
                    const device = root.sink ? (Theme.audio.deviceNames[root.sink.name] || root.sink.description || root.sink.nickname || root.sink.name) : "No output";
                    const vol = root.sinkMuted ? "Muted" : Math.round(root.volume * 100) + "%";
                    const mic = root.sourceMuted ? "\nMic muted" : "";
                    return device + "\n" + vol + mic;
                }
            }
        }
    }

    PopupWindow {
        id: osd

        Reveal {
            target: osd.contentItem
            when: osd.visible
        }

        readonly property real pad: 6 * Theme.scale

        visible: false
        implicitWidth: pad * 2 + 20 * Theme.scale + 10 * Theme.scale + 110 * Theme.scale
        implicitHeight: pad * 2 + 20 * Theme.scale
        color: "transparent"

        anchor.item: volumeIcon
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.rect.x: -pad
        anchor.rect.y: -pad

        // Click-through so it never blocks the icon underneath
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            color: Theme.colors.bg
            radius: Theme.rounding * Theme.scale
            border.width: 2 * Theme.scale
            border.color: Theme.colors.border

            // Same 20x20 box as the bar icon, so the glyph lands exactly on top of it
            MaterialIcon {
                x: osd.pad
                y: osd.pad
                width: 20 * Theme.scale
                height: 20 * Theme.scale
                icon: volumeIcon.icon
                color: Theme.colors.text
                size: 20 * Theme.scale
            }

            Rectangle {
                x: osd.pad + 30 * Theme.scale
                anchors.verticalCenter: parent.verticalCenter
                width: 110 * Theme.scale
                height: 6 * Theme.scale
                radius: height / 2
                color: Theme.colors.surface

                Rectangle {
                    width: parent.width * Math.min(1, root.volume)
                    height: parent.height
                    radius: parent.radius
                    color: root.sinkMuted ? Theme.colors.warning : Theme.colors.accent
                }
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 150
        repeat: false

        onTriggered: {
            if (!root.iconHovered && !root.popupHovered)
                popup.visible = false;
        }
    }
}
