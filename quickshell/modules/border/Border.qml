import "../../components/border"
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    color: "transparent"
    visible: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    WlrLayershell.keyboardFocus: (island.expanded && (island.expandMode === "apps" || island.expandMode === "wallpapers")) ? KeyboardFocus.Exclusive : KeyboardFocus.None
    implicitWidth: 460
    implicitHeight: 270

    Timer {
        id: autoCloseTimer

        interval: 2000 // Time in ms before collapsing after hover ends
        repeat: false
        onTriggered: {
            // Keep open if mouse is still inside or interactive modes like apps/wallpapers are open
            if (!islandHoverArea.containsMouse && island.expandMode !== "apps" && island.expandMode !== "wallpapers")
                island.expanded = false;

        }
    }

    ScreenBorder {
        id: screenBorder
    }

    Theme {
        id: themeDaemon
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

        windows: [root]
        onCleared: {
            island.expanded = false;
        }
    }

    // ==========================================
    // FLUSH TOP DYNAMIC ISLAND
    // ==========================================
    Rectangle {
        id: island

        property bool expanded: false
        property bool musicPlaying: musicDaemon.isPlaying
        property string expandMode: "stats" // "stats", "music", "apps", "wallpapers", "notif", "power"
        property bool dndActive: false

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 0
        width: expanded ? (expandMode === "power" ? 380 : expandMode === "notif" ? 380 : expandMode === "wallpapers" ? 390 : 380) : 210
        height: expanded ? (expandMode === "power" ? 90 : expandMode === "notif" ? 82 : expandMode === "music" ? 140 : expandMode === "apps" ? 220 : expandMode === "wallpapers" ? 230 : 110) : 36
        radius: 18
        clip: true
        border.width: 0
        border.color: "transparent"
        color: expanded ? themeDaemon.islandBg : Qt.rgba(themeDaemon.islandBg.r, themeDaemon.islandBg.g, themeDaemon.islandBg.b, 0.95)
        onExpandedChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
            if (expanded)
                autoCloseTimer.restart();
            else
                autoCloseTimer.stop();
        }
        onExpandModeChanged: {
            focusGrab.active = expanded && (expandMode === "apps" || expandMode === "wallpapers");
            if (expanded)
                autoCloseTimer.restart();

        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
            z: -1
        }

        // ==========================================
        // MOUSE HOVER AREA
        // ==========================================
        MouseArea {
            id: islandHoverArea

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            // Expand as soon as mouse enters the island
            onEntered: {
                if (!island.expanded) {
                    island.expandMode = island.musicPlaying ? "music" : "stats";
                    island.expanded = true;
                }
            }
            // Start countdown to shrink when mouse leaves
            onExited: {
                autoCloseTimer.restart();
            }
            onPositionChanged: {
                if (island.expanded && island.expandMode !== "notif")
                    autoCloseTimer.restart();

            }
            onClicked: (mouse) => {
                if (island.expanded)
                    autoCloseTimer.restart();

                if (mouse.button === Qt.RightButton) {
                    island.expandMode = "music";
                    island.expanded = true;
                } else if (mouse.button === Qt.MiddleButton) {
                    island.expandMode = "apps";
                    island.expanded = true;
                } else {
                    island.expandMode = "stats";
                    island.expanded = !island.expanded;
                }
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
                if (island.expandMode === "notif")
                    island.expanded = false;

            }
        }

        Expanded {
            id: expandedView

            anchors.centerIn: parent
            visible: island.expanded && island.expandMode === "stats"
            opacity: visible ? 1 : 0
            onRequestClose: {
                island.expanded = false;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutQuad
                }

            }

        }

        Music {
            id: musicView

            anchors.centerIn: parent
            music: musicDaemon
            visible: island.expanded && island.expandMode === "music"
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutQuad
                }

            }

        }

        AppLauncher {
            id: appLauncherView

            anchors.fill: parent
            visible: island.expanded && island.expandMode === "apps"
            opacity: visible ? 1 : 0
            onRequestClose: {
                island.expanded = false;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutQuad
                }

            }

        }

        WallpaperSelector {
            id: wallpaperView

            anchors.fill: parent
            visible: island.expanded && island.expandMode === "wallpapers"
            opacity: visible ? 1 : 0
            onRequestClose: {
                island.expanded = false;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutQuad
                }

            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.25
            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.25
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: 300
            }

        }

    }

    mask: Region {
        item: island
    }

}
