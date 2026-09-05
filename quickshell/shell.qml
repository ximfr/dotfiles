import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property string shellMode: "pill"

    Component.onCompleted: modeProc.running = true

    Process {
        id: modeProc

        running: true
        command: ["sh", "-c", "cat /tmp/quickshell_mode.txt 2>/dev/null || echo 'pill'"]

        stdout: StdioCollector {
            onStreamFinished: {
                var m = text.trim();
                if (m === "border" || m === "pill")
                    root.shellMode = m;

            }
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: modeProc.running = true
    }

    Loader {
        id: moduleLoader

        active: true
        source: root.shellMode === "border" ? Qt.resolvedUrl("modules/border/Border.qml") : Qt.resolvedUrl("modules/pill/Pill.qml")
    }

}
