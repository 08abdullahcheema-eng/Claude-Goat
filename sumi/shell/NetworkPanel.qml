import QtQuick
import Quickshell

// Network panel: current connection, live throughput, ping/loss, speed test, nearby networks.
Item {
    id: root
    anchors.fill: parent

    function fmtRate(b) {
        const m = Net.mbit(b);
        return m >= 100 ? m.toFixed(0) : m >= 10 ? m.toFixed(1) : m.toFixed(2);
    }

    Card {
        id: card
        width: Theme.px(470)
        x: Math.max(Theme.px(10), Math.min(parent.width - width - Theme.px(10), parent.width / 2 - Theme.px(170)))
        y: Theme.px(8)
        pad: Theme.px(16)

        Column {
            width: parent.width
            spacing: Theme.px(12)

            // header
            Item {
                width: parent.width; height: Theme.px(24)
                Row {
                    spacing: Theme.px(10); anchors.verticalCenter: parent.verticalCenter
                    Icon { name: "wifi"; color: Theme.hi; size: Theme.px(18); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Network"; color: Theme.hi; font.pixelSize: Theme.px(17); anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "網"; color: Theme.mute; font.family: Theme.serif; font.pixelSize: Theme.px(13); anchors.verticalCenter: parent.verticalCenter }
                }
                Toggle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    checked: Net.wifiEnabled
                    onToggled: (v) => Net.setWifi(v)
                }
            }

            // current connection
            Rectangle {
                width: parent.width
                height: Theme.px(58)
                radius: Theme.px(7)
                color: Net.kind !== "none" ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.07) : Theme.bg
                border.width: 1
                border.color: Net.kind !== "none" ? Theme.accent : Theme.line2
                Row {
                    anchors { left: parent.left; leftMargin: Theme.px(14); verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(12)
                    Item {
                        width: Theme.px(18); height: Theme.px(16); anchors.verticalCenter: parent.verticalCenter
                        SignalBars { visible: Net.kind === "wifi"; strength: Net.signal; color: Theme.hi; anchors.bottom: parent.bottom }
                        Icon { visible: Net.kind !== "wifi"; name: Net.kind === "ethernet" ? "eth" : "wifioff"; color: Theme.dim; size: Theme.px(16) }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.px(2)
                        T {
                            text: Net.kind === "none" ? (Net.wifiEnabled ? "Not connected" : "Wi-Fi is off") : (Net.kind === "ethernet" ? "Wired · " + Net.ssid : Net.ssid)
                            color: Theme.hi; font.pixelSize: Theme.px(15)
                            width: card.width - Theme.px(140); elide: Text.ElideRight
                        }
                        T {
                            visible: Net.kind !== "none"
                            text: (Net.kind === "wifi" ? [Net.freq, Net.chan ? "ch " + Net.chan : "", Net.signal + "%"].filter(x => x).join(" · ") + " · " : "") + (Net.ip || "…")
                            color: Theme.dim; font.pixelSize: Theme.px(10.5)
                        }
                    }
                }
                Rectangle {
                    visible: Net.kind === "wifi"
                    anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                    width: Theme.px(32); height: width; radius: Theme.px(6)
                    color: qrMa.containsMouse ? Theme.bg2 : "transparent"
                    border.width: 1; border.color: Theme.line2
                    Icon { anchors.centerIn: parent; name: "qr"; color: Theme.gold; size: Theme.px(17) }
                    MouseArea { id: qrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Net.qrPath ? (Net.qrPath = "") : Net.makeQr() }
                }
            }

            // QR code
            Row {
                visible: Net.qrPath !== "" || Net.qrBusy
                spacing: Theme.px(16)
                Rectangle {
                    width: Theme.px(150); height: width; radius: Theme.px(6); color: "white"
                    Image { anchors.fill: parent; anchors.margins: Theme.px(4); source: Net.qrPath; smooth: false; fillMode: Image.PreserveAspectFit }
                    T { visible: Net.qrBusy; anchors.centerIn: parent; text: "…"; color: "black" }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.px(6)
                    T { text: "Scan to join"; color: Theme.hi }
                    T { text: Net.ssid; color: Theme.dim; font.pixelSize: Theme.fsm }
                    Btn { text: "Hide"; onClicked: Net.qrPath = "" }
                }
            }

            // throughput
            Item {
                width: parent.width; height: Theme.px(16)
                Label { text: "Live throughput · 60 s"; anchors.verticalCenter: parent.verticalCenter }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(12)
                    T { text: "↓ " + root.fmtRate(Net.rxRate) + " Mb/s"; color: Theme.blue; font.pixelSize: Theme.fsm }
                    T { text: "↑ " + root.fmtRate(Net.txRate) + " Mb/s"; color: Theme.accent; font.pixelSize: Theme.fsm }
                }
            }
            Canvas {
                id: chart
                width: parent.width; height: Theme.px(88)
                property var rx: Net.rxHist
                property var tx: Net.txHist
                onRxChanged: requestPaint()
                onTxChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    ctx.strokeStyle = Theme.line; ctx.lineWidth = 1;
                    ctx.setLineDash([3, 5]);
                    for (const f of [1 / 3, 2 / 3]) { ctx.beginPath(); ctx.moveTo(0, h * f); ctx.lineTo(w, h * f); ctx.stroke(); }
                    ctx.setLineDash([]);
                    const max = Math.max(1, ...rx, ...tx) * 1.1;
                    function draw(arr, col) {
                        if (arr.length < 2) return;
                        const step = w / 59;
                        const x0 = w - (arr.length - 1) * step;
                        ctx.beginPath();
                        ctx.moveTo(x0, h);
                        arr.forEach((v, i) => ctx.lineTo(x0 + i * step, h - v / max * h));
                        ctx.lineTo(w, h); ctx.closePath();
                        ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.14); ctx.fill();
                        ctx.beginPath();
                        arr.forEach((v, i) => { const x = x0 + i * step, y = h - v / max * h; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); });
                        ctx.strokeStyle = col; ctx.lineWidth = Theme.px(1.5); ctx.stroke();
                    }
                    draw(rx, Theme.blue);
                    draw(tx, Theme.accent);
                }
            }

            Row {
                width: parent.width
                spacing: Theme.px(8)
                readonly property real w3: (width - spacing * 2) / 3
                Stat { width: parent.w3; label: "ping"; value: Net.pingMs >= 0 ? Math.round(Net.pingMs) + " ms" : "–" }
                Stat { width: parent.w3; label: "loss"; value: Net.loss.toFixed(1) + " %"; valueColor: Net.loss > 5 ? Theme.accent : Theme.green }
                Stat { width: parent.w3; label: "dns"; value: Net.dns || "–"; valueColor: Theme.dim }
            }

            // speed test
            Rectangle {
                width: parent.width; height: Theme.px(44); radius: Theme.px(6)
                color: Theme.bg; border.width: 1; border.color: Theme.line
                Row {
                    anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(10)
                    Icon { name: "down"; color: Theme.blue; size: Theme.px(15); anchors.verticalCenter: parent.verticalCenter }
                    T { text: "Speed test"; anchors.verticalCenter: parent.verticalCenter }
                    T {
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.mute; font.pixelSize: Theme.px(10.5)
                        text: Net.testing ? (Net.testPhase === "down" ? "measuring download…" : "measuring upload…")
                            : (Net.lastDown >= 0 ? "last: " + Math.round(Net.lastDown) + " ↓ / " + Math.round(Math.max(0, Net.lastUp)) + " ↑ Mb/s · " + Net.lastTestTime : "Cloudflare, ~75 MB")
                    }
                }
                Btn {
                    anchors { right: parent.right; rightMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
                    primary: true; text: Net.testing ? "…" : "Run"; enabled2: !Net.testing
                    onClicked: Net.speedTest()
                }
            }

            // nearby
            Label { visible: Net.wifiEnabled; text: "Nearby · " + Net.nearby.length }
            Column {
                visible: Net.wifiEnabled
                width: parent.width
                Repeater {
                    model: Net.nearby
                    delegate: Column {
                        id: nd
                        required property var modelData
                        width: parent.width
                        Rectangle {
                            width: parent.width; height: Theme.px(36)
                            color: nm.containsMouse ? Theme.bg2 : "transparent"
                            radius: Theme.px(4)
                            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Theme.line }
                            Row {
                                anchors { left: parent.left; leftMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                                spacing: Theme.px(12)
                                SignalBars { strength: nd.modelData.signal; anchors.verticalCenter: parent.verticalCenter }
                                T { text: nd.modelData.ssid; anchors.verticalCenter: parent.verticalCenter; width: card.width - Theme.px(200); elide: Text.ElideRight }
                            }
                            Row {
                                anchors { right: parent.right; rightMargin: Theme.px(6); verticalCenter: parent.verticalCenter }
                                spacing: Theme.px(10)
                                T { text: Net.connecting === nd.modelData.ssid ? "connecting…" : (nd.modelData.known ? "saved" : (nd.modelData.secure ? nd.modelData.freq : "open")); color: Theme.mute; font.pixelSize: Theme.px(10.5); anchors.verticalCenter: parent.verticalCenter }
                                Icon { visible: nd.modelData.secure; name: "lock"; color: Theme.mute; size: Theme.px(12); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (nd.modelData.secure && !nd.modelData.known) Net.needPassword = nd.modelData.ssid;
                                    else Net.connectTo(nd.modelData.ssid, "");
                                }
                            }
                        }
                        // password row
                        Rectangle {
                            visible: Net.needPassword === nd.modelData.ssid
                            width: parent.width; height: visible ? Theme.px(44) : 0
                            color: "transparent"
                            Rectangle {
                                anchors { left: parent.left; right: joinBtn.left; rightMargin: Theme.px(8); verticalCenter: parent.verticalCenter }
                                height: Theme.px(30); radius: Theme.px(5)
                                color: Theme.bg; border.width: 1; border.color: Theme.accent
                                TextInput {
                                    id: pw
                                    anchors { fill: parent; leftMargin: Theme.px(10); rightMargin: Theme.px(10) }
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.hi; font.family: Theme.mono; font.pixelSize: Theme.fmd
                                    focus: parent.parent.visible
                                    onVisibleChanged: if (visible) forceActiveFocus()
                                    onAccepted: Net.connectTo(nd.modelData.ssid, text)
                                    Text { visible: !pw.text; text: "password"; color: Theme.mute; font: pw.font; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                            Btn { id: joinBtn; anchors { right: parent.right; verticalCenter: parent.verticalCenter } primary: true; text: "Join"; onClicked: Net.connectTo(nd.modelData.ssid, pw.text) }
                        }
                    }
                }
            }
            T { visible: Net.connectError !== ""; text: Net.connectError; color: Theme.accent; font.pixelSize: Theme.px(10.5); width: parent.width; wrapMode: Text.Wrap }

            Item {
                width: parent.width; height: Theme.px(16)
                T { text: Net.kind !== "none" ? "Disconnect" : ""; color: Theme.mute; font.pixelSize: Theme.px(10.5)
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Net.disconnect() } }
                T { anchors.right: parent.right; text: "Advanced →"; color: Theme.mute; font.pixelSize: Theme.px(10.5)
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Ui.close(); Ui.run("nm-connection-editor"); } } }
            }
        }
    }
}
