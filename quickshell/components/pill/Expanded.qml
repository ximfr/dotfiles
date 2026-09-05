import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    // ==========================================
    // UI LAYOUT
    // ==========================================

    id: root

    property bool musicPlaying: false
    property real cpu: 0
    property real ram: 0
    property real prevTotal: 0
    property real prevIdle: 0
    property string hours: ""
    property string minutes: ""
    property string ampm: ""
    property int currentNotifIndex: 0

    signal requestClose()

    function updateClock() {
        let d = new Date();
        let h = d.getHours() % 12 || 12;
        root.hours = h < 10 ? "0" + h : "" + h;
        root.minutes = Qt.formatDateTime(d, "mm");
        root.ampm = d.getHours() >= 12 ? "PM" : "AM";
    }

    implicitWidth: 450
    implicitHeight: 84
    onVisibleChanged: {
        if (visible)
            inactivityTimer.restart();
        else
            inactivityTimer.stop();
    }
    Component.onCompleted: {
        root.updateClock();
        sysStatsProc.running = true;
    }

    ListModel {
        id: notifModel
    }

    Timer {
        id: inactivityTimer

        interval: 5000
        repeat: false
        running: false
        onTriggered: {
            root.requestClose();
        }
    }

    // ==========================================
    // NOTIFICATION SERVER
    // ==========================================
    NotificationServer {
        id: notifServer

        keepOnReload: true
        bodySupported: true
        onNotification: (notification) => {
            let app = notification.appName !== "" ? notification.appName : "Notification";
            let sum = notification.summary !== "" ? notification.summary : "New Notification";
            let bod = notification.body !== "" ? notification.body : "";
            let timeStr = Qt.formatDateTime(new Date(), "h:mm AP");
            notifModel.insert(0, {
                "appName": app,
                "summary": sum,
                "body": bod,
                "time": timeStr
            });
            root.currentNotifIndex = 0;
            inactivityTimer.restart();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.updateClock();
            sysStatsProc.running = true;
        }
    }

    Process {
        id: sysStatsProc

        command: ["sh", "-c", "cat /proc/stat | grep '^cpu ' && cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'"]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                if (lines.length >= 3) {
                    let cpuParts = lines[0].replace(/\s+/g, ' ').split(' ');
                    let user = parseFloat(cpuParts[1]) || 0;
                    let nice = parseFloat(cpuParts[2]) || 0;
                    let system = parseFloat(cpuParts[3]) || 0;
                    let idle = parseFloat(cpuParts[4]) || 0;
                    let iowait = parseFloat(cpuParts[5]) || 0;
                    let irq = parseFloat(cpuParts[6]) || 0;
                    let softirq = parseFloat(cpuParts[7]) || 0;
                    let steal = parseFloat(cpuParts[8]) || 0;
                    let total = user + nice + system + idle + iowait + irq + softirq + steal;
                    let idleTime = idle + iowait;
                    if (root.prevTotal > 0) {
                        let diffTotal = total - root.prevTotal;
                        let diffIdle = idleTime - root.prevIdle;
                        if (diffTotal > 0)
                            root.cpu = Math.max(0, Math.min(100, ((diffTotal - diffIdle) / diffTotal) * 100));

                    }
                    root.prevTotal = total;
                    root.prevIdle = idleTime;
                    let totalMem = 0;
                    let availMem = 0;
                    for (let i = 1; i < lines.length; i++) {
                        if (lines[i].includes("MemTotal:"))
                            totalMem = parseFloat(lines[i].replace(/[^0-9]/g, '')) || 0;
                        else if (lines[i].includes("MemAvailable:"))
                            availMem = parseFloat(lines[i].replace(/[^0-9]/g, '')) || 0;
                    }
                    if (totalMem > 0)
                        root.ram = Math.max(0, Math.min(100, ((totalMem - availMem) / totalMem) * 100));

                }
            }
        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        // CLOCK COLUMN
        Column {
            id: clockCol

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 40
            spacing: -4

            Text {
                text: root.hours
                color: "white"
                font.pixelSize: 22
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.ampm
                color: "#888888"
                font.pixelSize: 9
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.minutes
                color: "#666666"
                font.pixelSize: 22
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

        // CPU / RAM STATS (RIGHT NEXT TO CLOCK)
        Row {
            id: statsRow

            Layout.alignment: Qt.AlignVCenter
            spacing: 10

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 5
                    height: 46
                    color: "#111111"
                    radius: 3
                    border.width: 1
                    border.color: "#1c1a1a"

                    Rectangle {
                        width: parent.width
                        height: parent.height * (root.cpu / 100)
                        color: "white"
                        radius: 3
                        anchors.bottom: parent.bottom

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

                Text {
                    text: "CPU"
                    color: "#666666"
                    font.pixelSize: 8
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 5
                    height: 46
                    color: "#111111"
                    radius: 3
                    border.width: 1
                    border.color: "#1c1a1a"

                    Rectangle {
                        width: parent.width
                        height: parent.height * (root.ram / 100)
                        color: "white"
                        radius: 3
                        anchors.bottom: parent.bottom

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

                Text {
                    text: "RAM"
                    color: "#666666"
                    font.pixelSize: 8
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }

        }

        Rectangle {
            id: mainSeparator

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 2
            height: 50
            color: "#1a1a1a"
        }

        // ==========================================
        // DEDICATED NOTIFICATION DISPLAY AREA
        // ==========================================
        Rectangle {
            id: notifCard

            property var currentNotif: notifModel.count > 0 ? notifModel.get(Math.min(root.currentNotifIndex, notifModel.count - 1)) : null

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: "#141414"
            border.width: 1
            border.color: "#282828"

            // DISPLAY NOTIFICATIONS IF THEY EXIST
            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8
                visible: notifModel.count > 0

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                    radius: 8
                    color: "#1f1f1f"
                    border.width: 1
                    border.color: "#333333"

                    Text {
                        text: "💬"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: notifCard.currentNotif ? notifCard.currentNotif.appName : "Notification"
                            color: "#999999"
                            font.pixelSize: 9
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: notifCard.currentNotif ? notifCard.currentNotif.time : ""
                            color: "#555555"
                            font.pixelSize: 8
                        }

                    }

                    Text {
                        text: notifCard.currentNotif ? notifCard.currentNotif.summary : ""
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: notifCard.currentNotif ? notifCard.currentNotif.body : ""
                        color: "#888888"
                        font.pixelSize: 9
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: notifCard.currentNotif && notifCard.currentNotif.body !== ""
                    }

                }

                // CONTROLS COLUMN
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Row {
                        spacing: 4
                        visible: notifModel.count > 1

                        Text {
                            text: "◀"
                            color: root.currentNotifIndex < notifModel.count - 1 ? "#aaaaaa" : "#444444"
                            font.pixelSize: 9

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    inactivityTimer.restart();
                                    if (root.currentNotifIndex < notifModel.count - 1)
                                        root.currentNotifIndex++;

                                }
                            }

                        }

                        Text {
                            text: (root.currentNotifIndex + 1) + "/" + notifModel.count
                            color: "#666666"
                            font.pixelSize: 8
                        }

                        Text {
                            text: "▶"
                            color: root.currentNotifIndex > 0 ? "#aaaaaa" : "#444444"
                            font.pixelSize: 9

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    inactivityTimer.restart();
                                    if (root.currentNotifIndex > 0)
                                        root.currentNotifIndex--;

                                }
                            }

                        }

                    }

                    // DISMISS BUTTON
                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignHCenter
                        radius: 9
                        color: "#1a1a1a"
                        border.width: 1
                        border.color: "#2a2a2a"

                        Text {
                            text: "✕"
                            color: "#aaaaaa"
                            font.pixelSize: 9
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                inactivityTimer.restart();
                                if (notifModel.count > 0)
                                    notifModel.remove(Math.min(root.currentNotifIndex, notifModel.count - 1));

                                if (root.currentNotifIndex >= notifModel.count && notifModel.count > 0)
                                    root.currentNotifIndex = notifModel.count - 1;

                            }
                        }

                    }

                }

            }

            // DISPLAY IF NO NOTIFICATIONS EXIST
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: notifModel.count === 0

                Text {
                    text: "🔔"
                    font.pixelSize: 14
                    opacity: 0.5
                }

                Text {
                    text: "No New Notifications"
                    color: "#666666"
                    font.pixelSize: 10
                    font.bold: true
                }

            }

        }

    }

}
