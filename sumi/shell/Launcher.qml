import QtQuick
import Quickshell

// SUPER+SPACE: one search for apps, settings and commands.
Item {
    id: root
    anchors.fill: parent

    property string query: Theme.demo && Quickshell.env("SUMI_DEMO_QUERY") ? Quickshell.env("SUMI_DEMO_QUERY") : ""
    property string tab: Ui.launcherMode   // all | apps | settings | commands
    property int sel: 0
    readonly property var tabs: [["all", "All"], ["apps", "Apps"], ["settings", "Settings"], ["commands", "Commands"]]

    readonly property string cfg: Theme.home + "/nixos-config"
    function term(cmd) { Ui.run("kitty --class sumi-float -e sh -c " + JSON.stringify(cmd + "; echo; read -p 'press enter to close ' x")); }

    readonly property var settings: [
        { title: "Wi-Fi & network", sub: "networks, speed test, share via QR", icon: "wifi", kw: "wlan internet ethernet", run: () => Ui.open("network") },
        { title: "Agents usage", sub: "Claude Code limits and tokens", icon: "agent", kw: "claude ai tokens", run: () => Ui.open("agents") },
        { title: "Themes", sub: "Sumi, Kin, Ai, Washi · live preview", icon: "palette", kw: "colors appearance wallpaper", run: () => Ui.open("themes") },
        { title: "Predator", sub: "fans, thermal profile, keyboard light, battery", icon: "fan", kw: "predatorsense fan rgb keyboard turbo temperature battery limit", run: () => Ui.open("predator") },
        { title: "Sound", sub: "outputs, inputs, per-app volume", icon: "vol", kw: "audio speaker headphones pavucontrol", run: () => Ui.run("pavucontrol") },
        { title: "Network connections", sub: "advanced NetworkManager editor", icon: "eth", kw: "vpn ip dns", run: () => Ui.run("nm-connection-editor") },
        { title: "Display", sub: "monitors and scaling (hyprctl)", icon: "monitor", kw: "screen resolution", run: () => root.term("hyprctl monitors") },
        { title: "Power menu", sub: "lock, suspend, reboot, shut down", icon: "power", kw: "logout restart", run: () => Ui.open("power") }
    ]
    readonly property var commands: [
        { title: "Rebuild system", sub: "sudo nixos-rebuild switch --flake ~/nixos-config", icon: "term", kw: "nixos update switch", run: () => root.term("cd ~/nixos-config && git add -A && sudo nixos-rebuild switch --flake .") },
        { title: "Update and rebuild", sub: "nix flake update, then rebuild", icon: "refresh", kw: "upgrade packages", run: () => root.term("cd ~/nixos-config && nix flake update && git add -A && sudo nixos-rebuild switch --flake .") },
        { title: "Screenshot area", sub: "select with the mouse, copies to clipboard", icon: "shot", kw: "screen capture grim slurp", run: () => Ui.run("sleep 0.3; grim -g \"$(slurp)\" - | wl-copy") },
        { title: "Screenshot screen", sub: "saves to ~/Pictures", icon: "camera", kw: "screen capture", run: () => Ui.run("sleep 0.3; mkdir -p ~/Pictures; grim ~/Pictures/shot-$(date +%F-%H%M%S).png") },
        { title: "Lock screen", sub: "hyprlock", icon: "lock", kw: "lock", run: () => Ui.run("pidof hyprlock || hyprlock") },
        { title: "Do not disturb", sub: Ui.dnd ? "currently on" : "currently off", icon: "belloff", kw: "dnd notifications mute", run: () => Ui.dnd = !Ui.dnd },
        { title: "Edit config", sub: "open ~/nixos-config in nvim", icon: "file", kw: "nvim settings dotfiles", run: () => Ui.run("kitty -e nvim ~/nixos-config") },
        { title: "Clean up old generations", sub: "sudo nix-collect-garbage -d", icon: "refresh", kw: "garbage disk space", run: () => root.term("sudo nix-collect-garbage -d") },
        { title: "Reload shell", sub: "restart the bar and panels", icon: "refresh", kw: "quickshell restart", run: () => Quickshell.reload(true) }
    ]

    function score(text, q) {
        if (!q) return 1;
        text = (text || "").toLowerCase();
        const i = text.indexOf(q);
        if (i === 0) return 100;
        if (i > 0) return 80 - Math.min(i, 30);
        // subsequence
        let j = 0;
        for (let k = 0; k < text.length && j < q.length; k++) if (text[k] === q[j]) j++;
        return j === q.length ? 20 : 0;
    }
    function best(item, q) {
        return Math.max(score(item.title, q) * 1.0, score(item.sub, q) * 0.5, score(item.kw, q) * 0.6);
    }

    readonly property var apps: {
        const out = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            out.push({ title: e.name, sub: e.comment || e.genericName || "", kw: (e.keywords || []).join(" ") + " " + (e.genericName || ""),
                       appIcon: e.icon, entry: e });
        }
        return out;
    }

    readonly property var results: {
        let q = query.trim().toLowerCase();
        let t = tab;
        if (q.startsWith(">")) { t = "commands"; q = q.slice(1).trim(); }
        const pick = (list, kind, n) => list.map(x => ({ item: x, kind: kind, s: best(x, q) }))
            .filter(x => x.s > 0).sort((a, b) => b.s - a.s || a.item.title.localeCompare(b.item.title)).slice(0, n);
        if (t === "apps") return pick(apps, "apps", 9);
        if (t === "settings") return pick(settings, "settings", 9);
        if (t === "commands") return pick(commands, "commands", 9);
        if (!q) return pick(apps, "apps", 4).concat(pick(settings, "settings", 2), pick(commands, "commands", 3));
        return pick(apps, "apps", 4).concat(pick(settings, "settings", 3), pick(commands, "commands", 3));
    }
    onResultsChanged: sel = 0

    function activate(i) {
        const r = results[i];
        if (!r) return;
        Ui.close();
        if (r.kind === "apps") r.item.entry.execute();
        else r.item.run();
    }
    function cycleTab(d) {
        let i = tabs.findIndex(x => x[0] === tab);
        i = (i + d + tabs.length) % tabs.length;
        tab = tabs[i][0];
    }

    Card {
        id: card
        width: Math.min(Theme.px(740), parent.width - Theme.px(40))
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.15
        pad: Theme.px(14)

        Column {
            width: parent.width
            spacing: Theme.px(4)

            // search row
            Item {
                width: parent.width
                height: Theme.px(44)
                Icon { id: sIcon; name: "search"; color: Theme.accent; size: Theme.px(18); anchors { left: parent.left; leftMargin: Theme.px(8); verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: input
                    anchors { left: sIcon.right; leftMargin: Theme.px(12); right: tabRow.left; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                    text: root.query
                    onTextChanged: root.query = text
                    focus: true
                    color: Theme.hi
                    selectionColor: Theme.accent
                    font.family: Theme.mono
                    font.pixelSize: Theme.px(19)
                    cursorDelegate: Rectangle { width: Theme.px(2); color: Theme.hi }
                    Text {
                        visible: !input.text
                        text: "search apps, settings, > commands"
                        color: Theme.mute
                        font: input.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Keys.onPressed: (e) => {
                        if (e.key === Qt.Key_Down) { root.sel = Math.min(root.results.length - 1, root.sel + 1); e.accepted = true; }
                        else if (e.key === Qt.Key_Up) { root.sel = Math.max(0, root.sel - 1); e.accepted = true; }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.activate(root.sel); e.accepted = true; }
                        else if (e.key === Qt.Key_Tab) { root.cycleTab(1); e.accepted = true; }
                        else if (e.key === Qt.Key_Backtab) { root.cycleTab(-1); e.accepted = true; }
                        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
                    }
                }
                Row {
                    id: tabRow
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(2)
                    Repeater {
                        model: root.tabs
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: root.tab === modelData[0]
                            width: tl.implicitWidth + Theme.px(18); height: Theme.px(26); radius: Theme.px(4)
                            color: on ? Theme.bg2 : "transparent"
                            Text { id: tl; anchors.centerIn: parent; text: modelData[1]; color: parent.on ? Theme.hi : Theme.mute; font.family: Theme.mono; font.pixelSize: Theme.fsm }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.tab = parent.modelData[0]; input.forceActiveFocus(); } }
                        }
                    }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.line }

            // results
            Repeater {
                model: root.results
                delegate: Column {
                    id: rowD
                    required property var modelData
                    required property int index
                    width: parent.width
                    readonly property bool first: index === 0 || root.results[index - 1].kind !== modelData.kind
                    readonly property bool on: index === root.sel

                    Label {
                        visible: rowD.first
                        text: rowD.modelData.kind
                        topPadding: Theme.px(10); bottomPadding: Theme.px(4); leftPadding: Theme.px(12)
                    }
                    Rectangle {
                        width: parent.width
                        height: Theme.px(46)
                        radius: Theme.px(6)
                        color: rowD.on ? Theme.bg2 : (rm.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.5) : "transparent")
                        Rectangle { visible: rowD.on; width: Theme.px(2); height: parent.height; color: Theme.accent }

                        Item {
                            id: ico
                            width: Theme.px(32); height: Theme.px(32)
                            anchors { left: parent.left; leftMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                            Image {
                                visible: rowD.modelData.kind === "apps"
                                anchors.fill: parent
                                source: visible ? Quickshell.iconPath(rowD.modelData.item.appIcon || "", "application-x-executable") : ""
                                sourceSize: Qt.size(64, 64)
                                asynchronous: true
                            }
                            Rectangle {
                                visible: rowD.modelData.kind !== "apps"
                                anchors.fill: parent
                                radius: Theme.px(6)
                                color: Theme.bg1
                                border.width: 1; border.color: Theme.line2
                                Icon {
                                    anchors.centerIn: parent
                                    name: rowD.modelData.item.icon || "app"
                                    size: Theme.px(17)
                                    color: rowD.modelData.kind === "commands" ? Theme.gold : Theme.dim
                                }
                            }
                        }
                        Column {
                            anchors { left: ico.right; leftMargin: Theme.px(14); right: tag.left; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
                            spacing: Theme.px(1)
                            Text { width: parent.width; elide: Text.ElideRight; text: rowD.modelData.item.title; color: rowD.on ? Theme.hi : Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.px(14) }
                            Text { width: parent.width; elide: Text.ElideRight; text: rowD.modelData.item.sub; color: Theme.mute; font.family: Theme.mono; font.pixelSize: Theme.px(10.5); visible: text !== "" }
                        }
                        Row {
                            id: tag
                            anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                            spacing: Theme.px(10)
                            Text { text: ({ apps: "APP", settings: "PANEL", commands: "CMD" })[rowD.modelData.kind]; color: Theme.mute; font.family: Theme.mono; font.pixelSize: Theme.px(9.5); font.letterSpacing: Theme.px(1.5); anchors.verticalCenter: parent.verticalCenter }
                            Kbd { visible: rowD.on; text: "↵"; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            id: rm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = rowD.index
                            onClicked: root.activate(rowD.index)
                        }
                    }
                }
            }
            T {
                visible: root.results.length === 0
                text: "nothing found"
                color: Theme.mute
                topPadding: Theme.px(18); bottomPadding: Theme.px(18); leftPadding: Theme.px(12)
            }

            Rectangle { width: parent.width; height: 1; color: Theme.line; anchors.topMargin: Theme.px(8) }
            Row {
                spacing: Theme.px(16)
                topPadding: Theme.px(8)
                leftPadding: Theme.px(8)
                Repeater {
                    model: [["↑↓", "move"], ["↵", "open"], ["tab", "section"], [">", "commands only"]]
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.px(6)
                        Kbd { text: modelData[0] }
                        Text { text: modelData[1]; color: Theme.mute; font.family: Theme.mono; font.pixelSize: Theme.px(10.5); anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
    function focusFirst() { input.forceActiveFocus(); }
}
