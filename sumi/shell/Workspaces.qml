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
            width: on ? Theme.px(36) : Theme.px(27); height: Theme.px(26)
            radius: Theme.px(8)
            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                      : (ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.8) : "transparent")
            border.width: on ? 1 : 0
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
            Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.inf.windows > 0 ? -Theme.px(1.5) : 0
                text: modelData <= 10 ? root.kanji[modelData - 1] : modelData
                font.family: Theme.serif
                font.pixelSize: Theme.fmd
                color: parent.on ? Theme.hi : (parent.inf.windows > 0 ? Theme.fg : Theme.mute)
            }
            // one dot per window, up to three
            Row {
                visible: parent.inf.windows > 0
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(2.5) }
                spacing: Theme.px(2)
                Repeater {
                    model: Math.min(3, parent.parent.inf.windows)
                    delegate: Rectangle { width: Theme.px(3); height: width; radius: width / 2; color: parent.parent.on ? Theme.accent2 : Theme.dim }
                }
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
