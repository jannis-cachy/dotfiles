pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Idle inhibitor: a systemd idle inhibitor that hypridle respects (ignore_systemd_inhibit is off by
// default). It lives only while this process runs, so it ends with quickshell.
Singleton {
    id: root

    property bool active: false

    function toggle() {
        active = !active;
    }

    Process {
        running: root.active
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Idle inhibitor", "--mode=block", "sleep", "infinity"]
    }
}
