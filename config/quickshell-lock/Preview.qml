import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    id: root
    Preferences { id: prefs }
    FloatingWindow {
        id: window
        title: "Lock screen preview — not locked"
        implicitWidth: 1100
        implicitHeight: 700
        color: "#1d2021"
        LockView {
            id: view
            anchors.fill: parent
            theme: prefs
            preview: true
            message: "Preview only — no authentication"
            onSubmitted: { clearInput(); expanded = false; }
        }
        Timer { interval: 500; running: true; onTriggered: view.expanded = true }
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 20 }
            width: controls.implicitWidth + 24
            height: controls.implicitHeight + 16
            radius: 12
            color: "#ee1d2021"
            RowLayout {
                id: controls
                anchors.centerIn: parent
                spacing: 12
                Text { text: "PREVIEW · Not locked"; color: prefs.foreground; font.family: prefs.fontFamily }
                Button { text: "Lock animation"; onClicked: { view.expanded = true; view.focusInput(); } }
                Button { text: "Unlock animation"; onClicked: { view.clearInput(); view.expanded = false; } }
                Button { text: "Close"; onClicked: Qt.quit() }
            }
        }
        onVisibleChanged: if (!visible) Qt.quit()
    }
}
