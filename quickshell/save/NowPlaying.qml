import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: nowPlaying
    implicitWidth: 340
    implicitHeight: controlsOpen ? 88 : 40
        Layout.preferredWidth: 340
        Layout.maximumWidth: 340
    Layout.preferredHeight: implicitHeight
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

    property bool hasTrack: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string displayText: ""
    property string coverUrl: ""
    property string status: ""
    property bool controlsOpen: false
    property var process

    Process {
        id: playerctlProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var trimmed = text.trim()
                if (trimmed.length === 0) {
                    hasTrack = false
                    trackTitle = ""
                    trackArtist = ""
                    displayText = ""
                    coverUrl = ""
                    status = ""
                    return
                }

                var parts = trimmed.split("||")
                coverUrl = parts[0] ? parts[0].trim() : ""
                trackArtist = parts[1] ? parts[1].trim() : ""
                trackTitle = parts[2] ? parts[2].trim() : ""
                status = parts[3] ? parts[3].trim() : ""
                hasTrack = trackTitle.length > 0 || trackArtist.length > 0

                if (trackTitle && trackArtist) {
                    displayText = trackArtist + " - " + trackTitle
                } else if (trackTitle) {
                    displayText = trackTitle
                } else {
                    displayText = trackArtist
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                hasTrack = false
                trackTitle = ""
                trackArtist = ""
                displayText = ""
                coverUrl = ""
                status = ""
            }
        }
    }

    Process {
        id: controlProcess
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!playerctlProcess.running) {
                playerctlProcess.exec(["sh", "-c", "/usr/sbin/playerctl -p spotify metadata --format '{{mpris:artUrl}}||{{ artist }}||{{ title }}||{{ status }}' 2>/dev/null | head -n 1"])
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            RowLayout {
                anchors.fill: parent
                spacing: 6

                Rectangle {
                    id: coverBox
                    Layout.alignment: Qt.AlignVCenter
                    width: 40
                    height: 40
                    radius: width / 2
                    color: coverUrl !== "" ? "transparent" : "#111111"
                    border.color: "#333"
                    border.width: 1
                    opacity: hasTrack ? 1 : 0.4
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: coverUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: coverUrl !== ""
                        smooth: true
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                    Text {
                        text: hasTrack ? displayText : "No track playing"
                        color: "#f5e2d0"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }
                    Text {
                        text: hasTrack ? status : "Click to open Spotify menu"
                        color: "#8a8a8a"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        maximumLineCount: 1
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                id: popupPanel
                width: parent.width
                height: controlsOpen ? 42 : 0
                radius: 8
                color: "#0b0b0b"
                border.color: "#222"
                border.width: controlsOpen ? 1 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter
                    opacity: controlsOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 6
                        color: "#111111"
                        border.color: "#333"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "⏮︎"
                            font.pixelSize: 14
                            color: "#f5e2d0"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlProcess.exec(["sh", "-c", "/usr/sbin/playerctl previous"])
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 6
                        color: "#111111"
                        border.color: "#333"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: status === "Playing" ? "⏸︎" : "▶︎"
                            font.pixelSize: 14
                            color: "#f5e2d0"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlProcess.exec(["sh", "-c", "/usr/sbin/playerctl play-pause"])
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 6
                        color: "#111111"
                        border.color: "#333"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "⏭︎"
                            font.pixelSize: 14
                            color: "#f5e2d0"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlProcess.exec(["sh", "-c", "/usr/sbin/playerctl next"])
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (process) {
                        process.exec(["sh", "-c", "eww open spotifymenu"])
                    }
                }
            }
        }
    }
}