pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU load and keyboard layout for the bar.
Singleton {
    id: root
    property int cpu: Theme.demo ? 14 : 0
    property string layout: Theme.demo ? "DE" : ""
    property var lastIdle: -1
    property var lastTotal: -1

    Timer { interval: 3000; running: !Theme.demo; repeat: true; triggeredOnStart: true; onTriggered: statProc.running = true }
    Timer { interval: 4000; running: !Theme.demo; repeat: true; triggeredOnStart: true; onTriggered: kbProc.running = true }

    Process {
        id: statProc
        command: ["head", "-n", "1", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = this.text.trim().split(/\s+/).slice(1).map(Number);
                if (v.length < 5) return;
                const idle = v[3] + (v[4] || 0);
                const total = v.reduce((a, b) => a + b, 0);
                if (root.lastTotal >= 0 && total > root.lastTotal)
                    root.cpu = Math.round(100 * (1 - (idle - root.lastIdle) / (total - root.lastTotal)));
                root.lastIdle = idle; root.lastTotal = total;
            }
        }
    }
    Process {
        id: kbProc
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    const kb = (d.keyboards || []).find(k => k.main) || (d.keyboards || [])[0];
                    if (!kb) return;
                    const names = { "German": "DE", "English (US)": "US", "English (UK)": "UK", "French": "FR", "Italian": "IT" };
                    const km = kb.active_keymap || "";
                    root.layout = names[km] ?? (km.slice(0, 2).toUpperCase());
                } catch (e) { }
            }
        }
    }
}
