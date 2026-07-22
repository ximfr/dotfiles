import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./components"
import Quickshell.Io
import QtQuick.Window

PanelWindow {
    id: root

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors.top: true

    WlrLayershell.keyboardFocus: (island.expanded && (island.expandMode === "apps" || island.expandMode === "wallpapers")) 
                             ? KeyboardFocus.Exclusive 
                             : KeyboardFocus.None

    implicitWidth: 460
    implicitHeight: 270

    mask: Region {
        item: island
    }

    
    GlobalShortcut {
        name: "toggleAppLauncher"
        onPressed: {
            if (island.expanded && island.expandMode === "apps") {
                island.expanded = false;
            } else {
                island.expandMode = "apps";
                island.expanded = true;
            }
        }
    }

  
    GlobalShortcut {
        name: "toggleWallpaperSelector"
        onPressed: {
            if (island.expanded && island.expandMode === "wallpapers") {
                island.expanded = false;
            } else {
                island.expandMode = "wallpapers";
                island.expanded = true;
            }
        }
    }

    MusicInfo {
        id: musicDaemon
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [ root ]
        onCleared: {
            island.expanded = false;
        }
    }

    Rectangle {
        id: island

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 17

        property bool expanded: false
        property bool musicPlaying: musicDaemon.isPlaying
        property string expandMode: "stats"
        property bool dndActive: false

        width: expanded ? (expandMode === "notif" ? 380 : expandMode === "wallpapers" ? 390 : 380) : 210
        height: expanded ? (expandMode === "notif" ? 82 : expandMode === "music" ? 140 : expandMode === "apps" ? 220 : expandMode === "wallpapers" ? 230 : 110) : 40
        radius: 20

        clip: true

        color: expanded ? "#ff000000" : '#e9000000'
        border.width: 1
        border.color: '#000000'

        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        onExpandedChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
        }

        onExpandModeChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton 

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    island.expandMode = "music";
                    island.expanded = !island.expanded;
                } 
                else if (mouse.button === Qt.MiddleButton) {
                    island.expandMode = "apps";
                    island.expanded = !island.expanded;
                }
                else {
                    island.expandMode = "stats";
                    island.expanded = !island.expanded;
                }
            }
        }

   
        Idle {
            id: idleView
            z: 10
            anchors.centerIn: parent
            visible: !island.expanded && !island.musicPlaying
            dndActive: island.dndActive
            unreadCount: notifDaemon.unreadCount
            onToggleDnd: {
                island.dndActive = !island.dndActive;
            }
        }

        Visualizer {
            anchors.centerIn: parent
            visible: !island.expanded && island.musicPlaying
        }

      
        NotificationIsland {
            id: notifDaemon
            z: 10
            anchors.centerIn: parent
            width: parent.width - 24
            height: parent.height - 14
            dndActive: island.dndActive
            visible: island.expanded && island.expandMode === "notif"

            onNotificationTriggered: {
                island.expandMode = "notif";
                island.expanded = true;
            }

            onCloseRequested: {
                if (island.expandMode === "notif") {
                    island.expanded = false;
                }
            }
        }

        Expanded {
            id: expandedView
            anchors.centerIn: parent
            visible: island.expanded && island.expandMode === "stats"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        Music {
            id: musicView
            anchors.centerIn: parent
            music: musicDaemon
            visible: island.expanded && island.expandMode === "music"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        AppLauncher {
            id: appLauncherView
            anchors.fill: parent
            visible: island.expanded && island.expandMode === "apps"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }

        WallpaperSelector {
            id: wallpaperView
            anchors.fill: parent
            visible: island.expanded && island.expandMode === "wallpapers"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }
    }
}