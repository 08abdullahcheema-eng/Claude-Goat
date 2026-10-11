import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspace buttons in five looks, chosen by the bar layout:
// pill (kanji or numbers in rounded pills), dots, circles, blocks, text.
Row {
    id: root
    property string screenName: ""
    property string mode: BarStyle.wsMode
    property real h: BarStyle.itemH
    spacing: mode === "dots" ? Theme.px(6) : mode === "text" ? Theme.px(13) : mode === "blocks" ? 0 : Theme.px(3)

    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property int focusedId: Theme.demo ? 1 : (Hyprland.focusedWorkspace?.id ?? 1)
    readonly property var wsList: Hyprland.workspaces.values

    function info(id) {
        if (Theme.demo) return { exists: id <= 3, windows: (id === 2 || id === 3) ? 1 : 0 };
        const w = wsList.find(x => x.id === id);
        return { exists: !!w, windows: w ? w.toplevels.values.length : 0 };
    }
    function label(id) { return (Theme.wsKanji && id <= 10) ? kanji[id - 1] : String(id); }
    readonly property var ids: {
        const base = [1, 2, 3, 4, 5];
        for (const w of wsList) if (w.id > 5 && base.indexOf(w.id) < 0) base.push(w.id);
        return base.sort((a, b) => a - b);
    }

    Repeater {
        model: root.ids
        delegate: Item {
            id: cell
            required property int modelData
            readonly property bool on: modelData === root.focusedId
            readonly property var inf: root.info(modelData)
            readonly property bool used: inf.windows > 0
            anchors.verticalCenter: parent.verticalCenter
            height: root.mode === "blocks" ? root.h : root.mode === "dots" ? Theme.px(10) : root.mode === "circles" ? Theme.px(22) : root.h
            width: root.mode === "dots" ? (on ? Theme.px(26) : Theme.px(9))
                 : root.mode === "circles" ? Theme.px(22)
                 : root.mode === "blocks" ? Theme.px(34)
                 : root.mode === "text" ? txt.implicitWidth
                 : (on ? Theme.px(36) : Theme.px(27))
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                id: bg
                anchors.fill: parent
                radius: root.mode === "blocks" ? 0 : (root.mode === "pill" ? Theme.px(8) : height / 2)
                color: {
                    if (root.mode === "dots") return cell.on ? Theme.accent : (cell.used ? Theme.dim : Theme.line2);
                    if (root.mode === "circles") return cell.on ? Theme.accent : "transparent";
                    if (root.mode === "blocks" && cell.on && (Theme.p.barFx ?? "") === "fire") return Theme.accent;
                    if (root.mode === "blocks") return cell.on ? Theme.bg2 : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent");
                    if (root.mode === "pill") return cell.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.8) : "transparent");
                    return "transparent";
                }
                border.width: (root.mode === "pill" && cell.on) || (root.mode === "circles" && !cell.on && cell.used) ? 1 : 0
                border.color: root.mode === "pill" ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.dim
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            // block mode: accent line under the active workspace
            Rectangle { visible: root.mode === "blocks" && cell.on; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Theme.px(3); color: Theme.accent }
            // text mode: underline
            Rectangle { visible: root.mode === "text" && cell.on; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(1) } width: parent.width + Theme.px(8); height: 2; color: Theme.accent }

            Text {
                id: txt
                visible: root.mode !== "dots"
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.mode === "pill" && cell.used ? -Theme.px(1.5) : 0
                text: root.label(cell.modelData)
                font.family: (Theme.wsKanji && cell.modelData <= 10) ? Theme.serif : BarStyle.fontFamily
                font.pixelSize: root.mode === "circles" ? Theme.px(11) : root.mode === "blocks" ? Theme.px(18) : root.mode === "text" ? Theme.px(12) : Theme.fmd
                font.weight: root.mode === "circles" || root.mode === "blocks" ? Font.Bold : Font.Normal
                color: root.mode === "circles" && cell.on ? Theme.onAccent
                     : cell.on ? (root.mode === "blocks" ? ((Theme.p.barFx ?? "") === "fire" ? Theme.onAccent : Theme.accent) : Theme.hi)
                     : (cell.used ? Theme.fg : Theme.mute)
            }
            // pill mode: one dot per window, up to three
            Row {
                visible: root.mode === "pill" && cell.used
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(2.5) }
                spacing: Theme.px(2)
                Repeater {
                    model: Math.min(3, cell.inf.windows)
                    delegate: Rectangle { width: Theme.px(3); height: width; radius: width / 2; color: cell.on ? Theme.accent2 : Theme.dim }
                }
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                anchors.margins: root.mode === "dots" ? -Theme.px(5) : 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + cell.modelData)
            }
        }
    }
    WheelHandler {
        onWheel: (e) => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
    }
}
