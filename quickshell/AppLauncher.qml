import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland




PanelWindow {
    id: launcherWindow
    
    anchors {
        top: true
        right: true
        bottom: true
        
    }

    WlrLayershell.margins.top: 0
    width: 400
    height: 500
    visible: false
    
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top

    property string query: ""
    property int selectedIndex: -1
    property var favorites: ({})

    Component.onCompleted: loadFavorites()

    ListModel { id: appModel }
    ListModel { id: filteredModel }

    Process {
        id: appListProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var trimmed = text.trim()
                if (trimmed.length === 0) return
                try {
                    var apps = JSON.parse(trimmed)
                    appModel.clear()
                    for (var i = 0; i < apps.length; ++i) {
                        appModel.append(apps[i])
                    }
                    updateFilter()
                } catch (e) { console.log("AppLauncher parse error", e) }
            }
        }
    }

    Process { id: launchProcess }

    Process {
        id: favoritesLoadProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var trimmed = text.trim()
                var favs = {}
                try {
                    var arr = JSON.parse(trimmed.length > 0 ? trimmed : "[]")
                    for (var i = 0; i < arr.length; ++i) favs[arr[i]] = true
                } catch (e) { console.log("AppLauncher favorites parse error", e) }
                launcherWindow.favorites = favs
                launcherWindow.updateFilter()
            }
        }
    }

    Process { id: favoritesSaveProcess }
    Process { id: clipboardProcess }

    function open() {
        visible = true
        queryField.forceActiveFocus()
        if (appModel.count === 0) loadApps()
        updateFilter()
    }

    function toggle() {
        if (visible) {
            visible = false
            launcherWindow.query = ""
        } else {
            open()
        }
    }

    function updateFilter() {
        filteredModel.clear()

        var trimmedQuery = query.trim()
        if (trimmedQuery.indexOf(">") === 0) {
            var expr = trimmedQuery.substring(1).trim()
            if (expr.length > 0) {
                var result = evaluateExpression(expr)
                if (result !== null) {
                    filteredModel.append({
                        name: expr + " = " + result,
                        command: "",
                        icon: "accessories-calculator",
                        description: "Press Enter to copy result",
                        isFavorite: false,
                        isCalculator: true,
                        calcResult: result
                    })
                } else {
                    filteredModel.append({
                        name: "Invalid expression",
                        command: "",
                        icon: "accessories-calculator",
                        description: expr,
                        isFavorite: false,
                        isCalculator: true,
                        calcResult: ""
                    })
                }
            }
            selectedIndex = filteredModel.count > 0 ? 0 : -1
            return
        }

        var q = query.toLowerCase()
        var apps = []

        for (var i = 0; i < appModel.count; ++i) {
            var app = appModel.get(i)
            if (q === "" || 
                app.name.toLowerCase().includes(q) || 
                (app.description && app.description.toLowerCase().includes(q))) {
                apps.push({
                    name: app.name,
                    command: app.command,
                    icon: app.icon,
                    description: app.description,
                    isFavorite: !!launcherWindow.favorites[app.name],
                    isCalculator: false,
                    calcResult: ""
                })
            }
        }

        apps.sort(function(a, b) {
            if (a.isFavorite !== b.isFavorite) return a.isFavorite ? -1 : 1
            return a.name.localeCompare(b.name)
        })

        for (var i = 0; i < apps.length; ++i)
            filteredModel.append(apps[i])

        selectedIndex = filteredModel.count > 0 ? 0 : -1
    }

    function loadApps() {
        if (appListProcess.running) return
        // Running the advanced logic you provided as a compact python script
        appListProcess.exec(["python3", "-c", 
            "import json, os, configparser\n" +
            "from pathlib import Path\n" +
            "APP_DIRS = [Path.home() / '.local/share/applications', Path.home() / '.local/share/flatpak/exports/share/applications', Path('/usr/share/applications'), Path('/usr/local/share/applications'), Path('/var/lib/flatpak/exports/share/applications'), Path('/var/lib/snapd/desktop/applications')]\n" +
            "apps = {}\n" +
            "for app_dir in APP_DIRS:\n" +
            "    if not app_dir.exists(): continue\n" +
            "    for p in app_dir.glob('*.desktop'):\n" +
            "        try:\n" +
            "            parser = configparser.ConfigParser(interpolation=None)\n" +
            "            parser.read(p, encoding='utf-8')\n" +
            "            if 'Desktop Entry' not in parser: continue\n" +
            "            ent = parser['Desktop Entry']\n" +
            "            if ent.get('Type', '') != 'Application' or ent.get('NoDisplay', '').lower() == 'true' or ent.get('Hidden', '').lower() == 'true': continue\n" +
            "            name = ent.get('Name')\n" +
            "            if not name or name in apps: continue\n" +
            "            apps[name] = {'name': name, 'command': ent.get('Exec', '').split('%')[0].strip(), 'icon': ent.get('Icon', 'application-x-executable').strip(), 'description': ent.get('GenericName', ent.get('Comment', ''))}\n" +
            "        except: continue\n" +
            "print(json.dumps(list(apps.values())))"
        ])
    }

    function loadFavorites() {
        if (favoritesLoadProcess.running) return
        favoritesLoadProcess.exec(["python3", "-c",
            "import os, json\n" +
            "p = os.path.expanduser('~/.cache/quickshell/launcher_favorites.json')\n" +
            "if os.path.exists(p):\n" +
            "    print(open(p, encoding='utf-8').read())\n" +
            "else:\n" +
            "    print('[]')\n"
        ])
    }

    function saveFavorites() {
        var names = []
        for (var key in favorites) {
            if (favorites[key]) names.push(key)
        }
        var b64 = Qt.btoa(JSON.stringify(names))
        favoritesSaveProcess.exec(["python3", "-c",
            "import sys, os, base64\n" +
            "p = os.path.expanduser('~/.cache/quickshell/launcher_favorites.json')\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "data = base64.b64decode(sys.argv[1]).decode('utf-8')\n" +
            "with open(p, 'w', encoding='utf-8') as f:\n" +
            "    f.write(data)\n",
            b64
        ])
    }

    function evaluateExpression(expr) {
        if (!expr || expr.trim().length === 0) return null
        var sanitized = expr.trim()

        // Map friendly function/constant names to Math equivalents
        sanitized = sanitized.replace(/\bsqrt\b/gi, "Math.sqrt")
        sanitized = sanitized.replace(/\bsin\b/gi, "Math.sin")
        sanitized = sanitized.replace(/\bcos\b/gi, "Math.cos")
        sanitized = sanitized.replace(/\btan\b/gi, "Math.tan")
        sanitized = sanitized.replace(/\blog\b/gi, "Math.log10")
        sanitized = sanitized.replace(/\bln\b/gi, "Math.log")
        sanitized = sanitized.replace(/\babs\b/gi, "Math.abs")
        sanitized = sanitized.replace(/\bpow\b/gi, "Math.pow")
        sanitized = sanitized.replace(/\bpi\b/gi, "Math.PI")
        sanitized = sanitized.replace(/\^/g, "**")

        // Whitelist: once Math.xxx tokens are stripped, only digits/operators/() may remain
        var check = sanitized.replace(/Math\.[a-zA-Z0-9]+/g, "")
        if (!/^[0-9+\-*/%.()\s,]*$/.test(check)) return null
        if (sanitized.trim().length === 0) return null

        try {
            var result = Function('"use strict"; return (' + sanitized + ')')()
            if (typeof result !== "number" || !isFinite(result)) return null
            var rounded = Math.round(result * 1e10) / 1e10
            return rounded.toString()
        } catch (e) {
            return null
        }
    }

    function copyToClipboard(text) {
        if (!text || text.length === 0) return
        clipboardProcess.exec(["sh", "-c", "printf '%s' '" + text + "' | wl-copy"])
    }

    function toggleFavorite(name) {
        var favs = favorites
        if (favs[name]) {
            delete favs[name]
        } else {
            favs[name] = true
        }
        favorites = favs
        updateFilter()
        saveFavorites()
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: '#000000'
        border.color: '#000000'
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            TextField {
                id: queryField
                Layout.fillWidth: true
                placeholderText: ""
                color: "white"
                font.pixelSize: 16
                focus: true
                background: Rectangle { 
                    color: '#000000'
                    radius: 8
                    border.width: 1
                    border.color: parent.activeFocus ? "#444" : "#222"
                }
                onTextChanged: {
                    launcherWindow.query = text
                    launcherWindow.updateFilter()
                }
                Keys.onDownPressed: if (launcherWindow.selectedIndex < filteredModel.count - 1) launcherWindow.selectedIndex++
                Keys.onUpPressed: if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                Keys.onReturnPressed: {
                    if (launcherWindow.selectedIndex >= 0) {
                        var item = filteredModel.get(launcherWindow.selectedIndex)
                        if (item.isCalculator) {
                            if (item.calcResult && item.calcResult.length > 0) {
                                launcherWindow.copyToClipboard(item.calcResult)
                                launcherWindow.visible = false
                                launcherWindow.query = ""
                                queryField.text = ""
                            }
                            return
                        }
                        launchProcess.exec(["sh", "-c", item.command + " >/dev/null 2>&1 &"])
                        launcherWindow.visible = false
                        launcherWindow.query = ""
                        queryField.text = ""
                    }
                }
                Keys.onEscapePressed: launcherWindow.visible = false
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: filteredModel
                currentIndex: launcherWindow.selectedIndex
                clip: true
                spacing: 4

                delegate: Rectangle {
                    width: list.width
                    height: 55
                    radius: 8
                    color: ListView.isCurrentItem ? "#222222" : "transparent"
                    border.width: 1
                    border.color: itemMouseArea.containsMouse ? "#333333" : (ListView.isCurrentItem ? "#444444" : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 15

                        Image {
                            width: 32
                            height: 32
                            sourceSize.width: 32
                            sourceSize.height: 32
                            source: "image://icon/" + model.icon
                            fillMode: Image.PreserveAspectFit
                        }   

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: model.name
                                color: "white"
                                font.pixelSize: 14
                                font.weight: ListView.isCurrentItem ? Font.Bold : Font.Normal
                            }
                            Text {
                                text: model.description || ""
                                color: '#ffffff'
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }

                        Text {
                            text: "★"
                            color: "#f5c542"
                            font.pixelSize: 16
                            visible: model.isFavorite === true && model.isCalculator !== true
                        }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                if (!model.isCalculator) launcherWindow.toggleFavorite(model.name)
                            } else if (model.isCalculator) {
                                if (model.calcResult && model.calcResult.length > 0) {
                                    launcherWindow.copyToClipboard(model.calcResult)
                                    launcherWindow.visible = false
                                    launcherWindow.query = ""
                                    queryField.text = ""
                                }
                            } else {
                                launchProcess.exec(["sh", "-c", model.command + " >/dev/null 2>&1 &"])
                                launcherWindow.visible = false
                                launcherWindow.query = ""
                                queryField.text = ""
                            }
                        }
                        onEntered: launcherWindow.selectedIndex = index
                    }
                }
            }
        }
    }
}

