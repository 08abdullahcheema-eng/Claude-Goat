import QtQuick
// Keyboard layout indicator (DE, US...).
Row {
    visible: Sys.layout !== ""
    spacing: Theme.px(5)
    leftPadding: Theme.px(6); rightPadding: Theme.px(4)
    Icon { visible: !BarStyle.labels; name: "kbd"; color: Theme.dim; size: Theme.px(14); anchors.verticalCenter: parent.verticalCenter }
    Text { text: Sys.layout; color: Theme.dim; font.family: BarStyle.fontFamily; font.pixelSize: BarStyle.fontSize; font.letterSpacing: BarStyle.letterSpacing; anchors.verticalCenter: parent.verticalCenter }
}
