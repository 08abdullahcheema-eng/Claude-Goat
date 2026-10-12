import QtQuick
import Quickshell

// One bar per screen, in whichever layout is active. Switching layouts swaps the windows live.
Scope {
    id: host
    required property var modelData
    LazyLoader { active: Theme.layout === "islands"; LayoutIslands { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "bottom"; LayoutBottom { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "corners"; LayoutCorners { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "notch"; LayoutNotch { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "rail"; LayoutRail { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "pill"; LayoutPill { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "capsule"; LayoutCapsule { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "dune"; LayoutDune { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "side"; LayoutSide { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "horizon"; LayoutHorizon { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "ridge"; LayoutRidge { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "float"; LayoutFloat { screenRef: host.modelData } }
    LazyLoader { active: Theme.layout === "stars"; LayoutStars { screenRef: host.modelData } }
}
