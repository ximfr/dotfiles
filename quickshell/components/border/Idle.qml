import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property bool expanded: false
    property int unreadCount: 0
    property bool musicPlaying: false
    property string currentMode: "pill"

    signal openPowerMenu()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    Component.onCompleted: {
        modeReadProc.running = true;
    }

    // Read current mode
    Process {
        id: modeReadProc

        command: ["sh", "-c", "cat /tmp/quickshell_mode.txt 2>/dev/null || echo 'pill'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let m = text.trim();
                if (m === "border" || m === "pill")
                    root.currentMode = m;

            }
        }

    }

    // Toggle mode process
    Process {
        id: toggleModeProc

        running: false
        command: []
        onRunningChanged: {
            if (!running)
                modeReadProc.running = true;

        }
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            time.text = Qt.formatDateTime(new Date(), "h:mm AP");
            date.text = Qt.formatDateTime(new Date(), "dd MMM");
            day.text = Qt.formatDateTime(new Date(), "ddd");
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: expanded ? 12 : 8

        Text {
            id: time

            text: Qt.formatDateTime(new Date(), "h:mm AP")
            color: "white"
            font.pixelSize: expanded ? 24 : 20
            font.bold: true

            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

        }

        // --- CAVA VISUALIZER ---
        Visualizer {
            id: cavaVis

            visible: root.musicPlaying
            Layout.preferredWidth: 56
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
        }

        Image {
            id: divider

            source: "./assets/rikka.png"
            sourceSize.height: expanded ? 28 : 22
            fillMode: Image.PreserveAspectFit

            Behavior on sourceSize.height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

        }

        RowLayout {
            visible: expanded
            opacity: expanded ? 1 : 0
            spacing: 8

            Text {
                id: date

                text: Qt.formatDateTime(new Date(), "dd MMM")
                color: "#bbbbbb"
                font.pixelSize: 16
            }

            Text {
                id: day

                text: Qt.formatDateTime(new Date(), "ddd")
                color: "#888888"
                font.pixelSize: 16
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }

            }

        }

        // --- MONOCHROME SIGN-STYLE MODE SWITCHER ---
        Rectangle {
            id: modeBtn

            Layout.preferredWidth: 42
            Layout.preferredHeight: 20
            radius: 5
            color: modeMouse.containsMouse ? themeDaemon.islandBg : themeDaemon.islandBg

            Text {
                text: root.currentMode === "border" ? "BORDER" : "PILL"
                color: "#ffffff"
                font.pixelSize: 8
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                id: modeMouse

                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => {
                    mouse.accepted = true;
                }
                onClicked: (mouse) => {
                    mouse.accepted = true;
                    toggleModeProc.command = ["sh", "-c", "CUR=$(cat /tmp/quickshell_mode.txt 2>/dev/null || echo 'pill'); if [ \"$CUR\" = 'border' ]; then echo 'pill' > /tmp/quickshell_mode.txt; else echo 'border' > /tmp/quickshell_mode.txt; fi"];
                    toggleModeProc.running = true;
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }

            }

        }

    }

}
