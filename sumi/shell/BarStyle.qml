pragma Singleton
import QtQuick
import Quickshell

// How bar items look in the active layout. Every Pill reads its defaults from here.
Singleton {
    readonly property string l: Theme.layout
    readonly property bool labels: l === "rail" || l === "corners" || l === "bottom"
    readonly property bool caps: labels || l === "horizon" || l === "ridge" || l === "stars"
    readonly property string fontFamily: (l === "bottom" || l === "horizon") ? Theme.head : Theme.body
    readonly property int fontSize: l === "bottom" ? Theme.px(17)
        : (l === "rail" || l === "corners") ? Theme.px(10.5)
        : l === "capsule" ? Theme.px(12.5)
        : l === "dune" ? Theme.px(12.5)
        : l === "horizon" ? Theme.px(12.5)
        : (l === "ridge" || l === "float") ? Theme.px(12)
        : l === "stars" ? Theme.px(11.5)
        : Theme.fsm
    readonly property real letterSpacing: l === "horizon" ? Theme.px(1.6) : l === "ridge" ? Theme.px(1.2) : l === "stars" ? Theme.px(0.8) : l === "bottom" ? Theme.px(1.2) : (l === "rail" || l === "corners") ? Theme.px(1.8) : 0
    readonly property string activeStyle: l === "bottom" ? "fill" : (l === "rail" || l === "corners" || l === "dune" || l === "horizon" || l === "ridge" || l === "stars") ? "line" : "box"
    readonly property real itemH: l === "rail" ? Theme.px(22) : l === "corners" ? Theme.px(24) : l === "bottom" ? Theme.px(36)
        : l === "capsule" ? Theme.px(30) : l === "dune" ? Theme.px(30) : l === "side" ? Theme.px(32)
        : (l === "horizon" || l === "float") ? Theme.px(30) : (l === "ridge" || l === "stars") ? Theme.px(28)
        : Theme.barH - Theme.px(8)
    readonly property real radius: l === "bottom" ? 0 : (l === "pill" || l === "capsule" || l === "float") ? itemH / 2 : (l === "rail" || l === "corners") ? Theme.px(3) : Theme.px(8)
    readonly property real pad: labels ? Theme.px(7) : (l === "side" ? Theme.px(4) : (l === "horizon" || l === "ridge" || l === "float" || l === "stars") ? Theme.px(7) : Theme.px(10))
    readonly property string wsMode: l === "islands" ? "pill" : (l === "notch" || l === "capsule") ? "dots" : l === "pill" ? "circles" : l === "bottom" ? "blocks" : l === "horizon" ? "roman" : l === "float" ? "romanlow" : l === "stars" ? "dots" : "text"
}
