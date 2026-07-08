import QtQuick
import Quickshell

Item {
    id: root
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    Text {
        id: clockText
        anchors.centerIn: parent
        text: {
            var d = clock.date;
            if (!d) return "";
            var h = d.getHours();
            var m = d.getMinutes();
            var ampm = h >= 12 ? "PM" : "AM";
            h = h % 12;
            if (h === 0) h = 12;
            var hh = h < 10 ? ("" + h) : ("" + h);
            var mm = m < 10 ? ("0" + m) : ("" + m);
            return hh + ":" + mm + " " + ampm;
        }
        color: '#ffffff'
        font.family: ""
        font.pixelSize: 20
        font.bold: true
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
