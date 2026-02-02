import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Popup {
    id: root
    width: parent.width
    height: parent.height
    padding: 0
    modal: true
    focus: true

    background: Rectangle {
        color: "#020A1A"
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#08204D" }
                GradientStop { position: 1.0; color: "#020A1A" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 15

        // Заголовок
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "История температуры за 24ч"
                color: "#FFFFFF"
                font.pixelSize: 28
                font.weight: Font.Light
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 12; height: 12; radius: 6
                color: weatherEngine.isOnline ? "#00FFCC" : "#FF4444"
                Glow { anchors.fill: parent; radius: 8; samples: 16; color: parent.color; source: parent }
            }
        }

        // Основная область графика
        Canvas {
            id: chartCanvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            property var history: []

            readonly property real minTemp: -30
            readonly property real maxTemp: 15
            readonly property color accentColor: "#00CCFF"

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);

                // --- НАСТРОЙКИ ОТСТУПОВ ---
                var mLeft = 70;    // Отступ слева для цифр температуры
                var mRight = 10;  // УВЕЛИЧЕНО ДО 100, чтобы "Сейчас" точно влезло
                var mTop = 40;
                var mBottom = 80;  // Отступ снизу, чтобы не наезжать на кнопку "ЗАКРЫТЬ"

                var drawW = width - mLeft - mRight;
                var drawH = height - mTop - mBottom;
                var range = maxTemp - minTemp;

                // 1. Сетка и подписи температуры (слева)
                ctx.lineWidth = 1;
                ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
                ctx.fillStyle = "rgba(255, 255, 255, 0.7)";
                ctx.font = "17px sans-serif";
                ctx.textAlign = "right";
                ctx.textBaseline = "middle";

                for (var t = minTemp; t <= maxTemp; t += 10) {
                    var gridY = mTop + (maxTemp - t) / range * drawH;
                    ctx.beginPath();
                    ctx.moveTo(mLeft, gridY);
                    ctx.lineTo(width - mRight, gridY);
                    ctx.stroke();
                    ctx.fillText(t + "°", mLeft - 10, gridY);
                }

                // 2. Сетка и подписи времени (снизу)
                var now = new Date();
                ctx.textBaseline = "top";

                for (var i = 0; i <= 24; i += 6) {
                    var gridX = mLeft + (i / 24) * drawW;

                    ctx.beginPath();
                    ctx.moveTo(gridX, mTop);
                    ctx.lineTo(gridX, height - mBottom);
                    ctx.stroke();

                    if (i === 24) {
                        // ФИКС ДЛЯ СЛОВА "СЕЙЧАС"
                        ctx.textAlign = "right"; // Выравниваем по правому краю линии
                        ctx.fillText("Сейчас", gridX, height - mBottom + 10);
                    } else {
                        var labelHour = new Date(now.getTime() - (24 - i) * 3600000).getHours();
                        var timeStr = (labelHour < 10 ? "0" : "") + labelHour + ":00";

                        ctx.textAlign = (i === 0) ? "left" : "center";
                        ctx.fillText(timeStr, gridX, height - mBottom + 10);
                    }
                }

                // --- Отрисовка самого графика (линии) ---
                if (!history || history.length < 1) return;

                var points = [];
                for (var j = 0; j < history.length; j++) {
                    if (history[j] === null || isNaN(history[j])) continue;
                    points.push({
                        x: mLeft + (j / (history.length - 1)) * drawW,
                        y: mTop + (maxTemp - history[j]) / range * drawH
                    });
                }

                if (points.length > 1) {
                    // Линия графика
                    ctx.strokeStyle = "#00CCFF";
                    ctx.lineWidth = 4;
                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);
                    for (var l = 1; l < points.length; l++) ctx.lineTo(points[l].x, points[l].y);
                    ctx.stroke();
                }
            }
        }

        // Кнопка закрытия
        Button {
            id: exitBtn
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 200
            Layout.preferredHeight: 60
            contentItem: Text {
                text: "ЗАКРЫТЬ"
                color: "white"
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: exitBtn.pressed ? "#CC3300" : "transparent"
                border.color: "white"
                border.width: 2
                radius: 30
            }
            onClicked: root.close()
        }
    }

    onOpened: {
        chartCanvas.history = weatherEngine.getTemperatureHistory();
        chartCanvas.requestPaint();
    }
}
