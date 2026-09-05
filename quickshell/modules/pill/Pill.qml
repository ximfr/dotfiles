import "../../components"
import "../../components/pill"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    // Auto-hide when focused workspace has a fullscreen app
    visible: !(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    // Reserves a fixed 48px top strut so windows stay STILL and never shrink when expanding
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.exclusiveZone: 48
    WlrLayershell.keyboardFocus: (island.expanded && (island.expandMode === "apps" || island.expandMode === "wallpapers")) ? KeyboardFocus.Exclusive : KeyboardFocus.None
    implicitWidth: 500
    implicitHeight: 260

    anchors {
        top: true
    }

    Theme {
        id: themeDaemon
    }

    MusicInfo {
        id: musicDaemon
    }

    // Instant Close on ESC Key
    Shortcut {
        sequence: "Escape"
        enabled: island.expanded
        onActivated: island.expanded = false
    }

    // Auto-close timer after 3 seconds of inactivity
    Timer {
        id: autoCloseTimer

        interval: 3000
        repeat: false
        onTriggered: {
            if (island.expandMode !== "apps" && island.expandMode !== "wallpapers")
                island.expanded = false;

        }
    }

    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]
        onCleared: island.expanded = false
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

    // Click outside the expanded pill to close it instantly
    MouseArea {
        id: outsideDismissArea

        anchors.fill: parent
        visible: island.expanded
        z: 50
        onClicked: island.expanded = false
    }

    // ==========================================
    // FLOATING DYNAMIC ISLAND PILL
    // ==========================================
    Rectangle {
        id: island

        property bool expanded: false
        property bool musicPlaying: musicDaemon.isPlaying
        property string expandMode: "stats"
        property bool dndActive: false
        property var modeSequence: ["stats", "wallpapers", "apps", "music"]

        function cycleMode(dir) {
            var currIdx = modeSequence.indexOf(expandMode);
            if (currIdx === -1)
                currIdx = 0;

            var nextIdx = currIdx + dir;
            if (nextIdx >= 0 && nextIdx < modeSequence.length)
                expandMode = modeSequence[nextIdx];

        }

        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100
        // Smooth width & height stretch dimensions
        width: expanded ? (expandMode === "notif" ? 440 : expandMode === "wallpapers" ? 460 : 450) : (musicPlaying ? 260 : 210)
        height: expanded ? (expandMode === "notif" ? 70 : expandMode === "music" ? 120 : expandMode === "apps" ? 180 : expandMode === "wallpapers" ? 190 : 84) : 38
        radius: 20
        clip: true
        color: themeDaemon.islandBg
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
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

        // Horizontal Drag Gesture to cycle modes (M1 hold & drag)
        DragHandler {
            id: gestureHandler

            property real lastX: 0

            target: null
            acceptedButtons: Qt.LeftButton
            onActiveChanged: {
                if (active)
                    lastX = translation.x;

            }
            onTranslationChanged: {
                if (!active)
                    return ;

                var deltaX = translation.x - lastX;
                var threshold = 35;
                if (deltaX < -threshold) {
                    island.cycleMode(1);
                    lastX = translation.x;
                    autoCloseTimer.restart();
                } else if (deltaX > threshold) {
                    island.cycleMode(-1);
                    lastX = translation.x;
                    autoCloseTimer.restart();
                }
            }
        }

        // Mouse Click Handler
        MouseArea {
            id: islandClickArea

            anchors.fill: parent
            hoverEnabled: false
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (island.expanded)
                    autoCloseTimer.restart();

                if (mouse.button === Qt.LeftButton) {
                    island.expandMode = "stats";
                    island.expanded = !island.expanded;
                } else if (mouse.button === Qt.RightButton) {
                    island.expandMode = "music";
                    island.expanded = true;
                } else if (mouse.button === Qt.MiddleButton) {
                    island.expandMode = "apps";
                    island.expanded = true;
                }
            }
        }

        Idle {
            id: idleView

            z: 10
            anchors.centerIn: parent
            visible: (!island.expanded && !island.musicPlaying) || (island.expanded && island.expandMode === "idle")
            unreadCount: notifDaemon.unreadCount
            musicPlaying: island.musicPlaying
        }

        Visualizer {
            id: cavaVisualizer

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
            onRequestClose: {
                if (island.expandMode === "notif")
                    island.expanded = false;

            }
        }

        Expanded {
            id: expandedView

            anchors.centerIn: parent
            visible: island.expanded && island.expandMode === "stats"
            opacity: visible ? 1 : 0
            musicPlaying: island.musicPlaying
            onRequestClose: {
                island.expanded = false;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
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
                    duration: 150
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
                    duration: 150
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
                    duration: 150
                }

            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.18
            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.18
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }

        }

    }

    mask: Region {
        item: island
    }

}
