import QtQuick 2.12
import QtQuick.Layouts 1.12

Item {
    id: root
    property string icon: ""
    property string value: ""
    property color textColor: "white"

    signal clicked()

    // --- ВОТ ТУТ ИСПРАВЛЕНИЕ ---
    // Устанавливаем неявные размеры, чтобы Layout их видел
    implicitWidth: mainRow.implicitWidth
    implicitHeight: 50 // Или та высота, которая вам нужна (обычно 50-70)

    // Пробрасываем свойства Layout, чтобы они работали в main.qml
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    // ---------------------------

    RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: 20

        Image {
            source: root.icon
            sourceSize.width: 45
            fillMode: Image.PreserveAspectFit
        }

        Text {
            id: valueText
            text: root.value
            color: root.textColor
            font.family: "Inter"
            font.pixelSize: 42
            font.weight: Font.Medium
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
