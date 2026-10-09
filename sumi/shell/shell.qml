//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell

// Sumi shell: bar, launcher, panels, notifications, OSD and polkit in one process.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component { Bar {} }
    }
    Overlay {}
    Notifications {}
    Osd {}
    Polkit {}

    Component.onCompleted: {
        // demo/test hook: open a panel straight away
        const p = Quickshell.env("SUMI_OPEN");
        if (p) Ui.open(p);
        Quickshell.inhibitReloadPopup();
    }
}
