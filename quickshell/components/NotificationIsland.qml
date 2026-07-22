import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root


    property bool dndActive: false
    property int unreadCount: 0
    property bool active: false


    property string appName: ""
    property string summary: ""
    property string body: ""


    signal notificationTriggered()
    signal closeRequested()

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true

        onNotification: (notification) => {
            if (!root.dndActive) {
                root.appName = notification.appName !== "" ? notification.appName : "Notification";
                root.summary = notification.summary !== "" ? notification.summary : "";
                root.body = notification.body !== "" ? notification.body : "";
                root.unreadCount++;
                root.active = true;
                
                root.notificationTriggered();
                notifTimer.restart();
            }
        }
    }

   
    Timer {
        id: notifTimer
        interval: 5000
        repeat: false
        running: false
        onTriggered: {
            root.active = false;
            root.closeRequested();
        }
    }

   
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 28
        spacing: 12

        
        Rectangle {
            width: 40
            height: 40
            radius: 10
            color: "#1f1f1f"
            border.width: 1
            border.color: "#333333"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "💬"
                font.pixelSize: 18
                anchors.centerIn: parent
            }
        }

   
        Column {
            width: parent.width - 52
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Row {
                width: parent.width
                spacing: 6

                Text {
                    text: root.appName
                    color: "#999999"
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "• now"
                    color: "#555555"
                    font.pixelSize: 9
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: root.summary
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                width: parent.width
                elide: Text.ElideRight
            }

            Text {
                text: root.body
                color: "#cccccc"
                font.pixelSize: 11
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: 2
                visible: root.body !== ""
            }
        }
    }

  
    Rectangle {
        width: 22
        height: 22
        radius: 11
        color: "#1a1a1a"
        border.width: 1
        border.color: "#2a2a2a"
        anchors.top: parent.top
        anchors.right: parent.right

        Text {
            text: "✕"
            color: "#aaaaaa"
            font.pixelSize: 11
            font.bold: true
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.active = false;
                root.closeRequested();
            }
        }
    }
}