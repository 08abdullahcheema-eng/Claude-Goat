import QtQuick

// Panel surface. Swallows clicks so the overlay behind it doesn't close.
Rectangle {
    id: card
    default property alias content: inner.data
    property real pad: Theme.px(16)
    property color accentBorder: Theme.line2
    color: Theme.panelBg
    radius: Theme.px(10)
    border.width: 1
    border.color: accentBorder
    implicitHeight: inner.childrenRect.height + pad * 2

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
    }
}
