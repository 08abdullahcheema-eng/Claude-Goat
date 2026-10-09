pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Claude Code usage: plan limits + tokens per day (from the sumi-agents helper).
Singleton {
    id: root
    property bool installed: false
    property bool ok: false
    property string plan: ""
    property real fivePct: -1
    property string fiveReset: ""
    property real weekPct: -1
    property string weekReset: ""
    property var days: []
    property real weekTotal: 0
    property int sessions: 0
    property int running: 0
    property bool loading: false

    readonly property bool panelOpen: Ui.panel === "agents"

    function refresh() {
        if (Theme.demo) return;
        if (!proc.running) { loading = true; proc.running = true; }
    }

    function fmtTokens(n) {
        if (n >= 1e6) return (n / 1e6).toFixed(n >= 1e7 ? 0 : 1) + " M";
        if (n >= 1e3) return Math.round(n / 1e3) + " k";
        return Math.round(n) + "";
    }
    function fmtReset(iso, withDay) {
        if (!iso) return "";
        const t = new Date(iso);
        if (isNaN(t.getTime())) return "";
        const mins = Math.max(0, Math.round((t.getTime() - Date.now()) / 60000));
        const h = Math.floor(mins / 60), m = mins % 60;
        if (withDay) return "resets " + t.toLocaleString(Qt.locale("de_DE"), "ddd dd. MMM · HH:mm");
        return "resets in " + (h > 0 ? h + " h " : "") + m + " m · at " + Qt.formatTime(t, "HH:mm");
    }

    Component.onCompleted: {
        if (Theme.demo) {
            installed = true; ok = true; plan = "Max";
            fivePct = 62; fiveReset = new Date(Date.now() + 108 * 60000).toISOString();
            weekPct = 38; weekReset = new Date(Date.now() + 3.5 * 86400000).toISOString();
            const lab = ["Fr", "Sa", "So", "Mo", "Di", "Mi", "Do"], v = [.42, .18, .08, .66, .91, .74, .55];
            days = lab.map((l, i) => ({ label: l, dateLabel: (3 + i) + ".10.", cache: v[i] * 1.9e6, input: v[i] * 1.0e6, output: v[i] * 0.5e6,
                                         models: { opus: v[i] * 1.2e6, sonnet: v[i] * 0.3e6 } }));
            weekTotal = 12.4e6; sessions = 23; running = 1;
            return;
        }
        refresh();
    }
    Timer { interval: root.panelOpen ? 30000 : 300000; running: !Theme.demo; repeat: true; onTriggered: root.refresh() }
    onPanelOpenChanged: if (panelOpen) refresh()

    Process {
        id: proc
        command: ["sumi-agents"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                let d;
                try { d = JSON.parse(this.text); } catch (e) { return; }
                root.installed = !!d.installed;
                root.ok = !!d.ok;
                root.plan = d.plan || "";
                root.fivePct = d.five ? d.five.pct : -1;
                root.fiveReset = d.five ? d.five.resets : "";
                root.weekPct = d.week ? d.week.pct : -1;
                root.weekReset = d.week ? d.week.resets : "";
                root.days = d.days || [];
                root.weekTotal = d.weekTotal || 0;
                root.sessions = d.sessions || 0;
                root.running = d.running || 0;
            }
        }
        onExited: root.loading = false
    }
}
