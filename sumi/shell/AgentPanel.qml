import QtQuick
import Quickshell

// Claude Code usage: plan limits, tokens by day, sessions.
Item {
    id: root
    anchors.fill: parent
    property int hover: -1

    readonly property real maxDay: Math.max(1, ...Agents.days.map(d => d.cache + d.input + d.output))

    Card {
        id: card
        width: Theme.px(462)
        x: Math.max(Theme.px(10), Math.min(parent.width - width - Theme.px(10), parent.width / 2 - Theme.px(150)))
        y: Theme.px(8)
        pad: Theme.px(17)

        Column {
            width: parent.width
            spacing: Theme.px(14)

            Item {
                width: parent.width; height: Theme.px(26)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "agent"; color: Theme.gold; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Agents"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "代理"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle {
                    visible: Agents.plan !== ""
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: pl.implicitWidth + Theme.px(16); height: Theme.px(22); radius: Theme.px(4)
                    color: "transparent"; border.width: 1; border.color: Theme.gold
                    T { id: pl; anchors.centerIn: parent; text: "Claude " + Agents.plan; color: Theme.gold; font.pixelSize: Theme.px(10.5) }
                }
            }

            Row {
                spacing: Theme.px(6)
                Rectangle {
                    width: cc.implicitWidth + Theme.px(20); height: Theme.px(26); radius: Theme.px(4); color: Theme.bg2
                    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Theme.px(2); color: Theme.accent }
                    T { id: cc; anchors.centerIn: parent; text: "Claude Code"; color: Theme.hi; font.pixelSize: Theme.fsm }
                }
                T { text: Agents.running > 0 ? "● " + Agents.running + " running" : ""; color: Theme.green; font.pixelSize: Theme.px(10.5); anchors.verticalCenter: parent.verticalCenter; leftPadding: Theme.px(8) }
            }

            T {
                visible: !Agents.installed
                width: parent.width; wrapMode: Text.Wrap
                text: "Claude Code isn't set up on this machine yet (~/.claude is missing). Run `claude` once and sign in."
                color: Theme.dim; font.pixelSize: Theme.fsm
            }

            Meter {
                visible: Agents.fivePct >= 0
                width: parent.width
                title: "5-hour window"; pct: Agents.fivePct; barColor: Theme.accent
                sub: Agents.fmtReset(Agents.fiveReset, false)
            }
            Meter {
                visible: Agents.weekPct >= 0
                width: parent.width
                title: "Weekly"; pct: Agents.weekPct; barColor: Theme.gold
                sub: Agents.fmtReset(Agents.weekReset, true)
            }
            T {
                visible: Agents.installed && Agents.fivePct < 0
                width: parent.width; wrapMode: Text.Wrap
                text: Agents.loading ? "loading limits…" : "Plan limits unavailable (sign in with `claude` to see them). Token counts below are from your local sessions."
                color: Theme.mute; font.pixelSize: Theme.px(10.5)
            }

            Item {
                width: parent.width; height: Theme.px(14)
                Label { text: "Tokens by day"; anchors.verticalCenter: parent.verticalCenter }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(10)
                    Repeater {
                        model: [["cache", Theme.gold], ["in", Theme.blue], ["out", Theme.accent]]
                        delegate: Row {
                            required property var modelData
                            spacing: Theme.px(4)
                            Rectangle { width: Theme.px(7); height: width; color: modelData[1]; anchors.verticalCenter: parent.verticalCenter }
                            T { text: modelData[0]; color: Theme.mute; font.pixelSize: Theme.px(10) }
                        }
                    }
                }
            }

            // bars
            Item {
                width: parent.width
                height: Theme.px(150)
                Row {
                    id: bars
                    anchors.fill: parent
                    spacing: Theme.px(8)
                    readonly property real colW: (width - spacing * 6) / 7
                    Repeater {
                        model: Agents.days
                        delegate: Item {
                            id: dayD
                            required property var modelData
                            required property int index
                            width: bars.colW; height: bars.height
                            readonly property bool today: index === Agents.days.length - 1
                            readonly property bool lit: root.hover === index || (root.hover < 0 && today)
                            readonly property real total: modelData.cache + modelData.input + modelData.output
                            readonly property real hMax: height - Theme.px(22)
                            readonly property real hh: total > 0 ? Math.max(Theme.px(3), total / root.maxDay * hMax) : 0
                            Rectangle {
                                anchors.fill: parent; anchors.bottomMargin: -Theme.px(2)
                                visible: dayD.lit
                                color: "transparent"; radius: Theme.px(4)
                                border.width: 1; border.color: Theme.line2
                            }
                            Column {
                                anchors { bottom: parent.bottom; bottomMargin: Theme.px(20); horizontalCenter: parent.horizontalCenter }
                                width: Math.min(Theme.px(34), parent.width - Theme.px(8))
                                Rectangle { width: parent.width; height: dayD.total ? dayD.hh * dayD.modelData.output / dayD.total : 0; color: Theme.accent; opacity: dayD.lit ? 1 : 0.55 }
                                Rectangle { width: parent.width; height: dayD.total ? dayD.hh * dayD.modelData.input / dayD.total : 0; color: Theme.blue; opacity: dayD.lit ? 1 : 0.55 }
                                Rectangle { width: parent.width; height: dayD.total ? dayD.hh * dayD.modelData.cache / dayD.total : 0; color: Theme.gold; opacity: dayD.lit ? 1 : 0.55 }
                            }
                            T {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                text: dayD.modelData.label; font.pixelSize: Theme.px(10.5)
                                color: dayD.lit ? Theme.hi : Theme.mute
                            }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: root.hover = dayD.index; onExited: if (root.hover === dayD.index) root.hover = -1 }
                        }
                    }
                }
                // tooltip for the highlighted day
                Rectangle {
                    id: tip
                    readonly property int idx: root.hover >= 0 ? root.hover : Agents.days.length - 1
                    readonly property var d: Agents.days[idx]
                    visible: !!d && (d.cache + d.input + d.output) > 0
                    width: tipCol.implicitWidth + Theme.px(20); height: tipCol.implicitHeight + Theme.px(14)
                    radius: Theme.px(5); color: Theme.bg; border.width: 1; border.color: Theme.line2
                    x: {
                        const cx = idx * (bars.colW + bars.spacing);
                        return cx > parent.width / 2 ? cx - width - Theme.px(6) : cx + bars.colW + Theme.px(6);
                    }
                    y: 0
                    Column {
                        id: tipCol
                        anchors.centerIn: parent
                        spacing: Theme.px(2)
                        T { text: tip.d ? tip.d.label + " " + tip.d.dateLabel + " · " + Agents.fmtTokens(tip.d.cache + tip.d.input + tip.d.output) + " tokens" : ""; color: Theme.hi; font.pixelSize: Theme.px(10.5) }
                        T { text: tip.d ? "■ cache  " + Agents.fmtTokens(tip.d.cache) : ""; color: Theme.gold; font.pixelSize: Theme.px(10) }
                        T { text: tip.d ? "■ input  " + Agents.fmtTokens(tip.d.input) : ""; color: Theme.blue; font.pixelSize: Theme.px(10) }
                        T { text: tip.d ? "■ output " + Agents.fmtTokens(tip.d.output) : ""; color: Theme.accent; font.pixelSize: Theme.px(10) }
                        T {
                            text: {
                                if (!tip.d || !tip.d.models) return "";
                                const m = tip.d.models, tot = Object.values(m).reduce((a, b) => a + b, 0);
                                if (!tot) return "";
                                return Object.keys(m).sort((a, b) => m[b] - m[a]).map(k => k + " " + Math.round(m[k] / tot * 100) + "%").join(" · ");
                            }
                            color: Theme.mute; font.pixelSize: Theme.px(10)
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.px(8)
                readonly property real w3: (width - spacing * 2) / 3
                Stat { width: parent.w3; label: "this week"; value: Agents.fmtTokens(Agents.weekTotal) }
                Stat { width: parent.w3; label: "sessions"; value: Agents.sessions + "" }
                Stat { width: parent.w3; label: "running"; value: Agents.running + " active"; valueColor: Agents.running > 0 ? Theme.green : Theme.dim }
            }

            Item {
                width: parent.width; height: Theme.px(28)
                Btn { text: "Open Claude Code"; primary: true; onClicked: { Ui.close(); Ui.run("kitty -e claude"); } }
                Btn { anchors.right: parent.right; text: Agents.loading ? "…" : "Refresh"; onClicked: Agents.refresh() }
            }
        }
    }
}
