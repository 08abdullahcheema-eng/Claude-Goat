import QtQuick
import Quickshell
import Quickshell.Wayland

// A full-width (or, on the left edge, full-height) bar surface on one edge of a screen. Layouts put their content inside.
// Clicking empty bar space closes an open panel; the window counts as "inside" for the panel grab.
PanelWindow {
    id: win
    property string edge: "top"
    property int reserve: Theme.barReserve
    anchors { left: true; right: edge !== "left"; top: edge !== "bottom"; bottom: edge !== "top" }
    implicitHeight: edge === "left" ? 0 : reserve
    implicitWidth: edge === "left" ? reserve : 0
    exclusiveZone: reserve
    color: "transparent"
    WlrLayershell.namespace: "sumi-bar"
    WlrLayershell.layer: WlrLayer.Top

    Component.onCompleted: Ui.barWindows = Ui.barWindows.concat([win])
    Component.onDestruction: Ui.barWindows = Ui.barWindows.filter(w => w !== win)

    MouseArea { anchors.fill: parent; z: -1; onClicked: Ui.close() }
}
