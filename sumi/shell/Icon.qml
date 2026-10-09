import QtQuick
import QtQuick.Shapes
import "icons.js" as Icons

// Stroke icon drawn from a 24x24 SVG path, recolourable.
Item {
    id: root
    property string name: "app"
    property color color: Theme.fg
    property real size: Theme.px(16)
    property real stroke: 1.8
    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Icons.paths[root.name] ?? Icons.paths["app"] }
        }
    }
}
