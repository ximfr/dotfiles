import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Item {
    id: root

    property bool musicPlaying: false

    implicitWidth: 380
    implicitHeight: 110

    property real cpu: 0
    property real ram: 0
    property real vol: 50

    property real prevTotal: 0
    property real prevIdle: 0

    property string hours: ""
    property string minutes: ""
    property string ampm: ""

    property bool dndActive: false
    property string latestNotifAppName: ""
    property string latestNotifSummary: ""
    property string latestNotifBody: ""
    property bool showNotifBanner: false
    property int unreadCount: 0

    function updateClock() {
        let d = new Date();
        let h = d.getHours() % 12 || 12;
        root.hours = h < 10 ? "0" + h : "" + h;
        root.minutes = Qt.formatDateTime(d, "mm");
        root.ampm = d.getHours() >= 12 ? "PM" : "AM";
    }

    function switchToWorkspace(wsId) {
        wsProc.command = ["hyprctl", "dispatch", "workspace", wsId.toString()];
        wsProc.running = true;
    }

    
    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true

        onNotification: (notification) => {
            if (!root.dndActive) {
                root.latestNotifAppName = notification.appName !== "" ? notification.appName : "Notification";
                root.latestNotifSummary = notification.summary !== "" ? notification.summary : "";
                root.latestNotifBody = notification.body !== "" ? notification.body : "";
                root.showNotifBanner = true;
                root.unreadCount++;
                notifTimer.restart();
            }
        }
    }

    Timer {
        id: notifTimer
        interval: 6000
        repeat: false
        onTriggered: {
            root.showNotifBanner = false;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.updateClock();
            
            if (root.musicPlaying) {
                titleProc.running = true;
                artistProc.running = true;
            } else {
                sysStatsProc.running = true;
                volProc.running = true;
            }
        }
    }

    Component.onCompleted: {
        root.updateClock();
        if (root.musicPlaying) {
            titleProc.running = true;
            artistProc.running = true;
            coverExtractor.running = true;
        } else {
            sysStatsProc.running = true;
            volProc.running = true;
        }
    }

    

    Process {
        id: wsProc
        running: false
        command: []
    }

    Process {
        id: dndProc
        running: false
        command: []
    }

    Process {
        id: checkSwayncDnd
        command: ["swaync-client", "-D"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.dndActive = (text.trim() === "true");
            }
        }
    }

    Process {
        id: sysStatsProc
        command: [
            "sh",
            "-c",
            "cat /proc/stat | grep '^cpu ' && cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'"
        ]
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
                        if (diffTotal > 0) {
                            root.cpu = Math.max(0, Math.min(100, ((diffTotal - diffIdle) / diffTotal) * 100));
                        }
                    }
                    root.prevTotal = total;
                    root.prevIdle = idleTime;

                    let totalMem = 0;
                    let availMem = 0;
                    for (let i = 1; i < lines.length; i++) {
                        if (lines[i].includes("MemTotal:")) {
                            totalMem = parseFloat(lines[i].replace(/[^0-9]/g, '')) || 0;
                        } else if (lines[i].includes("MemAvailable:")) {
                            availMem = parseFloat(lines[i].replace(/[^0-9]/g, '')) || 0;
                        }
                    }
                    if (totalMem > 0) {
                        root.ram = Math.max(0, Math.min(100, ((totalMem - availMem) / totalMem) * 100));
                    }
                }
            }
        }
    }

    Process {
        id: volProc
        command: [
            "sh",
            "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseFloat(text.trim());
                if (!isNaN(v)) root.vol = Math.max(0, Math.min(100, v));
            }
        }
    }

    
    Process {
        id: volSetter
        running: false
        command: []
    }

   

    Column {
        id: clockCol
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        spacing: -6 

        Text {
            text: root.hours
            color: "white"
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.ampm
            color: "#888888"
            font.pixelSize: 10
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.minutes
            color: "#666666"
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Row {
        id: statsRow
        anchors.left: clockCol.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Column {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 6
                height: 64
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
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
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
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 6
                height: 64
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
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
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
        width: 3
        height: 70
        color: "#1a1a1a"
        anchors.left: statsRow.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: notifCard
        visible: root.showNotifBanner && !root.musicPlaying
        anchors.left: mainSeparator.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 210
        height: 70
        radius: 10
        color: "#141414"
        border.width: 1
        border.color: "#282828"

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Column {
                width: parent.width - 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "💬 " + root.latestNotifAppName
                    color: "#ffffff"
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - 12
                }

                Text {
                    text: root.latestNotifSummary
                    color: "#dddddd"
                    font.pixelSize: 10
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: root.latestNotifBody
                    color: "#888888"
                    font.pixelSize: 9
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            Text {
                text: "✕"
                color: "#666666"
                font.pixelSize: 10
                font.bold: true
                anchors.top: parent.top
                anchors.right: parent.right

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.showNotifBanner = false;
                    }
                }
            }
        }
    }

    Column {
        id: statsSlidersCol
        visible: !root.musicPlaying && !root.showNotifBanner
        anchors.left: mainSeparator.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 210
        spacing: 12

      
        Row {
            width: parent.width
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

           
            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

                    delegate: Rectangle {
                        id: wsBtn
                        width: 13
                        height: 20
                        radius: 4

                        property int wsId: modelData
                        property bool isCurrent: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)

                        color: isCurrent ? "#ffffff" : "#111111"
                        border.width: 1
                        border.color: isCurrent ? "#ffffff" : (btnMouse.containsMouse ? "#555555" : "#1a1a1a")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            text: wsId
                            color: wsBtn.isCurrent ? "#000000" : "#888888"
                            font.pixelSize: 8
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.switchToWorkspace(wsBtn.wsId);
                            }
                        }
                    }
                }
            }

            Item { width: 2 } 

           
            Rectangle {
                visible: root.unreadCount > 0
                width: 28
                height: 20
                radius: 5
                color: "#1c1c1c"
                border.width: 1
                border.color: "#333333"
                anchors.verticalCenter: parent.verticalCenter

                Row {
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

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.showNotifBanner = !root.showNotifBanner;
                    }
                }
            }

         
            Rectangle {
                id: dndBtn
                width: 20
                height: 20
                radius: 5
                anchors.verticalCenter: parent.verticalCenter

                color: root.dndActive ? "#ffffff" : "#111111"
                border.width: 1
                border.color: root.dndActive ? "#ffffff" : (dndMouse.containsMouse ? "#555555" : "#1a1a1a")

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    text: root.dndActive ? "🔕" : "🔔"
                    font.pixelSize: 10
                    anchors.centerIn: parent
                    color: root.dndActive ? "#000000" : "#ffffff"
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.dndActive = !root.dndActive;
                        dndProc.command = ["swaync-client", "-d", "-sw"];
                        dndProc.running = true;
                    }
                }
            }
        }

      
        Row {
            width: parent.width
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "VOL"
                color: "white"
                font.pixelSize: 9
                font.bold: true
                width: 24
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                height: 8
                color: "#111111"
                radius: 4
                border.width: 1
                border.color: "#1a1a1a"
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64

                Rectangle {
                    height: parent.height
                    width: parent.width * (root.vol / 100)
                    color: "white"
                    radius: 4

                    Behavior on width {
                        NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    
                    function updateVol(mouseX) {
                        let pct = Math.max(0, Math.min(100, Math.round((mouseX / parent.width) * 100)));
                        root.vol = pct;
                        volSetter.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"];
                        volSetter.running = true;
                    }

                    onPressed: function(mouse) { updateVol(mouse.x); }
                    onPositionChanged: function(mouse) { updateVol(mouse.x); }
                }
            }

            Text {
                text: root.vol.toFixed(0) + "%"
                color: "#666666"
                font.pixelSize: 9
                font.bold: true
                width: 24
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}