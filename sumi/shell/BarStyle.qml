pragma Singleton
import QtQuick
import Quickshell

// How bar items look in the active layout. Every Pill reads its defaults from here.
Singleton {
    readonly property string l: Theme.pickLayout !== "" ? Theme.pickLayout : Theme.layout   // the picker previews a layout
    readonly property bool labels: l === "rail" || l === "corners" || l === "bottom"
    readonly property bool caps: labels || l === "ridge"
    readonly property string fontFamily: l === "bottom" ? Theme.head : Theme.body
    readonly property int fontSize: l === "bottom" ? Theme.px(17)
        : (l === "rail" || l === "corners") ? Theme.px(10.5)
        : l === "capsule" ? Theme.px(12.5)
        : l === "ridge" ? Theme.px(12)
        : Theme.fsm
    readonly property real letterSpacing: l === "ridge" ? Theme.px(1.2) : l === "bottom" ? Theme.px(1.2) : (l === "rail" || l === "corners") ? Theme.px(1.8) : 0
    readonly property string activeStyle: l === "bottom" ? "fill" : (l === "rail" || l === "corners" || l === "ridge") ? "line" : "box"
    readonly property real itemH: l === "rail" ? Theme.px(22) : l === "corners" ? Theme.px(24) : l === "bottom" ? Theme.px(36)
        : l === "capsule" ? Theme.px(30) : l === "side" ? Theme.px(32)
        : l === "ridge" ? Theme.px(28)
        : Theme.barH - Theme.px(8)
    readonly property real radius: l === "bottom" ? 0 : (l === "pill" || l === "capsule") ? itemH / 2 : (l === "rail" || l === "corners") ? Theme.px(3) : Theme.px(8)
    readonly property real pad: labels ? Theme.px(7) : (l === "side" ? Theme.px(4) : l === "ridge" ? Theme.px(7) : Theme.px(10))
    readonly property string wsMode: l === "islands" ? ((Theme.p.barFx ?? "") === "neon" ? "text" : "pill") : (l === "notch" || l === "capsule") ? "dots" : l === "pill" ? "circles" : l === "bottom" ? "blocks" : "text"
}
