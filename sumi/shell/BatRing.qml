import QtQuick
import QtQuick.Shapes

// Battery as a full ring, the percentage inside. Charging shows a small bolt instead of the number.
Item {
    id: r
    property real value: Dev.batPct / 100
    property color color: Dev.batColor
    property color track: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.16)
    property real thickness: Math.max(2, width * 0.11)
    property bool showText: true
    property color textColor: Theme.hi
    implicitWidth: Theme.px(24)
    implicitHeight: implicitWidth
    width: implicitWidth; height: width

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: r.track; strokeWidth: r.thickness; fillColor: "transparent"
            PathAngleArc { centerX: r.width / 2; centerY: r.height / 2; radiusX: (r.width - r.thickness) / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: r.shown > 0.005 ? r.color : "transparent"; strokeWidth: r.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: r.width / 2; centerY: r.height / 2; radiusX: (r.width - r.thickness) / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * r.shown }
        }
    }
    Text {
        visible: r.showText
        anchors.centerIn: parent
        text: Dev.charging ? "⚡" : Math.round(r.value * 100)
        color: r.textColor
        font.family: Theme.body
        font.pixelSize: r.width * (Dev.charging ? 0.42 : 0.36)
        font.weight: Font.Bold
    }
}
