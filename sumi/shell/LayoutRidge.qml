import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland

// Ridge (Summit): the bar is a strip of night sky whose lower edge is a mountain ridge.
// Every workspace is a peak, the active one rises highest and wears a snow cap.
// Time, date, a few icons and the battery ring sit on the right.
Scope {
    id: lay
    required property var screenRef
    property bool preview: false        // a copy drawn above the theme picker

    BarWindow {
        id: bw
        screen: lay.screenRef
        preview: lay.preview
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

        readonly property real x0: Theme.px(64)        // first peak
        readonly property real step: Theme.px(52)      // distance between peaks
        readonly property real base: Theme.px(58)      // ridge height at the valleys
        // peak heights (distance from the top), a fixed irregular pattern
        readonly property var tops: [Theme.px(44), Theme.px(40), Theme.px(46), Theme.px(41), Theme.px(45), Theme.px(42), Theme.px(46), Theme.px(40), Theme.px(44)]
        function peakX(i) { return x0 + i * step; }
        // the active workspace rises above the others, the lift glides from peak to peak
        readonly property int focusedIdx: Math.max(0, ids.indexOf(focusedId))
        property real liftPos: focusedIdx
        Behavior on liftPos { NumberAnimation { duration: Theme.mIn; easing.type: Theme.mEase } }
        function peakY(i) { return tops[i % tops.length] - Theme.px(16) * Math.max(0, 1 - Math.abs(i - liftPos)); }

        // ridge points: peaks for the workspaces, then a calm far range across the rest
        readonly property var pts: {
            const w = width, p = [Qt.point(0, base + Theme.px(4)), Qt.point(x0 - step * 0.6, base - Theme.px(4))];
            for (let i = 0; i < ids.length; i++) {
                p.push(Qt.point(peakX(i), peakY(i)));
                p.push(Qt.point(peakX(i) + step * (0.45 + 0.1 * (i % 2)), base - (i % 3) * Theme.px(3)));
            }
            const far = [0.0, 6, 2, 9, 4, 11, 3, 8, 1, 7, 5, 10, 2, 6];
            let x = peakX(ids.length - 1) + step;
            let k = 0;
            while (x < w) {
                p.push(Qt.point(x, base + Theme.px(6) - Theme.px(far[k % far.length])));
                x += Theme.px(70 + 30 * ((k * 7) % 3)); k++;
            }
            p.push(Qt.point(w, base));
            return p;
        }

        Shape {
            id: ridge
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: bw.base
                    GradientStop { position: 0; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9) }
                    GradientStop { position: 1; color: Qt.rgba(Theme.bg1.r, Theme.bg1.g, Theme.bg1.b, 0.72) }
                }
                // one closed polyline: across the top, then back along the ridge
                PathPolyline { path: [Qt.point(0, 0), Qt.point(ridge.width, 0)].concat(bw.pts.slice().reverse()).concat([Qt.point(0, 0)]) }
            }
            ShapePath {
                strokeColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.42)
                strokeWidth: 1.2
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: bw.pts }
            }
        }

        // the theme mark at the far left
        Text {
            x: Theme.px(16); y: Theme.px(9)
            text: Theme.kanji; color: Theme.accent; font.family: Theme.serif; font.pixelSize: Theme.px(17); font.weight: Font.Bold
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
        }

        // a peak per workspace: number above it, snow cap and glow on the active one
        Repeater {
            model: bw.ids
            delegate: Item {
                id: pk
                required property int modelData
                required property int index
                readonly property bool on: modelData === bw.focusedId
                readonly property bool used: bw.windows(modelData) > 0
                readonly property real px0: bw.peakX(index)
                readonly property real py0: bw.peakY(index)
                x: px0 - Theme.px(20); y: 0
                width: Theme.px(40); height: py0 + Theme.px(14)
                Rectangle {
                    visible: pk.on
                    x: pk.width / 2 - width / 2; y: pk.py0 - height / 2
                    width: Theme.px(26); height: width; radius: width / 2
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                }
                Shape {
                    visible: pk.on
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.hi; strokeWidth: Theme.px(2.2); fillColor: "transparent"
                        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                        startX: pk.width / 2 - Theme.px(9); startY: pk.py0 + Theme.px(6.5)
                        PathLine { x: pk.width / 2; y: pk.py0 }
                        PathLine { x: pk.width / 2 + Theme.px(9); y: pk.py0 + Theme.px(6.5) }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: pk.py0 - Theme.px(19)
                    text: String(pk.modelData).padStart(2, "0")
                    color: pk.on ? Theme.hi : (pk.used ? Theme.fg : Theme.mute)
                    font.family: Theme.head; font.pixelSize: Theme.px(12); font.letterSpacing: Theme.px(0.8)
                    font.weight: pk.on ? Font.Bold : Font.Normal
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + pk.modelData)
                }
            }
        }
        WheelHandler { onWheel: (e) => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1") }

        // clock
        Item {
            id: clock
            anchors { right: icons.left; rightMargin: Theme.px(18) }
            y: Theme.px(3)
            width: crow.implicitWidth + Theme.px(16); height: Theme.px(30)
            readonly property var d: Dev.clockDate
            Row {
                id: crow
                anchors.centerIn: parent
                spacing: Theme.px(12)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.d, "HH:mm")
                    color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(20); font.weight: Font.Light; font.letterSpacing: Theme.px(2.5)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: clock.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd MMM").replace(/\./g, "").toUpperCase()
                    color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(10.5); font.letterSpacing: Theme.px(2.2)
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("calendar", clock.mapToItem(null, clock.width / 2, 0).x) }
        }

        Row {
            id: icons
            anchors { right: parent.right; rightMargin: Theme.px(14) }
            y: Theme.px(3)
            height: Theme.px(30)
            spacing: Theme.px(1)
            ModDnd { anchors.verticalCenter: parent.verticalCenter; visible: Ui.dnd }
            ModNet { anchors.verticalCenter: parent.verticalCenter; text: "" }
            ModBt { anchors.verticalCenter: parent.verticalCenter; text: "" }
            ModVol { anchors.verticalCenter: parent.verticalCenter; text: "" }
            ModBatRing { anchors.verticalCenter: parent.verticalCenter; ringSize: Theme.px(20); color: "transparent" }
        }
    }
}
