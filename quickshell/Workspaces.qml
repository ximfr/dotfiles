import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

RowLayout {
    spacing: 7

    property string previousWorkspacesJson: ""
    ListModel { id: wsModel }

    Process {
        id: hyprProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var trimmed = text.trim()
                if (trimmed.length === 0 || trimmed === previousWorkspacesJson) {
                    return
                }
                previousWorkspacesJson = trimmed
                try {
                    var j = JSON.parse(trimmed)
                    j.sort(function(a, b) { return a.id - b.id })
                    wsModel.clear()
                    for (var i = 0; i < j.length; ++i) {
                        var ws = j[i]
                        // include workspaces with windows OR the currently focused workspace
                        var hasWindows = (ws.windows && ws.windows > 0)
                        var isFocused = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws.id)
                        if (hasWindows || isFocused) {
                            wsModel.append({ id: ws.id, name: ws.name })
                        }
                    }
                } catch(e) {
                   
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!hyprProcess.running) {
                hyprProcess.exec(["sh","-c","hyprctl -j workspaces 2>/dev/null"])
            }
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (!hyprProcess.running) {
                hyprProcess.exec(["sh","-c","hyprctl -j workspaces 2>/dev/null"])
            }
        }
    }

    Repeater {
        model: wsModel
        delegate: Text {
            property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === model.id
            text: model.name
            color: isActive ? "#f5e2d0" : "#8a8a8a"
            font.pixelSize: 18
            font.bold: isActive
        }
    }
}
