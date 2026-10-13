import QtQuick

// Panel surface. Swallows clicks so the overlay behind it doesn't close.
// When it appears it plays the theme's second beat: the surface lands first (Overlay.qml),
// then the content follows. Sumi and Summit flash the border with the accent, Hagane
// runs a hairline across the top edge.
Rectangle {
    id: card
    default property alias content: inner.data
    property real pad: Theme.px(16)
    property color accentBorder: Theme.line2
    property bool intro: true
    color: Theme.panelBg
    radius: Theme.px(10)
    border.width: 1
    border.color: Qt.tint(accentBorder, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, card.flash * 0.85))
    implicitHeight: inner.childrenRect.height + pad * 2

    property real flash: 0
    property real beat: intro && Theme.mStagger > 0 ? 0 : 1
    property real scan: 0

    // soft drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: -Theme.px(1)
        anchors.topMargin: Theme.px(6)
        anchors.bottomMargin: -Theme.px(14)
        radius: parent.radius + Theme.px(4)
        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.35 : 0.12)
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => w.accepted = false }
    Item {
        id: inner
        anchors { fill: parent; margins: card.pad }
        opacity: card.beat
        transform: Translate { y: (1 - card.beat) * Theme.mDist * 0.5 }
    }

    // hagane: a bright hairline runs along the top edge once
    Rectangle {
        visible: card.scan > 0 && card.scan < 1
        x: card.radius; y: 0
        width: (card.width - card.radius * 2) * card.scan; height: 1
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.85; color: Theme.accent }
            GradientStop { position: 1; color: Theme.hi } }
    }

    SequentialAnimation {
        running: card.intro && Theme.mStagger > 0
        PauseAnimation { duration: Theme.mStagger }
        NumberAnimation { target: card; property: "beat"; to: 1; duration: Theme.mMed; easing.type: Theme.mStyle === "wave" ? Easing.OutBack : Easing.OutCubic }
    }
    SequentialAnimation {
        running: card.intro && (Theme.mStyle === "bloom" || Theme.mStyle === "descend")
        NumberAnimation { target: card; property: "flash"; from: 0; to: 1; duration: Math.round(Theme.mIn * 0.4); easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "flash"; to: 0; duration: Theme.mMed * 3; easing.type: Easing.InOutSine }
    }
    NumberAnimation {
        running: card.intro && Theme.mStyle === "wipe"
        target: card; property: "scan"; from: 0.001; to: 1; duration: 340; easing.type: Easing.OutCubic
        onFinished: card.scan = 0
    }
}
