pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state: which overlay is open, do-not-disturb, OSD.
Singleton {
    id: root

    // "", "launcher", "network", "agents", "power", "themes", "calendar", "system", "battery"
    property string panel: ""
    property string launcherMode: "all"
    property bool dnd: false
    property real anchorX: -1   // screen x of the bar icon that opened the panel, so it drops down under it

    // OSD
    property string osdKind: ""      // "volume" | "brightness"
    property real osdValue: 0
    property bool osdMuted: false
    property int osdSerial: 0

    readonly property var fullscreenPanels: ["launcher", "power", "themes"]
    readonly property bool panelIsFull: fullscreenPanels.indexOf(panel) >= 0

    function toggle(name) { panel = (panel === name) ? "" : name; }
    // open a dropdown panel under the icon at screen x (press the same icon again to close)
    function toggleAt(name, x) {
        if (panel !== name) anchorX = x;
        toggle(name);
    }
    // x for a dropdown card of width w in a screen of width sw, centred under anchorX
    function dropX(w, sw, fallback) {
        const m = Theme.px(10);
        if (anchorX < 0) return Math.max(m, Math.min(sw - w - m, fallback));
        return Math.max(m, Math.min(sw - w - m, anchorX - w / 2));
    }
    function open(name) { anchorX = -1; panel = name; }
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
        function toggle(name: string): void { if (root.panel !== name) root.anchorX = -1; root.toggle(name); }
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
