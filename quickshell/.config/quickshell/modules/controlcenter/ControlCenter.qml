import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../theme"
import "../../services"

Scope {
    id: root

    property bool open: false
    property string page: "main"
    // Entry that was selected in the main menu, shown again when coming back
    property int mainIndex: 0
    // Same for the Bar submenu
    property int barIndex: 0
    // Set by the loaded page (blurBackground), the dim layer and blur backdrop only exist while true
    property bool blur: true
    // Monitor the menu opened on, it stays there while the focus moves to another monitor
    property var targetScreen: focusedScreen()

    function focusedScreen() {
        return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    readonly property var pages: ({
            main: "MainPage.qml",
            appearance: "AppearancePage.qml",
            settings: "SettingsPage.qml",
            keybinds: "KeybindsPage.qml",
            bar: "BarPage.qml",
            power: "PowerPage.qml",
            audio: "AudioPage.qml",
            network: "NetworkPage.qml",
            datetime: "DateTimePage.qml",
            binaries: "BinariesPage.qml",
            wallpapers: "WallpapersPage.qml",
            finder: "FinderPage.qml",
            apps: "AppsPage.qml"
        })

    // Pages opened from another page go back to it, everything else back to the main menu
    readonly property var parentPage: ({
            power: "bar",
            audio: "bar",
            network: "bar",
            datetime: "bar",
            finder: "bar"
        })

    function back() {
        root.page = root.parentPage[root.page] ?? "main";
    }

    // The bar stays expanded on the Appearance page to show color changes
    Binding {
        target: BarState
        property: "pinned"
        value: root.open && root.page === "appearance"
    }

    // qs ipc call controlcenter toggle
    // qs ipc call controlcenter goto <main|appearance|settings|keybinds|binaries|wallpapers|finder|apps|bar|power|audio|network|datetime>
    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            root.page = "main";
            if (!root.open)
                root.targetScreen = root.focusedScreen();
            root.open = !root.open;
        }

        function goto(name: string): void {
            root.page = name in root.pages ? name : "main";
            root.targetScreen = root.focusedScreen();
            root.open = true;
        }
    }

    // qs ipc call wallpaper set <monitor|all> <path>
    IpcHandler {
        target: "wallpaper"

        function set(monitor: string, path: string): void {
            Wallpaper.apply(monitor === "all" ? "" : monitor, path);
        }
    }

    // Blur backdrop, matched by the controlcenter-blur layer rule in Rules.lua.
    // Below the page window and without input, so clicks reach the page window.
    LazyLoader {
        active: root.open && root.blur && Theme.controlcenter.blur

        PanelWindow {
            screen: root.targetScreen

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "controlcenter-blur"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            mask: Region {}
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: root.targetScreen

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            // OnDemand lets a click on another window or monitor take the keyboard, Exclusive would block that
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            // Full screen so clicks outside the page can close it
            WlrLayershell.namespace: "controlcenter"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            Item {
                anchors.fill: parent

                // Dim layer behind the menus, pages with blurBackground false (Appearance) skip it
                Rectangle {
                    anchors.fill: parent
                    visible: root.blur && Theme.controlcenter.dim
                    color: Qt.rgba(Theme.colors.surface.r, Theme.colors.surface.g, Theme.colors.surface.b, 0.7)
                }

                Keys.onEscapePressed: {
                    if (root.page === "main")
                        root.open = false;
                    else
                        root.back();
                }

                // Click outside the page closes
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        const p = mapToItem(loader, mouse.x, mouse.y);
                        if (p.x < 0 || p.y < 0 || p.x > loader.width || p.y > loader.height)
                            root.open = false;
                    }
                }

                Reveal {
                    id: pageReveal
                    target: loader
                    when: false
                }

                // Each page sets its own implicitWidth and implicitHeight, the Loader follows
                Loader {
                    id: loader
                    anchors.centerIn: parent
                    source: root.pages[root.page]
                    onLoaded: {
                        pageReveal.restart();
                        if (root.page === "main")
                            item.current = root.mainIndex;
                        if (root.page === "bar")
                            item.focusRow(root.barIndex);
                        else if (item.focusDefault)
                            item.focusDefault();
                        else
                            item.forceActiveFocus();
                        root.blur = item.blurBackground !== false;
                    }
                }

                Connections {
                    target: loader.item
                    ignoreUnknownSignals: true

                    function onNavigate(target) {
                        if (root.page === "main")
                            root.mainIndex = loader.item.current;
                        else if (root.page === "bar")
                            root.barIndex = loader.item.current;
                        if (target === "main")
                            root.back();
                        else
                            root.page = target;
                    }

                    function onClose() {
                        root.open = false;
                    }
                }
            }
        }
    }
}
