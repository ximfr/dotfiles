import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland._GlobalShortcuts

ShellRoot {
    PanelWindow {
        id: panel
        anchors { top: true; left: true; right: true }
        implicitHeight: 40
        color: '#000000'

        Process {
            id: powerProcess
        }
        Process {
            id: spotifyMenuProcess
        }
        Process {
            id: appLauncherProcess
        }

        AppLauncher {
            id: appLauncher
        }

        GlobalShortcut {
    appid: "quickshell"
    name: "launcher"
    description: "Toggle launcher"
    onPressed: appLauncher.toggle()
}

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            spacing: 7

            RowLayout {
                spacing: 24
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Workspaces {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                }
                Rectangle { width: 1; height: 16; color: root.colMuted }
                Clock {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

            NowPlaying {
                process: spotifyMenuProcess
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }

           
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Rectangle {
                    width: 30
                    height: 30
                    radius: 6
                    color: "#111111"
                    border.color: "#333"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "⌘"
                        color: "#f5e2d0"
                        font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: appLauncher.toggle()
                    }
                }

                 Rectangle { width: 1; height: 16; color: root.colMuted }

                Powerbutton {
                    process: powerProcess
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}


