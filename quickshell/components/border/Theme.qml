import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property color islandBg: "#0a0a0d"
    property color islandFg: "#ffffff"
    property color islandMuted: "#888888"
    property color islandAccent: "#ffffff"

    function reloadColors() {
        domColorProc.running = false;
        domColorProc.running = true;
        colorsProc.running = false;
        colorsProc.running = true;
    }

    
    Process {
        id: domColorProc
        command: ["sh", "-c", "cat /tmp/dominant_color.txt 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let hex = text.trim();
                if (hex && hex.startsWith("#")) {
                    root.islandAccent = Qt.color(hex);
                }
            }
        }
    }

    Process {
        id: colorsProc
        command: ["sh", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text);
                    if (data && data.special) {
                        root.islandBg = Qt.color(data.special.background || "#0a0a0d");
                        root.islandFg = Qt.color(data.special.foreground || "#ffffff");
                        root.islandMuted = data.colors.color8 || "#888888";
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.reloadColors()
    }

    Component.onCompleted: root.reloadColors()
}