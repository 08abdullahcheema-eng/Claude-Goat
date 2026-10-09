pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PredatorSense: thermal profile, fans, 4-zone keyboard, battery and extras via the linuwu_sense driver.
Singleton {
    id: root

    readonly property string base: "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi"
    readonly property bool panelOpen: Ui.panel === "predator"

    property bool available: false
    property string model: ""
    property string senseDir: ""          // .../predator_sense or .../nitro_sense
    property bool writable: false

    // thermal
    property string profile: ""
    property var profiles: []
    // sensors
    property int cpuTemp: -1
    property int gpuTemp: -1
    property int cpuRpm: -1
    property int gpuRpm: -1
    // fans: 0 = auto
    property int fanCpu: 0
    property int fanGpu: 0
    // keyboard
    property bool hasKb: false
    property int kbMode: 0
    property int kbSpeed: 4
    property int kbBright: 70
    property int kbDir: 1
    property var zones: ["c8323a", "c8323a", "c8323a", "c8323a"]
    // battery + extras
    property int limiter: -1
    property int usbCharge: -1
    property int lcdOverdrive: -1
    property int bootSound: -1
    property int kbTimeout: -1
    // follow theme
    property bool followTheme: false

    readonly property var modeNames: ["Static", "Breathing", "Neon", "Wave", "Shifting", "Zoom", "Meteor", "Twinkling"]
    readonly property var profileInfo: ({
        "low-power": { label: "Eco", kanji: "省" },
        "quiet": { label: "Quiet", kanji: "静" },
        "balanced": { label: "Balanced", kanji: "均" },
        "balanced-performance": { label: "Performance", kanji: "速" },
        "performance": { label: "Turbo", kanji: "烈" }
    })
    function profileLabel(p) { return (profileInfo[p] || { label: p }).label; }
    function profileKanji(p) { return (profileInfo[p] || { kanji: "熱" }).kanji; }

    function refresh() {
        if (Theme.demo) return;
        if (!readProc.running) readProc.running = true;
    }

    function write(file, value) {
        if (Theme.demo) return;
        writeProc.queue.push([file, String(value)]);
        writeProc.next();
    }

    function setProfile(p) { profile = p; write("/sys/firmware/acpi/platform_profile", p); }
    function setFans(c, g) {
        fanCpu = c; fanGpu = g;
        write(senseDir + "/fan_speed", c + "," + g);
    }
    function setToggle(name, v) {
        const map = { limiter: "battery_limiter", lcdOverdrive: "lcd_override", bootSound: "boot_animation_sound", kbTimeout: "backlight_timeout" };
        root[name] = v ? 1 : 0;
        write(senseDir + "/" + map[name], v ? 1 : 0);
    }
    function setUsbCharge(v) { usbCharge = v; write(senseDir + "/usb_charging", v); }

    // keyboard: apply after a short pause so sliders don't flood the firmware
    function applyKb() { kbTimer.restart(); }
    Timer {
        id: kbTimer; interval: 220
        onTriggered: {
            const kb = root.base + "/four_zoned_kb";
            if (root.kbMode === 0) {
                root.write(kb + "/four_zone_mode", [0, 1, root.kbBright, 1].concat(root.rgb(root.zones[0])).join(","));
                root.write(kb + "/per_zone_mode", root.zones.concat([root.kbBright]).join(","));
            } else {
                root.write(kb + "/four_zone_mode", [root.kbMode, root.kbSpeed, root.kbBright, root.kbDir].concat(root.rgb(root.zones[0])).join(","));
            }
        }
    }
    function rgb(hex) {
        const h = String(hex).replace("#", "");
        return [parseInt(h.slice(0, 2), 16) || 0, parseInt(h.slice(2, 4), 16) || 0, parseInt(h.slice(4, 6), 16) || 0];
    }
    function setZone(i, hex) {
        const z = zones.slice();
        if (i < 0) for (let k = 0; k < 4; k++) z[k] = hex; else z[i] = hex;
        zones = z;
        applyKb();
    }
    function setFollowTheme(v) {
        followTheme = v;
        if (!Theme.demo) Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.config/sumi && printf '{\"followTheme\": %s}\\n' \"$1\" > ~/.config/sumi/predator.json", "sh", v ? "true" : "false"]);
        if (v) setZone(-1, String(Theme.accent).replace("#", "").slice(-6));
    }

    Component.onCompleted: {
        if (Theme.demo) {
            available = true; writable = true; model = "Predator PHN16-72"; senseDir = "demo";
            profile = "balanced-performance"; profiles = ["low-power", "quiet", "balanced", "balanced-performance", "performance"];
            cpuTemp = 61; gpuTemp = 54; cpuRpm = 3150; gpuRpm = 2890; fanCpu = 0; fanGpu = 0;
            hasKb = true; kbMode = 0; kbBright = 70; zones = ["c8323a", "e46876", "e6c384", "c8323a"];
            limiter = 1; usbCharge = 0; lcdOverdrive = 1; bootSound = 0; kbTimeout = 0; followTheme = true;
            return;
        }
        refresh();
    }
    Timer { interval: root.panelOpen ? 2000 : 15000; running: !Theme.demo; repeat: true; onTriggered: root.refresh() }
    onPanelOpenChanged: if (panelOpen) refresh()

    Process {
        id: readProc
        command: ["sh", "-c", `
            b="${root.base}"
            [ -d "$b" ] || { echo "available=0"; exit 0; }
            echo "available=1"
            echo "model=$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
            d=$(ls -d "$b"/predator_sense "$b"/nitro_sense 2>/dev/null | head -n1)
            echo "sense=$d"
            [ -w "$d/fan_speed" ] && echo "writable=1" || echo "writable=0"
            echo "profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"
            echo "profiles=$(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null)"
            for f in fan_speed battery_limiter usb_charging lcd_override boot_animation_sound backlight_timeout; do
              [ -r "$d/$f" ] && echo "$f=$(cat "$d/$f" 2>/dev/null)"
            done
            if [ -d "$b/four_zoned_kb" ]; then
              echo "kb=1"
              echo "four=$(cat "$b/four_zoned_kb/four_zone_mode" 2>/dev/null)"
              echo "per=$(cat "$b/four_zoned_kb/per_zone_mode" 2>/dev/null)"
            fi
            for h in /sys/class/hwmon/hwmon*; do
              [ "$(cat "$h/name" 2>/dev/null)" = "acer" ] || continue
              for x in temp1 temp2 fan1 fan2; do [ -r "$h/$x"_input ] && echo "$x=$(cat "$h/$x"_input 2>/dev/null)"; done
            done
            cat ~/.config/sumi/predator.json 2>/dev/null | grep -q '"followTheme": true' && echo "follow=1" || echo "follow=0"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {};
                for (const l of this.text.split("\n")) {
                    const i = l.indexOf("=");
                    if (i > 0) v[l.slice(0, i)] = l.slice(i + 1).trim();
                }
                root.available = v.available === "1";
                if (!root.available) return;
                root.model = v.model || "";
                root.senseDir = v.sense || "";
                root.writable = v.writable === "1";
                root.profile = v.profile || "";
                root.profiles = (v.profiles || "").split(/\s+/).filter(x => x);
                if (v.fan_speed) { const f = v.fan_speed.split(","); root.fanCpu = parseInt(f[0]) || 0; root.fanGpu = parseInt(f[1]) || 0; }
                const num = (k) => v[k] === undefined || v[k] === "" ? -1 : parseInt(v[k]);
                root.limiter = num("battery_limiter");
                root.usbCharge = num("usb_charging");
                root.lcdOverdrive = num("lcd_override");
                root.bootSound = num("boot_animation_sound");
                root.kbTimeout = num("backlight_timeout");
                root.hasKb = v.kb === "1";
                if (root.hasKb && !kbTimer.running) {
                    const f4 = (v.four || "").split(",").map(x => parseInt(x));
                    if (f4.length >= 4 && !isNaN(f4[0])) { root.kbMode = f4[0]; root.kbSpeed = f4[1] || 4; root.kbBright = f4[2]; root.kbDir = f4[3] || 1; }
                    const p = (v.per || "").split(",");
                    if (p.length >= 5) { root.zones = p.slice(0, 4).map(x => x.trim().padStart(6, "0")); if (root.kbMode === 0) root.kbBright = parseInt(p[4]); }
                }
                root.cpuTemp = v.temp1 ? Math.round(parseInt(v.temp1) / 1000) : -1;
                root.gpuTemp = v.temp2 ? Math.round(parseInt(v.temp2) / 1000) : -1;
                root.cpuRpm = v.fan1 ? parseInt(v.fan1) : -1;
                root.gpuRpm = v.fan2 ? parseInt(v.fan2) : -1;
                root.followTheme = v.follow === "1";
            }
        }
    }

    // writes go one after another
    Process {
        id: writeProc
        property var queue: []
        function next() {
            if (running || queue.length === 0) return;
            const w = queue.shift();
            command = ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "sh", w[1], w[0]];
            running = true;
        }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) console.warn("predator write:", this.text.trim()) }
        onExited: { next(); refreshSoon.restart(); }
    }
    Timer { id: refreshSoon; interval: 600; onTriggered: root.refresh() }
}
