import QtQuick 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: tile
    property int value: 0
    property int min: 0
    property int max: 0
    property bool isYear: false
    signal valuePicked(int newValue)

    Layout.fillWidth: true
    Layout.fillHeight: true
    color: "#2A52BE"
    radius: 2

    Text {
        anchors.centerIn: parent
        text: isYear ? value : (value < 10 ? "0" + value : value)
        color: "white"
        font.pixelSize: 100
    }

    MouseArea {
        anchors.fill: parent
        property int startY: 0
        onPressed: startY = mouse.y
        onReleased: {
            var diff = startY - mouse.y
            if (Math.abs(diff) > 30) {
                var nextVal = value
                if (diff > 0) nextVal = (value < max) ? value + 1 : min
                else nextVal = (value > min) ? value - 1 : max
                tile.valuePicked(nextVal)
            }
        }
    }
}
