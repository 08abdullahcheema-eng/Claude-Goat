import QtQuick
import QtQuick.Effects

// Album art with rounded corners (or a round disc); a soft accent gradient when there is no art.
Item {
    id: c
    property real radius: Theme.px(5)
    property string source: Media.art
    implicitWidth: Theme.px(22); implicitHeight: implicitWidth
    Rectangle {
        id: fallback
        anchors.fill: parent
        radius: c.radius
        visible: img.status !== Image.Ready
        gradient: Gradient { orientation: Gradient.Vertical
            GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
    }
    Image {
        id: img
        anchors.fill: parent
        source: c.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width * 2, height * 2)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: c.radius; color: "black" }
    }
}
