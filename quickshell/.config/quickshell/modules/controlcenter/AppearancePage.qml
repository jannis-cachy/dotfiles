import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../../theme"
import "../../services"

PageFrame {
    id: page

    title: "Appearance"
    blurBackground: false
    implicitWidth: 720 * Theme.scale
    implicitHeight: 560 * Theme.scale

    // Row the picker was opened for
    property int pickRow: 0

    // Every control (slider, picker, color field) fills one grid cell of this height, so the
    // two-column grid stays even regardless of control type. Groups pad to an even item count
    // with a filler cell so a group never leaves a lone item dangling in one column.
    readonly property real cellHeight: 58 * Theme.scale

    readonly property var colorRows: [
        {
            label: "Background",
            group: "base",
            key: "bg"
        },
        {
            label: "Surface",
            group: "base",
            key: "surface"
        },
        {
            label: "Border",
            group: "base",
            key: "border"
        },
        {
            label: "Text",
            group: "base",
            key: "text"
        },
        {
            label: "Muted text",
            group: "base",
            key: "textMuted"
        },
        {
            label: "Accent",
            group: "base",
            key: "accent"
        },
        {
            label: "Text on accent",
            group: "base",
            key: "textOnAccent"
        },
        {
            label: "Selection",
            group: "base",
            key: "selection"
        },
        {
            label: "Focus ring",
            group: "base",
            key: "focus"
        },
        {
            label: "Error",
            group: "base",
            key: "error"
        },
        {
            label: "Warning",
            group: "base",
            key: "warning"
        },
        {
            label: "Success",
            group: "base",
            key: "success"
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
            spacing: 22 * Theme.scale

            // Group 0: general appearance sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * Theme.scale

                Text {
                    Layout.fillWidth: true
                    text: "General"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20 * Theme.scale
                    rowSpacing: 10 * Theme.scale

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Scale"
                        from: 0.5
                        to: 2
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.scale
                        onCommitted: v => Theme.scale = Math.round(v * 100) / 100
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Rounding"
                        from: 0
                        to: 30
                        stepSize: 1
                        value: Theme.rounding
                        onCommitted: v => Theme.rounding = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Gaps in"
                        from: 0
                        to: 30
                        stepSize: 1
                        value: Theme.hypr.gapsIn
                        onCommitted: v => Theme.hypr.gapsIn = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Gaps out"
                        from: 0
                        to: 60
                        stepSize: 1
                        value: Theme.hypr.gapsOut
                        onCommitted: v => Theme.hypr.gapsOut = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Border size"
                        from: 0
                        to: 10
                        stepSize: 1
                        value: Theme.hypr.borderSize
                        onCommitted: v => Theme.hypr.borderSize = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Frame rounding"
                        from: 0
                        to: 40
                        stepSize: 1
                        value: Theme.frameRounding
                        onCommitted: v => Theme.frameRounding = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Menu angle"
                        from: 0
                        to: 30
                        stepSize: 1
                        value: Theme.menuAngle
                        onCommitted: v => Theme.menuAngle = Math.round(v)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 0
                        label: "Menu rounding"
                        from: 0
                        to: 20
                        stepSize: 1
                        value: Theme.menuRounding
                        onCommitted: v => Theme.menuRounding = Math.round(v)
                    }
                }
            }

            // Group 1: theme and font
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * Theme.scale

                Text {
                    Layout.fillWidth: true
                    text: "Theme & font"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20 * Theme.scale
                    rowSpacing: 10 * Theme.scale

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "Font size"
                        from: 0.8
                        to: 1.5
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.font.scale
                        onCommitted: v => Theme.font.scale = Math.round(v * 100) / 100
                    }

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "Font"
                        value: Theme.font.family
                        onActivated: {
                            fontPicker.items = SystemFonts.fontFamilies;
                            fontPicker.cursor = Math.max(0, SystemFonts.fontFamilies.indexOf(Theme.font.family));
                            fontPicker.open();
                        }
                    }

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "UI font"
                        value: Theme.font.uiFamily
                        onActivated: {
                            uiFontPicker.items = SystemFonts.fontFamilies;
                            uiFontPicker.cursor = Math.max(0, SystemFonts.fontFamilies.indexOf(Theme.font.uiFamily));
                            uiFontPicker.open();
                        }
                    }

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "Icon theme"
                        value: Theme.font.iconTheme
                        onActivated: {
                            iconPicker.items = SystemFonts.iconThemes;
                            iconPicker.cursor = Math.max(0, SystemFonts.iconThemes.indexOf(Theme.font.iconTheme));
                            iconPicker.open();
                        }
                    }

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "GTK theme"
                        value: Theme.font.gtkTheme
                        onActivated: {
                            gtkThemePicker.items = SystemFonts.gtkThemes;
                            gtkThemePicker.cursor = Math.max(0, SystemFonts.gtkThemes.indexOf(Theme.font.gtkTheme));
                            gtkThemePicker.open();
                        }
                    }

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "Cursor theme"
                        value: Theme.font.cursorTheme
                        onActivated: {
                            cursorPicker.items = SystemFonts.cursorThemes;
                            cursorPicker.cursor = Math.max(0, SystemFonts.cursorThemes.indexOf(Theme.font.cursorTheme));
                            cursorPicker.open();
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 1
                        label: "Cursor size"
                        from: 12
                        to: 48
                        stepSize: 2
                        value: Theme.font.cursorSize
                        onCommitted: v => Theme.font.cursorSize = Math.round(v)
                    }

                    // Escape hatch for cursor size (and anything else here) when the automatic
                    // live-reload in SystemTheme.qml doesn't actually take effect for already-running apps
                    Rectangle {
                        id: applyButton

                        // Group index for PageFrame's Right-arrow group-jump
                        property int navGroup: 1

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        radius: Theme.rounding / 2 * Theme.scale
                        activeFocusOnTab: true
                        color: applyButton.activeFocus ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : (applyArea.containsMouse ? Theme.colors.surface : "transparent")
                        border.width: applyButton.activeFocus ? 2 * Theme.scale : 0
                        border.color: Theme.colors.focus

                        function run() {
                            SystemTheme.apply();
                            Quickshell.execDetached(["hyprctl", "reload"]);
                        }

                        Keys.onReturnPressed: applyButton.run()
                        Keys.onSpacePressed: applyButton.run()

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Theme.scale

                            MaterialIcon {
                                icon: "refresh"
                                size: 16 * Theme.scale
                                iconColor: applyButton.activeFocus ? Theme.colors.text : Theme.colors.textMuted
                            }

                            Text {
                                text: "Apply"
                                color: applyButton.activeFocus ? Theme.colors.text : Theme.colors.textMuted
                                font.family: Theme.font.uiFamily
                                font.pixelSize: 14 * Theme.scale * Theme.font.scale
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: applyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                applyButton.forceActiveFocus();
                                applyButton.run();
                            }
                        }
                    }
                }
            }

            // Group 2: colors
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * Theme.scale

                Text {
                    Layout.fillWidth: true
                    text: "Colors"
                    color: Theme.colors.textMuted
                    font.family: Theme.font.uiFamily
                    font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20 * Theme.scale
                    rowSpacing: 10 * Theme.scale

                    PickerRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Color set"
                        value: Theme.currentColorSet()
                        onActivated: {
                            const names = Object.keys(Theme.colorSets).sort();
                            colorSetPicker.items = names;
                            colorSetPicker.cursor = Math.max(0, names.indexOf(Theme.currentColorSet()));
                            colorSetPicker.open();
                        }
                    }

                    TextRow {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Save as"
                        placeholder: "name"
                        onCommitted: text => Theme.saveColorSet(text)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Focus opacity"
                        from: 0
                        to: 0.8
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.base.focusFill
                        onCommitted: v => Theme.base.focusFill = Math.round(v * 100) / 100
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Brightness"
                        from: -1
                        to: 1
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.base.brightness
                        onCommitted: v => Theme.base.brightness = Math.round(v * 100) / 100
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Contrast"
                        from: -1
                        to: 1
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.base.contrast
                        onCommitted: v => Theme.base.contrast = Math.round(v * 100) / 100
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: page.cellHeight
                        navGroup: 2
                        label: "Saturation"
                        from: -1
                        to: 1
                        stepSize: 0.05
                        decimals: 2
                        value: Theme.base.saturation
                        onCommitted: v => Theme.base.saturation = Math.round(v * 100) / 100
                    }

                    Repeater {
                        id: colorRepeater
                        model: page.colorRows

                        ColorField {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: page.cellHeight
                            navGroup: 2
                            label: modelData.label
                            value: Theme[modelData.group][modelData.key]
                            onReleased: page.forceActiveFocus()
                            onActivated: {
                                page.pickRow = index;
                                picker.open();
                            }
                            onCommitted: hex => Theme.setColor(modelData.group, modelData.key, hex)
                        }
                    }
                }
            }
        }
    }

    // Picked colors go through the same path as typed hex codes
    ColorPicker {
        id: picker

        anchors.fill: parent
        onPicked: hex => {
            const row = page.colorRows[page.pickRow];
            Theme.setColor(row.group, row.key, hex);
        }
        onClosed: colorRepeater.itemAt(page.pickRow)?.forceActiveFocus()
    }

    ListPicker {
        id: colorSetPicker

        anchors.fill: parent
        deletable: true
        onPicked: value => Theme.applyColorSet(value)
        onDeleteRequested: value => {
            Theme.deleteColorSet(value);
            items = Object.keys(Theme.colorSets).sort();
        }
    }

    ListPicker {
        id: fontPicker

        anchors.fill: parent
        onPicked: value => Theme.font.family = value
    }

    ListPicker {
        id: uiFontPicker

        anchors.fill: parent
        onPicked: value => Theme.font.uiFamily = value
    }

    ListPicker {
        id: iconPicker

        anchors.fill: parent
        onPicked: value => Theme.font.iconTheme = value
    }

    ListPicker {
        id: gtkThemePicker

        anchors.fill: parent
        onPicked: value => Theme.font.gtkTheme = value
    }

    ListPicker {
        id: cursorPicker

        anchors.fill: parent
        onPicked: value => Theme.font.cursorTheme = value
    }

    // The lists load in the background, keep an already open picker in step
    Connections {
        target: SystemFonts

        function onFontFamiliesChanged() {
            fontPicker.items = SystemFonts.fontFamilies;
            uiFontPicker.items = SystemFonts.fontFamilies;
        }
        function onIconThemesChanged() {
            iconPicker.items = SystemFonts.iconThemes;
        }
        function onGtkThemesChanged() {
            gtkThemePicker.items = SystemFonts.gtkThemes;
        }
        function onCursorThemesChanged() {
            cursorPicker.items = SystemFonts.cursorThemes;
        }
    }
}
