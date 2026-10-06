import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

PageFrame {
    id: page

    title: "Keybinds"
    implicitWidth: 520 * Theme.scale
    implicitHeight: 560 * Theme.scale

    // Runs what the physical key does. Destructive system binds never execute from here,
    // they only warn, so an accidental Enter in this menu can't reboot/poweroff/kill quickshell.
    function run(item) {
        if (item.dangerous) {
            Quickshell.execDetached(["notify-send", "-u", "critical", "Control Center", item.keys + " is destructive and can't be run from the menu. Use the physical keys."]);
            return;
        }
        if (item.type === "dispatch")
            Hyprland.dispatch(item.action);
        else if (item.type === "cmd")
            Quickshell.execDetached(item.action);
    }

    // Kept by hand, mirrors hyprland_modules/Keybinds.lua
    readonly property var groups: [
        {
            title: "Compositor",
            items: [
                {
                    keys: "SUPER + F",
                    desc: "Maximize window",
                    type: "dispatch",
                    action: 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'
                },
                {
                    keys: "SUPER + Q",
                    desc: "Close window",
                    dangerous: true
                },
                {
                    keys: "SUPER + V",
                    desc: "Toggle floating",
                    type: "dispatch",
                    action: 'hl.dsp.window.float({ action = "toggle" })'
                },
                {
                    keys: "SUPER + Tab",
                    desc: "Cycle windows",
                    type: "dispatch",
                    action: "hl.dsp.window.cycle_next()"
                },
                {
                    keys: "SUPER + Down / I",
                    desc: "Next workspace",
                    type: "dispatch",
                    action: 'hl.dsp.focus({ workspace = "e+1" })'
                },
                {
                    keys: "SUPER + Up / U",
                    desc: "Previous workspace",
                    type: "dispatch",
                    action: 'hl.dsp.focus({ workspace = "e-1" })'
                },
                {
                    keys: "SUPER + 1-0",
                    desc: "Go to workspace",
                    type: "none"
                },
                {
                    keys: "SUPER + SHIFT + 1-0",
                    desc: "Move window to workspace",
                    type: "none"
                },
                {
                    keys: "SUPER + SHIFT + Space",
                    desc: "Move window to special workspace",
                    type: "dispatch",
                    action: 'hl.dsp.window.move({ workspace = "special:magic" })'
                },
                {
                    keys: "ALT + G",
                    desc: "Toggle special workspace",
                    type: "dispatch",
                    action: 'hl.dsp.workspace.toggle_special("magic")'
                },
                {
                    keys: "ALT + F",
                    desc: "Toggle fullscreen",
                    type: "dispatch",
                    action: 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'
                },
                {
                    keys: "SUPER + SHIFT + V",
                    desc: "Focus floating <-> tiled",
                    type: "none"
                }
            ]
        },
        {
            title: "Media / audio",
            items: [
                {
                    keys: "XF86AudioRaiseVolume",
                    desc: "Volume up",
                    type: "cmd",
                    action: ["bash", "-c", "wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 10%+"]
                },
                {
                    keys: "XF86AudioLowerVolume",
                    desc: "Volume down",
                    type: "cmd",
                    action: ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"]
                },
                {
                    keys: "XF86AudioMute",
                    desc: "Mute output",
                    type: "cmd",
                    action: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
                },
                {
                    keys: "XF86AudioMicMute",
                    desc: "Mute microphone",
                    type: "cmd",
                    action: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
                },
                {
                    keys: "XF86MonBrightnessUp",
                    desc: "Brightness up",
                    type: "cmd",
                    action: ["brightnessctl", "set", "10%+"]
                },
                {
                    keys: "XF86MonBrightnessDown",
                    desc: "Brightness down",
                    type: "cmd",
                    action: ["brightnessctl", "set", "10%-"]
                },
                {
                    keys: "XF86AudioPrev",
                    desc: "Previous track",
                    type: "cmd",
                    action: ["playerctl", "previous"]
                },
                {
                    keys: "XF86AudioPlay",
                    desc: "Play / pause",
                    type: "cmd",
                    action: ["playerctl", "play-pause"]
                },
                {
                    keys: "XF86AudioNext",
                    desc: "Next track",
                    type: "cmd",
                    action: ["playerctl", "next"]
                },
                {
                    keys: "ALT + B",
                    desc: "Seek forward 1s",
                    type: "cmd",
                    action: ["playerctl", "position", "1+"]
                },
                {
                    keys: "ALT + Z",
                    desc: "Seek back 1s",
                    type: "cmd",
                    action: ["playerctl", "position", "1-"]
                }
            ]
        },
        {
            title: "Applications",
            items: [
                {
                    keys: "SUPER + T",
                    desc: "Terminal",
                    type: "cmd",
                    action: ["kitty"]
                },
                {
                    keys: "SUPER + B",
                    desc: "Browser",
                    type: "cmd",
                    action: ["firefox"]
                },
                {
                    keys: "SUPER + A",
                    desc: "App launcher",
                    type: "cmd",
                    action: ["bash", "-c", "pkill rofi || rofi -show drun"]
                },
                {
                    keys: "SUPER + C",
                    desc: "Clipboard history",
                    type: "cmd",
                    action: ["qs", "ipc", "call", "clipboard", "toggle"]
                },
                {
                    keys: "SUPER + W / Mouse side 1",
                    desc: "Control center",
                    type: "cmd",
                    action: ["qs", "ipc", "call", "controlcenter", "toggle"]
                },
                {
                    keys: "SUPER + E / Mouse side 2",
                    desc: "Expand / collapse bar",
                    type: "cmd",
                    action: ["qs", "ipc", "call", "bar", "toggle"]
                },
                {
                    keys: "SUPER + N",
                    desc: "Notification center",
                    type: "cmd",
                    action: ["qs", "ipc", "call", "notification", "toggle"]
                },
                {
                    keys: "SUPER + K",
                    desc: "PDF finder",
                    type: "cmd",
                    action: ["qs", "ipc", "call", "pdf", "toggle"]
                },
                {
                    keys: "SUPER + S",
                    desc: "Screenshot area",
                    type: "cmd",
                    action: ["bash", "-c", "grim -g \"$(slurp)\" ~/Pictures/Screenshot_$(date +'%Y%m%d_%H%M%S').png"]
                },
                {
                    keys: "Print",
                    desc: "Screenshot focused screen",
                    type: "cmd",
                    action: [Quickshell.env("HOME") + "/Binaries/FullScreenshot"]
                },
                {
                    keys: "ALT + Print",
                    desc: "Partial screenshot",
                    type: "cmd",
                    action: [Quickshell.env("HOME") + "/Binaries/PartialScreenshot"]
                },
                {
                    keys: "CTRL + Print",
                    desc: "Screen recorder",
                    type: "cmd",
                    action: [Quickshell.env("HOME") + "/Binaries/ScreenRecorder"]
                }
            ]
        },
        {
            title: "Unused / system",
            items: [
                {
                    keys: "SUPER + Z",
                    desc: "LocalSend",
                    type: "cmd",
                    action: ["bash", "-c", "pkill localsend || localsend"]
                },
                {
                    keys: "ALT + N",
                    desc: "Reload Hyprland config",
                    type: "cmd",
                    action: ["bash", "-c", "hyprctl reload && notify-send 'Hyprland' 'Config reloaded'"]
                },
                {
                    keys: "SUPER + R",
                    desc: "Restart quickshell",
                    dangerous: true
                },
                {
                    keys: "ALT + O",
                    desc: "Power off",
                    dangerous: true
                },
                {
                    keys: "ALT + R",
                    desc: "Reboot",
                    dangerous: true
                },
                {
                    keys: "ALT + S",
                    desc: "Suspend",
                    dangerous: true
                }
            ]
        },
        {
            title: "Suggested (not bound)",
            items: [
                {
                    keys: "SUPER + D",
                    desc: "Application menu",
                    type: "none"
                },
                {
                    keys: "SUPER + Return",
                    desc: "Alternate terminal",
                    type: "none"
                },
                {
                    keys: "SUPER + H",
                    desc: "Focus window left",
                    type: "none"
                },
                {
                    keys: "SUPER + L",
                    desc: "Focus window right",
                    type: "none"
                },
                {
                    keys: "SUPER + SHIFT + H",
                    desc: "Move window left",
                    type: "none"
                },
                {
                    keys: "SUPER + SHIFT + L",
                    desc: "Move window right",
                    type: "none"
                },
                {
                    keys: "SUPER + G",
                    desc: "Toggle gaps",
                    type: "none"
                },
                {
                    keys: "SUPER + Comma",
                    desc: "Previous layout",
                    type: "none"
                },
                {
                    keys: "SUPER + Period",
                    desc: "Next layout",
                    type: "none"
                },
                {
                    keys: "SUPER + Minus",
                    desc: "Shrink window",
                    type: "none"
                },
                {
                    keys: "SUPER + Equal",
                    desc: "Grow window",
                    type: "none"
                },
                {
                    keys: "SUPER + X",
                    desc: "Lock screen",
                    type: "none"
                },
                {
                    keys: "ALT + Tab",
                    desc: "Quick window switcher",
                    type: "none"
                },
                {
                    keys: "ALT + Space",
                    desc: "Window context menu",
                    type: "none"
                }
            ]
        }
    ]

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
            spacing: 14 * Theme.scale

            Repeater {
                model: page.groups

                ColumnLayout {
                    id: group

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: 6 * Theme.scale

                    Text {
                        Layout.fillWidth: true
                        text: group.modelData.title
                        color: Theme.colors.textMuted
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 12 * Theme.scale * Theme.font.scale
                        font.bold: true
                    }

                    Repeater {
                        model: group.modelData.items

                        KeybindRow {
                            required property var modelData

                            Layout.fillWidth: true
                            keys: modelData.keys
                            desc: modelData.desc
                            disabledStyle: modelData.dangerous === true || modelData.type === "none"
                            scrollTarget: flick
                            navGroup: group.index

                            onActivated: page.run(modelData)
                        }
                    }
                }
            }
        }
    }
}
