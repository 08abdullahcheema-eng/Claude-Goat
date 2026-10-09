import QtQuick
import Quickshell
import Quickshell.Hyprland

// Kanji workspace buttons 一..五, plus any extra workspace that exists.
Row {
    id: root
    property string screenName: ""
    spacing: Theme.px(3)

    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property int focusedId: Theme.demo ? 1 : (Hyprland.focusedWorkspace?.id ?? 1)
    readonly property var wsList: Hyprland.workspaces.values

    function info(id) {
        if (Theme.demo) return { exists: id <= 3, windows: (id === 2 || id === 3) ? 1 : 0 };
        const w = wsList.find(x => x.id === id);
        return { exists: !!w, windows: w ? w.toplevels.values.length : 0 };
    }
    readonly property var ids: {
        const base = [1, 2, 3, 4, 5];
        for (const w of wsList) if (w.id > 5 && base.indexOf(w.id) < 0) base.push(w.id);
        return base.sort((a, b) => a - b);
    }

    Repeater {
        model: root.ids
        delegate: Rectangle {
            required property int modelData
            readonly property bool on: modelData === root.focusedId
            readonly property var inf: root.info(modelData)
            width: Theme.px(27); height: Theme.px(25)
            radius: Theme.px(4)
            color: on ? Theme.bg2 : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent")
            Text {
                anchors.centerIn: parent
                text: modelData <= 10 ? root.kanji[modelData - 1] : modelData
                font.family: Theme.serif
                font.pixelSize: Theme.fmd
                color: parent.on ? Theme.hi : (parent.inf.windows > 0 ? Theme.dim : Theme.mute)
            }
            Rectangle {
                visible: parent.on
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Theme.px(2); color: Theme.accent
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + parent.modelData)
            }
        }
    }
    WheelHandler {
        onWheel: (e) => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
    }
}
