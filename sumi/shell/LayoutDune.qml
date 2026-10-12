import QtQuick
import QtQuick.Shapes
import Quickshell

// Dune: the bar is a sand dune along the bottom edge, rising under the clock in the middle.
// Workspaces and music on the left, CPU curve, controls and a battery ring on the right.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        id: bw
        screen: lay.screenRef
        edge: "bottom"
        readonly property real crest: Theme.px(2)     // top of the dune in the middle
        readonly property real flank: Theme.px(20)    // height of the dune edge at the screen sides

        Shape {
            id: dune
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real w: width
            readonly property real h: height
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: dune.h
                    GradientStop { position: 0; color: Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.62) }
                    GradientStop { position: 1; color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.86) }
                }
                startX: 0; startY: dune.h
                PathLine { x: 0; y: bw.flank + Theme.px(4) }
                PathCubic { x: dune.w * 0.4; y: bw.flank; control1X: dune.w * 0.16; control1Y: bw.flank + Theme.px(8); control2X: dune.w * 0.3; control2Y: bw.flank + Theme.px(2) }
                PathCubic { x: dune.w * 0.5; y: bw.crest; control1X: dune.w * 0.45; control1Y: bw.flank - Theme.px(2); control2X: dune.w * 0.46; control2Y: bw.crest }
                PathCubic { x: dune.w * 0.6; y: bw.flank; control1X: dune.w * 0.54; control1Y: bw.crest; control2X: dune.w * 0.55; control2Y: bw.flank - Theme.px(2) }
                PathCubic { x: dune.w; y: bw.flank + Theme.px(2); control1X: dune.w * 0.72; control1Y: bw.flank + Theme.px(4); control2X: dune.w * 0.86; control2Y: bw.flank + Theme.px(9) }
                PathLine { x: dune.w; y: dune.h }
                PathLine { x: 0; y: dune.h }
            }
            // the ridge line
            ShapePath {
                strokeColor: Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.5)
                strokeWidth: 1.2
                fillColor: "transparent"
                startX: 0; startY: bw.flank + Theme.px(4)
                PathCubic { x: dune.w * 0.4; y: bw.flank; control1X: dune.w * 0.16; control1Y: bw.flank + Theme.px(8); control2X: dune.w * 0.3; control2Y: bw.flank + Theme.px(2) }
                PathCubic { x: dune.w * 0.5; y: bw.crest; control1X: dune.w * 0.45; control1Y: bw.flank - Theme.px(2); control2X: dune.w * 0.46; control2Y: bw.crest }
                PathCubic { x: dune.w * 0.6; y: bw.flank; control1X: dune.w * 0.54; control1Y: bw.crest; control2X: dune.w * 0.55; control2Y: bw.flank - Theme.px(2) }
                PathCubic { x: dune.w; y: bw.flank + Theme.px(2); control1X: dune.w * 0.72; control1Y: bw.flank + Theme.px(4); control2X: dune.w * 0.86; control2Y: bw.flank + Theme.px(9) }
            }
        }
        // clicks above the dune line fall through to empty bar space (closes panels)

        // clock on the crest
        Item {
            id: clock
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(9) }
            width: Math.max(t1.implicitWidth, t2.implicitWidth) + Theme.px(24)
            height: t1.implicitHeight + t2.implicitHeight
            readonly property var d: Dev.clockDate
            Column {
                anchors.centerIn: parent
                spacing: -Theme.px(2)
                Text {
                    id: t1
                    anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.StyledText
                    text: Qt.formatTime(clock.d, "HH") + "<font color='" + Theme.accent + "'>:</font>" + Qt.formatTime(clock.d, "mm")
                    color: Theme.hi; font.family: Theme.head; font.pixelSize: Theme.px(25); font.weight: Font.Bold
                }
                Text {
                    id: t2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.d.toLocaleDateString(Qt.locale("de_DE"), "ddd · dd MMM").replace(/\./g, "").toUpperCase()
                    color: Theme.dim; font.family: Theme.body; font.pixelSize: Theme.px(9.5); font.letterSpacing: Theme.px(2.5)
                }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: Ui.toggleAt("calendar", clock.mapToItem(null, clock.width / 2, 0).x)
            }
        }

        Row {
            anchors { left: parent.left; leftMargin: Theme.px(18); bottom: parent.bottom; bottomMargin: Theme.px(9) }
            height: BarStyle.itemH
            spacing: Theme.px(8)
            Text {
                text: Theme.kanji; color: Theme.accent; font.family: Theme.head; font.pixelSize: Theme.px(20); font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggle("launcher") }
            }
            Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
            Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active }
            ModMedia {
                anchors.verticalCenter: parent.verticalCenter
                twoLines: true; coverSize: Theme.px(26); coverRadius: Theme.px(13); barW: Theme.px(70)
                barColor: Theme.accent; maxTitle: Theme.px(150)
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(14); bottom: parent.bottom; bottomMargin: Theme.px(9) }
            height: BarStyle.itemH
            spacing: Theme.px(2)
            ModCpuCurve { anchors.verticalCenter: parent.verticalCenter; curveColor: Theme.accent; curveWidth: Theme.px(64) }
            ModFan { anchors.verticalCenter: parent.verticalCenter }
            ModAgent { anchors.verticalCenter: parent.verticalCenter }
            Sep { anchors.verticalCenter: parent.verticalCenter }
            ModNet { anchors.verticalCenter: parent.verticalCenter }
            ModBt { anchors.verticalCenter: parent.verticalCenter }
            ModVol { anchors.verticalCenter: parent.verticalCenter }
            ModMic { anchors.verticalCenter: parent.verticalCenter }
            ModDnd { anchors.verticalCenter: parent.verticalCenter }
            KbdLayout { anchors.verticalCenter: parent.verticalCenter }
            ModBatRing { anchors.verticalCenter: parent.verticalCenter; ringSize: Theme.px(26) }
            ModPower { anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
