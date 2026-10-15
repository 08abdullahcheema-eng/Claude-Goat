import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Effects

// Theme picker: the whole screen is the preview. The selected theme's wallpaper fills it and
// its real bar is drawn on top (a live copy, see shell.qml), so you see the desktop as it will be.
// A glass dock at the bottom holds one kanji tile per theme, the selected tile lifts and fills
// with the theme's accent. Name and a short description sit above the dock.
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
    readonly property var layoutNames: ({ islands: "Glasleiste", capsule: "Glas-Kapsel", rail: "Haarlinie", side: "Seitenleiste", ridge: "Grat", notch: "Notch", pill: "Pille", bottom: "Leiste unten", corners: "Ecken" })
    readonly property var blurbs: ({ yoru: "Neon-Tokio im Regen", koyo: "Ahorn im Herbst", hotaru: "Glühwürmchen im Wald", shinkai: "Leuchten der Tiefsee", tsuki: "Mondlicht über dem Meer" })
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
        Theme.pickLayout = L[i];
    }
    property bool applied: false
    readonly property int n: themes.length
    readonly property var cur: themes[sel] || Theme.p

    function wallsOf(t) { return (t && t.walls && t.walls.length) ? t.walls : ["wall-" + (t ? t.name : "yoru") + ".jpg"]; }
    function wallIndex(t) { return ((wv[t.name] ?? 0) % wallsOf(t).length + wallsOf(t).length) % wallsOf(t).length; }
    function wallFile(t) { return wallsOf(t)[wallIndex(t)]; }
    function focusFirst() { root.forceActiveFocus(); }

    function select(i) {
        if (n < 1) return;
        sel = ((i % n) + n) % n;
        previewTimer.restart();
    }
    // the whole shell recolours on preview; wait a moment so fast browsing stays fluid
    Timer {
        id: previewTimer
        interval: 90
        onTriggered: {
            const t = root.themes[root.sel];
            if (!t) return;
            Theme.preview(t);
            Theme.pickLayout = root.layoutOf(t);
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
        Theme.pickLayout = "";
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
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) { select(e.key - Qt.Key_1); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { apply(); e.accepted = true; }
        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in yoru koyo hotaru shinkai tsuki; do [ -f \"$1/$f.json\" ] || continue; cat \"$1/$f.json\"; printf '\\036'; done; printf 'WALL:'; cat \"$HOME/.config/sumi/wall\" 2>/dev/null", "sh", Theme.themeDir]
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
                // start on the wallpaper and the layout that are active right now
                const cw = (parts[1] || "").trim();
                if (cw !== "" && i >= 0) {
                    const k = root.wallsOf(list[i]).indexOf(cw);
                    if (k > 0) { const w = {}; w[list[i].name] = k; root.wv = w; }
                }
                if (i >= 0 && Theme.userLayout && Theme.layouts.indexOf(Theme.userLayout) >= 0) {
                    const m = {}; m[list[i].name] = Theme.userLayout; root.lv = m;
                }
                const pre = Quickshell.env("SUMI_PICK");          // test hook: start on another theme
                const j = pre ? list.findIndex(t => t.name === pre) : -1;
                root.sel = j >= 0 ? j : (i >= 0 ? i : 0);
                const t = list[root.sel];
                if (t) { Theme.preview(t); Theme.pickLayout = root.layoutOf(t); }
            }
        }
    }

    // ------------------------------------------------------------------ the preview
    // the selected wallpaper, sharp and full screen, crossfading and settling as you browse
    Item {
        id: backdrop
        anchors.fill: parent
        Repeater {
            model: root.themes
            delegate: Item {
                id: bd
                required property var modelData
                required property int index
                readonly property bool on: index === root.sel
                anchors.fill: parent
                opacity: on ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
                scale: on ? 1 : 1.035
                Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutQuint } }
                Repeater {
                    model: root.wallsOf(bd.modelData).length
                    delegate: Image {
                        required property int index
                        anchors.fill: parent
                        // every theme keeps its chosen wallpaper loaded, the others load once it is selected
                        source: (bd.on || index === root.wallIndex(bd.modelData)) ? "file://" + Theme.wall(root.wallsOf(bd.modelData)[index]) : ""
                        sourceSize: Qt.size(root.width, root.height)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: index === root.wallIndex(bd.modelData) && status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
        // a soft darkening towards the bottom so the dock and the name read well
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.5
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.62) }
            }
        }
    }

    WheelHandler { onWheel: (e) => root.browse(e.angleDelta.y > 0 || e.angleDelta.x > 0 ? -1 : 1) }
    // clicks on the picture do nothing, a right click cancels
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: (m) => { if (m.button === Qt.RightButton) Ui.close(); } }

    // ------------------------------------------------------------------ name and dock
    Item {
        id: stage
        anchors.fill: parent
        property real intro: 0
        NumberAnimation on intro { from: 0; to: 1; duration: 620; easing.type: Easing.OutQuint }

        // name of the selected theme in its own display font, re-entering on every change
        Connections { target: root; function onSelChanged() { nameAnim.restart(); } }
        ParallelAnimation {
            id: nameAnim
            NumberAnimation { target: nameCol; property: "opacity"; from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { target: nameCol; property: "shift"; from: Theme.px(12); to: 0; duration: 520; easing.type: Easing.OutQuint }
        }
        Column {
            id: nameCol
            property real shift: 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: dock.top
            anchors.bottomMargin: Theme.px(22) - shift
            spacing: Theme.px(10)
            opacity: stage.intro
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.cur.label || ""
                color: "#ffffff"
                font.family: root.cur.fontHead || Theme.serif
                font.pixelSize: Theme.px(52)
                font.weight: Font.Medium
                style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.25)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: [root.blurbs[root.cur.name] || "", root.layoutNames[root.layoutOf(root.cur)] || "",
                       root.wallsOf(root.cur).length + " Wallpaper"].filter(x => x).join("  ·  ")
                color: Qt.rgba(1, 1, 1, 0.62)
                font.family: "Inter"; font.pixelSize: Theme.px(13)
            }
            // wallpaper dots
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(7)
                height: Theme.px(10)
                Repeater {
                    model: root.wallsOf(root.cur).length > 1 ? root.wallsOf(root.cur).length : 0
                    delegate: Rectangle {
                        required property int index
                        readonly property bool on: index === root.wallIndex(root.cur)
                        anchors.verticalCenter: parent.verticalCenter
                        width: on ? Theme.px(18) : Theme.px(6); height: Theme.px(6); radius: height / 2
                        color: on ? (root.cur.accent || "#ffffff") : Qt.rgba(1, 1, 1, 0.55)
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        MouseArea { anchors.fill: parent; anchors.margins: -Theme.px(5); cursorShape: Qt.PointingHandCursor
                            onClicked: { const w = Object.assign({}, root.wv); w[root.cur.name] = index; root.wv = w; } }
                    }
                }
            }
        }

        // the dock: frosted glass, one tile per theme
        Item {
            id: dock
            readonly property real tile: Theme.px(76)
            readonly property real gap: Theme.px(16)
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - Theme.px(84) + (1 - stage.intro) * Theme.px(40)
            width: tiles.implicitWidth + Theme.px(36)
            height: tile + Theme.px(44)
            opacity: stage.intro

            Rectangle {
                id: glassShape
                anchors.fill: parent
                radius: Theme.px(26)
                color: Qt.rgba(0.04, 0.05, 0.07, 0.52)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10)
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: parent.radius; rightMargin: parent.radius; topMargin: 1 }
                    height: 1
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                        GradientStop { position: 1; color: "transparent" } }
                }
            }

            Row {
                id: tiles
                anchors.centerIn: parent
                spacing: dock.gap
                Repeater {
                    model: root.themes
                    delegate: Item {
                        id: tl
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.sel
                        width: dock.tile; height: dock.tile
                        // tiles pop in one after another when the picker opens
                        property real pop: 0
                        SequentialAnimation on pop {
                            running: true
                            PauseAnimation { duration: 60 + tl.index * 45 }
                            NumberAnimation { to: 1; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                        }
                        Rectangle {
                            id: face
                            width: parent.width; height: parent.height
                            y: tl.on ? -Theme.px(10) : 0
                            Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                            scale: tl.pop * (tl.on ? 1.08 : (tma.containsMouse ? 1.03 : 1))
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            radius: Theme.px(18)
                            color: tl.on ? tl.modelData.accent : Qt.rgba(1, 1, 1, tma.containsMouse ? 0.10 : 0.06)
                            Behavior on color { ColorAnimation { duration: 260 } }
                            border.width: 1
                            border.color: tl.on ? Qt.lighter(tl.modelData.accent, 1.25) : Qt.rgba(1, 1, 1, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: tl.modelData.kanji
                                color: tl.on ? tl.modelData.bg : tl.modelData.accent
                                Behavior on color { ColorAnimation { duration: 260 } }
                                font.family: Theme.serif; font.weight: Font.Bold
                                font.pixelSize: dock.tile * 0.5
                            }
                        }
                        // soft glow of the accent under the lifted tile
                        Rectangle {
                            z: -1
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: face.y + Theme.px(8)
                            width: parent.width * 0.9; height: parent.height * 0.9; radius: Theme.px(22)
                            color: tl.modelData.accent
                            opacity: tl.on ? 0.22 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 }
                        }
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: Theme.px(8) }
                            width: Theme.px(5); height: width; radius: width / 2
                            color: "#ffffff"
                            opacity: tl.on ? 0.9 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (tl.on) root.apply(); else root.select(tl.index); }
                        }
                    }
                }
            }
        }

        // quiet key hints
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(22) }
            spacing: Theme.px(24)
            opacity: 0.55 * stage.intro
            Repeater {
                model: [["←  →", "Theme"], ["↑  ↓", "Wallpaper"], ["Tab", "Leiste"], ["↵", "Übernehmen"], ["Esc", "Abbrechen"]]
                delegate: Row {
                    required property var modelData
                    spacing: Theme.px(7)
                    Text { text: modelData[0]; color: "#ffffff"; font.family: "Inter"; font.pixelSize: Theme.px(12); font.weight: Font.DemiBold }
                    Text { text: modelData[1]; color: "#ffffff"; font.family: "Inter"; font.pixelSize: Theme.px(12) }
                }
            }
        }
    }
}
