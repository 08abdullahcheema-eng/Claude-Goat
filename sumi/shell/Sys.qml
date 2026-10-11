pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU load and keyboard layout for the bar, plus details for the system panel.
Singleton {
    id: root
    property int cpu: Theme.demo ? 14 : 0
    property string layout: Theme.demo ? "DE" : ""
    property var prevIdles: []
    property var prevTotals: []

    // usage per hardware thread, and the last 60 total samples (3 s each)
    property var cores: Theme.demo
        ? Array.from({ length: 32 }, (_, i) => Math.round(8 + 38 * Math.abs(Math.sin(i * 1.3)) + (i < 6 ? 34 : 0)))
        : []
    property var hist: Theme.demo
        ? Array.from({ length: 60 }, (_, i) => Math.round(12 + 10 * Math.sin(i / 4) + 8 * Math.sin(i / 1.7) + (i > 44 ? 22 : 0)))
        : []

    // filled only while the system panel is open
    property bool detail: false
    property string model: Theme.demo ? "Intel Core i9-14900HX" : ""
    property real freqAvg: Theme.demo ? 3.4 : 0     // GHz
    property real freqMax: Theme.demo ? 5.1 : 0
    property real memTotal: Theme.demo ? 32 * 1048576 : 0     // kB
    property real memAvail: Theme.demo ? 21.4 * 1048576 : 0   // kB
    property real swapTotal: 0
    property real swapFree: 0
    property string load: Theme.demo ? "0.62 0.48 0.40" : ""
    property int temp: Theme.demo ? 47 : -1
    property int upSec: Theme.demo ? 11520 : 0
    property var procs: Theme.demo
        ? [{ name: "firefox", mb: 1480 }, { name: "quickshell", mb: 412 }, { name: "Hyprland", mb: 188 }, { name: "kitty", mb: 96 }, { name: "pipewire", mb: 41 }]
        : []

    Timer { interval: 3000; running: !Theme.demo; repeat: true; triggeredOnStart: true; onTriggered: statProc.running = true }
    Timer { interval: 4000; running: !Theme.demo; repeat: true; triggeredOnStart: true; onTriggered: kbProc.running = true }
    Timer { interval: 2000; running: root.detail && !Theme.demo; repeat: true; triggeredOnStart: true; onTriggered: detProc.running = true }

    Process {
        id: statProc
        command: ["grep", "^cpu", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const idles = [], totals = [];
                for (const l of this.text.trim().split("\n")) {
                    const v = l.trim().split(/\s+/).slice(1).map(Number);
                    if (v.length < 5) continue;
                    idles.push(v[3] + (v[4] || 0));
                    totals.push(v.reduce((a, b) => a + b, 0));
                }
                if (idles.length < 1) return;
                if (root.prevTotals.length === totals.length) {
                    const u = totals.map((t, i) => t > root.prevTotals[i]
                        ? Math.max(0, Math.min(100, Math.round(100 * (1 - (idles[i] - root.prevIdles[i]) / (t - root.prevTotals[i])))))
                        : 0);
                    root.cpu = u[0];
                    root.cores = u.slice(1);
                    root.hist = root.hist.concat([u[0]]).slice(-60);
                }
                root.prevIdles = idles;
                root.prevTotals = totals;
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
    Process {
        id: detProc
        command: ["sh", "-c",
            "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; "
            + "echo \"LOAD $(cut -d' ' -f1-3 /proc/loadavg)\"; "
            + "echo \"TEMP $(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)\"; "
            + "echo \"UP $(cut -d. -f1 /proc/uptime)\"; "
            + "echo \"MODEL $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2)\"; "
            + "echo \"FREQ $(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{s+=$1; n++; if ($1>m) m=$1} END{if (n) print int(s/n), m}')\"; "
            + "ps -eo comm=,rss= --sort=-rss 2>/dev/null | head -6 | sed 's/^/PROC /'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const procs = [];
                for (const l of this.text.split("\n")) {
                    if (l.startsWith("MemTotal:")) root.memTotal = parseInt(l.split(/\s+/)[1]);
                    else if (l.startsWith("MemAvailable:")) root.memAvail = parseInt(l.split(/\s+/)[1]);
                    else if (l.startsWith("SwapTotal:")) root.swapTotal = parseInt(l.split(/\s+/)[1]);
                    else if (l.startsWith("SwapFree:")) root.swapFree = parseInt(l.split(/\s+/)[1]);
                    else if (l.startsWith("LOAD ")) root.load = l.slice(5).trim();
                    else if (l.startsWith("TEMP ")) { const t = parseInt(l.slice(5)); root.temp = isNaN(t) ? -1 : Math.round(t / 1000); }
                    else if (l.startsWith("UP ")) root.upSec = parseInt(l.slice(3)) || 0;
                    else if (l.startsWith("MODEL ")) root.model = l.slice(6).replace(/\((R|TM)\)/g, "").replace(/\s+/g, " ").replace(/^\s*\d+(st|nd|rd|th) Gen /, "").trim();
                    else if (l.startsWith("FREQ ")) {
                        const f = l.slice(5).trim().split(/\s+/).map(Number);
                        if (f.length === 2 && !isNaN(f[0])) { root.freqAvg = f[0] / 1e6; root.freqMax = f[1] / 1e6; }
                    }
                    else if (l.startsWith("PROC ")) {
                        const w = l.slice(5).trim().split(/\s+/);
                        const kb = parseInt(w.pop());
                        const name = w.join(" ");
                        if (name && !isNaN(kb)) procs.push({ name: name, mb: kb / 1024 });
                    }
                }
                root.procs = procs.slice(0, 5);
            }
        }
    }
}
