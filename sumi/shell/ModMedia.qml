import QtQuick

// Now playing: cover, title, artist and a progress line. Click plays or pauses,
// right click skips, middle click goes back. Hidden when no player has a track.
Rectangle {
    id: m
    property real maxTitle: Theme.px(150)
    property real barW: Theme.px(60)
    property color barColor: Theme.accent
    property color trackColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14)
    property bool showArtist: true
    property bool twoLines: false
    property real coverSize: Theme.px(20)
    property real coverRadius: Theme.px(5)
    property string fontFamily: BarStyle.fontFamily
    property int fontSize: BarStyle.fontSize
    visible: Media.active
    implicitHeight: BarStyle.itemH
    implicitWidth: row.implicitWidth + Theme.px(16)
    radius: BarStyle.radius
    color: ma.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(8)
        Cover { width: m.coverSize; height: m.coverSize; radius: m.coverRadius; anchors.verticalCenter: parent.verticalCenter
            opacity: Media.playing ? 1 : 0.55 }
        Column {
            visible: m.twoLines
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text { text: Media.title; color: Theme.hi; font.family: m.fontFamily; font.pixelSize: m.fontSize; width: Math.min(implicitWidth, m.maxTitle); elide: Text.ElideRight }
            Text { text: Media.artist + (Media.length > 0 ? " · " + Media.fmt(Media.position) : ""); color: Theme.dim; font.family: m.fontFamily; font.pixelSize: m.fontSize * 0.8; width: Math.min(implicitWidth, m.maxTitle); elide: Text.ElideRight }
        }
        Text {
            visible: !m.twoLines
            anchors.verticalCenter: parent.verticalCenter
            text: Media.title; color: Theme.hi; font.family: m.fontFamily; font.pixelSize: m.fontSize
            width: Math.min(implicitWidth, m.maxTitle); elide: Text.ElideRight
        }
        Text {
            visible: !m.twoLines && m.showArtist && Media.artist !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: Media.artist; color: Theme.dim; font.family: m.fontFamily; font.pixelSize: m.fontSize
            width: Math.min(implicitWidth, Theme.px(90)); elide: Text.ElideRight
        }
        Rectangle {
            visible: Media.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: m.barW; height: Theme.px(2.5); radius: height / 2
            color: m.trackColor
            Rectangle { width: parent.width * Media.progress; height: parent.height; radius: parent.radius; color: m.barColor
                Behavior on width { NumberAnimation { duration: 900 } } }
        }
        Icon { name: Media.playing ? "pause" : "play"; size: Theme.px(12); color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (e) => { if (e.button === Qt.RightButton) Media.next(); else if (e.button === Qt.MiddleButton) Media.previous(); else Media.toggle(); }
    }
}
