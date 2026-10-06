import QtQuick
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Login screen for greetd, runs as the greeter user inside cage (system/greetd/greeter-session.sh).
// Preview in a window: GREETER_WALLPAPERS=$HOME/Wallpapers quickshell -p system/greetd/greeter
ShellRoot {
    id: root

    // Single user PC, the username is never asked
    readonly property string user: "jannis"
    readonly property string wallDir: Quickshell.env("GREETER_WALLPAPERS") || "/var/lib/greeter-wallpapers"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    // Right panel share of the width
    readonly property real split: 0.62

    FontLoader {
        id: clockFont
        source: "fonts/Oxanium.ttf"
    }

    FontLoader {
        id: personaFont
        source: "fonts/DelaGothicOne.ttf"
    }

    // Persona 5 look when the wallpaper file name contains persona (the login copy keeps the name)
    readonly property bool persona: wallpaper.toLowerCase().includes("persona")

    // Same values as the defaults in the quickshell theme (the home dir is not readable here)
    readonly property color cPrimary: "#c62828"
    readonly property color cSecondary: "#732424"
    readonly property color cText: "#ffffff"
    readonly property color cSubtext: "#9a9a9a"
    readonly property color cWidget: "#313244"

    property var sessions: []
    property int sessionIndex: 0
    property string wallpaper: ""
    property string status: ""
    property bool busy: false
    property bool askingPassword: false
    // Password text shared by every screen, so the field looks the same everywhere
    property string typed: ""
    signal focusField

    // cage spans one window over all outputs, so each screen gets its own copy of the scene.
    // One screen (or the windowed preview) uses the whole window.
    readonly property bool preview: !!Quickshell.env("GREETER_WALLPAPERS")
    readonly property var tiles: {
        const list = Quickshell.screens;
        if (preview || list.length < 2)
            return [
                {
                    x: 0,
                    y: 0,
                    w: -1,
                    h: -1,
                    primary: true
                }
            ];
        const minX = Math.min(...list.map(s => s.x));
        const minY = Math.min(...list.map(s => s.y));
        // Keyboard goes to DP-1, the other screens mirror the field
        const main = list.findIndex(s => s.name === "DP-1");
        return list.map((s, i) => ({
                    x: s.x - minX,
                    y: s.y - minY,
                    w: s.width,
                    h: s.height,
                    primary: i === (main >= 0 ? main : 0)
                }));
    }

    readonly property string sessionName: sessions.length > 0 ? sessions[sessionIndex].name : "Hyprland"

    function cycleSession(step) {
        if (sessions.length > 0)
            sessionIndex = (sessionIndex + step + sessions.length) % sessions.length;
    }

    function submit(password) {
        if (!Greetd.available) {
            status = "greetd not available";
            return;
        }
        if (!askingPassword || busy)
            return;
        busy = true;
        askingPassword = false;
        status = "";
        Greetd.respond(password);
    }

    function startSession() {
        if (!Greetd.available)
            return;
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        Greetd.createSession(user);
    }

    // A file named current.* in the wallpaper dir wins, otherwise a random one
    function pickWallpaper() {
        if (wallpaper !== "" || wallModel.status !== FolderListModel.Ready || wallModel.count === 0)
            return;
        let index = Math.floor(Math.random() * wallModel.count);
        for (let i = 0; i < wallModel.count; i++) {
            if (wallModel.get(i, "fileName").startsWith("current"))
                index = i;
        }
        wallpaper = wallModel.get(index, "fileUrl");
    }

    Component.onCompleted: startSession()

    FolderListModel {
        id: wallModel
        folder: "file://" + root.wallDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        onStatusChanged: root.pickWallpaper()
        onCountChanged: root.pickWallpaper()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do printf '%s\\t%s\\n' \"$(sed -n 's/^Name=//p' \"$f\" | head -1)\" \"$(sed -n 's/^Exec=//p' \"$f\" | head -1)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts.length === 2 && parts[0] !== "" && parts[1] !== "")
                        list.push({
                            name: parts[0],
                            exec: parts[1]
                        });
                }
                root.sessions = list;
            }
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                root.askingPassword = true;
                root.busy = false;
                root.focusField();
            } else {
                root.status = message;
            }
        }

        function onAuthFailure(message) {
            root.status = "Wrong password";
            root.busy = false;
            root.typed = "";
            root.startSession();
        }

        function onReadyToLaunch() {
            const exec = root.sessions.length > 0 ? root.sessions[root.sessionIndex].exec : "/usr/bin/start-hyprland";
            Greetd.launch(exec.split(" "), ["XDG_SESSION_TYPE=wayland"], true);
        }

        function onError(error) {
            root.status = error;
            root.busy = false;
        }
    }

    FloatingWindow {
        id: win
        visible: true
        color: "#101014"

        Repeater {
        model: root.tiles

        Item {
            id: scene

            required property var modelData

            x: modelData.x
            y: modelData.y
            width: modelData.w > 0 ? modelData.w : win.width
            height: modelData.h > 0 ? modelData.h : win.height
            clip: true

            readonly property real s: Math.max(0.5, height / 1080)
            readonly property real split: root.split
            readonly property real skew: height * 0.1
            // Divider top and bottom x, leaning like a slash, two thirds across
            readonly property real xTop: width * split + skew / 2
            readonly property real xBot: width * split - skew / 2

            Image {
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            // Left area light dim, right panel strong dim
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: Qt.rgba(0, 0, 0, 0.25)
                    startX: 0
                    startY: 0
                    PathLine { x: scene.xTop; y: 0 }
                    PathLine { x: scene.xBot; y: scene.height }
                    PathLine { x: 0; y: scene.height }
                }

                ShapePath {
                    strokeWidth: -1
                    fillColor: Qt.rgba(0, 0, 0, 0.7)
                    startX: scene.xTop
                    startY: 0
                    PathLine { x: scene.width; y: 0 }
                    PathLine { x: scene.width; y: scene.height }
                    PathLine { x: scene.xBot; y: scene.height }
                }

                // Main divider
                ShapePath {
                    strokeWidth: 3 * scene.s
                    strokeColor: root.cPrimary
                    fillColor: "transparent"
                    startX: scene.xTop
                    startY: 0
                    PathLine { x: scene.xBot; y: scene.height }
                }

                // Thin echo line next to it
                ShapePath {
                    strokeWidth: 1 * scene.s
                    strokeColor: root.cSecondary
                    fillColor: "transparent"
                    startX: scene.xTop + 24 * scene.s
                    startY: 0
                    PathLine { x: scene.xBot + 24 * scene.s; y: scene.height }
                }
            }

            // Clock and date on the open area
            Column {
                visible: !root.persona
                x: 96 * scene.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * scene.s

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: root.cText
                    font.family: clockFont.name
                    font.weight: Font.Light
                    font.pixelSize: 200 * scene.s
                }

                Text {
                    leftPadding: 8 * scene.s
                    text: Qt.formatDateTime(clock.date, "dddd, d. MMMM yyyy")
                    color: root.cText
                    opacity: 0.85
                    font.family: clockFont.name
                    font.pixelSize: 36 * scene.s
                    font.weight: Font.Light
                    font.letterSpacing: 2 * scene.s
                }
            }

            // Persona 5 style: lower left, tilted, every letter its own item
            Column {
                visible: root.persona
                x: 70 * scene.s
                y: scene.height - height - 60 * scene.s
                spacing: 40 * scene.s
                rotation: -4
                transformOrigin: Item.BottomLeft

                PersonaWord {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    size: 200 * scene.s
                    seed: 3
                    fam: personaFont.name
                }

                PersonaWord {
                    z: 1
                    x: 40 * scene.s
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM").toUpperCase()
                    size: 54 * scene.s
                    seed: 11
                    fam: personaFont.name
                }
            }

            // Login column centered in the right third
            Column {
                id: panel
                x: (scene.width * root.split + scene.width) / 2 - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 380 * scene.s
                spacing: 18 * scene.s

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.user
                    color: root.cText
                    font.family: root.fontFamily
                    font.pixelSize: 38 * scene.s
                }

                Rectangle {
                    width: parent.width
                    height: 54 * scene.s
                    radius: 12 * scene.s
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 2 * scene.s
                    border.color: pwField.activeFocus ? root.cPrimary : Qt.rgba(1, 1, 1, 0.15)

                    TextInput {
                        id: pwField
                        anchors.fill: parent
                        anchors.leftMargin: 18 * scene.s
                        anchors.rightMargin: 18 * scene.s
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.cText
                        font.family: root.fontFamily
                        font.pixelSize: 22 * scene.s
                        selectionColor: root.cPrimary
                        enabled: !root.busy
                        focus: scene.modelData.primary
                        onTextEdited: root.typed = text
                        onAccepted: {
                            root.submit(text);
                            root.typed = "";
                        }
                        Keys.onEscapePressed: root.typed = ""

                        Connections {
                            target: root

                            function onTypedChanged() {
                                if (pwField.text !== root.typed)
                                    pwField.text = root.typed;
                            }

                            function onFocusField() {
                                if (scene.modelData.primary)
                                    pwField.forceActiveFocus();
                            }
                        }
                    }

                    Text {
                        visible: root.typed === "" && !root.busy
                        anchors.left: parent.left
                        anchors.leftMargin: 18 * scene.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        color: root.cSubtext
                        font.family: root.fontFamily
                        font.pixelSize: 20 * scene.s
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 20 * scene.s
                    text: root.status
                    color: root.cPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 16 * scene.s
                }

                // Session: Left/Right (or h/l) or Enter cycles
                Btn {
                    s: scene.s
                    fam: root.fontFamily
                    accent: root.cPrimary
                    txt: root.cText
                    id: sessionBtn
                    width: parent.width
                    label: "‹  " + root.sessionName + "  ›"
                    onActivated: root.cycleSession(1)
                    Keys.onLeftPressed: root.cycleSession(-1)
                    Keys.onRightPressed: root.cycleSession(1)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_H) root.cycleSession(-1);
                        else if (event.key === Qt.Key_L) root.cycleSession(1);
                    }
                }

                Row {
                    spacing: 12 * scene.s
                    width: parent.width

                    Btn {

                        s: scene.s

                        fam: root.fontFamily

                        accent: root.cPrimary

                        txt: root.cText
                        width: (parent.width - parent.spacing) / 2
                        label: "  Reboot"
                        onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                    }

                    Btn {

                        s: scene.s

                        fam: root.fontFamily

                        accent: root.cPrimary

                        txt: root.cText
                        width: (parent.width - parent.spacing) / 2
                        label: "  Power off"
                        onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }
        }
        }
    }

    // One word as separate letters: jittered height and tilt, a polygon behind, a hard shadow
    component PersonaWord: Row {
        id: word

        property string text
        property real size: 100
        property int seed: 1
        property string fam

        function rnd(n) {
            const x = Math.sin(n * 12.9898) * 43758.5453;
            return x - Math.floor(x);
        }

        spacing: size * 0.03

        Repeater {
            model: word.text.length

            Item {
                id: ch

                required property int index
                readonly property string c: word.text.charAt(index)
                readonly property bool blank: c === " "
                readonly property real r1: word.rnd(word.seed * 7 + index * 3 + 1)
                readonly property real r2: word.rnd(word.seed * 5 + index * 3 + 2)
                readonly property real r3: word.rnd(word.seed * 3 + index * 3 + 3)
                readonly property real r4: word.rnd(word.seed * 11 + index * 5 + 4)
                readonly property real r5: word.rnd(word.seed * 13 + index * 7 + 5)
                // Few letters sit on a black polygon in white
                readonly property bool inverted: r5 < 0.15
                readonly property bool red: !inverted && r3 < 0.3
                readonly property color letterColor: inverted ? "#ffffff" : (red ? "#e60012" : "#0a0a0a")
                readonly property color shadowColor: red ? "#0a0a0a" : "#e60012"
                readonly property real off: word.size * 0.045

                width: blank ? word.size * 0.35 : glyph.implicitWidth + word.size * 0.14
                height: word.size
                y: (r1 - 0.5) * word.size * 0.32
                rotation: (r2 - 0.5) * 12

                Shape {
                    visible: !ch.blank
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    // Shadow of the polygon
                    ShapePath {
                        strokeWidth: -1
                        fillColor: Qt.rgba(0, 0, 0, 0.7)
                        startX: ch.r3 * 0.15 * ch.width + ch.off * 1.5
                        startY: ch.height * 0.06 + ch.off * 1.5
                        PathLine { x: ch.width + ch.off * 1.5; y: ch.r4 * 0.12 * ch.height + ch.off * 1.5 }
                        PathLine { x: ch.width * (1 - ch.r2 * 0.15) + ch.off * 1.5; y: ch.height * 0.96 + ch.off * 1.5 }
                        PathLine { x: ch.off * 1.5; y: ch.height * (1 - ch.r4 * 0.1) + ch.off * 1.5 }
                    }

                    ShapePath {
                        strokeWidth: -1
                        fillColor: ch.inverted ? "#0a0a0a" : "#ffffff"
                        startX: ch.r3 * 0.15 * ch.width
                        startY: ch.height * 0.06
                        PathLine { x: ch.width; y: ch.r4 * 0.12 * ch.height }
                        PathLine { x: ch.width * (1 - ch.r2 * 0.15); y: ch.height * 0.96 }
                        PathLine { x: 0; y: ch.height * (1 - ch.r4 * 0.1) }
                    }
                }

                Text {
                    visible: !ch.blank
                    x: (ch.width - width) / 2 + ch.off
                    y: (ch.height - height) / 2 + ch.off
                    text: ch.c
                    color: ch.shadowColor
                    font.family: word.fam
                    font.pixelSize: word.size
                }

                Text {
                    id: glyph
                    visible: !ch.blank
                    anchors.centerIn: parent
                    text: ch.c
                    color: ch.letterColor
                    font.family: word.fam
                    font.pixelSize: word.size
                }
            }
        }
    }

    // Focusable button, Enter or click activates
    component Btn: Rectangle {
        id: btn

        property string label
        property real s: 1
        property string fam
        property color accent
        property color txt
        signal activated

        height: 44 * s
        radius: 10 * s
        color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 2 * s
        border.color: activeFocus ? accent : Qt.rgba(1, 1, 1, 0.15)
        activeFocusOnTab: true

        Keys.onReturnPressed: activated()
        Keys.onEnterPressed: activated()

        Text {
            anchors.centerIn: parent
            text: btn.label
            color: txt
            font.family: fam
            font.pixelSize: 18 * s
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                btn.forceActiveFocus();
                btn.activated();
            }
        }
    }
}
