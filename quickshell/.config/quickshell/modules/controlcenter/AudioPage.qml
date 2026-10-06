import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../"
import "../../theme"

PageFrame {
    id: page

    title: "Audio"
    implicitWidth: 480 * Theme.scale
    implicitHeight: 560 * Theme.scale

    property var sinkNodes: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    property var sourceNodes: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    property var streamNodes: Pipewire.nodes.values.filter(n => n.audio && n.isStream && !n.isSink)

    function streamLabel(node) {
        return node.properties?.["application.name"] || node.description || node.nickname || node.name || "";
    }

    function defaultDeviceName(node) {
        return node.description || node.nickname || node.name || "";
    }

    function deviceLabel(node) {
        return Theme.audio.deviceNames[node.name] || defaultDeviceName(node);
    }

    function renameDevice(node, text) {
        const names = Object.assign({}, Theme.audio.deviceNames);
        if (!text || text === defaultDeviceName(node))
            delete names[node.name];
        else
            names[node.name] = text;
        Theme.audio.deviceNames = names;
    }

    function volumeOf(node) {
        return (node && node.audio) ? node.audio.volume : 0;
    }

    function mutedOf(node) {
        return (node && node.audio) ? node.audio.muted : false;
    }

    PwObjectTracker {
        objects: [...page.sinkNodes, ...page.sourceNodes, ...page.streamNodes]
    }

    Flickable {
        id: flick

        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content

            width: flick.width
            spacing: 16 * Theme.scale

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Theme.scale

                Text {
                    text: "Output"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                SettingSlider {
                    Layout.fillWidth: true
                    navGroup: 0
                    label: "Volume"
                    from: 0
                    to: 1.5
                    stepSize: 0.05
                    decimals: 2
                    value: page.volumeOf(Pipewire.defaultAudioSink)
                    onCommitted: v => {
                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                            Pipewire.defaultAudioSink.audio.volume = v;
                    }
                }

                SettingToggle {
                    Layout.fillWidth: true
                    navGroup: 0
                    label: "Mute"
                    checked: page.mutedOf(Pipewire.defaultAudioSink)
                    onToggled: value => {
                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                            Pipewire.defaultAudioSink.audio.muted = value;
                    }
                }

                Repeater {
                    model: page.sinkNodes

                    DeviceRow {
                        required property var modelData

                        Layout.fillWidth: true
                        navGroup: 0
                        label: page.deviceLabel(modelData)
                        current: modelData === Pipewire.defaultAudioSink
                        scrollTarget: flick
                        onActivated: Pipewire.preferredDefaultAudioSink = modelData
                        onRenamed: text => page.renameDevice(modelData, text)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Theme.scale

                Text {
                    text: "Input"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                SettingSlider {
                    Layout.fillWidth: true
                    navGroup: 1
                    label: "Volume"
                    from: 0
                    to: 1.5
                    stepSize: 0.05
                    decimals: 2
                    value: page.volumeOf(Pipewire.defaultAudioSource)
                    onCommitted: v => {
                        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio)
                            Pipewire.defaultAudioSource.audio.volume = v;
                    }
                }

                SettingToggle {
                    Layout.fillWidth: true
                    navGroup: 1
                    label: "Mute"
                    checked: page.mutedOf(Pipewire.defaultAudioSource)
                    onToggled: value => {
                        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio)
                            Pipewire.defaultAudioSource.audio.muted = value;
                    }
                }

                Repeater {
                    model: page.sourceNodes

                    DeviceRow {
                        required property var modelData

                        Layout.fillWidth: true
                        navGroup: 1
                        label: page.deviceLabel(modelData)
                        current: modelData === Pipewire.defaultAudioSource
                        scrollTarget: flick
                        onActivated: Pipewire.preferredDefaultAudioSource = modelData
                        onRenamed: text => page.renameDevice(modelData, text)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Theme.scale
                visible: page.streamNodes.length > 0

                Text {
                    text: "Playing"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                Repeater {
                    model: page.streamNodes

                    ColumnLayout {
                        id: streamRow

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 2 * Theme.scale

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8 * Theme.scale

                            Text {
                                Layout.fillWidth: true
                                text: page.streamLabel(streamRow.modelData)
                                color: Theme.colors.text
                                font.family: Theme.font.uiFamily
                                font.pixelSize: 13 * Theme.scale * Theme.font.scale
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: muteButton

                                property int navGroup: 2

                                implicitWidth: 26 * Theme.scale
                                implicitHeight: 26 * Theme.scale
                                radius: Theme.rounding / 2 * Theme.scale
                                activeFocusOnTab: true
                                color: activeFocus ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : Theme.colors.surface
                                border.width: activeFocus ? 2 * Theme.scale : 0
                                border.color: Theme.colors.focus

                                Keys.onReturnPressed: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                                Keys.onSpacePressed: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    icon: streamRow.modelData.audio.muted ? "volume_off" : "volume_up"
                                    size: 16 * Theme.scale
                                    iconColor: streamRow.modelData.audio.muted ? Theme.colors.warning : Theme.colors.text
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                                }
                            }
                        }

                        SettingSlider {
                            Layout.fillWidth: true
                            navGroup: 2
                            from: 0
                            to: 1.5
                            stepSize: 0.05
                            decimals: 2
                            value: streamRow.modelData.audio.volume
                            onCommitted: v => streamRow.modelData.audio.volume = v
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
