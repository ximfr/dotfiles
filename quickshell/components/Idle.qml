import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool expanded: false
    property int unreadCount: 0

    signal openPowerMenu()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        running: true
        repeat: true
        interval: 1000

        onTriggered: {
            time.text = Qt.formatDateTime(new Date(), "h:mm AP")
            date.text = Qt.formatDateTime(new Date(), "dd MMM")
            day.text = Qt.formatDateTime(new Date(), "ddd")
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: expanded ? 10 : 6

        Text {
            id: time

            text: Qt.formatDateTime(new Date(), "h:mm AP")

            color: "white"
            font.pixelSize: expanded ? 22 : 18
            font.bold: true

            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        Image {
            id: divider

            source: "./assets/rikka.png" 

            sourceSize.height: expanded ? 26 : 20
            fillMode: Image.PreserveAspectFit

            Behavior on sourceSize.height {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        RowLayout {
            visible: expanded

            opacity: expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            spacing: 8

            Text {
                id: date

                text: Qt.formatDateTime(new Date(), "dd MMM")
                color: "#bbbbbb"
                font.pixelSize: 15
            }

            Text {
                id: day

                text: Qt.formatDateTime(new Date(), "ddd")
                color: "#888888"
                font.pixelSize: 15
            }
        }

        // --- UNREAD NOTIFICATION BADGE ---
        Rectangle {
            id: notifBadge
            visible: root.unreadCount > 0
            Layout.preferredWidth: 26
            Layout.preferredHeight: 18
            radius: 5
            color: "#1c1c1c"
            border.width: 1
            border.color: "#333333"

            RowLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: "💬"
                    font.pixelSize: 8
                }

                Text {
                    text: root.unreadCount.toString()
                    color: "white"
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }

        // --- POWER MENU BUTTON ---
        Rectangle {
            id: powerBtn
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: 5

            color: powerMouse.containsMouse ? "#221111" : "#111111"
            border.width: 1
            border.color: powerMouse.containsMouse ? "#ff5555" : "#1a1a1a"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                text: "⏻"
                font.pixelSize: 10
                anchors.centerIn: parent
                color: powerMouse.containsMouse ? "#ff5555" : "#888888"
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                onPressed: (mouse) => {
                    mouse.accepted = true;
                }

                onClicked: (mouse) => {
                    mouse.accepted = true;
                    root.openPowerMenu();
                }
            }
        }
    }
}