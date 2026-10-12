import QtQuick
// CPU as a live curve plus the current percentage, opens the system panel.
Pill {
    id: m
    property color curveColor: Theme.accent2
    property real curveWidth: Theme.px(58)
    property bool curveFill: true
    label: "cpu"
    text: Sys.cpu + "%"
    textColor: Theme.fg
    active: Ui.panel === "system"
    lead: Component { CpuCurve { color: m.curveColor; width: m.curveWidth; height: Theme.px(16); fill: m.curveFill } }
    onClicked: Ui.toggleAt("system", centerX())
}
