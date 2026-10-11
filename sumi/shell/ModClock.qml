import QtQuick
// Clock, opens the calendar. "parts" chooses what is shown.
Pill {
    id: clk
    property bool showDate: true
    property bool showKanji: false
    property int timeSize: Theme.fmd
    property string timeFont: Theme.body
    property int timeWeight: Font.DemiBold
    readonly property var d: Dev.clockDate
    active: Ui.panel === "calendar"
    implicitWidth: crow.implicitWidth + pad * 2
    onClicked: Ui.toggleAt("calendar", centerX())
    Row {
        id: crow
        anchors.centerIn: parent
        spacing: Theme.px(9)
        Text { text: Qt.formatTime(clk.d, "HH:mm"); color: Theme.hi; font.family: clk.timeFont; font.pixelSize: clk.timeSize; font.weight: clk.timeWeight; anchors.verticalCenter: parent.verticalCenter }
        Text {
            visible: clk.showDate
            text: { const s = clk.d.toLocaleDateString(Qt.locale("de_DE"), "ddd dd MMM").replace(/\./g, ""); return clk.caps ? s.toUpperCase() : s; }
            color: Theme.dim; font.family: clk.fontFamily; font.pixelSize: clk.fontSize; font.letterSpacing: clk.letterSpacing
            anchors.verticalCenter: parent.verticalCenter
        }
        Text { visible: clk.showKanji; text: ["日", "月", "火", "水", "木", "金", "土"][clk.d.getDay()]; color: Theme.accent; font.family: Theme.serif; font.pixelSize: Theme.fsm; anchors.verticalCenter: parent.verticalCenter }
    }
}
