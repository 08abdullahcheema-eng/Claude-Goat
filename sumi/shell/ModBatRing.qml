import QtQuick
// Battery ring, opens the battery panel. showPct adds the percentage next to the ring.
Pill {
    id: m
    property real ringSize: Theme.px(22)
    property bool showPct: false
    property bool ringText: !showPct
    visible: Dev.hasBattery
    text: showPct ? Dev.batPct + "%" : ""
    textColor: Theme.fg
    pad: Theme.px(6)
    active: Ui.panel === "battery"
    lead: Component { BatRing { implicitWidth: m.ringSize; showText: m.ringText } }
    onClicked: Ui.toggleAt("battery", centerX())
}
