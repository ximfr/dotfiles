import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string title: "No Title"
    property string artist: "Unknown Artist"
    property string elapsedTime: "0:00"
    property string totalDuration: "0:00"
    property real percent: 0
    property bool isPlaying: false
    property int coverVersion: 0
    property string coverPath: "file:///tmp/cover.png?" + coverVersion
    property string rawTitle: "No Title"
    property string rawArtist: "Unknown Artist"
    property string rawPosition: "0"
    property string rawLength: "0"
    property string rawStatus: "Stopped"

    function formatTime(sec) {
        if (sec <= 0)
            return "0:00";

        let m = Math.floor(sec / 60);
        let s = sec % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function control(action) {
        controlProc.action = action;
        controlProc.running = true;
    }

    function seek(percentStr) {
        seekProc.percentStr = percentStr;
        seekProc.running = true;
    }

    Component.onCompleted: {
        statusProc.running = true;
        coverExtractor.running = true;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            statusProc.running = true;
        }
    }

    Process {
        id: statusProc

        command: ["sh", "-c", "playerctl metadata --format '{{title}}\n{{artist}}\n{{position}}\n{{mpris:length}}' 2>/dev/null && playerctl status 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                if (lines.length >= 5) {
                    root.title = lines[0] !== "" ? lines[0] : "No Title";
                    root.artist = lines[1] !== "" ? lines[1] : "Unknown Artist";
                    let pos = parseFloat(lines[2]) || 0;
                    let len = parseFloat(lines[3]) || 0;
                    let status = lines[4];
                    root.isPlaying = (status === "Playing");
                    let pos_sec = pos > 100000 ? Math.round(pos / 1e+06) : Math.round(pos);
                    let len_sec = len > 100000 ? Math.round(len / 1e+06) : Math.round(len);
                    root.elapsedTime = root.formatTime(pos_sec);
                    root.totalDuration = root.formatTime(len_sec);
                    root.percent = len_sec > 0 ? (pos_sec * 100 / len_sec) : 0;
                } else {
                    root.title = "Not Playing";
                    root.artist = "No Active Media";
                    root.elapsedTime = "0:00";
                    root.totalDuration = "0:00";
                    root.percent = 0;
                    root.isPlaying = false;
                }
            }
        }

    }

    Process {
        id: controlProc

        property string action: ""

        command: {
            let targetAction = action;
            if (action === "toggle")
                targetAction = "play-pause";

            if (action === "prev")
                targetAction = "previous";

            return ["playerctl", targetAction];
        }
        onRunningChanged: {
            if (!running)
                statusProc.running = true;

        }
    }

    Process {
        id: seekProc

        property string percentStr: ""

        command: {
            let pct = parseInt(percentStr.replace("%", "")) || 0;
            return ["sh", "-c", "LEN=$(playerctl metadata mpris:length 2>/dev/null) && LEN_SEC=$((LEN / 1000000)) && TARGET_SEC=$((LEN_SEC * " + pct + " / 100)) && playerctl position $TARGET_SEC 2>/dev/null"];
        }
        onRunningChanged: {
            if (!running)
                statusProc.running = true;

        }
    }

    Process {
        id: coverExtractor

        command: ["sh", "-c", "ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null) && if [ -n \"$ART_URL\" ]; then if echo \"$ART_URL\" | grep -q '^file://'; then cp \"${ART_URL#file://}\" /tmp/cover.png 2>/dev/null; else curl -s \"$ART_URL\" > /tmp/cover.tmp 2>/dev/null && mv /tmp/cover.tmp /tmp/cover.png 2>/dev/null; fi; fi"]
        onRunningChanged: {
            if (!running)
                root.coverVersion++;

        }

        stdout: SplitParser {
        }

    }

    Process {
        id: mediaWatcher

        command: ["playerctl", "-F", "metadata"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                coverDelay.restart();
                statusProc.running = true;
            }
        }

    }

    Timer {
        id: coverDelay

        interval: 300
        repeat: false
        onTriggered: {
            coverExtractor.running = true;
        }
    }

}
