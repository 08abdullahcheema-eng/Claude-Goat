import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Effects

// Theme picker in the spirit of Omarchy: big pictures first. A carousel of desktop previews
// over a blurred backdrop of the selected theme, the name in the theme's own font, nothing else.
//   left / right or wheel  theme      up / down  wallpaper      tab  bar layout
//   enter or click         apply      esc        cancel
Item {
    id: root
    anchors.fill: parent
    focus: true

    property var themes: []
    property int sel: 0
    property var wv: ({})              // theme name -> wallpaper index
    property var lv: ({})              // theme name -> chosen bar layout
    readonly property var layoutNames: ({ islands: "Inseln", capsule: "Glas-Kapsel", rail: "Haarlinie", dune: "Düne", side: "Seitenleiste", notch: "Notch", pill: "Pille", bottom: "Leiste unten", corners: "Ecken" })
    function layoutOf(t) {
        if (!t) return "islands";
        const c = lv[t.name];
        if (c) return c;
        return Theme.layouts.indexOf(t.layout) >= 0 ? t.layout : "islands";
    }
    function cycleLayout(d) {
        const t = themes[sel];
        if (!t) return;
        const L = Theme.layouts;
        const i = (L.indexOf(layoutOf(t)) + d + L.length) % L.length;
        const m = Object.assign({}, lv); m[t.name] = L[i]; lv = m;
    }
    property bool applied: false
    readonly property int n: themes.length
    readonly property var cur: themes[sel] || Theme.p
    // the picker draws on a dark scrim whatever theme is being previewed, so its own text is fixed
    readonly property color tInk: "#f2ecd2"
    readonly property color tDim: "#b8b29a"
    readonly property color tMute: "#85816f"
    readonly property color tLine: "#454552"

    function wallsOf(t) { return (t && t.walls && t.walls.length) ? t.walls : ["wall-" + (t ? t.name : "sumi") + ".jpg"]; }
    function wallIndex(t) { return ((wv[t.name] ?? 0) % wallsOf(t).length + wallsOf(t).length) % wallsOf(t).length; }
    function wallFile(t) { return wallsOf(t)[wallIndex(t)]; }
    function focusFirst() { root.forceActiveFocus(); }

    function select(i) {
        if (n < 1) return;
        sel = ((i % n) + n) % n;
        previewTimer.restart();
    }
    // the whole shell recolours on preview; wait until browsing pauses so the carousel stays fluid
    Timer {
        id: previewTimer
        interval: 140
        onTriggered: {
            const t = root.themes[root.sel];
            if (!t) return;
            Theme.preview(t);
            if (!Theme.demo) Quickshell.execDetached(["hyprctl", "keyword", "general:col.active_border", "rgb(" + String(t.accent).replace("#", "") + ")"]);
        }
    }
    function browse(d) { select(sel + d); }
    function cycleWall(d) {
        const t = themes[sel];
        if (!t) return;
        const w = Object.assign({}, wv);
        w[t.name] = wallIndex(t) + d;
        wv = w;
    }
    function apply() {
        const t = themes[sel];
        if (!t) { Ui.close(); return; }
        applied = true;
        const l = layoutOf(t);
        if (!Theme.demo) Quickshell.execDetached(["sumi-theme", t.name, wallFile(t), l === t.layout ? "auto" : l]);
        Ui.close();
    }
    Component.onDestruction: {
        if (!applied) {
            Theme.revert();
            if (!Theme.demo) Quickshell.execDetached(["sumi-theme", "--restore"]);
        }
    }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_A) { browse(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_D) { browse(1); e.accepted = true; }
        else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) { cycleWall(1); e.accepted = true; }
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) { cycleWall(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Tab) { cycleLayout(1); e.accepted = true; }
        else if (e.key === Qt.Key_Backtab) { cycleLayout(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { apply(); e.accepted = true; }
        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in sumi kiri hagane suna iso; do [ -f \"$1/$f.json\" ] || continue; cat \"$1/$f.json\"; printf '\\036'; done; printf 'WALL:'; cat \"$HOME/.config/sumi/wall\" 2>/dev/null", "sh", Theme.themeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("WALL:");
                const list = [];
                for (const chunk of parts[0].split("\u001e")) {
                    if (!chunk.trim()) continue;
                    try { list.push(JSON.parse(chunk)); } catch (e) { }
                }
                root.themes = list;
                const i = list.findIndex(t => t.name === Theme.name);
                root.sel = i >= 0 ? i : 0;
                // start on the wallpaper that is applied right now
                const cw = (parts[1] || "").trim();
                if (cw !== "" && i >= 0) {
                    const k = root.wallsOf(list[i]).indexOf(cw);
                    if (k > 0) { const w = {}; w[list[i].name] = k; root.wv = w; }
                }
                // and on the layout that is active right now
                if (i >= 0 && Theme.userLayout && Theme.layouts.indexOf(Theme.userLayout) >= 0) {
                    const m = {}; m[list[i].name] = Theme.userLayout; root.lv = m;
                }
            }
        }
    }

    function pictureOf(t, wi) {
        // the desktop preview for the theme's first wallpaper, the wallpaper itself for the others
        if (wi === 0) return Quickshell.shellPath("assets/previews/preview-" + t.name + ".jpg");
        return Theme.wall(wallsOf(t)[wi]);
    }

    // ------------------------------------------------------------------ backdrop
    // blurred picture of the selected theme filling the screen, crossfading as you browse
    Item {
        id: backdrop
        anchors.fill: parent
        Repeater {
            model: root.themes
            delegate: Item {
                required property var modelData
                required property int index
                anchors.fill: parent
                opacity: index === root.sel ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                Image {
                    id: bimg
                    anchors.fill: parent
                    source: "file://" + root.pictureOf(modelData, 0)
                    sourceSize: Qt.size(480, 300)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent; source: bimg; blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.25; saturation: 0.1
                    // a very slow drift keeps the backdrop alive
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.04; to: 1.12; duration: 14000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.12; to: 1.04; duration: 14000; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.45) }
    }

    // ------------------------------------------------------------------ carousel
    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        scale: 1.04
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }

        readonly property real cw: Math.min(width * 0.6, Theme.px(1000))   // selected picture width
        readonly property real ch: cw * 0.625
        readonly property real midY: height * 0.44

        WheelHandler { onWheel: (e) => root.browse(e.angleDelta.y > 0 || e.angleDelta.x > 0 ? -1 : 1) }

        Repeater {
            model: root.themes
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property var t: modelData
                readonly property int d: { const v = (index - root.sel + root.n) % root.n; return v > root.n / 2 ? v - root.n : v; }
                readonly property bool on: d === 0
                readonly property real k: on ? 1 : (Math.abs(d) === 1 ? 0.66 : 0.46)     // size relative to the selected card
                readonly property int wi: root.wallIndex(t)
                readonly property bool near: Math.abs(d) <= 2

                // fixed size, moved and scaled on the GPU: no image re-layout while animating
                width: stage.cw
                height: stage.ch
                x: stage.width / 2 - width / 2 + (d === 0 ? 0 : Math.sign(d) * (stage.cw * 0.5 + stage.cw * 0.66 * 0.5 * 0.5 + (Math.abs(d) - 1) * stage.cw * 0.46 * 0.75))
                y: stage.midY - height / 2 + (1 - intro) * Theme.px(60)
                z: 10 - Math.abs(d)
                scale: k * (0.92 + 0.08 * intro)
                opacity: (on ? 1 : (Math.abs(d) === 1 ? 0.55 : (Math.abs(d) === 2 ? 0.18 : 0))) * intro
                visible: opacity > 0.01
                // neighbours turn slightly towards the middle, like a cover flow
                transform: Rotation {
                    origin.x: card.width / 2; origin.y: card.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: card.d === 0 ? 0 : (card.d > 0 ? -16 : 16)
                    Behavior on angle { NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
                }

                Behavior on x { enabled: card.near; NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
                Behavior on scale { enabled: card.near; NumberAnimation { duration: 520; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

                // entry: cards rise in one after another, the selected one first
                property real intro: 0
                SequentialAnimation on intro {
                    running: true
                    PauseAnimation { duration: 40 + Math.abs(card.d) * 70 }
                    NumberAnimation { to: 1; duration: 560; easing.type: Easing.OutQuint }
                }

                // soft shadow under the picture
                Rectangle {
                    id: shadowSrc
                    anchors.fill: pic
                    radius: pic.radius
                    color: "black"
                    visible: false
                }
                MultiEffect {
                    anchors.fill: pic
                    source: shadowSrc
                    shadowEnabled: true; shadowBlur: 1.0; shadowOpacity: card.on ? 0.7 : 0.35
                    shadowVerticalOffset: Theme.px(14); shadowColor: "black"
                    opacity: 0.9
                }
                Rectangle {
                    id: pic
                    anchors.fill: parent
                    radius: Theme.px(card.on ? 18 : 14)
                    color: card.t.bg
                    clip: true
                    // the pictures: desktop preview, then the theme's other wallpapers
                    Repeater {
                        model: root.wallsOf(card.t).length
                        delegate: Image {
                            required property int index
                            anchors.fill: parent
                            source: "file://" + root.pictureOf(card.t, index)
                            sourceSize: Qt.size(1280, 800)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            mipmap: true
                            opacity: index === card.wi && status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        }
                    }
                    // a hairline frame, in the theme's accent on the selected picture
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: card.on ? Theme.px(2) : 1
                        border.color: card.on ? card.t.accent : Qt.rgba(1, 1, 1, 0.12)
                        Behavior on border.color { ColorAnimation { duration: 250 } }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (card.on) root.apply(); else root.browse(card.d); }
                }
            }
        }

        // name of the selected theme, set in its own display font; it slides in on every change
        Connections { target: root; function onSelChanged() { nameAnim.restart(); } }
        ParallelAnimation {
            id: nameAnim
            NumberAnimation { target: nameCol; property: "opacity"; from: 0; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: nameCol; property: "shift"; from: Theme.px(14); to: 0; duration: 480; easing.type: Easing.OutQuint }
        }
        Column {
            id: nameCol
            property real shift: 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: stage.midY + stage.ch / 2 + Theme.px(30) + shift
            spacing: Theme.px(12)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(14)
                Text {
                    text: root.cur.label || ""
                    color: "#ffffff"
                    font.family: root.cur.fontHead || Theme.serif
                    font.pixelSize: Theme.px(34)
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.cur.kanji || ""
                    color: root.cur.accent || root.tInk
                    font.family: Theme.serif
                    font.pixelSize: Theme.px(26)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(16)
                // wallpaper dots
                Row {
                    visible: root.wallsOf(root.cur).length > 1
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.px(7)
                    Repeater {
                        model: root.wallsOf(root.cur).length
                        delegate: Rectangle {
                            required property int index
                            width: index === root.wallIndex(root.cur) ? Theme.px(20) : Theme.px(7); height: Theme.px(7); radius: height / 2
                            color: index === root.wallIndex(root.cur) ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)
                            Behavior on width { NumberAnimation { duration: 180 } }
                        }
                    }
                }
                // bar layout, click or tab to change
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: lchip.implicitWidth + Theme.px(22); height: Theme.px(26); radius: height / 2
                    color: lma.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
                    Text {
                        id: lchip; anchors.centerIn: parent
                        text: "Bar · " + (root.layoutNames[root.layoutOf(root.cur)] || "")
                        color: root.layoutOf(root.cur) === root.cur.layout ? Qt.rgba(1, 1, 1, 0.7) : (root.cur.accent || "#ffffff")
                        font.family: Theme.mono; font.pixelSize: Theme.px(11)
                    }
                    MouseArea { id: lma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleLayout(1) }
                }
            }
        }

        // quiet key hints
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(36) }
            text: "←→ Theme    ↑↓ Wallpaper    ⇥ Bar    ↵ Übernehmen    esc Abbrechen"
            color: Qt.rgba(1, 1, 1, 0.35)
            font.family: Theme.mono; font.pixelSize: Theme.px(11); font.letterSpacing: Theme.px(1)
        }
    }
}
