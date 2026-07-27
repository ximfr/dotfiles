import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal requestClose()

    implicitWidth: 380
    implicitHeight: 90

    Process {
        id: execProc
        running: false
        command: []
    }

    function runAction(cmd) {
        execProc.command = ["sh", "-c", cmd];
        execProc.running = true;
        root.requestClose();
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 14

        // 🔒 LOCK
        Rectangle {
            id: lockBtn
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 27
            color: lockMouse.containsMouse ? "#222222" : "#111111"
            border.width: 1
            border.color: lockMouse.containsMouse ? "#ffffff" : "#222222"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text { text: "🔒"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Lock"; color: "#888888"; font.pixelSize: 8; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                id: lockMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction("hyprlock || loginctl lock-session")
            }
        }

        // 🌙 SLEEP
        Rectangle {
            id: sleepBtn
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 27
            color: sleepMouse.containsMouse ? "#222222" : "#111111"
            border.width: 1
            border.color: sleepMouse.containsMouse ? "#ffffff" : "#222222"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text { text: "🌙"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Sleep"; color: "#888888"; font.pixelSize: 8; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                id: sleepMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction("systemctl suspend")
            }
        }

        // 🚪 LOGOUT
        Rectangle {
            id: logoutBtn
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 27
            color: logoutMouse.containsMouse ? "#222222" : "#111111"
            border.width: 1
            border.color: logoutMouse.containsMouse ? "#ffffff" : "#222222"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text { text: "🚪"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Logout"; color: "#888888"; font.pixelSize: 8; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                id: logoutMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction("hyprctl dispatch exit")
            }
        }

        // 🔄 REBOOT
        Rectangle {
            id: rebootBtn
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 27
            color: rebootMouse.containsMouse ? "#222222" : "#111111"
            border.width: 1
            border.color: rebootMouse.containsMouse ? "#ffb86c" : "#222222"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text { text: "🔄"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Reboot"; color: "#888888"; font.pixelSize: 8; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                id: rebootMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction("systemctl reboot")
            }
        }

        // ⏻ POWER OFF
        Rectangle {
            id: shutdownBtn
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 27
            color: shutdownMouse.containsMouse ? "#e53935" : "#111111"
            border.width: 1
            border.color: shutdownMouse.containsMouse ? "#e53935" : "#222222"

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text { text: "⏻"; color: shutdownMouse.containsMouse ? "#ffffff" : "#ff5555"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Power Off"; color: shutdownMouse.containsMouse ? "#ffffff" : "#888888"; font.pixelSize: 8; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }

            MouseArea {
                id: shutdownMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction("systemctl poweroff")
            }
        }
    }
}