pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "OkColor.js" as OkColor

Singleton {
    id: root

    property alias scale: adapter.scale
    property alias rounding: adapter.rounding
    property alias frameRounding: adapter.frameRounding
    property alias menuAngle: adapter.menuAngle
    property alias menuRounding: adapter.menuRounding
    // The colors as picked, saved and edited on the Appearance page
    property alias base: adapter.colors
    // What the shell draws with: base colors after the brightness, contrast and saturation sliders
    readonly property QtObject colors: QtObject {
        readonly property string bg: root.adjusted("bg")
        readonly property string surface: root.adjusted("surface")
        readonly property string border: root.adjusted("border")
        readonly property string text: root.adjusted("text")
        readonly property string textMuted: root.adjusted("textMuted")
        readonly property string accent: root.adjusted("accent")
        readonly property string textOnAccent: root.adjusted("textOnAccent")
        readonly property string selection: root.adjusted("selection")
        readonly property string focus: root.adjusted("focus")
        readonly property string error: root.adjusted("error")
        readonly property string warning: root.adjusted("warning")
        readonly property string success: root.adjusted("success")
    }

    function adjusted(key) {
        return OkColor.adjust(base[key], base.brightness, base.contrast, base.saturation);
    }
    property alias hypr: adapter.hypr
    property alias autostart: adapter.autostart
    property alias bar: adapter.bar
    property alias animations: adapter.animations
    property alias colorHistory: adapter.colorHistory
    property alias colorSets: adapter.colorSets
    property alias mainMonitor: adapter.mainMonitor
    property alias font: adapter.font
    property alias notification: adapter.notification
    property alias wallpapers: adapter.wallpapers
    property alias lockWallpaper: adapter.lockWallpaper
    property alias loginWallpaper: adapter.loginWallpaper
    property alias mouse: adapter.mouse
    property alias audio: adapter.audio
    property alias launcher: adapter.launcher
    property alias screenshot: adapter.screenshot
    property alias finder: adapter.finder
    property alias controlcenter: adapter.controlcenter
    property alias clock: adapter.clock

    // Fill opacity of the selection color behind whatever has keyboard focus, used by every menu
    readonly property real focusFill: base.focusFill

    // One row of swatches in the Appearance page, the oldest color drops out
    readonly property int colorHistoryMax: 11

    // Screen for the expandable bar and the pdf widget
    readonly property var mainScreen: Quickshell.screens.find(s => s.name === mainMonitor) ?? Quickshell.screens[0]

    // True while several values are set in one go, so the file is written once at the end. Writing
    // after each value let the file watcher reload a half updated file over the remaining values.
    property bool batching: false

    // Only these settings.json values (dotted paths) are pushed to Hyprland when they change,
    // everything else is quickshell only. They are applied live with `hyprctl eval`, no reload
    // (hyprApply mirrors what Generals.lua, Decorations.lua and Input.lua read at config load).
    readonly property var hyprReloadKeys: ["hypr", "rounding", "colors.focus", "colors.brightness", "colors.contrast", "colors.saturation", "mouse", "font.iconTheme", "font.cursorTheme", "font.cursorSize", "animations"]
    property string lastHyprSig: ""

    function hyprSignature() {
        try {
            const data = JSON.parse(settingsFile.text());
            return hyprReloadKeys.map(path => JSON.stringify(path.split(".").reduce((o, k) => o === undefined || o === null ? undefined : o[k], data))).join("|");
        } catch (e) {
            return null;
        }
    }

    function hyprApply() {
        const h = adapter.hypr;
        const lua = 'hl.config({ general = { gaps_in = ' + h.gapsIn + ', gaps_out = ' + h.gapsOut + ', border_size = ' + h.borderSize + ', col = { active_border = "' + root.colors.focus + '" } }, animations = { enabled = ' + adapter.animations.enabled + ' }, decoration = { rounding = ' + adapter.rounding + ' } }) ' + 'hl.device({ name = "sonix-usb-device", sensitivity = ' + adapter.mouse.sensitivity + ', scroll_factor = ' + adapter.mouse.scrollFactor + ' }) ' + 'hl.env("QS_ICON_THEME", "' + adapter.font.iconTheme + '") hl.env("XCURSOR_THEME", "' + adapter.font.cursorTheme + '") hl.env("XCURSOR_SIZE", "' + adapter.font.cursorSize + '") hl.env("HYPRCURSOR_THEME", "' + adapter.font.cursorTheme + '") hl.env("HYPRCURSOR_SIZE", "' + adapter.font.cursorSize + '")';
        applyProcess.command = ["hyprctl", "eval", lua + " " + Motion.hyprLua()];
        applyProcess.running = true;
    }

    // Applied once on start too, since Generals.lua only knows the unadjusted focus color
    Component.onCompleted: {
        lastHyprSig = hyprSignature() ?? "";
        hyprReload.restart();
    }

    FileView {
        id: settingsFile

        path: Quickshell.shellPath("settings.json")
        blockLoading: true
        watchChanges: true

        // File edits (manual or from the control center) update the shell and Hyprland
        onFileChanged: {
            reload();
            const sig = root.hyprSignature();
            if (sig !== null && sig !== root.lastHyprSig) {
                root.lastHyprSig = sig;
                hyprReload.restart();
            }
        }
        onAdapterUpdated: {
            if (!root.batching)
                writeAdapter();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: adapter

            property real scale: 1
            property int rounding: 8
            // Inverse corners where the frame meets the workspace
            property int frameRounding: 12
            // Slant of the main menu end buttons in degrees and corner radius of all menu buttons
            property real menuAngle: 10
            property real menuRounding: 6
            property string mainMonitor: "DP-1"

            // Monitor name to absolute image path, applied at login by hyprland_modules/Wallpaper.lua
            property var wallpapers: ({})
            // Source file of the hyprlock and greetd wallpapers (copies live in the state dir and /var/lib/greeter-wallpapers)
            property string lockWallpaper: ""
            property string loginWallpaper: ""

            // Roles: neutrals (bg, surface, border, text, textMuted), accent with its text, selection fill,
            // GUI focus ring (also the Hyprland window border), status colors. Stored as hex.
            property JsonObject colors: JsonObject {
                property string bg: "#0d0d0d"
                property string surface: "#313244"
                property string border: "#2a2a2e"
                property string text: "#ffffff"
                property string textMuted: "#7b7b7b"
                property string accent: "#d92323"
                property string textOnAccent: "#ffffff"
                property string selection: "#732424"
                property string focus: "#d92323"
                property string error: "#ff4d6d"
                property string warning: "#f2e852"
                property string success: "#4ade80"
                // Opacity of the selection fill behind the focused item, saved with color sets
                property real focusFill: 0.3
                // Global tweaks of every color above, 0 leaves the picked colors untouched
                property real brightness: 0
                property real contrast: 0
                property real saturation: 0
            }

            // Saved palettes, name to a copy of the colors group
            property var colorSets: ({})

            // Colors that were replaced, newest first, so they can be restored
            property var colorHistory: []

            property JsonObject font: JsonObject {
                // Nerd/mono font: code, icons, anything fixed-width. UI chrome uses uiFamily instead.
                property string family: "JetBrainsMono Nerd Font"
                property string uiFamily: "Noto Sans"
                property int fontSize: 13
                // Relative multiplier on top of Theme.scale, applied to every font.pixelSize
                property real scale: 1.0
                // GTK/Qt/cursor only, quickshell draws its own icons via MaterialIcon and never shows a cursor itself
                property string iconTheme: "Papirus-Dark"
                property string gtkTheme: "adw-gtk3-dark"
                property string cursorTheme: "Bibata-Modern-Ice"
                property int cursorSize: 24
            }

            property JsonObject notification: JsonObject {
                // Popup lifetime in ms, width in px before Theme.scale
                property int timeout: 5000
                property int width: 380
                property int maxHistory: 50
            }

            property JsonObject autostart: JsonObject {
                property bool enabled: true
                // Read by autostart.lua
                property bool quickshell: true
            }

            // Hyprland (Animations.lua) and quickshell animations, off means everything is instant
            property JsonObject animations: JsonObject {
                property bool enabled: false
            }

            property JsonObject bar: JsonObject {
                // SUPER + E also hides the frame, so a monitor shows either nothing or frame and bar
                property bool toggleFrame: false
            }

            // Applied to the Speedlink mouse (sonix-usb-device) via hl.device in Input.lua
            property JsonObject mouse: JsonObject {
                property real sensitivity: 0
                property real scrollFactor: 0.0
            }

            property JsonObject hypr: JsonObject {
                property int gapsIn: 2
                property int gapsOut: 15
                property int borderSize: 2
            }

            // Read by scripts/Binaries/FullScreenshot
            property JsonObject screenshot: JsonObject {
                property bool allScreens: false
            }

            property JsonObject launcher: JsonObject {
                property bool blur: false
                property bool dim: true
                // Also list apps from modules/launcher/Hidden.js and Steam games
                property bool showMore: false
            }

            property JsonObject finder: JsonObject {
                // Ignore the lists below and hidden folders filter, search everything in home
                property bool searchAll: false
                // Dot files and folders, the excludes still apply plus excludeHiddenDirs
                property bool showHidden: false
                // Also index systemDirs, installed software and system config
                property bool searchSystem: false
                property var systemDirs: ["/etc", "/opt", "/usr/local", "/usr/share/applications"]
                property var excludeHiddenDirs: [".git", ".cache", ".local/share", ".local/state", ".steam", ".var", ".mozilla", ".npm", ".cargo", ".rustup", ".nvm", ".thunderbird"]
                // Folder names or paths relative to home (fd glob), searched nowhere
                property var excludeDirs: ["node_modules", "__pycache__", "venv", "site-packages", "build", "target", "dist", "DaVinci Resolve Media", "resolve-linux", "Wallpapers", "Templates"]
                // File extensions without the dot
                property var excludeExts: ["pyc", "pyo", "o", "obj", "class", "so", "a", "dll", "lock", "tmp", "temp", "bak", "swp", "log", "aux", "fls", "fdb_latexmk", "toc", "out", "bbl", "blg", "idx", "ilg", "ind", "lof", "lot", "synctex.gz", "cache", "db", "sqlite", "dat", "pak", "mo", "qmlc", "jsc", "ttf", "otf", "woff", "woff2", "map"]
            }

            property JsonObject clock: JsonObject {
                property bool use24h: true
            }

            property JsonObject controlcenter: JsonObject {
                property bool blur: false
                // Dark layer behind the pages, Appearance never shows it
                property bool dim: true
            }

            property JsonObject audio: JsonObject {
                // Pipewire node name to a custom display name, set from the Audio page
                property var deviceNames: ({})
            }
        }
    }

    // group is "base", key the property inside it, hex is "#rrggbb"
    function setColor(group, key, hex) {
        const target = root[group];
        const old = target[key];
        if (old.toLowerCase() === hex.toLowerCase())
            return;
        const rest = Array.from(colorHistory).filter(c => c.toLowerCase() !== old.toLowerCase() && c.toLowerCase() !== hex.toLowerCase());
        colorHistory = [old, ...rest].slice(0, colorHistoryMax);
        target[key] = hex;
    }

    readonly property var colorKeys: ["bg", "surface", "border", "text", "textMuted", "accent", "textOnAccent", "selection", "focus", "error", "warning", "success"]

    readonly property var numKeys: ["focusFill", "brightness", "contrast", "saturation"]

    function saveColorSet(name) {
        const snap = {};
        colorKeys.forEach(k => snap[k] = base[k]);
        numKeys.forEach(k => snap[k] = base[k]);
        const next = Object.assign({}, colorSets);
        next[name] = snap;
        colorSets = next;
    }

    function deleteColorSet(name) {
        const next = Object.assign({}, colorSets);
        delete next[name];
        colorSets = next;
    }

    function applyColorSet(name) {
        const set = colorSets[name];
        if (!set)
            return;
        batching = true;
        colorKeys.forEach(k => {
            if (set[k] && base[k].toLowerCase() !== set[k].toLowerCase())
                base[k] = set[k];
        });
        numKeys.forEach(k => {
            if (set[k] !== undefined)
                base[k] = set[k];
        });
        batching = false;
        settingsFile.writeAdapter();
    }

    // Name of the saved set equal to the current colors, "Custom" if none
    function currentColorSet() {
        const match = Object.keys(colorSets).find(n => colorKeys.every(k => (colorSets[n][k] ?? "").toLowerCase() === base[k].toLowerCase()) && numKeys.every(k => Math.abs((colorSets[n][k] ?? base[k]) - base[k]) < 0.001));
        return match ?? "Custom";
    }

    Timer {
        id: hyprReload
        interval: 300
        onTriggered: root.hyprApply()
    }

    // A Hyprland reload runs Animations.lua again, which would replace the pushed curves
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                hyprReload.restart();
        }
    }

    Process {
        id: reloadProcess
        command: ["hyprctl", "reload"]
    }

    Process {
        id: applyProcess
    }
}
