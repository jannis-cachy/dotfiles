import QtQuick
import Quickshell
import "./modules/bar"
import "./modules"
import "./modules/controlcenter"
import "./modules/clipboard"
import "./modules/launcher"
import "./services"

Scope {
    id: root

    // References the singleton so it loads and applies at startup, no visible UI of its own
    QtObject {
        Component.onCompleted: {
            SystemTheme.apply();
            // Touching the singletons starts their lists (fonts, themes) before a page needs them
            Notification.count;
            SystemFonts.fontFamilies;
        }
    }

    // Top Bar Module
    Bar {}

    // Standalone Popups & Overlays
    PdfWidget {}
    NetworkModule {}
    ControlCenter {}
    ClipboardPopup {}
    Launcher {}
    Shutdown {}
}
