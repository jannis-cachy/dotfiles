import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtQuick.Effects
import Quickshell
import "../../theme"
import "Nav.js" as Nav
import "../../services"

PageFrame {
    id: page

    title: "Wallpapers"
    implicitWidth: 560 * Theme.scale
    implicitHeight: 500 * Theme.scale

    // "" applies to all screens
    property string target: ""
    readonly property var targets: [""].concat(Quickshell.screens.map(s => s.name), ["lock", "login"])

    function applyCurrent() {
        if (grid.currentItem)
            Wallpaper.apply(target, grid.currentItem.filePath);
    }

    // Tab cycles the target, the grid takes the arrow keys and passes Up at the first row to PageFrame (focus chain)
    Keys.onTabPressed: target = targets[(targets.indexOf(target) + 1) % targets.length]

    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Theme.scale

        // Which screen a click applies to
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Theme.scale

            Repeater {
                model: page.targets

                Rectangle {
                    required property string modelData
                    readonly property bool selected: page.target === modelData

                    implicitWidth: chipText.implicitWidth + 24 * Theme.scale
                    implicitHeight: 28 * Theme.scale
                    radius: Theme.rounding / 2 * Theme.scale
                    color: selected ? Theme.colors.selection : Theme.colors.surface

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: parent.modelData === "" ? "All screens" : parent.modelData === "lock" ? "Lock screen" : parent.modelData === "login" ? "Login" : parent.modelData
                        color: Theme.colors.text
                        font.family: Theme.font.uiFamily
                        font.pixelSize: 12 * Theme.scale * Theme.font.scale
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: page.target = parent.modelData
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property int columns: 2

            clip: true
            currentIndex: 0
            activeFocusOnTab: true
            keyNavigationEnabled: false

            // Arrows and hjkl share one move, an edge hands the key to PageFrame
            function step(dir) {
                if (dir === "left" && currentIndex % columns !== 0)
                    moveCurrentIndexLeft();
                else if (dir === "right")
                    moveCurrentIndexRight();
                else if (dir === "up" && currentIndex >= columns)
                    moveCurrentIndexUp();
                else if (dir === "down" && currentIndex + columns < count)
                    moveCurrentIndexDown();
                else
                    return false;
                return true;
            }
            Keys.onLeftPressed: event => event.accepted = step("left")
            Keys.onRightPressed: event => event.accepted = step("right")
            Keys.onUpPressed: event => event.accepted = step("up")
            Keys.onDownPressed: event => event.accepted = step("down")
            Keys.onPressed: event => {
                const dir = Nav.vim(event);
                if (dir)
                    event.accepted = step(dir);
            }
            Keys.onReturnPressed: page.applyCurrent()
            Keys.onTabPressed: page.target = page.targets[(page.targets.indexOf(page.target) + 1) % page.targets.length]
            cellWidth: width / columns
            cellHeight: cellWidth * 0.62

            model: FolderListModel {
                folder: "file://" + Quickshell.env("HOME") + "/Wallpapers"
                nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                showDirs: false
            }

            delegate: Item {
                id: cell

                required property int index
                required property string fileName
                required property url fileUrl
                readonly property string filePath: fileUrl.toString().replace("file://", "")

                // Screens currently showing this file
                readonly property var shownOn: Object.keys(Wallpaper.active).filter(m => Wallpaper.active[m] === fileName).concat(Theme.lockWallpaper === filePath ? ["lock"] : [], Theme.loginWallpaper === filePath ? ["login"] : [])

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4 * Theme.scale
                    radius: Theme.rounding / 2 * Theme.scale
                    color: Theme.colors.surface

                    // Thumbnail and name bar are masked so they follow the rounded corners
                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: mask
                        }

                        Image {
                            anchors.fill: parent
                            source: cell.fileUrl
                            sourceSize.width: 320
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 22 * Theme.scale
                            color: "#99000000"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8 * Theme.scale
                                anchors.rightMargin: 8 * Theme.scale
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: cell.fileName
                                color: Theme.colors.text
                                font.family: Theme.font.uiFamily
                                font.pixelSize: 11 * Theme.scale * Theme.font.scale
                            }
                        }
                    }

                    Rectangle {
                        id: mask
                        anchors.fill: parent
                        radius: parent.radius
                        visible: false
                        layer.enabled: true
                    }

                    // Screens showing this wallpaper
                    Rectangle {
                        visible: cell.shownOn.length > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6 * Theme.scale
                        width: badge.implicitWidth + 12 * Theme.scale
                        height: 20 * Theme.scale
                        radius: Theme.rounding / 2 * Theme.scale
                        color: Theme.colors.accent

                        Text {
                            id: badge
                            anchors.centerIn: parent
                            text: cell.shownOn.join(", ")
                            color: Theme.colors.textOnAccent
                            font.family: Theme.font.uiFamily
                            font.pixelSize: 11 * Theme.scale * Theme.font.scale
                        }
                    }

                    // Cursor is focus, wallpaper in use is accent
                    Rectangle {
                        readonly property bool focused: cell.GridView.isCurrentItem && grid.activeFocus
                        anchors.fill: parent
                        color: focused ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : "transparent"
                        border.width: (focused || cell.shownOn.length > 0) ? (focused ? 4 : 2) * Theme.scale : 0
                        border.color: (cell.GridView.isCurrentItem && grid.activeFocus) ? Theme.colors.focus : Theme.colors.accent
                        radius: parent.radius
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            grid.currentIndex = cell.index;
                            grid.forceActiveFocus();
                        }
                        onClicked: {
                            grid.currentIndex = cell.index;
                            page.applyCurrent();
                        }
                    }
                }
            }
        }
    }
}
