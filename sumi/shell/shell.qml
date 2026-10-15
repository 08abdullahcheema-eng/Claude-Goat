//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Sumi shell: bar, launcher, panels, notifications, OSD and polkit in one process.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component { BarHost {} }
    }
    Overlay {}
    // while the theme picker is open, a live copy of the browsed theme's bar sits above it
    LazyLoader {
        active: Theme.pickLayout !== ""
        BarHost {
            modelData: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            preview: true
        }
    }
    Notifications {}
    Osd {}
    Polkit {}
    Saver {}

    Component.onCompleted: {
        // demo/test hook: open a panel straight away
        const lm = Quickshell.env("SUMI_LAUNCHER");
        if (lm) Ui.launcherMode = lm;
        const p = Quickshell.env("SUMI_OPEN");
        if (p) Ui.open(p);
        if (Quickshell.env("SUMI_DEMO_SAVER") === "1") Ui.saver = true;
        Quickshell.inhibitReloadPopup();
    }
}
