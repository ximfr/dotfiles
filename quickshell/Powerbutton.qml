import QtQuick
import QtQuick.Layouts

Text {
    id: powerButton
    property var process
    text: "⏻"
    color: "#f5e2d0"
    font.pixelSize: 16
    Layout.margins: 6

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (process) {
                process.exec(["eww", "open", "pwrmnu"])
            }
        }
    }
}
        