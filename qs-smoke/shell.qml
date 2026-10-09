import QtQuick
import Quickshell
ShellRoot {
  PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#0f0f14"
    Text { anchors.centerIn: parent; text: "sumi smoke " + Quickshell.env("USER"); color: "#c8323a"; font.pixelSize: 20 }
  }
}
