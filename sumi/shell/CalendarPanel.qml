import QtQuick
import Quickshell

// Month calendar, Monday first, with ISO week numbers.
// Keys: left/right month, up/down year, T or Home back to today, scroll wheel changes month.
Item {
    id: root
    anchors.fill: parent
    focus: true

    readonly property var now: Theme.demo ? new Date(2026, 9, 9, 8, 12) : new Date()
    property int year: now.getFullYear()
    property int month: now.getMonth()
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7

    readonly property var months: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    readonly property var dayShort: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    readonly property var dayLong: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]

    function shift(n) {
        const d = new Date(year, month + n, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }
    function today() { year = now.getFullYear(); month = now.getMonth(); }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const dn = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - dn);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }
    function focusFirst() { root.forceActiveFocus(); }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_PageUp) { shift(-1); e.accepted = true; }
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_PageDown) { shift(1); e.accepted = true; }
        else if (e.key === Qt.Key_Up) { shift(-12); e.accepted = true; }
        else if (e.key === Qt.Key_Down) { shift(12); e.accepted = true; }
        else if (e.key === Qt.Key_T || e.key === Qt.Key_Home) { today(); e.accepted = true; }
    }

    Card {
        id: card
        width: Theme.px(344)
        x: Ui.calX < 0
            ? (parent.width - width) / 2
            : Math.max(Theme.px(10), Math.min(parent.width - width - Theme.px(10), Ui.calX - width / 2))
        y: Theme.px(8)
        pad: Theme.px(16)

        Column {
            width: parent.width
            spacing: Theme.px(10)

            // title and navigation
            Item {
                width: parent.width; height: Theme.px(28)
                T {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.months[root.month] + " " + root.year
                    color: Theme.hi; font.pixelSize: Theme.px(16)
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(4)
                    Repeater {
                        model: [{ t: "‹", d: -1 }, { t: "Heute", d: 0 }, { t: "›", d: 1 }]
                        delegate: Rectangle {
                            required property var modelData
                            width: modelData.d === 0 ? Theme.px(54) : Theme.px(28); height: Theme.px(26)
                            radius: Theme.px(5)
                            color: nm.containsMouse ? Theme.bg2 : "transparent"
                            border.width: 1; border.color: Theme.line2
                            T { anchors.centerIn: parent; text: parent.modelData.t; color: Theme.fg; font.pixelSize: parent.modelData.d === 0 ? Theme.fsm : Theme.px(16) }
                            MouseArea {
                                id: nm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.d === 0 ? root.today() : root.shift(parent.modelData.d)
                            }
                        }
                    }
                }
            }

            // week number column + 7 days, 6 rows
            Grid {
                id: grid
                width: parent.width
                columns: 8
                WheelHandler { onWheel: (e) => root.shift(e.angleDelta.y > 0 ? -1 : 1) }

                Repeater {
                    model: 56
                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property int r: Math.floor(index / 8) - 1   // -1 = header row
                        readonly property int c: index % 8                   // 0 = week number
                        readonly property var d: new Date(root.year, root.month, 1 - root.offset + r * 7 + (c - 1))
                        readonly property bool inMonth: r >= 0 && c > 0 && d.getMonth() === root.month
                        readonly property bool isToday: r >= 0 && c > 0
                            && d.getFullYear() === root.now.getFullYear()
                            && d.getMonth() === root.now.getMonth()
                            && d.getDate() === root.now.getDate()
                        width: grid.width / 8; height: Theme.px(32)

                        Rectangle {
                            anchors.centerIn: parent
                            width: Theme.px(28); height: Theme.px(28); radius: Theme.px(6)
                            visible: cell.isToday
                            color: Theme.accent
                        }
                        T {
                            anchors.centerIn: parent
                            font.pixelSize: cell.r < 0 ? Theme.px(10) : Theme.fsm
                            text: {
                                if (cell.r < 0) return cell.c === 0 ? "KW" : root.dayShort[cell.c - 1];
                                if (cell.c === 0) return root.isoWeek(new Date(root.year, root.month, 1 - root.offset + cell.r * 7 + 3)) + "";
                                return cell.d.getDate() + "";
                            }
                            color: {
                                if (cell.r < 0 || cell.c === 0) return Theme.mute;
                                if (cell.isToday) return Theme.onAccent;
                                if (!cell.inMonth) return Theme.mute;
                                return cell.c >= 6 ? Theme.accent2 : Theme.fg;
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: cell.r >= 0 && cell.c > 0 && !cell.inMonth
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shift(cell.d.getFullYear() * 12 + cell.d.getMonth() > root.year * 12 + root.month ? 1 : -1)
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.line }
            T {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.dayLong[root.now.getDay()] + ", " + root.now.getDate() + ". " + root.months[root.now.getMonth()] + " " + root.now.getFullYear() + "  ·  KW " + root.isoWeek(root.now)
                color: Theme.dim; font.pixelSize: Theme.fsm
            }
        }
    }
}
