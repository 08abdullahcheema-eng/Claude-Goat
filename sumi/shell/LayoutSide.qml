import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland

// Side: a floating column on the left edge, like a tide gauge.
// Top: mark, workspaces, music disc. Middle: the clock. Bottom: CPU curve, controls, battery ring.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "left"

        Rectangle {
            id: col
            x: Theme.px(10); y: Theme.px(10)
            width: Theme.px(52); height: parent.height - Theme.px(20)
            radius: Theme.px(18)
            color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.62)
            border.width: 1
            border.color: Qt.rgba(Theme.hi.r, Theme.hi.g, Theme.hi.b, 0.12)

            component Line: Rectangle { width: Theme.px(22); height: 1; color: Theme.line2; anchors.horizontalCenter: parent.horizontalCenter }

            // ---- top
            Column {
                anchors { top: parent.top; topMargin: Theme.px(14); horizontalCenter: parent.horizontalCenter }
                spacing: Theme.px(12)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.kanji; color: Theme.accent; font.family: Theme.head; font.pixelSize: Theme.px(22); font.weight: Font.Bold
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
                }
                Line {}
                // workspaces: a tall bar for the active one, dots for the rest
                Column {
                    id: ws
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.px(7)
                    readonly property int focusedId: Theme.demo ? 1 : (Hyprland.focusedWorkspace?.id ?? 1)
                    readonly property var ids: {
                        const base = [1, 2, 3, 4, 5];
                        for (const w of Hyprland.workspaces.values) if (w.id > 5 && base.indexOf(w.id) < 0) base.push(w.id);
                        return base.sort((a, b) => a - b);
                    }
                    function used(id) {
                        if (Theme.demo) return id === 2 || id === 3;
                        const w = Hyprland.workspaces.values.find(x => x.id === id);
                        return w ? w.toplevels.values.length > 0 : false;
                    }
                    Repeater {
                        model: ws.ids
                        delegate: Rectangle {
                            required property int modelData
                            readonly property bool on: modelData === ws.focusedId
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Theme.px(6); height: on ? Theme.px(26) : Theme.px(6); radius: width / 2
                            color: on ? Theme.accent : (ws.used(modelData) ? Theme.dim : "transparent")
                            border.width: on || ws.used(modelData) ? 0 : 1
                            border.color: Theme.mute
                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            MouseArea { anchors.fill: parent; anchors.margins: -Theme.px(6); cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("workspace " + parent.modelData) }
                        }
                    }
                    WheelHandler { onWheel: (e) => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1") }
                }
                Line { visible: Media.active }
                // music: the cover as a disc inside a progress ring, the title running down
                Item {
                    visible: Media.active
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.px(36); height: width
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath { strokeColor: Theme.line2; strokeWidth: Theme.px(2); fillColor: "transparent"
                            PathAngleArc { centerX: Theme.px(18); centerY: Theme.px(18); radiusX: Theme.px(17); radiusY: Theme.px(17); startAngle: 0; sweepAngle: 360 } }
                        ShapePath { strokeColor: Theme.accent2; strokeWidth: Theme.px(2); fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: Theme.px(18); centerY: Theme.px(18); radiusX: Theme.px(17); radiusY: Theme.px(17); startAngle: -90; sweepAngle: 360 * Media.progress } }
                    }
                    Cover { anchors.centerIn: parent; width: Theme.px(26); height: width; radius: width / 2 }
                    Icon { anchors.centerIn: parent; name: Media.playing ? "pause" : "play"; size: Theme.px(11); color: "white" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: (e) => { if (e.button === Qt.RightButton) Media.next(); else if (e.button === Qt.MiddleButton) Media.previous(); else Media.toggle(); }
                    }
                }
                Item {
                    visible: Media.active
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.px(14); height: Math.min(Theme.px(130), title.implicitWidth)
                    clip: true
                    Text {
                        id: title
                        rotation: 90
                        transformOrigin: Item.TopLeft
                        x: Theme.px(13); y: 0
                        width: parent.height
                        elide: Text.ElideRight
                        text: Media.title + (Media.artist ? " · " + Media.artist : "")
                        color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(10); font.letterSpacing: Theme.px(1.2)
                    }
                }
            }

            // ---- middle: the clock
            Item {
                id: clock
                anchors.centerIn: parent
                width: parent.width; height: cc.implicitHeight
                readonly property var d: Dev.clockDate
                Column {
                    id: cc
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.px(2)
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(clock.d, "HH"); color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(22); font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(clock.d, "mm"); color: Theme.accent; font.family: Theme.head; font.pixelSize: Theme.px(22); font.weight: Font.Bold }
                    Item { width: 1; height: Theme.px(4) }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: clock.d.toLocaleDateString(Qt.locale("de_DE"), "ddd").replace(/\./g, "").toUpperCase(); color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(8.5); font.letterSpacing: Theme.px(1.5) }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(clock.d, "dd.MM"); color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(8.5) }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { Ui.anchorY = clock.mapToItem(null, 0, clock.height / 2).y; Ui.toggleAt("calendar", 1); }
                }
            }

            // ---- bottom
            Column {
                anchors { bottom: parent.bottom; bottomMargin: Theme.px(12); horizontalCenter: parent.horizontalCenter }
                spacing: Theme.px(4)
                Item {
                    id: cpu
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.px(40); height: Theme.px(34)
                    CpuCurve { anchors.horizontalCenter: parent.horizontalCenter; width: Theme.px(36); height: Theme.px(16); color: Theme.accent }
                    Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } text: Sys.cpu + "%"; color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(9.5) }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { Ui.anchorY = cpu.mapToItem(null, 0, cpu.height / 2).y; Ui.toggleAt("system", 1); }
                    }
                }
                Line {}
                ModFan { anchors.horizontalCenter: parent.horizontalCenter; text: "" }
                ModAgent { anchors.horizontalCenter: parent.horizontalCenter; text: "" }
                ModNet { anchors.horizontalCenter: parent.horizontalCenter }
                ModBt { anchors.horizontalCenter: parent.horizontalCenter; text: "" }
                ModVol { anchors.horizontalCenter: parent.horizontalCenter; text: "" }
                ModMic { anchors.horizontalCenter: parent.horizontalCenter }
                ModDnd { anchors.horizontalCenter: parent.horizontalCenter }
                Item { width: 1; height: Theme.px(2) }
                ModBatRing { anchors.horizontalCenter: parent.horizontalCenter; ringSize: Theme.px(28); pad: 0 }
                ModPower { anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}
