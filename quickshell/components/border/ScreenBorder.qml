import "./components"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: borderOverlay

    property int borderWidth: 21
    property int cornerRadius: 18
    property color borderColor: themeDaemon.islandBg
    property bool topRightMenuOpen: false
    property bool isRecording: false

    function runToolCommand(cmdArray) {
        toolProcess.command = cmdArray;
        toolProcess.running = true;
    }

    visible: !(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: (island.expanded && (island.expandMode === "apps" || island.expandMode === "wallpapers")) ? KeyboardFocus.Exclusive : KeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Theme {
        id: themeDaemon
    }

    Shortcut {
        sequence: "Escape"
        enabled: island.expanded || borderOverlay.topRightMenuOpen
        onActivated: {
            island.expanded = false;
            borderOverlay.topRightMenuOpen = false;
        }
    }

    Timer {
        id: autoCloseTimer

        interval: 2000
        repeat: false
        onTriggered: {
            if (island.expandMode !== "apps" && island.expandMode !== "wallpapers")
                island.expanded = false;

            if (!topRightHoverArea.containsMouse)
                borderOverlay.topRightMenuOpen = false;

        }
    }

    MusicInfo {
        id: musicDaemon
    }

    HyprlandFocusGrab {
        id: focusGrab

        windows: [borderOverlay]
        onCleared: {
            island.expanded = false;
            borderOverlay.topRightMenuOpen = false;
        }
    }

    Process {
        id: toolProcess

        running: false
        command: []
        onRunningChanged: {
            if (!running)
                command = [];

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

    Shape {
        id: screenFrame

        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: borderOverlay.borderColor
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenWinding

            PathRectangle {
                width: borderOverlay.width
                height: borderOverlay.height
            }

            PathRectangle {
                x: borderOverlay.borderWidth
                y: borderOverlay.borderWidth
                width: borderOverlay.width - (borderOverlay.borderWidth * 2)
                height: borderOverlay.height - (borderOverlay.borderWidth * 2)
                radius: borderOverlay.cornerRadius
            }

        }

    }

    Column {
        id: workspaceBar

        property int focusedWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

        function format12HourClock() {
            var d = new Date();
            var h = d.getHours() % 12 || 12;
            var m = d.getMinutes();
            var hStr = h < 10 ? "0" + h : "" + h;
            var mStr = m < 10 ? "0" + m : "" + m;
            return hStr + "\n" + mStr;
        }

        anchors.left: parent.left
        anchors.leftMargin: Math.max(1, (borderOverlay.borderWidth - width) / 2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        z: 20

        Text {
            id: leftBorderClock

            text: workspaceBar.format12HourClock()
            color: themeDaemon.islandFg
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: leftBorderClock.text = workspaceBar.format12HourClock()
        }

        Rectangle {
            width: 8
            height: 1
            color: themeDaemon.islandMuted
            opacity: 0.5
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: 5

            Item {
                id: wsDelegate

                required property int index
                property int wsId: index + 1
                property bool isActive: workspaceBar.focusedWsId === wsDelegate.wsId

                width: 14
                height: wsDelegate.isActive ? 28 : 10
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: parent.height
                    radius: 3
                    color: wsDelegate.isActive ? "#ffffff" : Qt.rgba(themeDaemon.islandFg.r, themeDaemon.islandFg.g, themeDaemon.islandFg.b, 0.3)

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("workspace " + wsDelegate.wsId);
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                }

            }

        }

    }

    MouseArea {
        id: outsideDismissArea

        anchors.top: parent.top
        anchors.left: parent.left
        width: (island.expanded || borderOverlay.topRightMenuOpen) ? parent.width : 0
        height: (island.expanded || borderOverlay.topRightMenuOpen) ? parent.height : 0
        visible: island.expanded || borderOverlay.topRightMenuOpen
        z: 50
        onClicked: {
            island.expanded = false;
            borderOverlay.topRightMenuOpen = false;
        }
    }

    Rectangle {
        id: topRightMenu

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: borderOverlay.borderWidth
        z: 100
        width: 110
        height: borderOverlay.topRightMenuOpen ? 56 : 0
        opacity: borderOverlay.topRightMenuOpen ? 1 : 0
        visible: height > 0 || opacity > 0
        radius: 12
        clip: true
        color: borderOverlay.borderColor

        MouseArea {
            id: topRightHoverArea

            anchors.fill: parent
            hoverEnabled: true
            onExited: autoCloseTimer.restart()
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 8
                color: fullArea.containsMouse ? "#2a2a2a" : "#181818"
                border.width: 1
                border.color: fullArea.containsMouse ? themeDaemon.islandAccent : "#282828"

                Text {
                    text: "󰍹"
                    font.family: "JetBrainsMono Nerd Font, Font Awesome 6 Free, Symbola, sans-serif"
                    font.pixelSize: 18
                    color: themeDaemon.islandFg
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: fullArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        borderOverlay.topRightMenuOpen = false;
                        borderOverlay.runToolCommand(["sh", "-c", "mkdir -p ~/Pictures/Screenshots && FILE=\"$HOME/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png\" && (hyprcap screenshot monitor:active \"$FILE\" || grim \"$FILE\") && wl-copy < \"$FILE\" && notify-send -i \"$FILE\" \"Screenshot Taken\" \"Copied to Clipboard & Saved to Screenshots\""]);
                    }
                }

            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 8
                color: borderOverlay.isRecording ? "#441111" : (recArea.containsMouse ? "#2a2a2a" : "#181818")
                border.width: 1
                border.color: borderOverlay.isRecording ? "#ff5555" : (recArea.containsMouse ? themeDaemon.islandAccent : "#282828")

                Text {
                    text: "󰑋"
                    font.family: "JetBrainsMono Nerd Font, Font Awesome 6 Free, Symbola, sans-serif"
                    font.pixelSize: 18
                    color: borderOverlay.isRecording ? "#ff5555" : themeDaemon.islandFg
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: recArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        borderOverlay.topRightMenuOpen = false;
                        if (borderOverlay.isRecording) {
                            borderOverlay.runToolCommand(["hyprcap", "rec-stop"]);
                            borderOverlay.isRecording = false;
                        } else {
                            borderOverlay.isRecording = true;
                            borderOverlay.runToolCommand(["hyprcap", "rec", "region"]);
                        }
                    }
                }

            }

        }

    }

    Shape {
        id: topRightNotchWing

        width: 18
        height: 18
        anchors.top: topRightMenu.top
        anchors.right: topRightMenu.left
        z: 100
        visible: topRightMenu.height > 2
        opacity: Math.min(1, topRightMenu.height / 20)

        ShapePath {
            fillColor: borderOverlay.borderColor
            strokeColor: "transparent"

            PathMove {
                x: 0
                y: 0
            }

            PathLine {
                x: 18
                y: 0
            }

            PathLine {
                x: 18
                y: 18
            }

            PathArc {
                x: 0
                y: 0
                radiusX: 18
                radiusY: 18
                direction: PathArc.CounterClockwise
            }

        }

    }

    MouseArea {
        id: topRightCornerTrigger

        anchors.top: parent.top
        anchors.right: parent.right
        width: 140
        height: borderOverlay.borderWidth + 8
        hoverEnabled: true
        z: 90
        onEntered: {
            borderOverlay.topRightMenuOpen = true;
        }
    }

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
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100
        width: expanded ? (expandMode === "idle" ? 220 : expandMode === "notif" ? 440 : expandMode === "wallpapers" ? 460 : 450) : 240
        height: expanded ? (expandMode === "idle" ? 36 : expandMode === "notif" ? 70 : expandMode === "music" ? 120 : expandMode === "apps" ? 180 : expandMode === "wallpapers" ? 190 : 84) : 36
        opacity: 1
        visible: true
        radius: 18
        clip: true
        color: borderOverlay.borderColor
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
                    duration: 100
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
                    duration: 100
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
                    duration: 100
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
                    duration: 100
                }

            }

        }

        Behavior on width {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }

        }

        Behavior on height {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }

        }

    }

    Shape {
        id: leftNotchWing

        width: 18
        height: 18
        anchors.top: island.top
        anchors.right: island.left
        z: 100
        visible: island.height > 2
        opacity: Math.min(1, island.height / 25)

        ShapePath {
            fillColor: borderOverlay.borderColor
            strokeColor: "transparent"

            PathMove {
                x: 0
                y: 0
            }

            PathLine {
                x: 18
                y: 0
            }

            PathLine {
                x: 18
                y: 18
            }

            PathArc {
                x: 0
                y: 0
                radiusX: 18
                radiusY: 18
                direction: PathArc.CounterClockwise
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }

        }

    }

    Shape {
        id: rightNotchWing

        width: 18
        height: 18
        anchors.top: island.top
        anchors.left: island.right
        z: 100
        visible: island.height > 2
        opacity: Math.min(1, island.height / 25)

        ShapePath {
            fillColor: borderOverlay.borderColor
            strokeColor: "transparent"

            PathMove {
                x: 0
                y: 0
            }

            PathLine {
                x: 18
                y: 0
            }

            PathArc {
                x: 0
                y: 18
                radiusX: 18
                radiusY: 18
                direction: PathArc.CounterClockwise
            }

            PathLine {
                x: 0
                y: 0
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }

        }

    }

    mask: Region {
        Region {
            x: 0
            y: 0
            width: borderOverlay.width
            height: borderOverlay.borderWidth
        }

        Region {
            x: 0
            y: borderOverlay.height - borderOverlay.borderWidth
            width: borderOverlay.width
            height: borderOverlay.borderWidth
        }

        Region {
            x: 0
            y: 0
            width: borderOverlay.borderWidth
            height: borderOverlay.height
        }

        Region {
            x: borderOverlay.width - borderOverlay.borderWidth
            y: 0
            width: borderOverlay.width
            height: borderOverlay.height
        }

        Region {
            item: topRightCornerTrigger
        }

        Region {
            item: topRightMenu
        }

        Region {
            item: topRightNotchWing
        }

        Region {
            item: island
        }

        Region {
            item: leftNotchWing
        }

        Region {
            item: rightNotchWing
        }

        Region {
            item: outsideDismissArea
        }

    }

}
