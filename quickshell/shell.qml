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

    // Automatically hide when any app goes fullscreen
    visible: !(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen)

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

    Theme {
        id: themeDaemon
    }

    // 5-SECOND AUTO-CLOSE TIMER
    Timer {
        id: autoCloseTimer
        interval: 5000
        repeat: false
        running: false
        onTriggered: {
            island.expanded = false;
        }
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

    GlobalShortcut {
        name: "togglePowerMenu"
        onPressed: {
            if (island.expanded && island.expandMode === "power") {
                island.expanded = false;
            } else {
                island.expandMode = "power";
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

    // ==========================================
    // FLUSH TOP DYNAMIC ISLAND
    // ==========================================
    Rectangle {
        id: island

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        // FLUSH TO TOP EDGE
        anchors.topMargin: 0

        property bool expanded: false
        property bool musicPlaying: musicDaemon.isPlaying
        property string expandMode: "stats" // "stats", "music", "apps", "wallpapers", "notif", "power"
        property bool dndActive: false

        width: expanded ? (expandMode === "power" ? 380 : expandMode === "notif" ? 380 : expandMode === "wallpapers" ? 390 : 380) : 210
        height: expanded ? (expandMode === "power" ? 90 : expandMode === "notif" ? 82 : expandMode === "music" ? 140 : expandMode === "apps" ? 220 : expandMode === "wallpapers" ? 230 : 110) : 36
        
        // Rounded bottom corners
        radius: 18

        clip: true

        border.width: 0
        border.color: "transparent"

        // Pure Pywal Background Color
        color: expanded 
               ? themeDaemon.islandBg 
               : Qt.rgba(themeDaemon.islandBg.r, themeDaemon.islandBg.g, themeDaemon.islandBg.b, 0.95)

        // Flatten top corners for MacBook notch look
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
            z: -1
        }

        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
        Behavior on color { ColorAnimation { duration: 300 } }

        onExpandedChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
            if (expanded) {
                autoCloseTimer.restart();
            } else {
                autoCloseTimer.stop();
            }
        }

        onExpandModeChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
            if (expanded) {
                autoCloseTimer.restart();
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton 

            onPositionChanged: {
                if (island.expanded && island.expandMode !== "notif") {
                    autoCloseTimer.restart();
                }
            }

            onClicked: (mouse) => {
                if (island.expanded) autoCloseTimer.restart();

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

        // --- IDLE VIEW ---
        Idle {
            id: idleView
            z: 10
            anchors.centerIn: parent
            visible: !island.expanded && !island.musicPlaying
            unreadCount: notifDaemon.unreadCount

            onOpenPowerMenu: {
                island.expandMode = "power";
                island.expanded = true;
            }
        }

        Visualizer {
            anchors.centerIn: parent
            visible: !island.expanded && island.musicPlaying
        }

        // --- NOTIFICATION DAEMON ---
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
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }

        Music {
            id: musicView
            anchors.centerIn: parent
            music: musicDaemon
            visible: island.expanded && island.expandMode === "music"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        }

        AppLauncher {
            id: appLauncherView
            anchors.fill: parent
            visible: island.expanded && island.expandMode === "apps"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }

        WallpaperSelector {
            id: wallpaperView
            anchors.fill: parent
            visible: island.expanded && island.expandMode === "wallpapers"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }

        PowerMenu {
            id: powerView
            anchors.centerIn: parent
            visible: island.expanded && island.expandMode === "power"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            onRequestClose: {
                island.expanded = false;
            }
        }
    }
}