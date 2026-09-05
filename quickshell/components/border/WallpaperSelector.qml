import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property int selectedIndex: 0

    signal requestClose()

    function loadWallpapers() {
        if (scanProcess.running)
            return ;

        scanProcess.exec(["python3", "-c", "import os, json\n" + "from pathlib import Path\n" + "wall_dir = Path.home() / 'Pictures/Wallpapers'\n" + "wall_dir.mkdir(parents=True, exist_ok=True)\n" + "exts = ('*.jpg', '*.jpeg', '*.png', '*.webp')\n" + "files = []\n" + "for ext in exts:\n" + "    files.extend(wall_dir.glob(ext))\n" + "files.sort(key=lambda p: p.stat().st_mtime, reverse=True)\n" + "res = [{'name': p.name, 'path': str(p)} for p in files]\n" + "print(json.dumps(res))\n"]);
    }

    function applyWallpaper(path) {
        if (!path)
            return ;

        var getSingleColor = "python3 -c \"from PIL import Image; img=Image.open('" + path + "').convert('RGB').resize((60,60)); colors=sorted(img.getcolors(3600), key=lambda x:x[0], reverse=True); best=next((c[1] for c in colors if not (sum(c[1])<30 or sum(c[1])>720)), colors[0][1]); print('#%02x%02x%02x' % best)\" > /tmp/dominant_color.txt";
        var cmd = getSingleColor + "; wal -i '" + path + "' -q -n; awww img '" + path + "' || swww img '" + path + "' || hyprctl hyprpaper wallpaper '," + path + "'";
        setWallpaperProcess.exec(["sh", "-c", cmd]);
        root.requestClose();
    }

    implicitWidth: 460
    implicitHeight: 190
    Component.onCompleted: loadWallpapers()
    onVisibleChanged: {
        if (visible) {
            loadWallpapers();
            grid.forceActiveFocus();
        }
    }

    ListModel {
        id: wallpaperModel
    }

    Process {
        id: scanProcess

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var trimmed = text.trim();
                if (trimmed.length === 0)
                    return ;

                try {
                    var items = JSON.parse(trimmed);
                    wallpaperModel.clear();
                    for (var i = 0; i < items.length; ++i) {
                        wallpaperModel.append(items[i]);
                    }
                } catch (e) {
                    console.log("Wallpaper parse error:", e);
                }
            }
        }

    }

    Process {
        id: setWallpaperProcess
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Wallpapers"
                color: "white"
                font.pixelSize: 12
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: wallpaperModel.count + " images"
                color: "#777777"
                font.pixelSize: 9
            }

        }

        Text {
            visible: wallpaperModel.count === 0 && !scanProcess.running
            text: "No images in ~/Pictures/Wallpapers"
            color: "#888888"
            font.pixelSize: 10
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillHeight: true
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 104
            cellHeight: 68
            focus: true
            model: wallpaperModel
            Keys.onRightPressed: {
                if (grid.currentIndex < wallpaperModel.count - 1) {
                    grid.currentIndex++;
                }
            }
            Keys.onLeftPressed: {
                if (grid.currentIndex > 0) {
                    grid.currentIndex--;
                }
            }
            Keys.onDownPressed: {
                if (grid.currentIndex + 4 < wallpaperModel.count) {
                    grid.currentIndex += 4;
                }
            }
            Keys.onUpPressed: {
                if (grid.currentIndex - 4 >= 0) {
                    grid.currentIndex -= 4;
                }
            }
            Keys.onReturnPressed: {
                if (grid.currentItem && grid.currentItem.modelPath)
                    root.applyWallpaper(grid.currentItem.modelPath);

            }
            Keys.onEscapePressed: root.requestClose()

            delegate: Item {
                id: delegateItem

                property string modelPath: model.path

                width: grid.cellWidth - 6
                height: grid.cellHeight - 6

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: "#111111"
                    border.width: delegateItem.GridView.isCurrentItem || mouseArea.containsMouse ? 2 : 1
                    border.color: delegateItem.GridView.isCurrentItem || mouseArea.containsMouse ? "#ffffff" : "#222222"
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file://" + model.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true

                        Rectangle {
                            anchors.fill: parent
                            color: mouseArea.containsMouse ? "#22ffffff" : "transparent"
                        }

                    }

                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.applyWallpaper(model.path)
                    onEntered: grid.currentIndex = index
                }

            }

        }

    }

}
