import QtQuick 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: pressureBlock
    Layout.fillWidth: true
    Layout.preferredHeight: 180
    color: "#25000000"
    radius: 15
    border.color: "#20FFFFFF"
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        Text {
            text: "Давление"
            color: "#00CCFF"
            font.pixelSize: 16
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.5
            Layout.alignment: Qt.AlignLeft
            leftPadding: 10
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // --- ГРАФИК (Единый контейнер для линий и баров) ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: weatherEngine.pressureHistory  //[3, 5, 2, 6, 4] // Данные (высота столбиков)

                        // Каждый элемент Row - это вертикальный "слот"
                        Item {
                            width: parent.width / 5
                            height: parent.height

                            // 1. Линия сетки (ровно по центру слота)
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 1
                                height: parent.height - 35
                                color: "white"
                                opacity: 0.1
                            }

                            // 2. Столбик (ровно по центру слота)
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 30 // Отступ для текста снизу
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4

                                Repeater {
                                    model: modelData
                                    Rectangle {
                                        width: 32
                                        height: 8
                                        radius: 4
                                        color: index === 0 ? "white" : "#CCFFFFFF"
                                    }
                                }
                            }

                            // 3. Подпись времени (ровно по центру слота)
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: index === 4 ? "0" : (index - 4).toString()
                                color: "#88FFFFFF"
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                // Слово "час" сбоку
                Text {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: -10
                    text: "час"
                    color: "#55FFFFFF"
                    font.pixelSize: 10
                }
            }

            // --- ТЕКУЩЕЕ ЗНАЧЕНИЕ ---
            Rectangle {
                Layout.preferredWidth: 130
                Layout.fillHeight: true
                color: "#15FFFFFF"
                radius: 12

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    RowLayout {
                        spacing: 4
                        Text {
                            text: weatherEngine.pressure
                            color: "white"
                            font.pixelSize: 42
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: weatherEngine.pressureTrend
                            color: "#00FFCC"
                            font.pixelSize: 30
                        }
                    }

                    Text {
                        text: "мм.рт.ст."
                        color: "#66FFFFFF"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
