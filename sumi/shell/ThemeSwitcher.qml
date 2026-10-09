import QtQuick
import Quickshell
import Quickshell.Io

// Theme switcher with live preview. Arrows browse (the shell recolours), Enter applies everything.
Item {
    id: root
    anchors.fill: parent
    focus: true

    property var themes: []
    property int sel: 0
    property bool applied: false
    readonly property var cur: themes[sel] || Theme.p

    function focusFirst() { root.forceActiveFocus(); }
    function browse(d) {
        if (!themes.length) return;
        sel = (sel + d + themes.length) % themes.length;
        Theme.preview(themes[sel]);
        if (!Theme.demo) Quickshell.execDetached(["hyprctl", "keyword", "general:col.active_border", "rgb(" + String(themes[sel].accent).replace("#", "") + ")"]);
    }
    function apply() {
        applied = true;
        if (!Theme.demo) Quickshell.execDetached(["sumi-theme", themes[sel].name]);
        Ui.close();
    }
    Component.onDestruction: {
        if (!applied) {
            Theme.revert();
            if (!Theme.demo) Quickshell.execDetached(["sumi-theme", "--restore"]);
        }
    }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) { browse(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab) { browse(1); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { apply(); e.accepted = true; }
        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
    }

    component MiniWin: Rectangle {
        id: mw
        property var t: ({})
        property bool act: false
        color: t.bg ?? "black"; opacity: 0.96; radius: Theme.px(3)
        border.width: Theme.px(1.5); border.color: act ? t.accent : t.bg2
        Column {
            x: Theme.px(5); y: Theme.px(6); spacing: Theme.px(4)
            Repeater { model: [0.6, 0.8, 0.45, 0.7, 0.3]; delegate: Rectangle { required property real modelData; width: (mw.width - Theme.px(10)) * modelData; height: Theme.px(2.5); radius: 1; color: mw.t.fg ?? "white"; opacity: 0.35 } }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in sumi kin ai washi; do cat \"$1/$f.json\"; printf '\\036'; done", "sh", Theme.themeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const chunk of this.text.split("\u001e")) {
                    if (!chunk.trim()) continue;
                    try { list.push(JSON.parse(chunk)); } catch (e) { }
                }
                root.themes = list;
                const i = list.findIndex(t => t.name === Theme.name);
                root.sel = i >= 0 ? i : 0;
            }
        }
    }

    Card {
        id: card
        width: Math.min(parent.width - Theme.px(60), Theme.px(1380))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Theme.px(40), (parent.height - height) / 2 - Theme.px(40))
        pad: Theme.px(22)

        Column {
            width: parent.width
            spacing: Theme.px(18)

            Item {
                width: parent.width; height: Theme.px(26)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "palette"; color: Theme.accent; size: Theme.px(19); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Themes"; color: Theme.hi; font.pixelSize: Theme.px(19); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "色"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(15); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "live preview · the shell follows your selection"; color: Theme.mute; font.pixelSize: Theme.px(11.5); leftPadding: Theme.px(14); anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(8)
                    Kbd { text: "←→" } T { text: "browse"; color: Theme.mute; font.pixelSize: Theme.px(11) }
                    Kbd { text: "↵" } T { text: "apply"; color: Theme.mute; font.pixelSize: Theme.px(11) }
                    Kbd { text: "esc" } T { text: "revert"; color: Theme.mute; font.pixelSize: Theme.px(11) }
                }
            }

            Row {
                id: cards
                width: parent.width
                spacing: Theme.px(16)
                readonly property real cw: (width - spacing * 3) / 4
                Repeater {
                    model: root.themes
                    delegate: Rectangle {
                        id: tc
                        required property var modelData
                        required property int index
                        readonly property bool on: root.sel === index
                        readonly property var t: modelData
                        width: cards.cw
                        height: prev.height + Theme.px(56)
                        radius: Theme.px(9)
                        color: Theme.bg1
                        border.width: on ? Theme.px(2) : 1
                        border.color: on ? Theme.accent : Theme.line2

                        // mini desktop in this theme's colours
                        Rectangle {
                            id: prev
                            x: Theme.px(9); y: Theme.px(9)
                            width: parent.width - Theme.px(18); height: width * 0.62
                            radius: Theme.px(5)
                            clip: true
                            color: tc.t.bg
                            Image {
                                anchors.fill: parent
                                source: "file://" + Theme.wallpaper(tc.t.name)
                                sourceSize: Qt.size(width * 2, height * 2)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Rectangle {
                                width: parent.width; height: Theme.px(13); color: tc.t.bg
                                Row {
                                    anchors { left: parent.left; leftMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                                    spacing: Theme.px(3)
                                    Repeater { model: 5; delegate: Rectangle { required property int index; width: Theme.px(8); height: Theme.px(5); radius: 1; color: index === 0 ? tc.t.accent : tc.t.fg; opacity: index === 0 ? 1 : 0.3 } }
                                }
                                Rectangle { anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter } width: Theme.px(34); height: Theme.px(3); color: tc.t.fg; opacity: 0.4 }
                            }
                            MiniWin { t: tc.t; x: parent.width * 0.03; y: parent.height * 0.14; width: parent.width * 0.3; height: parent.height * 0.82 }
                            MiniWin { t: tc.t; x: parent.width * 0.35; y: parent.height * 0.14; width: parent.width * 0.62; height: parent.height * 0.47; act: true }
                            MiniWin { t: tc.t; x: parent.width * 0.35; y: parent.height * 0.65; width: parent.width * 0.62; height: parent.height * 0.31 }
                        }
                        Row {
                            anchors { left: parent.left; leftMargin: Theme.px(14); bottom: parent.bottom; bottomMargin: Theme.px(14) }
                            spacing: Theme.px(8)
                            T { text: tc.t.label; color: tc.on ? Theme.hi : Theme.fg; font.pixelSize: Theme.px(15) }
                            Text { text: tc.t.kanji; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                        }
                        Row {
                            anchors { right: parent.right; rightMargin: Theme.px(14); bottom: parent.bottom; bottomMargin: Theme.px(16) }
                            spacing: Theme.px(4)
                            Repeater { model: [tc.t.bg, tc.t.fg, tc.t.accent]; delegate: Rectangle { required property var modelData; width: Theme.px(11); height: width; radius: Theme.px(2); color: modelData; border.width: 1; border.color: Theme.line2 } }
                            Icon { visible: tc.t.name === Theme.saved.name; name: "check"; color: Theme.accent; size: Theme.px(14) }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.sel === tc.index) root.apply(); else root.browse(tc.index - root.sel); }
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: Theme.px(14)
                Label { text: (root.cur.label || "") + " · 24 semantic colours"; anchors.verticalCenter: parent.verticalCenter }
                T { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "applies to: shell · hyprland · kitty · wallpaper · lock screen"; color: Theme.mute; font.pixelSize: Theme.px(10.5) }
            }
            Grid {
                id: sw
                width: parent.width
                columns: 12
                columnSpacing: Theme.px(9); rowSpacing: Theme.px(9)
                readonly property real cw: (width - columnSpacing * 11) / 12
                readonly property var keys: ["bg", "bg1", "bg2", "line", "line2", "mute", "dim", "fg", "hi", "accent", "accent2", "gold",
                                            "orange", "green", "cyan", "blue", "violet", "error", "warn", "ok", "info", "sel", "diffAdd", "diffDel"]
                Repeater {
                    model: sw.keys
                    delegate: Column {
                        required property string modelData
                        spacing: Theme.px(4)
                        Rectangle { width: sw.cw; height: Theme.px(32); radius: Theme.px(4); color: root.cur[modelData] || "transparent"; border.width: 1; border.color: Theme.line2 }
                        T { text: modelData; color: Theme.mute; font.pixelSize: Theme.px(9) }
                    }
                }
            }
        }
    }
}
