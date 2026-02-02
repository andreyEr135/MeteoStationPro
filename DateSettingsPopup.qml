import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Popup {
    id: root
    width: parent.width
    height: parent.height
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.NoAutoClose

    property int selDay: new Date().getDate()
    property int selMonth: new Date().getMonth() + 1
    property int selYear: new Date().getFullYear()
    property int selHour: new Date().getHours()
    property int selMin: new Date().getMinutes()

    background: Rectangle {
        color: "#051A4D"
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1A45A0" }
                GradientStop { position: 1.0; color: "#051A4D" }
            }
            horizontalRadius: width / 2
            verticalRadius: height / 2
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. ХЕДЕР (Компактный)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "black"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                Text { text: "Настройка даты"; color: "white"; font.pixelSize: 20 }
                Item { Layout.fillWidth: true }
                Text { text: "(( 📶 ))"; color: "#00FFCC"; font.pixelSize: 22; font.bold: true; Layout.rightMargin: 15 }
            }
        }

        // 2. БЛОК С ЧИСЛАМИ (УВЕЛИЧЕННЫЙ)
        // Благодаря Layout.fillHeight он заберет всё свободное пространство
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 10   // Минимальные отступы
            Layout.rightMargin: 10
            spacing: 5              // Минимальное расстояние между колонками

            FlipTumbler {
                id: dayTumbler
                Layout.fillWidth: true
                Layout.preferredWidth: 1 // Коэффициент ширины 1
                from: 1; to: 31
                currentIndex: root.selDay - 1
            }

            FlipTumbler {
                id: monthTumbler
                Layout.fillWidth: true
                Layout.preferredWidth: 1 // Коэффициент ширины 1
                from: 1; to: 12
                currentIndex: root.selMonth - 1
            }

            FlipTumbler {
                id: yearTumbler
                Layout.fillWidth: true
                Layout.preferredWidth: 1.5 // ДАЕМ ГОДУ В ПОЛТОРА РАЗА БОЛЬШЕ МЕСТА
                from: 2020; to: 2035
                isYear: true
                currentIndex: root.selYear - 2020
            }
        }

        // 3. МАЛЕНЬКИЕ КНОПКИ (ФИКСИРОВАННЫЙ РАЗМЕР)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 80 // Ограничиваем высоту всего контейнера кнопок
            Layout.bottomMargin: 20
            spacing: 40

            // Прослойка слева, чтобы центрировать кнопки
            Item { Layout.fillWidth: true }

            // Кнопка Отмена
            Rectangle {
                implicitWidth: 250  // Фиксированная ширина
                implicitHeight: 60  // Фиксированная высота
                color: "#2A52BE"
                border.color: "#00CCFF"
                border.width: 1
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "Отмена"
                    color: "white"
                    font.pixelSize: 18 // Уменьшенный шрифт
                }

                MouseArea { anchors.fill: parent; onClicked: root.close() }
            }

            // Кнопка ОК
            Rectangle {
                implicitWidth: 250  // Фиксированная ширина
                implicitHeight: 60  // Фиксированная высота
                color: "#2A52BE"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "ОК"
                    color: "white"
                    font.pixelSize: 18 // Уменьшенный шрифт
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selDay = dayTumbler.currentIndex + 1
                        root.selMonth = monthTumbler.currentIndex + 1
                        root.selYear = yearTumbler.currentIndex + 2020
                        root.selHour = new Date().getHours()
                        root.selMin = new Date().getMinutes()
                        systemHelper.setSystemDate(
                            root.selYear,
                            root.selMonth,
                            root.selDay,
                            root.selHour,
                            root.selMin
                        );
                        root.close()
                    }
                }
            }

            // Прослойка справа, чтобы центрировать кнопки
            Item { Layout.fillWidth: true }
        }
    }
}

