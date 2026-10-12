import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland

// Stars (Ginga): only the two top corners, the sky in between stays free.
// Left: the workspaces as a constellation (the active one is a bright star with spikes)
// and the music. Right: CPU, RAM, controls, battery and a star-chart clock.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        id: bw
        screen: lay.screenRef
        edge: "top"

        readonly property int focusedId: Theme.demo ? 1 : (Hyprland.focusedWorkspace?.id ?? 1)
        readonly property var wsList: Hyprland.workspaces.values
        readonly property var ids: {
            const base = [1, 2, 3, 4, 5];
            for (const w of wsList) if (w.id > 5 && base.indexOf(w.id) < 0) base.push(w.id);
            return base.sort((a, b) => a - b);
        }
        function windows(id) {
            if (Theme.demo) return (id === 2 || id === 3) ? 1 : 0;
            const w = wsList.find(x => x.id === id);
            return w ? w.toplevels.values.length : 0;
        }
        readonly property var greek: ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ"]
        readonly property var ys: [0.58, 0.3, 0.66, 0.36, 0.6, 0.28, 0.62, 0.4]

        component Box: Rectangle {
            y: Theme.px(8)
            height: Theme.px(50)
            radius: Theme.px(16)
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.66)
            border.width: 1
            border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)
        }

        Box {
            id: left
            x: Theme.px(8)
            width: lrow.implicitWidth + Theme.px(28)
            Row {
                id: lrow
                anchors { left: parent.left; leftMargin: Theme.px(14); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(10)
                Item {
                    id: con
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property real gap: Theme.px(34)
                    width: (bw.ids.length - 1) * gap + Theme.px(26); height: Theme.px(44)
                    function sx(i) { return Theme.px(13) + i * gap; }
                    function sy(i) { return height * bw.ys[i % bw.ys.length]; }
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                            strokeWidth: 1
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [1.5, 3.5]
                            fillColor: "transparent"
                            PathPolyline { path: bw.ids.map((id, i) => Qt.point(con.sx(i), con.sy(i))) }
                        }
                    }
                    Repeater {
                        model: bw.ids
                        delegate: Item {
                            id: st
                            required property int modelData
                            required property int index
                            readonly property bool on: modelData === bw.focusedId
                            readonly property bool used: bw.windows(modelData) > 0
                            x: con.sx(index) - width / 2; y: con.sy(index) - height / 2
                            width: Theme.px(26); height: width
                            Rectangle { visible: st.on; anchors.centerIn: parent; width: Theme.px(22); height: width; radius: width / 2; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
                            Rectangle { visible: st.on; anchors.centerIn: parent; width: Theme.px(24); height: 1; color: Qt.rgba(1, 1, 1, 0.75) }
                            Rectangle { visible: st.on; anchors.centerIn: parent; width: 1; height: Theme.px(24); color: Qt.rgba(1, 1, 1, 0.75) }
                            Rectangle {
                                anchors.centerIn: parent
                                width: st.on ? Theme.px(7) : (st.used ? Theme.px(5) : Theme.px(3.5)); height: width; radius: width / 2
                                color: st.on ? "#ffffff" : (st.used ? Theme.fg : Theme.mute)
                                Behavior on width { NumberAnimation { duration: 160 } }
                            }
                            Text {
                                x: parent.width / 2 + Theme.px(5); y: parent.height / 2 + Theme.px(2)
                                text: bw.greek[st.index % bw.greek.length]
                                color: st.on ? Theme.accent : Theme.mute
                                font.family: Theme.body; font.pixelSize: Theme.px(9)
                            }
                            MouseArea { anchors.fill: parent; anchors.margins: -Theme.px(4); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("workspace " + st.modelData) }
                        }
                    }
                    WheelHandler { onWheel: (e) => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1") }
                }
                Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active; height: Theme.px(24) }
                ModMedia {
                    anchors.verticalCenter: parent.verticalCenter
                    twoLines: true; fontSize: Theme.px(11.5); maxTitle: Theme.px(150)
                    coverSize: Theme.px(28); coverRadius: Theme.px(14); barW: Theme.px(46); barColor: Theme.accent
                }
            }
        }

        Box {
            id: right
            anchors.right: parent.right; anchors.rightMargin: Theme.px(8)
            width: rrow.implicitWidth + Theme.px(24)
            Row {
                id: rrow
                anchors { right: parent.right; rightMargin: Theme.px(14); verticalCenter: parent.verticalCenter }
                spacing: Theme.px(1)
                ModCpu { anchors.verticalCenter: parent.verticalCenter }
                ModMem { anchors.verticalCenter: parent.verticalCenter }
                ModFan { anchors.verticalCenter: parent.verticalCenter }
                ModAgent { anchors.verticalCenter: parent.verticalCenter }
                ModNet { anchors.verticalCenter: parent.verticalCenter }
                ModBt { anchors.verticalCenter: parent.verticalCenter }
                ModVol { anchors.verticalCenter: parent.verticalCenter }
                ModMic { anchors.verticalCenter: parent.verticalCenter }
                ModDnd { anchors.verticalCenter: parent.verticalCenter }
                KbdLayout { anchors.verticalCenter: parent.verticalCenter }
                ModBat { anchors.verticalCenter: parent.verticalCenter }
                Item { width: Theme.px(8); height: 1 }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: Theme.px(30); color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14) }
                Item { width: Theme.px(10); height: 1 }
                Item {
                    id: clock
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(ct.implicitWidth, cd.implicitWidth); height: ct.implicitHeight + cd.implicitHeight
                    readonly property var d: Dev.clockDate
                    Text {
                        id: ct
                        anchors.right: parent.right
                        text: Qt.formatTime(clock.d, "HH:mm")
                        color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(24); font.weight: Font.Light; font.letterSpacing: Theme.px(1.5)
                    }
                    Text {
                        id: cd
                        anchors { right: parent.right; top: ct.bottom; topMargin: -Theme.px(3) }
                        text: clock.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd MMM").replace(/\./g, "").toUpperCase() + " · ☾ " + Sky.moon + "%"
                        color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(8.5); font.letterSpacing: Theme.px(1.2)
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", clock.mapToItem(null, clock.width / 2, 0).x) }
                }
                Item { width: Theme.px(6); height: 1 }
                ModPower { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
