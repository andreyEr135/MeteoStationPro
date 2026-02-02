import QtQuick 2.12
import QtQuick.Layouts 1.12

RowLayout {
    property string icon: ""
    property string value: ""
    property color textColor: "white"
    spacing: 20

    Image {
        source: icon
        sourceSize.width: 45
        fillMode: Image.PreserveAspectFit
    }

    Text {
        text: value
        color: textColor
        font.family: "Inter"
        font.pixelSize: 42
        font.weight: Font.Medium
    }
}
