import Quickshell
import Quickshell.Io

// Power off and reboot through systemctl (hyprshutdown left a gray screen and never finished)
Scope {
    id: root

    IpcHandler {
        target: "shutdown"

        function poweroff(): void {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }

        function reboot(): void {
            Quickshell.execDetached(["systemctl", "reboot"]);
        }
    }
}
