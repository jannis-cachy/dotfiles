pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Singleton {
    id: root

    // Monitor name to file name currently shown, from hyprpaper
    property var active: ({})

    // monitor is a screen name or "" for all screens, the choice is saved in settings.json
    function apply(monitor, path) {
        if (monitor === "lock" || monitor === "login") {
            applySpecial(monitor, path);
            return;
        }
        const names = monitor === "" ? Quickshell.screens.map(s => s.name) : [monitor];
        const saved = Object.assign({}, Theme.wallpapers);
        for (const name of names) {
            Quickshell.execDetached(["hyprctl", "hyprpaper", "wallpaper", `${name},${path},cover`]);
            saved[name] = path;
        }
        Theme.wallpapers = saved;
        refreshTimer.restart();
    }

    // hyprlock reads a fixed png, the greeter prefers current* in its dir (the name keeps the original, the greeter styles Persona wallpapers by it)
    function applySpecial(kind, path) {
        const state = Quickshell.env("HOME") + "/.local/state/quickshell";
        if (kind === "lock") {
            // Persona wallpapers get the Persona clock, anything else the normal one
            const style = path.toLowerCase().includes("persona") ? "persona" : "normal";
            Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && magick "$2" "$1/lock-wallpaper.png" && cp "$HOME/.config/hypr/hyprlock-clock-$3.conf" "$1/lock-clock.conf"', "sh", state, path, style]);
            Theme.lockWallpaper = path;
        } else {
            const dir = "/var/lib/greeter-wallpapers";
            Quickshell.execDetached(["sh", "-c", 'rm -f "$1"/current* && cp "$2" "$1/current--$(basename "$2")" && chmod 644 "$1"/current*', "sh", dir, path]);
            Theme.loginWallpaper = path;
        }
    }

    function refresh() {
        listProcess.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: listProcess
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf(": ");
                    if (i > 0)
                        map[line.slice(0, i)] = line.slice(i + 2).split("/").pop();
                }
                root.active = map;
            }
        }
    }
}
