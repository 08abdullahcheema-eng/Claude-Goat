pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours, fonts and sizes for the whole shell.
// The active palette lives in ~/.config/sumi/theme.json and is reloaded live.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property bool demo: Quickshell.env("SUMI_DEMO") === "1"
    readonly property string themeFile: home + "/.config/sumi/theme.json"
    readonly property string themeDir: Quickshell.shellPath("themes")

    // global size multiplier, 1.0 = designed for 2560x1600 at scale 1.6
    property real s: {
        const v = parseFloat(Quickshell.env("SUMI_SCALE"));
        return isNaN(v) ? 1.0 : v;
    }

    property var p: ({})
    readonly property string name: p.name ?? "sumi"
    readonly property string label: p.label ?? "Sumi"
    readonly property bool dark: p.dark ?? true
    readonly property string kanji: p.kanji ?? "墨"
    readonly property string logo: Quickshell.shellPath("assets/" + (p.logo ?? "logo-sumi.svg"))

    readonly property color bg: p.bg ?? "#0f0f14"
    readonly property color bg1: p.bg1 ?? "#16161d"
    readonly property color bg2: p.bg2 ?? "#1d1d26"
    readonly property color line: p.line ?? "#2a2a37"
    readonly property color line2: p.line2 ?? "#363646"
    readonly property color mute: p.mute ?? "#54546d"
    readonly property color dim: p.dim ?? "#727169"
    readonly property color fg: p.fg ?? "#dcd7ba"
    readonly property color hi: p.hi ?? "#f2ecd2"
    readonly property color accent: p.accent ?? "#c8323a"
    readonly property color accent2: p.accent2 ?? "#e46876"
    readonly property color onAccent: p.onAccent ?? "#f2ecd2"
    readonly property color gold: p.gold ?? "#e6c384"
    readonly property color orange: p.orange ?? "#ffa066"
    readonly property color green: p.green ?? "#98bb6c"
    readonly property color cyan: p.cyan ?? "#7aa89f"
    readonly property color blue: p.blue ?? "#7e9cd8"
    readonly property color violet: p.violet ?? "#957fb8"

    readonly property color barBg: Qt.rgba(bg.r, bg.g, bg.b, 0.92)
    readonly property color panelBg: Qt.rgba(bg1.r, bg1.g, bg1.b, 0.97)
    readonly property color scrim: Qt.rgba(0, 0, 0, dark ? 0.78 : 0.55)

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string serif: "Noto Serif CJK JP"
    // per theme: display font for clocks and titles, font for bar text
    readonly property string head: p.fontHead ?? serif
    readonly property string body: p.fontBody ?? mono
    readonly property bool wsKanji: p.wsKanji ?? false

    // bar layout: the user's choice in ~/.config/sumi/layout, else the theme's own layout
    readonly property var layouts: ["islands", "bottom", "corners", "notch", "rail", "pill"]
    property string userLayout: ""
    property string previewLayout: ""          // set by the theme picker while browsing
    readonly property string envLayout: Quickshell.env("SUMI_LAYOUT") ?? ""
    readonly property string layout: {
        for (const c of [previewLayout, envLayout, userLayout, saved.layout ?? ""])
            if (c && layouts.indexOf(c) >= 0) return c;
        return "islands";
    }
    function edgeOf(l) { return (l === "bottom" || l === "pill") ? "bottom" : "top"; }
    function reserveOf(l) {
        switch (l) {
        case "islands": return barH + barM;
        case "bottom": return px(40);
        case "corners": return px(44);
        case "notch": return px(42);
        case "rail": return px(26);
        case "pill": return px(58);
        }
        return barH + barM;
    }
    readonly property string barEdge: edgeOf(layout)
    readonly property int barReserve: reserveOf(layout)

    function px(v) { return Math.round(v * s); }

    // font sizes
    readonly property int fxs: px(10)
    readonly property int fsm: px(11.5)
    readonly property int fmd: px(13)
    readonly property int flg: px(15)
    readonly property int fxl: px(18)

    readonly property int barH: px(36)
    readonly property int barM: px(7)       // gap around the floating bar
    readonly property int radius: px(8)
    readonly property int gap: px(9)

    // preview a palette without saving it (theme switcher)
    property var saved: ({})
    function preview(pal) { if (pal) root.p = pal; }
    function revert() { if (saved && saved.name) root.p = saved; }
    function wall(file) { return Quickshell.shellPath("assets/walls/" + file); }
    function wallpaper(name) { return Quickshell.shellPath("assets/walls/wall-" + (name || root.name) + ".jpg"); }

    function load() {
        let t = "";
        try { t = themeView.text(); } catch (e) { t = ""; }
        if (!t || t.length < 2) {
            try { t = defaultView.text(); } catch (e) { t = ""; }
        }
        try { root.p = JSON.parse(t); root.saved = root.p; } catch (e) { console.warn("sumi: bad theme json", e); }
    }

    FileView {
        id: themeView
        path: root.themeFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.load()
        onLoadFailed: root.load()
    }
    FileView {
        id: layoutView
        path: root.home + "/.config/sumi/layout"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { let t = ""; try { t = text(); } catch (e) {} root.userLayout = (t || "").trim(); }
        onLoadFailed: root.userLayout = ""
    }
    FileView {
        id: defaultView
        path: root.themeDir + "/sumi.json"
        onLoaded: root.load()
    }
}
