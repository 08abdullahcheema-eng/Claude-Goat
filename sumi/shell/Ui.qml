pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state: which overlay is open, do-not-disturb, OSD.
Singleton {
    id: root

    // "", "launcher", "network", "agents", "power", "themes"
    property string panel: ""
    property string launcherMode: "all"
    property bool dnd: false

    // OSD
    property string osdKind: ""      // "volume" | "brightness"
    property real osdValue: 0
    property bool osdMuted: false
    property int osdSerial: 0

    readonly property var fullscreenPanels: ["launcher", "power", "themes"]
    readonly property bool panelIsFull: fullscreenPanels.indexOf(panel) >= 0

    function toggle(name) { panel = (panel === name) ? "" : name; }
    function open(name) { panel = name; }
    function close() { panel = ""; }

    function showOsd(kind, value, muted) {
        osdKind = kind;
        osdValue = Math.max(0, Math.min(1, value));
        osdMuted = !!muted;
        osdSerial++;
    }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

    IpcHandler {
        target: "shell"
        function toggle(name: string): void { root.toggle(name); }
        function open(name: string): void { root.open(name); }
        function close(): void { root.close(); }
        function launcher(mode: string): void { root.launcherMode = mode || "all"; root.toggle("launcher"); }
        function dnd(): void { root.dnd = !root.dnd; }
    }

    IpcHandler {
        target: "osd"
        // called after brightnessctl in the keybind
        function brightness(): void { brightProc.running = true; }
    }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v)) root.showOsd("brightness", v / 100, false);
            }
        }
    }
}
