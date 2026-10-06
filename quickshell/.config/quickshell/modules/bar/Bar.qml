import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../../theme"

// Thin frame around every monitor. On a monitor whose bar is toggled (SUPER + E, acts on the
// focused monitor, or the main one while the Appearance page is open) the left edge grows into
// the bar. All edges reserve space. With bar.toggleFrame the frame only exists while the bar does.
Scope {
    id: root

    // qs ipc call bar toggle
    IpcHandler {
        target: "bar"

        function toggle(): void {
            const name = Hyprland.focusedMonitor?.name ?? Theme.mainMonitor;
            BarState.toggle(name);
        }

        function open(): void {
            const name = Hyprland.focusedMonitor?.name ?? Theme.mainMonitor;
            if (!BarState.shown[name])
                BarState.toggle(name);
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData
            readonly property bool expanded: BarState.isExpanded(modelData.name)
            readonly property real leftThickness: expanded ? BarState.barSize : BarState.frameSize

            // Unloaded rather than hidden, so a monitor without frame holds no windows
            LazyLoader {
                active: !Theme.bar.toggleFrame || screenScope.expanded

                Scope {
                    Frame {
                        screen: screenScope.modelData
                        leftThickness: screenScope.leftThickness
                        expanded: screenScope.expanded
                    }

                    FrameReserve {
                        screen: screenScope.modelData
                        edge: "top"
                    }

                    FrameReserve {
                        screen: screenScope.modelData
                        edge: "bottom"
                    }

                    FrameReserve {
                        screen: screenScope.modelData
                        edge: "right"
                    }

                    FrameReserve {
                        screen: screenScope.modelData
                        edge: "left"
                        thickness: screenScope.leftThickness
                    }
                }
            }
        }
    }
}
