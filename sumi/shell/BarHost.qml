import QtQuick
import Quickshell

// One bar per screen, in whichever layout is active. Switching layouts swaps the windows live.
Scope {
    id: host
    required property var modelData
    property bool preview: false                 // the copy shown above the theme picker
    readonly property string want: preview ? Theme.pickLayout : Theme.layout
    LazyLoader { active: host.want === "islands"; LayoutIslands { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "bottom"; LayoutBottom { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "corners"; LayoutCorners { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "notch"; LayoutNotch { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "rail"; LayoutRail { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "pill"; LayoutPill { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "capsule"; LayoutCapsule { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "side"; LayoutSide { screenRef: host.modelData; preview: host.preview } }
    LazyLoader { active: host.want === "ridge"; LayoutRidge { screenRef: host.modelData; preview: host.preview } }
}
