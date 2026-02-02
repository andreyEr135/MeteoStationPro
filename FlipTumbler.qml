/*import QtQuick 2.12
import QtQuick.Controls 2.12

Tumbler {
    id: control
    property int from: 0
    property int to: 0
    property bool isYear: false

    model: to - from + 1
    visibleItemCount: 3

    delegate: Item {
        implicitHeight: 140
        implicitWidth: control.width

        // Эффект наслоения и прозрачности при прокрутке
        opacity: 1.0 - Math.min(0.7, Math.abs(Tumbler.displacement) * 0.5)
        scale: 1.0 - Math.abs(Tumbler.displacement) * 0.2
        z: 1.0 - Math.abs(Tumbler.displacement)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "#2A52BE"
            radius: 4
            border.color: "#4A72DE"
            border.width: 1

            Text {
                anchors.centerIn: parent
                property int val: index + control.from
                text: control.isYear ? val : (val < 10 ? "0" + val : val)
                color: "white"
                // ГИГАНТСКИЕ ЧИСЛА
                font.pixelSize: control.isYear ? 90 : 120
                font.bold: true
            }
        }
    }
}
*/

import QtQuick 2.12
import QtQuick.Controls 2.12

Tumbler {
    id: control
    property int from: 0
    property int to: 0
    property bool isYear: false

    model: to - from + 1
    visibleItemCount: 3

    delegate: Item {
        // Еще сильнее уменьшаем высоту, чтобы не было тесно по вертикали
        implicitHeight: control.isYear ? 90 : 110
        implicitWidth: control.width

        opacity: 1.0 - Math.min(0.7, Math.abs(Tumbler.displacement) * 0.6)
        scale: 1.0 - Math.abs(Tumbler.displacement) * 0.2

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            // Оставляем фон только у центрального
            color: Math.abs(Tumbler.displacement) < 0.1 ? "#2A52BE" : "transparent"
            radius: 4

            Text {
                anchors.centerIn: parent
                property int val: index + control.from
                text: control.isYear ? val : (val < 10 ? "0" + val : val)
                color: "white"

                // РЕШАЮЩЕЕ ИЗМЕНЕНИЕ:
                // День/Месяц оставляем крупными (110), а Год уменьшаем до 65, чтобы влез
                font.pixelSize: control.isYear ? 65 : 110
                font.bold: true
            }
        }
    }
}
