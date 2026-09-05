import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var cavaValues: []
    property var music
    property string cavaConfigPath: ""

    implicitWidth: 450
    implicitHeight: 120
    Component.onCompleted: {
        let url = Qt.resolvedUrl("../cava.conf").toString();
        root.cavaConfigPath = url.replace("file://", "");
        cava.running = true;
    }

    Process {
        id: cava

        running: false
        command: ["cava", "-p", root.cavaConfigPath]

        stdout: SplitParser {
            onRead: (data) => {
                root.cavaValues = data.trim().split(";");
            }
        }

    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 10

        // ------------------------------------------
        // ROW 1: [COVER] [TITLE & ARTIST] --- [CAVA VISUALIZER]
        // ------------------------------------------
        Item {
            width: parent.width
            height: 40

            Rectangle {
                id: coverRect

                width: 40
                height: 40
                radius: 8
                clip: true
                color: "#111111"
                border.width: 1
                border.color: "#1c1a1a"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    cache: false
                    source: music ? music.coverPath : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }

            }

            Column {
                id: titleCol

                anchors.left: coverRect.right
                anchors.leftMargin: 12
                anchors.right: visualizerRow.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: music ? music.title : "No Title"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: music ? music.artist : "Unknown Artist"
                    color: "#888888"
                    font.pixelSize: 10
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

            }

            Row {
                id: visualizerRow

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                height: 30
                spacing: 2

                Repeater {
                    model: Math.min(root.cavaValues.length, 20)

                    Rectangle {
                        width: 3
                        height: {
                            let v = parseInt(root.cavaValues[index]) || 0;
                            return Math.max(2, v / 5);
                        }
                        color: "white"
                        radius: 1.5
                        anchors.bottom: parent.bottom
                    }

                }

            }

        }

        // ------------------------------------------
        // ROW 2: PROGRESS BAR TIMELINE
        // ------------------------------------------
        Row {
            width: parent.width
            height: 14
            spacing: 8

            Text {
                text: music ? music.elapsedTime : "0:00"
                color: "#666666"
                font.pixelSize: 9
                font.bold: true
                width: 28
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                height: 4
                color: "#111111"
                radius: 2
                border.width: 1
                border.color: "#1a1a1a"
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 72
                clip: true

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, (music ? music.percent : 0) / 100))
                    color: "white"
                    radius: 2

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }

                    }

                }

                MouseArea {
                    function updateSeek(mouseX) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouseX / parent.width) * 100)));
                        if (music)
                            music.seek(pct + "%");

                    }

                    anchors.fill: parent
                    onPressed: function(mouse) {
                        updateSeek(mouse.x);
                    }
                    onPositionChanged: function(mouse) {
                        updateSeek(mouse.x);
                    }
                }

            }

            Text {
                text: music ? music.totalDuration : "0:00"
                color: "#666666"
                font.pixelSize: 9
                font.bold: true
                width: 28
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        // ------------------------------------------
        // ROW 3: PLAYBACK CONTROLS
        // ------------------------------------------
        Item {
            width: parent.width
            height: 22

            Row {
                anchors.centerIn: parent
                spacing: 48
                height: parent.height

                Text {
                    text: "⏮"
                    color: "white"
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: prevMouse.containsMouse ? 1 : 0.7

                    MouseArea {
                        id: prevMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (music)
                                music.control("prev");

                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

                Text {
                    text: (music && music.isPlaying) ? "⏸" : "▶"
                    color: "white"
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: playMouse.containsMouse ? 1 : 0.7

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (music)
                                music.control("toggle");

                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

                Text {
                    text: "⏭"
                    color: "white"
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: nextMouse.containsMouse ? 1 : 0.7

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (music)
                                music.control("next");

                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

            }

        }

    }

}
