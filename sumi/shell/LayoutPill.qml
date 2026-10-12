import QtQuick
import QtQuick.Shapes
import Quickshell
import QtQuick.Effects

// Pill: one floating capsule at the bottom centre, battery as a ring.
Scope {
    id: lay
    required property var screenRef

    BarWindow {
        screen: lay.screenRef
        edge: "bottom"
        // electric: a violet glow around the capsule
        MultiEffect {
            visible: (Theme.p.barFx ?? "") === "electric"
            anchors.fill: cap
            source: cap
            shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 0.9; shadowOpacity: 0.55
        }
        Rectangle {
            id: cap
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(9) }
            height: Theme.px(42)
            width: row.implicitWidth + Theme.px(28)
            radius: height / 2
            color: Theme.barBg
            border.width: 1
            border.color: (Theme.p.barFx ?? "") === "electric" ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45) : Theme.line
            Row {
                id: row
                anchors.centerIn: parent
                height: BarStyle.itemH
                spacing: Theme.px(4)
                Logo { anchors.verticalCenter: parent.verticalCenter; size: Theme.px(20) }
                Workspaces { anchors.verticalCenter: parent.verticalCenter; screenName: lay.screenRef.name }
                Sep { anchors.verticalCenter: parent.verticalCenter }
                ModClock { anchors.verticalCenter: parent.verticalCenter; showDate: false; timeFont: Theme.head; timeSize: Theme.px(16); timeWeight: Font.Bold }
                Sep { anchors.verticalCenter: parent.verticalCenter }
                ModMedia { anchors.verticalCenter: parent.verticalCenter; maxTitle: Theme.px(120); barW: Theme.px(44) }
                Sep { anchors.verticalCenter: parent.verticalCenter; visible: Media.active }
                ModFan { anchors.verticalCenter: parent.verticalCenter }
                ModCpuCurve { anchors.verticalCenter: parent.verticalCenter }
                ModAgent { anchors.verticalCenter: parent.verticalCenter }
                ModNet { anchors.verticalCenter: parent.verticalCenter }
                ModBt { anchors.verticalCenter: parent.verticalCenter }
                ModVol { anchors.verticalCenter: parent.verticalCenter }
                ModMic { anchors.verticalCenter: parent.verticalCenter }
                ModDnd { anchors.verticalCenter: parent.verticalCenter }
                // battery ring
                Item {
                    visible: Dev.hasBattery
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.px(30); height: width
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath { strokeColor: Theme.line2; strokeWidth: Theme.px(3); fillColor: "transparent"
                            PathAngleArc { centerX: Theme.px(15); centerY: Theme.px(15); radiusX: Theme.px(12); radiusY: Theme.px(12); startAngle: 0; sweepAngle: 360 } }
                        ShapePath { strokeColor: Dev.batColor; strokeWidth: Theme.px(3); fillColor: "transparent"; capStyle: ShapePath.RoundCap
                            PathAngleArc { centerX: Theme.px(15); centerY: Theme.px(15); radiusX: Theme.px(12); radiusY: Theme.px(12); startAngle: -90; sweepAngle: 3.6 * Dev.batPct } }
                    }
                    Text { anchors.centerIn: parent; text: Dev.batPct; color: Theme.fg; font.family: Theme.head; font.pixelSize: Theme.px(9); font.weight: Font.Bold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleAt("battery", mapToItem(null, width / 2, 0).x) }
                }
                ModPower { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
