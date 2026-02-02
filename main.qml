import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

Window {
    id: window
    visible: true
    width: 800
    height: 480
    title: "Weather Station Pro"

    DateSettingsPopup {
        id: dateSettingsPopup
        anchors.centerIn: parent
    }


    TimeSettingsPopup {
        id: timeSettingsPopup
        anchors.centerIn: parent
    }



    // --- ОБЩИЙ ФОН С ГРАДИЕНТОМ ---
    Rectangle {
        id: mainBg
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#050b30" }
            GradientStop { position: 1.0; color: "#1a3a8a" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- ВЕРХНЯЯ ПАНЕЛЬ (STATUS BAR) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "black"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 25; anchors.rightMargin: 25

                Text {
                    text: Qt.formatDate(new Date(), "d/MM/yyyy")
                    color: "#AAA"
                    font.family: "Inter"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dateSettingsPopup.open() // 2. Вызываем при клике
                    }
                }

                Item { Layout.fillWidth: true }

                Image {
                    source: weatherEngine.forecastStatusIcon
                    sourceSize.height: 25

                    // Добавляем мягкое свечение как в прошлом коде
                    layer.enabled: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    MouseArea {
                        anchors.fill: parent
                        onClicked: timeSettingsPopup.open() // 2. Вызываем при клике
                    }
                }

                Image {
                    id: signalIcon
                    source: "icons/Signal.svg"
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit

                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        // Логика: если isOnline true — бирюзовый, иначе — красный
                        color: weatherEngine.isOnline ? "#00FFCC" : "#FF3366"
                    }

                    // Опционально: можно добавить легкое мигание, если связи нет
                    SequentialAnimation on opacity {
                        running: !weatherEngine.isOnline // Мигаем только когда связи НЕТ
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 500 }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 500 }
                    }
                }
            }
        }

        // --- ОСНОВНОЙ КОНТЕНТ ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ЛЕВАЯ КОЛОНКА (Прогноз и Давление)
            ColumnLayout {
                Layout.preferredWidth: 550
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 30

                // Центрированная иконка погоды
                Image {
                    id: mainWeatherIcon
                    source: weatherEngine.forecastMainIcon
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 200
                    fillMode: Image.PreserveAspectFit

                    // Добавляем мягкое свечение как в прошлом коде
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 20; samples: 25;
                        color: "white"; opacity: 0.3; spread: 0.1
                    }
                }
                Item { Layout.fillHeight: true } // Распорка

                // Блок давления
                PressureBlock {
                    Layout.fillWidth: true // Растягиваем на всю ширину колонки
                }
                /*ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Давление"
                        color: "#00CCFF"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.letterSpacing: 2
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        // Здесь будет ваш график или иконка давления
                        Text {
                            text: weatherEngine.pressure + " ↗️"
                            color: "white"
                            font.family: "Inter"
                            font.pixelSize: 38
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "мм.рт.ст."
                            color: "#AAA"
                            font.family: "Inter"
                            font.pixelSize: 14
                        }
                    }
                }*/
            }

            // Вертикальный разделитель
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: "#1FFFFFFF" // Очень слабая прозрачная линия
            }

            // ПРАВАЯ КОЛОНКА (Датчики)
            ColumnLayout {
                Layout.preferredWidth: 250
                Layout.fillHeight: true
                Layout.margins: 30
                spacing: 10

                // Секция УЛИЦА
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    // Используем RowLayout для заголовка "Улица" и иконки батареи
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Улица"
                            color: "#00CCFF"
                            font.pixelSize: 18 // Уменьшил шрифт для компактности
                            font.weight: Font.Bold
                        }

                        Item { Layout.fillWidth: true } // Разделитель, чтобы батарея была справа

                        // Иконка батареи
                        Image {
                            id: batteryIcon
                            source: "icons/BatteryErr.svg" // Убедись, что путь к иконке правильный
                            sourceSize.width: 30 // Размер иконки
                            sourceSize.height: 15
                            visible: weatherEngine.isBatteryLow

                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: "#FF3366" // Яркий красно-розовый цвет для привлечения внимания
                            }

                            // Добавим небольшую анимацию мигания, чтобы точно заметили
                            SequentialAnimation on opacity {
                                running: batteryIcon.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                            }
                        }
                    }

                    // Метрики Улицы
                    MetricRow {
                        icon: "icons/temp.png"
                        value: weatherEngine.outdoorTemp + "°C"
                    }
                    MetricRow {
                        icon: "icons/hum.png"
                        value: weatherEngine.outdoorHum + "%"
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1FFFFFFF" }

                // Секция КОМНАТА
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    Text { text: "Комната"; color: "#00CCFF"; font.pixelSize: 20; font.weight: Font.Bold }

                    MetricRow {
                        icon: "icons/temp.png"
                        value: weatherEngine.indoorTemp + "°C"
                    }

                    MetricRow {
                        icon: "icons/hum.png"
                        value: weatherEngine.indoorHum + "%"
                    }

                    MetricRow {
                        icon: "icons/co2.png"
                        value: weatherEngine.co2 + " ppm"
                        textColor: parseInt(weatherEngine.co2) > 1000 ? "#FF3366" : "white"
                    }
                }
            }
        }
    }
}
