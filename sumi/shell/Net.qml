pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Network state from NetworkManager (nmcli) plus live stats for the panel.
Singleton {
    id: root

    readonly property bool demo: Theme.demo
    readonly property bool panelOpen: Ui.panel === "network"

    property string kind: "none"        // "wifi" | "ethernet" | "none"
    property bool wifiEnabled: true
    property string ssid: ""
    property string device: ""
    property int signal: 0
    property string freq: ""
    property string chan: ""
    property string security: ""
    property string ip: ""
    property string dns: ""
    property var nearby: []              // [{ssid, signal, secure, freq, known}]
    property var known: []

    // live stats
    property var rxHist: []
    property var txHist: []
    property real rxRate: 0              // bytes/s
    property real txRate: 0
    property real pingMs: -1
    property var pingHist: []            // true = ok, false = lost
    readonly property real loss: pingHist.length ? pingHist.filter(x => !x).length / pingHist.length * 100 : 0

    // speed test
    property bool testing: false
    property string testPhase: ""
    property real lastDown: -1
    property real lastUp: -1
    property string lastTestTime: ""

    // connect flow
    property string connecting: ""
    property string needPassword: ""
    property string connectError: ""

    // qr
    property string qrPath: ""
    property bool qrBusy: false

    function mbit(bytesPerSec) { return bytesPerSec * 8 / 1e6; }

    function refresh() {
        if (demo) return;
        statusProc.running = true;
    }
    function rescan() {
        if (demo) return;
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        listTimer.restart();
    }
    function setWifi(on) {
        if (demo) { wifiEnabled = on; return; }
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        wifiEnabled = on;
        refreshTimer.restart();
    }
    function connectTo(name, password) {
        if (demo) return;
        connecting = name; connectError = "";
        const cmd = ["nmcli", "--wait", "20", "device", "wifi", "connect", name];
        if (password && password.length) cmd.push("password", password);
        connectProc.target = name;
        connectProc.hadPassword = !!(password && password.length);
        connectProc.command = cmd;
        connectProc.running = true;
    }
    function disconnect() {
        if (demo || !device) return;
        Quickshell.execDetached(["nmcli", "device", "disconnect", device]);
        refreshTimer.restart();
    }
    function speedTest() {
        if (testing) return;
        if (demo) { lastDown = 412; lastUp = 38; lastTestTime = Qt.formatTime(new Date(), "hh:mm"); return; }
        testing = true; testPhase = "down";
        downProc.running = true;
    }
    function makeQr() {
        if (demo || kind !== "wifi" || !ssid) return;
        qrBusy = true; qrPath = "";
        pskProc.command = ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", "id", ssid];
        pskProc.running = true;
    }

    Component.onCompleted: {
        if (demo) {
            kind = "wifi"; ssid = "FRITZ!Box 7590"; signal = 86; freq = "5 GHz"; chan = "44";
            security = "WPA2"; ip = "192.168.178.34"; dns = "1.1.1.1"; device = "wlp0s20f3";
            nearby = [
                { ssid: "Vodafone-6F21", signal: 64, secure: true, freq: "2.4 GHz", known: false },
                { ssid: "o2-WLAN88", signal: 48, secure: true, freq: "5 GHz", known: false },
                { ssid: "FreeWifi_Bahnhof", signal: 41, secure: false, freq: "2.4 GHz", known: false },
                { ssid: "DIRECT-PrintHP", signal: 22, secure: true, freq: "2.4 GHz", known: false }
            ];
            let rx = [], tx = [];
            for (let i = 0; i < 60; i++) {
                rx.push(1e6 * (4 + 5 * Math.abs(Math.sin(i / 6)) + 3 * Math.random()));
                tx.push(1e6 * (0.3 + 0.6 * Math.random()));
            }
            rxHist = rx; txHist = tx; rxRate = 10.5e6; txRate = 0.76e6;
            pingMs = 14; pingHist = Array(20).fill(true);
            lastDown = 412; lastUp = 38; lastTestTime = "07:40";
            return;
        }
        refresh();
    }

    Timer { id: refreshTimer; interval: 1500; onTriggered: root.refresh() }
    Timer { interval: 5000; running: !root.demo; repeat: true; onTriggered: root.refresh() }
    Timer { id: listTimer; interval: 2500; onTriggered: listProc.running = true }

    onPanelOpenChanged: {
        if (panelOpen && !demo) { rescan(); listProc.running = true; dnsProc.running = true; }
        if (!panelOpen) { qrPath = ""; needPassword = ""; connectError = ""; }
    }

    // ---- status: which device is connected
    Process {
        id: statusProc
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device; echo ---; nmcli -t -f WIFI radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---");
                let k = "none", name = "", dev = "";
                for (const line of parts[0].trim().split("\n")) {
                    const f = line.split(":");
                    if (f.length < 4) continue;
                    if (f[1] !== "connected") continue;
                    if (f[0] === "wifi" && k !== "ethernet") { k = "wifi"; name = f[2]; dev = f[3]; }
                    if (f[0] === "ethernet") { k = "ethernet"; name = f[2]; dev = f[3]; }
                }
                root.kind = k; root.ssid = name; root.device = dev;
                root.wifiEnabled = (parts[1] || "").trim() !== "disabled";
                listProc.running = true;
            }
        }
    }

    // ---- wifi list (active network details + nearby)
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,FREQ,CHAN,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const raw of this.text.trim().split("\n")) {
                    // nmcli -t escapes ':' inside fields as '\:'
                    const f = raw.replace(/\\:/g, "\u0001").split(":").map(s => s.replace(/\u0001/g, ":"));
                    if (f.length < 6 || !f[1]) continue;
                    const e = { ssid: f[1], signal: parseInt(f[2]) || 0, freq: f[3], chan: f[4],
                                secure: f[5] !== "" && f[5] !== "--", inUse: f[0] === "*" };
                    const mhz = parseInt(e.freq); e.freq = mhz >= 5900 ? "6 GHz" : (mhz >= 4900 ? "5 GHz" : "2.4 GHz");
                    if (e.inUse) {
                        root.signal = e.signal; root.freq = e.freq; root.chan = e.chan;
                        root.security = f[5];
                        continue;
                    }
                    if (seen[e.ssid] || e.ssid === root.ssid) continue;
                    seen[e.ssid] = true;
                    e.known = root.known.indexOf(e.ssid) >= 0;
                    out.push(e);
                }
                out.sort((a, b) => b.signal - a.signal);
                root.nearby = out.slice(0, 8);
            }
        }
    }

    Process {
        id: knownProc
        running: !root.demo
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.known = this.text.trim().split("\n").filter(l => l.indexOf("wireless") >= 0)
                    .map(l => l.replace(/\\:/g, "\u0001").split(":")[0].replace(/\u0001/g, ":"));
            }
        }
    }

    Process {
        id: dnsProc
        command: ["sh", "-c", "d=$(nmcli -t -f DEVICE,STATE device | awk -F: '$2==\"connected\"{print $1; exit}'); [ -n \"$d\" ] && nmcli -t -f IP4.ADDRESS,IP4.DNS device show \"$d\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let ipv = "", dnsv = "";
                for (const l of this.text.trim().split("\n")) {
                    const i = l.indexOf(":");
                    const k = l.slice(0, i), v = l.slice(i + 1);
                    if (k.startsWith("IP4.ADDRESS") && !ipv) ipv = v.split("/")[0];
                    if (k.startsWith("IP4.DNS") && !dnsv) dnsv = v;
                }
                root.ip = ipv; root.dns = dnsv || "auto";
            }
        }
    }

    // ---- throughput, 1 s while the panel is open
    property var lastRx: -1
    property var lastTx: -1
    property real lastT: 0
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.panelOpen && !root.demo
        onTriggered: { devProc.running = true; pingProc.running = true; }
    }
    Process {
        id: devProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0;
                for (const l of this.text.split("\n").slice(2)) {
                    const m = l.trim().split(/[:\s]+/);
                    if (m.length < 10 || m[0] === "lo") continue;
                    rx += parseFloat(m[1]); tx += parseFloat(m[9]);
                }
                const now = Date.now() / 1000;
                if (root.lastRx >= 0) {
                    const dt = Math.max(0.2, now - root.lastT);
                    root.rxRate = Math.max(0, (rx - root.lastRx) / dt);
                    root.txRate = Math.max(0, (tx - root.lastTx) / dt);
                    root.rxHist = root.rxHist.concat([root.rxRate]).slice(-60);
                    root.txHist = root.txHist.concat([root.txRate]).slice(-60);
                }
                root.lastRx = rx; root.lastTx = tx; root.lastT = now;
            }
        }
    }
    Process {
        id: pingProc
        command: ["ping", "-n", "-c", "1", "-W", "1", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/time=([\d.]+)/);
                const ok = !!m;
                if (ok) root.pingMs = parseFloat(m[1]);
                root.pingHist = root.pingHist.concat([ok]).slice(-20);
            }
        }
    }

    // ---- connect
    Process {
        id: connectProc
        property string target: ""
        property bool hadPassword: false
        stderr: StdioCollector { id: connErr }
        stdout: StdioCollector { id: connOut }
        onExited: (code, status) => {
            root.connecting = "";
            if (code === 0) { root.needPassword = ""; root.connectError = ""; knownProc.running = true; }
            else {
                const msg = (connErr.text + connOut.text).toLowerCase();
                if (!hadPassword && (msg.indexOf("secret") >= 0 || msg.indexOf("password") >= 0 || msg.indexOf("802-11-wireless-security") >= 0))
                    root.needPassword = target;
                else root.connectError = (connErr.text || connOut.text).trim().split("\n").pop();
            }
            refreshTimer.restart();
        }
    }

    // ---- speed test via Cloudflare
    Process {
        id: downProc
        command: ["curl", "-s", "-o", "/dev/null", "-w", "%{speed_download}", "--max-time", "12",
                  "https://speed.cloudflare.com/__down?bytes=60000000"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(this.text);
                root.lastDown = isNaN(v) ? -1 : root.mbit(v);
                root.testPhase = "up";
                upProc.running = true;
            }
        }
    }
    Process {
        id: upProc
        command: ["sh", "-c", "head -c 15000000 /dev/zero | curl -s -o /dev/null -w '%{speed_upload}' --max-time 12 --data-binary @- https://speed.cloudflare.com/__up"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(this.text);
                root.lastUp = isNaN(v) ? -1 : root.mbit(v);
                root.testing = false; root.testPhase = "";
                root.lastTestTime = Qt.formatTime(new Date(), "hh:mm");
            }
        }
    }

    // ---- QR code for sharing the current wifi
    function qrEscape(s) { return s.replace(/([\;,:"])/g, "\\$1"); }
    Process {
        id: pskProc
        stdout: StdioCollector {
            onStreamFinished: {
                const psk = this.text.trim();
                const payload = psk.length
                    ? "WIFI:T:WPA;S:" + root.qrEscape(root.ssid) + ";P:" + root.qrEscape(psk) + ";;"
                    : "WIFI:T:nopass;S:" + root.qrEscape(root.ssid) + ";;";
                const out = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/sumi-wifi-qr-" + Date.now() + ".png";
                qrProc.outPath = out;
                qrProc.command = ["qrencode", "-t", "PNG", "-s", "8", "-m", "2", "-o", out, payload];
                qrProc.running = true;
            }
        }
    }
    Process {
        id: qrProc
        property string outPath: ""
        onExited: (code) => { root.qrBusy = false; if (code === 0) root.qrPath = "file://" + outPath; }
    }
}
