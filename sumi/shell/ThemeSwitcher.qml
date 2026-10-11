import QtQuick
import Quickshell
import Quickshell.Io

// Theme picker: a carousel of full previews, one per theme, each showing its wallpaper
// with the bar and two windows on top. The shell recolours live while you browse.
//   left / right   theme        up / down or tab   wallpaper of that theme
//   enter or click apply        esc                cancel
Item {
    id: root
    anchors.fill: parent
    focus: true

    property var themes: []
    property int sel: 0
    property var wv: ({})              // theme name -> wallpaper index
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
        if (!Theme.demo) Quickshell.execDetached(["sumi-theme", t.name, wallFile(t)]);
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
        else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || e.key === Qt.Key_J) { cycleWall(1); e.accepted = true; }
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || e.key === Qt.Key_K) { cycleWall(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { apply(); e.accepted = true; }
        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in sumi tokyo catppuccin gruvbox nord everforest jade matte latte; do [ -f \"$1/$f.json\" ] || continue; cat \"$1/$f.json\"; printf '\\036'; done; printf 'WALL:'; cat \"$HOME/.config/sumi/wall\" 2>/dev/null", "sh", Theme.themeDir]
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
            }
        }
    }

    // ------------------------------------------------------------------ stage
    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        scale: 0.97
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

        readonly property real cwC: Math.min(width * 0.46, Theme.px(760))
        readonly property real cwS: cwC * 0.54
        readonly property real gap: Theme.px(30)
        readonly property real midY: height / 2 - Theme.px(34)

        WheelHandler { onWheel: (e) => root.browse(e.angleDelta.y > 0 ? -1 : 1) }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: (w) => root.browse(w.angleDelta.y > 0 ? -1 : 1) }

        // heading
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.px(96) }
            spacing: Theme.px(12)
            T { text: "Theme"; color: root.tInk; font.pixelSize: Theme.px(22) }
            Text { text: "色"; color: root.tMute; font.family: Theme.serif; font.pixelSize: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
            T { visible: root.n > 0; text: (root.sel + 1) + " / " + root.n; color: root.tMute; font.pixelSize: Theme.px(12); anchors.verticalCenter: parent.verticalCenter }
        }

        Repeater {
            model: root.themes
            delegate: Rectangle {
                id: tc
                required property var modelData
                required property int index
                readonly property var t: modelData
                readonly property int d: { const v = (index - root.sel + root.n) % root.n; return v > root.n / 2 ? v - root.n : v; }
                readonly property bool on: d === 0
                readonly property real u: width / 100          // layout unit: 1% of the card width

                width: on ? stage.cwC : stage.cwS
                height: width * 0.625
                x: on ? (stage.width - stage.cwC) / 2
                    : (d > 0 ? stage.width / 2 + stage.cwC / 2 + stage.gap + (d - 1) * (stage.cwS + stage.gap)
                             : stage.width / 2 - stage.cwC / 2 - stage.gap - stage.cwS - (-d - 1) * (stage.cwS + stage.gap))
                y: stage.midY - height / 2
                opacity: on ? 1 : (Math.abs(d) === 1 ? 0.55 : (Math.abs(d) === 2 ? 0.18 : 0))
                visible: opacity > 0.01
                z: on ? 2 : 1
                radius: Theme.px(14)
                color: t.bg
                clip: true
                border.width: on ? Theme.px(2.5) : 1
                border.color: on ? t.accent : Theme.line2

                // hidden cards jump across the wrap-around point without flying over the screen
                Behavior on x { enabled: Math.abs(tc.d) <= 2; NumberAnimation { duration: 360; easing.type: Easing.OutQuint } }
                Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutQuint } }
                Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                // every wallpaper of the theme, decoded small once, crossfaded on ↑↓
                Repeater {
                    model: root.wallsOf(tc.t)
                    delegate: Image {
                        required property string modelData
                        required property int index
                        anchors.fill: parent
                        source: "file://" + Theme.wall(modelData)
                        sourceSize: Qt.size(960, 600)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: index === root.wallIndex(tc.t) && status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }

                // the bar, as floating islands
                Rectangle { x: tc.u * 1.6; y: tc.u * 1.6; width: tc.u * 17; height: tc.u * 4.6; radius: tc.u * 1.4; color: tc.t.bg; opacity: 0.92; border.width: 1; border.color: tc.t.line
                    Row { anchors.centerIn: parent; spacing: tc.u * 1.1
                        Rectangle { width: tc.u * 2; height: width; radius: width / 2; color: tc.t.accent; anchors.verticalCenter: parent.verticalCenter }
                        Repeater { model: 4; delegate: Rectangle { required property int index; width: index === 0 ? tc.u * 3.2 : tc.u * 1.6; height: tc.u * 1.6; radius: height / 2; color: index === 0 ? tc.t.accent : tc.t.fg; opacity: index === 0 ? 1 : 0.35; anchors.verticalCenter: parent.verticalCenter } }
                    }
                }
                Rectangle { x: (parent.width - width) / 2; y: tc.u * 1.6; width: tc.u * 14; height: tc.u * 4.6; radius: tc.u * 1.4; color: tc.t.bg; opacity: 0.92; border.width: 1; border.color: tc.t.line
                    Rectangle { anchors.centerIn: parent; width: tc.u * 8; height: tc.u * 1.5; radius: height / 2; color: tc.t.fg; opacity: 0.6 }
                }
                Rectangle { x: parent.width - width - tc.u * 1.6; y: tc.u * 1.6; width: tc.u * 22; height: tc.u * 4.6; radius: tc.u * 1.4; color: tc.t.bg; opacity: 0.92; border.width: 1; border.color: tc.t.line
                    Row { anchors.centerIn: parent; spacing: tc.u * 1.4
                        Repeater { model: 6; delegate: Rectangle { required property int index; width: tc.u * 1.8; height: width; radius: width / 2; color: index === 5 ? tc.t.accent : tc.t.fg; opacity: index === 5 ? 1 : 0.4 } }
                    }
                }

                // three tiled windows, kept to the left so the wallpaper stays visible
                Rectangle { x: tc.u * 4; y: tc.u * 11; width: tc.u * 31; height: tc.u * 44; radius: tc.u * 1.3; color: tc.t.bg; opacity: 0.93; border.width: tc.u * 0.35; border.color: tc.t.accent
                    Column { x: tc.u * 2.4; y: tc.u * 3; spacing: tc.u * 2
                        Rectangle { width: tc.u * 11; height: tc.u * 1.5; radius: height / 2; color: tc.t.accent }
                        Repeater { model: [22, 26, 17, 24, 13]; delegate: Rectangle { required property real modelData; width: tc.u * modelData; height: tc.u * 1.3; radius: height / 2; color: tc.t.fg; opacity: 0.4 } }
                        Rectangle { width: tc.u * 8; height: tc.u * 1.5; radius: height / 2; color: tc.t.green }
                        Rectangle { width: tc.u * 16; height: tc.u * 1.3; radius: height / 2; color: tc.t.gold; opacity: 0.8 }
                    }
                }
                Rectangle { x: tc.u * 37; y: tc.u * 11; width: tc.u * 25; height: tc.u * 21; radius: tc.u * 1.3; color: tc.t.bg1; opacity: 0.93; border.width: 1; border.color: tc.t.line2
                    Column { x: tc.u * 2.4; y: tc.u * 3; spacing: tc.u * 2
                        Repeater { model: [17, 11, 19, 14]; delegate: Rectangle { required property real modelData; width: tc.u * modelData; height: tc.u * 1.3; radius: height / 2; color: tc.t.fg; opacity: 0.35 } }
                        Rectangle { width: tc.u * 8; height: tc.u * 1.4; radius: height / 2; color: tc.t.blue }
                    }
                }
                Rectangle { x: tc.u * 37; y: tc.u * 35; width: tc.u * 25; height: tc.u * 20; radius: tc.u * 1.3; color: tc.t.bg; opacity: 0.93; border.width: 1; border.color: tc.t.line2
                    Grid { anchors.centerIn: parent; columns: 3; spacing: tc.u * 1.3
                        Repeater { model: [tc.t.accent, tc.t.gold, tc.t.green, tc.t.cyan, tc.t.blue, tc.t.violet]; delegate: Rectangle { required property var modelData; width: tc.u * 5.4; height: tc.u * 5.4; radius: tc.u * 1; color: modelData } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (tc.on) root.apply(); else root.browse(tc.d); }
                }
            }
        }

        // name, wallpaper dots and colour chips under the selected card
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: stage.midY + stage.cwC * 0.3125 + Theme.px(26)
            spacing: Theme.px(12)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(10)
                T { text: root.cur.label || ""; color: root.tInk; font.pixelSize: Theme.px(26) }
                Text { text: root.cur.kanji || ""; color: root.tMute; font.family: Theme.serif; font.pixelSize: Theme.px(22); anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(7)
                Repeater {
                    model: [root.cur.bg, root.cur.fg, root.cur.accent, root.cur.gold, root.cur.green, root.cur.cyan, root.cur.blue, root.cur.violet]
                    delegate: Rectangle { required property var modelData; width: Theme.px(14); height: width; radius: width / 2; color: modelData || "transparent"; border.width: 1; border.color: root.tLine }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.px(8)
                visible: root.wallsOf(root.cur).length > 1
                Repeater {
                    model: root.wallsOf(root.cur).length
                    delegate: Rectangle {
                        required property int index
                        width: index === root.wallIndex(root.cur) ? Theme.px(22) : Theme.px(7); height: Theme.px(7); radius: height / 2
                        color: index === root.wallIndex(root.cur) ? (root.cur.accent || root.tInk) : root.tLine
                        Behavior on width { NumberAnimation { duration: 160 } }
                    }
                }
            }
        }

        // keys
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(46) }
            spacing: Theme.px(18)
            Repeater {
                model: [["←→", "theme"], ["↑↓", "wallpaper"], ["↵", "apply"], ["esc", "cancel"]]
                delegate: Row {
                    required property var modelData
                    spacing: Theme.px(7)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: kt.implicitWidth + Theme.px(12); height: kt.implicitHeight + Theme.px(5)
                        radius: Theme.px(4); color: "transparent"; border.width: 1; border.color: root.tLine
                        T { id: kt; anchors.centerIn: parent; text: modelData[0]; color: root.tDim; font.pixelSize: Theme.px(10.5) }
                    }
                    T { text: modelData[1]; color: root.tMute; font.pixelSize: Theme.px(12); anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
