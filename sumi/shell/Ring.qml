import QtQuick
import QtQuick.Shapes

// Circular gauge with a 270 degree sweep. value is 0..1, children are drawn in the middle.
Item {
    id: r
    property real value: 0
    property color color: Theme.accent
    property color track: Theme.line
    property real thickness: Theme.px(9)
    default property alias content: holder.data
    implicitWidth: Theme.px(110)
    height: width

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: r.track
            strokeWidth: r.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: r.width / 2; centerY: r.height / 2
                radiusX: (r.width - r.thickness) / 2; radiusY: (r.height - r.thickness) / 2
                startAngle: 135; sweepAngle: 270
            }
        }
        ShapePath {
            strokeColor: r.shown > 0.005 ? r.color : "transparent"
            strokeWidth: r.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: r.width / 2; centerY: r.height / 2
                radiusX: (r.width - r.thickness) / 2; radiusY: (r.height - r.thickness) / 2
                startAngle: 135; sweepAngle: 270 * r.shown
            }
        }
    }
    Item { id: holder; anchors.fill: parent }
}
