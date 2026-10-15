import QtQuick
import Quickshell
import Quickshell.Io

// SUPER+SPACE: one search with four tabs.
//   Apps       apps and the shell's panels
//   Clipboard  what you copied (cliphist), with a preview; SUPER+V opens straight here
//   Emoji      emoji and symbols, recently used first
//   Commands   rebuild, screenshots, lock ...  (">" in any tab jumps here)
Item {
    id: root
    anchors.fill: parent

    property string query: Theme.demo && Quickshell.env("SUMI_DEMO_QUERY") ? Quickshell.env("SUMI_DEMO_QUERY") : ""
    property string tab: modeToTab(Ui.launcherMode)
    property int sel: 0
    readonly property var tabs: [["apps", "Apps"], ["clip", "Clipboard"], ["emoji", "Emoji"], ["commands", "Commands"]]
    function modeToTab(m) { return m === "clip" || m === "emoji" || m === "commands" ? m : "apps"; }
    Connections { target: Ui; function onLauncherModeChanged() { root.tab = root.modeToTab(Ui.launcherMode); } }
    readonly property bool wide: tab === "clip" || tab === "emoji"
    onTabChanged: { sel = 0; if (tab === "clip") clip.reload(); }

    readonly property string cfg: Theme.home + "/nixos-config"
    function term(cmd) { Ui.run("kitty --class sumi-float -e sh -c " + JSON.stringify(cmd + "; echo; read -p 'press enter to close ' x")); }

    readonly property var settings: [
        { title: "Wi-Fi & network", sub: "networks, speed test, share via QR", icon: "wifi", kw: "wlan internet ethernet", run: () => Ui.open("network") },
        { title: "Agents usage", sub: "Claude Code limits and tokens", icon: "agent", kw: "claude ai tokens", run: () => Ui.open("agents") },
        { title: "Themes", sub: "Sumi, Iso, Kiri, Hagane, Summit · live preview", icon: "palette", kw: "colors appearance wallpaper theme", run: () => Ui.open("themes") },
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
        { title: "Screensaver", sub: "show it now, any key ends it", icon: "moon", kw: "standby idle saver", run: () => Ui.saver = true },
        { title: "Do not disturb", sub: Ui.dnd ? "currently on" : "currently off", icon: "belloff", kw: "dnd notifications mute", run: () => Ui.dnd = !Ui.dnd },
        { title: "Clear clipboard history", sub: "cliphist wipe", icon: "x", kw: "clipboard delete history", run: () => Ui.run("cliphist wipe") },
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

    readonly property string q: { const s = query.trim().toLowerCase(); return s.startsWith(">") ? s.slice(1).trim() : s; }
    readonly property string listTab: query.trim().startsWith(">") ? "commands" : tab
    readonly property var results: {
        const pick = (list, kind, n) => list.map(x => ({ item: x, kind: kind, s: best(x, q) }))
            .filter(x => x.s > 0).sort((a, b) => b.s - a.s || a.item.title.localeCompare(b.item.title)).slice(0, n);
        if (listTab === "commands") return pick(commands, "commands", 9);
        if (listTab === "apps") return q ? pick(apps, "apps", 6).concat(pick(settings, "settings", 3)) : pick(apps, "apps", 6).concat(pick(settings, "settings", 3));
        return [];
    }
    onResultsChanged: if (!wide) sel = 0

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

    // ------------------------------------------------------------------ clipboard (cliphist)
    QtObject {
        id: clip
        property var all: []            // { id, line, text, kind, w, h }
        property string full: ""        // full text of the selected entry
        property string img: ""         // decoded picture of the selected entry
        readonly property var items: {
            const qq = root.q;
            return qq ? all.filter(x => x.text.toLowerCase().indexOf(qq) >= 0 || x.kind.indexOf(qq) >= 0) : all;
        }
        readonly property var cur: items[Math.min(root.sel, items.length - 1)] || null
        onCurChanged: decode()
        function kindOf(t) {
            const m = t.match(/^\[\[ binary data .* (png|jpe?g|gif|webp|bmp) (\d+)x(\d+) \]\]$/);
            if (m) return { kind: "bild", w: +m[2], h: +m[3] };
            if (/^\[\[ binary data/.test(t)) return { kind: "datei" };
            if (/^https?:\/\/\S+$/.test(t)) return { kind: "link" };
            if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(t.trim())) return { kind: "farbe" };
            return { kind: "text" };
        }
        function parse(out) {
            const list = [];
            for (const line of out.split("\n")) {
                const tab = line.indexOf("\t");
                if (tab < 1) continue;
                const t = line.slice(tab + 1);
                list.push(Object.assign({ id: line.slice(0, tab), line: line, text: t }, kindOf(t)));
                if (list.length >= 200) break;
            }
            all = list;
        }
        function reload() {
            if (Theme.demo) {
                parse(["9\tsudo nixos-rebuild switch --flake .#nixos", "8\t[[ binary data 212 KiB png 1280x800 ]]",
                       "7\tnix-shell -p pciutils --run \"lspci | grep -E 'VGA|3D'\"", "6\thttps://pro.easyeda.com/editor",
                       "5\tboot.loader.grub.useOSProber = lib.mkForce false;", "4\t#c8323a", "3\tkommst du heute noch online? cs2 um 8"].join("\n"));
                return;
            }
            listProc.running = false; listProc.running = true;
        }
        function decode() {
            full = ""; img = "";
            if (!cur) return;
            if (Theme.demo) { full = cur.kind === "text" && cur.id === "9" ? "$ sudo nixos-rebuild switch \\\n    --flake .#nixos\n\nbuilding the system configuration...\nDone." : cur.text; return; }
            if (cur.kind === "bild") {
                imgProc.target = "/tmp/sumi-clip-" + cur.id + ".img";
                imgProc.running = false; imgProc.running = true;
            } else if (cur.kind !== "datei") {
                textProc.running = false; textProc.running = true;
            }
        }
        function copy(paste) {
            if (!cur) return;
            const id = cur.id;
            Ui.close();
            if (Theme.demo) return;
            Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy" + (paste ? " && sleep 0.25 && wtype -M ctrl -M shift v -m shift -m ctrl" : ""), "sh", id]);
        }
        function remove() {
            if (!cur) return;
            const line = cur.line;
            all = all.filter(x => x.line !== line);
            if (!Theme.demo) Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", line]);
        }
    }
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: clip.parse(this.text) }
    }
    Process {
        id: textProc
        command: ["sh", "-c", "cliphist decode \"$1\" | head -c 4000", "sh", clip.cur ? clip.cur.id : ""]
        stdout: StdioCollector { onStreamFinished: clip.full = this.text }
    }
    Process {
        id: imgProc
        property string target: ""
        command: ["sh", "-c", "[ -s \"$2\" ] || cliphist decode \"$1\" > \"$2\"; echo \"$2\"", "sh", clip.cur ? clip.cur.id : "", target]
        stdout: StdioCollector { onStreamFinished: clip.img = this.text.trim() }
    }

    // ------------------------------------------------------------------ emoji
    property var emojiAll: []
    property var recent: []
    readonly property string recentFile: Theme.home + "/.local/state/sumi/recent-symbols"
    FileView {
        path: Quickshell.shellPath("assets/data/emoji.json")
        onLoaded: { try { root.emojiAll = JSON.parse(text()); } catch (e) { root.emojiAll = []; } }
    }
    FileView {
        path: root.recentFile
        printErrors: false
        onLoaded: { const t = (text() || "").split("\n").filter(x => x); root.recent = t.slice(0, 16); }
        onLoadFailed: root.recent = Theme.demo ? ["墨", "★", "♥", "√", "→", "♪", "☀", "◆"] : ["★", "♥", "√", "→", "♪", "☀", "◆", "✓"]
    }
    readonly property var emojiItems: {
        const qq = q;
        if (!qq) {
            const r = recent.map(c => emojiAll.find(e => e[0] === c) || [c, "zuletzt benutzt"]);
            const rest = emojiAll.filter(e => recent.indexOf(e[0]) < 0);
            return r.concat(rest).slice(0, 400);
        }
        return emojiAll.filter(e => e[1].indexOf(qq) >= 0).slice(0, 400);
    }
    readonly property var emojiCur: emojiItems[Math.min(sel, emojiItems.length - 1)] || null
    function useSymbol(c, paste) {
        if (!c) return;
        Ui.close();
        if (Theme.demo) return;
        Quickshell.execDetached(["sh", "-c",
            "printf '%s' \"$1\" | wl-copy; f=\"$2\"; mkdir -p \"$(dirname \"$f\")\"; { printf '%s\\n' \"$1\"; grep -vxF -- \"$1\" \"$f\" 2>/dev/null | head -n 15; } > \"$f.new\" && mv \"$f.new\" \"$f\"" +
            (paste ? "; sleep 0.25; wtype -M ctrl -M shift v -m shift -m ctrl" : ""), "sh", c, root.recentFile]);
    }

    function count() { return tab === "clip" ? clip.items.length : tab === "emoji" ? emojiItems.length : results.length; }
    function move(d) { const n = count(); if (n > 0) sel = Math.max(0, Math.min(n - 1, sel + d)); }
    onQChanged: sel = 0

    // ------------------------------------------------------------------ the card
    Card {
        id: card
        width: Math.min(root.wide ? Theme.px(980) : Theme.px(760), parent.width - Theme.px(40))
        Behavior on width { NumberAnimation { duration: Theme.mMed; easing.type: Theme.mEaseSmall } }
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        pad: Theme.px(14)

        Column {
            width: parent.width
            spacing: Theme.px(4)

            // search row: the theme's mark, the query, the tabs
            Item {
                width: parent.width
                height: Theme.px(46)
                Logo { id: sIcon; size: Theme.px(26); anchors { left: parent.left; leftMargin: Theme.px(4); verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: input
                    anchors { left: sIcon.right; leftMargin: Theme.px(10); right: tabRow.left; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                    text: root.query
                    onTextChanged: root.query = text
                    focus: true
                    color: Theme.hi
                    selectionColor: Theme.accent
                    font.family: "Inter"
                    font.pixelSize: Theme.px(20)
                    cursorDelegate: Rectangle { width: Theme.px(2); color: Theme.accent }
                    Text {
                        visible: !input.text
                        text: ({ apps: "Apps und Einstellungen suchen", clip: "Zwischenablage durchsuchen", emoji: "Emoji und Symbole suchen", commands: "Befehl suchen" })[root.tab]
                        color: Theme.mute
                        font: input.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Keys.onPressed: (e) => {
                        const grid = root.tab === "emoji";
                        const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
                        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                        if (e.key === Qt.Key_Down) { root.move(grid ? emojiGrid.cols : 1); e.accepted = true; }
                        else if (e.key === Qt.Key_Up) { root.move(grid ? -emojiGrid.cols : -1); e.accepted = true; }
                        else if (grid && e.key === Qt.Key_Right && input.cursorPosition === input.text.length) { root.move(1); e.accepted = true; }
                        else if (grid && e.key === Qt.Key_Left && input.cursorPosition === input.text.length) { root.move(-1); e.accepted = true; }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            if (root.tab === "clip" && root.listTab === "clip") clip.copy(shift);
                            else if (grid && root.listTab === "emoji") root.useSymbol(root.emojiCur ? root.emojiCur[0] : "", shift);
                            else root.activate(root.sel);
                            e.accepted = true;
                        }
                        else if (ctrl && e.key === Qt.Key_D && root.tab === "clip") { clip.remove(); e.accepted = true; }
                        else if (e.key === Qt.Key_Tab) { root.cycleTab(1); e.accepted = true; }
                        else if (e.key === Qt.Key_Backtab) { root.cycleTab(-1); e.accepted = true; }
                        else if (e.key === Qt.Key_Escape) { Ui.close(); e.accepted = true; }
                    }
                }
                Row {
                    id: tabRow
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: Theme.px(4)
                    Repeater {
                        model: root.tabs
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: root.tab === modelData[0]
                            width: tl.implicitWidth + Theme.px(22); height: Theme.px(30); radius: Theme.px(8)
                            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (tm.containsMouse ? Theme.bg2 : "transparent")
                            border.width: on ? 1 : 0
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
                            Behavior on color { ColorAnimation { duration: Theme.mFast } }
                            Text { id: tl; anchors.centerIn: parent; text: modelData[1]; color: parent.on ? Theme.hi : Theme.dim; font.family: "Inter"; font.pixelSize: Theme.px(13) }
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.tab = parent.modelData[0]; input.forceActiveFocus(); } }
                        }
                    }
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.line }

            // ---- apps and commands: the result list
            Column {
                visible: !root.wide || root.listTab === "commands"
                width: parent.width
                Repeater {
                    model: root.wide && root.listTab !== "commands" ? [] : root.results
                    delegate: Column {
                        id: rowD
                        required property var modelData
                        required property int index
                        width: parent.width
                        readonly property bool first: index === 0 || root.results[index - 1].kind !== modelData.kind
                        readonly property bool on: index === root.sel
                        property real k: root.settled || Theme.mStagger === 0 || index > 7 ? 1 : 0
                        opacity: Math.max(0, Math.min(1, k * 1.3))
                        transform: Translate { y: (1 - rowD.k) * Theme.mDist * (Theme.mStyle === "descend" ? -0.8 : 0.8) }
                        SequentialAnimation {
                            running: rowD.k < 1
                            PauseAnimation { duration: Theme.mStagger + rowD.index * Math.round(Theme.mStagger * 0.45) }
                            NumberAnimation { target: rowD; property: "k"; to: 1; duration: Theme.mMed; easing.type: Theme.mEase; easing.overshoot: Theme.mOvershoot }
                        }

                        Label {
                            visible: rowD.first
                            text: ({ apps: "Apps", settings: "Einstellungen", commands: "Befehle" })[rowD.modelData.kind]
                            topPadding: Theme.px(10); bottomPadding: Theme.px(4); leftPadding: Theme.px(12)
                        }
                        Rectangle {
                            width: parent.width
                            height: Theme.px(46)
                            radius: Theme.px(8)
                            color: rowD.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16) : (rm.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0))
                            border.width: rowD.on ? 1 : 0
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                            Behavior on color { ColorAnimation { duration: Theme.mFast } }

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
                                    radius: Theme.px(8)
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
                                Text { width: parent.width; elide: Text.ElideRight; text: rowD.modelData.item.title; color: rowD.on ? Theme.hi : Theme.fg; font.family: "Inter"; font.pixelSize: Theme.px(14) }
                                Text { width: parent.width; elide: Text.ElideRight; text: rowD.modelData.item.sub; color: Theme.mute; font.family: "Inter"; font.pixelSize: Theme.px(11); visible: text !== "" }
                            }
                            Row {
                                id: tag
                                anchors { right: parent.right; rightMargin: Theme.px(12); verticalCenter: parent.verticalCenter }
                                spacing: Theme.px(10)
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
                    text: "nichts gefunden"
                    color: Theme.mute
                    topPadding: Theme.px(18); bottomPadding: Theme.px(18); leftPadding: Theme.px(12)
                }
            }

            // ---- clipboard and emoji: list or grid on the left, preview on the right
            Item {
                visible: root.wide && root.listTab !== "commands"
                width: parent.width
                height: visible ? Theme.px(430) : 0

                // left pane
                Item {
                    id: leftPane
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: Theme.px(8) }
                    width: parent.width * 0.5

                    ListView {
                        id: clipList
                        visible: root.tab === "clip"
                        anchors.fill: parent
                        clip: true
                        spacing: Theme.px(2)
                        model: root.tab === "clip" ? clip.items : []
                        currentIndex: root.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            id: ce
                            required property var modelData
                            required property int index
                            readonly property bool on: index === root.sel
                            width: clipList.width - Theme.px(6)
                            height: Theme.px(54)
                            radius: Theme.px(8)
                            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : (cm.containsMouse ? Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6) : "transparent")
                            border.width: on ? 1 : 0
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                            Behavior on color { ColorAnimation { duration: Theme.mFast } }
                            Rectangle {
                                id: ci
                                width: Theme.px(30); height: width; radius: Theme.px(7)
                                anchors { left: parent.left; leftMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
                                color: Theme.bg1
                                border.width: 1; border.color: Theme.line2
                                Rectangle {
                                    visible: ce.modelData.kind === "farbe"
                                    anchors.centerIn: parent; width: Theme.px(12); height: width; radius: width / 2
                                    color: ce.modelData.kind === "farbe" ? ce.modelData.text.trim() : "transparent"
                                }
                                Text {
                                    visible: ce.modelData.kind !== "farbe"
                                    anchors.centerIn: parent
                                    text: ({ text: "¶", link: "↗", bild: "▣", datei: "▤" })[ce.modelData.kind] || "¶"
                                    color: ce.on ? Theme.accent : Theme.dim
                                    font.family: "Inter"; font.pixelSize: Theme.px(14)
                                }
                            }
                            Column {
                                anchors { left: ci.right; leftMargin: Theme.px(12); right: parent.right; rightMargin: Theme.px(10); verticalCenter: parent.verticalCenter }
                                spacing: Theme.px(2)
                                Text {
                                    width: parent.width; elide: Text.ElideRight; maximumLineCount: 1
                                    text: ce.modelData.kind === "bild" ? "Bild  ·  " + ce.modelData.w + "×" + ce.modelData.h : ce.modelData.text.replace(/\s+/g, " ")
                                    color: ce.on ? Theme.hi : Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.px(12.5)
                                }
                                Text {
                                    text: ({ text: "Text", link: "Link", bild: "Bild", datei: "Datei", farbe: "Farbe" })[ce.modelData.kind] + (ce.index === 0 ? "  ·  zuletzt kopiert" : "")
                                    color: Theme.mute; font.family: "Inter"; font.pixelSize: Theme.px(10.5)
                                }
                            }
                            MouseArea {
                                id: cm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: root.sel = ce.index
                                onClicked: { root.sel = ce.index; clip.copy(false); }
                            }
                        }
                        T {
                            visible: clip.items.length === 0
                            anchors.centerIn: parent
                            text: Theme.demo || clip.all.length ? "nichts gefunden" : "noch nichts kopiert"
                            color: Theme.mute
                        }
                    }

                    GridView {
                        id: emojiGrid
                        visible: root.tab === "emoji"
                        anchors.fill: parent
                        clip: true
                        readonly property real cell: Theme.px(48)
                        readonly property int cols: Math.max(1, Math.floor(width / cell))
                        cellWidth: width / cols
                        cellHeight: cell
                        model: root.tab === "emoji" ? root.emojiItems : []
                        currentIndex: root.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Item {
                            id: ee
                            required property var modelData
                            required property int index
                            readonly property bool on: index === root.sel
                            width: emojiGrid.cellWidth; height: emojiGrid.cellHeight
                            Rectangle {
                                anchors.centerIn: parent
                                width: Theme.px(42); height: width; radius: Theme.px(9)
                                color: ee.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (em.containsMouse ? Theme.bg2 : "transparent")
                                border.width: ee.on ? 1 : 0
                                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                                scale: ee.on ? 1.06 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.mFast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: ee.modelData[0]
                                    color: Theme.hi
                                    font.family: Theme.serif
                                    font.pixelSize: Theme.px(22)
                                }
                            }
                            MouseArea {
                                id: em
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: root.sel = ee.index
                                onClicked: root.useSymbol(ee.modelData[0], false)
                            }
                        }
                    }
                }

                Rectangle { anchors { left: leftPane.right; leftMargin: Theme.px(8); top: parent.top; bottom: parent.bottom; topMargin: Theme.px(8) } width: 1; color: Theme.line }

                // right pane: preview
                Column {
                    anchors { left: leftPane.right; leftMargin: Theme.px(24); right: parent.right; rightMargin: Theme.px(6); top: parent.top; topMargin: Theme.px(14) }
                    spacing: Theme.px(10)

                    Label { text: root.tab === "clip" ? "Vorschau" : "Symbol" }
                    Rectangle {
                        width: parent.width
                        height: Theme.px(200)
                        radius: Theme.px(10)
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.6)
                        border.width: 1; border.color: Theme.line2
                        clip: true
                        // clipboard text
                        Text {
                            visible: root.tab === "clip" && clip.cur && clip.cur.kind !== "bild"
                            anchors { fill: parent; margins: Theme.px(16) }
                            text: clip.full || (clip.cur ? clip.cur.text : "")
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                            color: Theme.fg; font.family: Theme.mono; font.pixelSize: Theme.px(12.5)
                            lineHeight: 1.25
                        }
                        // clipboard colour
                        Rectangle {
                            visible: root.tab === "clip" && !!clip.cur && clip.cur.kind === "farbe"
                            anchors { right: parent.right; bottom: parent.bottom; margins: Theme.px(16) }
                            width: Theme.px(64); height: width; radius: Theme.px(12)
                            color: visible ? clip.cur.text.trim() : "transparent"
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        // clipboard picture
                        Image {
                            visible: root.tab === "clip" && !!clip.cur && clip.cur.kind === "bild"
                            anchors { fill: parent; margins: Theme.px(8) }
                            source: visible && clip.img ? "file://" + clip.img : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }
                        Text {
                            visible: root.tab === "clip" && !!clip.cur && clip.cur.kind === "bild" && !clip.img
                            anchors.centerIn: parent
                            text: clip.cur ? clip.cur.w + " × " + clip.cur.h : ""
                            color: Theme.mute; font.family: "Inter"; font.pixelSize: Theme.px(13)
                        }
                        // emoji: the symbol, big
                        Text {
                            visible: root.tab === "emoji"
                            anchors.centerIn: parent
                            text: root.emojiCur ? root.emojiCur[0] : ""
                            color: Theme.hi
                            font.family: Theme.serif
                            font.pixelSize: Theme.px(96)
                        }
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: {
                            if (root.tab === "emoji") {
                                const e = root.emojiCur;
                                if (!e) return "";
                                const cp = e[0].codePointAt(0).toString(16).toUpperCase();
                                return e[1].split(" zuletzt")[0] + "  ·  U+" + cp;
                            }
                            const c = clip.cur;
                            if (!c) return "";
                            if (c.kind === "bild") return "Bild  ·  " + c.w + "×" + c.h;
                            const t = clip.full || c.text;
                            const lines = t.split("\n").length;
                            return t.length + " Zeichen  ·  " + lines + (lines === 1 ? " Zeile" : " Zeilen");
                        }
                        color: Theme.dim; font.family: "Inter"; font.pixelSize: Theme.px(12)
                    }
                    Item { width: 1; height: Theme.px(10) }
                    Label { text: "Zuletzt benutzt" }
                    Flow {
                        width: parent.width
                        spacing: Theme.px(8)
                        Repeater {
                            model: root.recent.slice(0, 8)
                            delegate: Rectangle {
                                required property var modelData
                                width: Theme.px(42); height: width; radius: Theme.px(9)
                                color: rsm.containsMouse ? Theme.bg2 : Qt.rgba(Theme.bg2.r, Theme.bg2.g, Theme.bg2.b, 0.6)
                                border.width: 1; border.color: Theme.line2
                                Text { anchors.centerIn: parent; text: modelData; color: Theme.hi; font.family: Theme.serif; font.pixelSize: Theme.px(19) }
                                MouseArea { id: rsm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.useSymbol(parent.modelData, false) }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.line }
            Item {
                width: parent.width
                height: hints.implicitHeight + Theme.px(8)
                Row {
                    id: hints
                    spacing: Theme.px(16)
                    topPadding: Theme.px(8)
                    leftPadding: Theme.px(8)
                    Repeater {
                        model: root.tab === "clip" ? [["↵", "kopieren"], ["⇧ ↵", "einfügen"], ["Tab", "Bereich"], ["Ctrl D", "löschen"]]
                             : root.tab === "emoji" ? [["↵", "kopieren"], ["⇧ ↵", "einfügen"], ["←↑↓→", "wählen"], ["Tab", "Bereich"]]
                             : [["↑↓", "wählen"], ["↵", "öffnen"], ["Tab", "Bereich"], [">", "nur Befehle"]]
                        delegate: Row {
                            required property var modelData
                            spacing: Theme.px(6)
                            Kbd { text: modelData[0] }
                            Text { text: modelData[1]; color: Theme.mute; font.family: "Inter"; font.pixelSize: Theme.px(11); anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
                Text {
                    anchors { right: parent.right; rightMargin: Theme.px(8); verticalCenter: hints.verticalCenter; verticalCenterOffset: Theme.px(4) }
                    text: root.tab === "clip" ? "SUPER V" : root.tab === "emoji" ? "SUPER CTRL E" : "SUPER SPACE"
                    color: Theme.mute; font.family: "Inter"; font.pixelSize: Theme.px(10.5); font.letterSpacing: Theme.px(1.2)
                }
            }
        }
    }
    function focusFirst() { input.forceActiveFocus(); if (tab === "clip") clip.reload(); }
    // the first rows cascade in once when the launcher opens, not on every keystroke
    property bool settled: false
    Timer { interval: 700; running: true; onTriggered: root.settled = true }
}
