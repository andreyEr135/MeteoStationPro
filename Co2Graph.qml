import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Popup {
    id: root
    property string chartTitle: "История CO2"
    property alias canvas: chartCanvas
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

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.chartTitle
                color: "#FFFFFF"
                font.pixelSize: 28
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 12; height: 12; radius: 6
                color: weatherEngine.isOnline ? "#00FFCC" : "#FF4444"
                Glow { anchors.fill: parent; radius: 8; samples: 16; color: parent.color; source: parent }
            }
        }

        Canvas {
            id: chartCanvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            property var history: []

            // Авто-перерисовка при получении новых данных
            onHistoryChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);

                if (!history || history.length < 1) return;

                // --- 1. ВЫЧИСЛЯЕМ ДИАПАЗОН CO2 ---
                var minV = 9999;
                var maxV = -9999;
                var hasData = false;

                for (var k = 0; k < history.length; k++) {
                    if (history[k] !== null && !isNaN(history[k])) {
                        if (history[k] < minV) minV = history[k];
                        if (history[k] > maxV) maxV = history[k];
                        hasData = true;
                    }
                }

                // Дефолтный диапазон, если данных нет
                if (!hasData) { minV = 400; maxV = 1000; }

                // Динамические границы (запас 50 ppm сверху и снизу)
                var viewMax = Math.ceil((maxV + 50) / 50) * 50;
                var viewMin = Math.floor((minV - 50) / 50) * 50;

                // Если график плоский, расширяем диапазон до 200 единиц
                if (viewMax - viewMin < 200) {
                    var mid = (viewMax + viewMin) / 2;
                    viewMax = Math.ceil((mid + 100) / 50) * 50;
                    viewMin = Math.floor((mid - 100) / 50) * 50;
                }

                var range = viewMax - viewMin;

                // --- 2. ОТСТУПЫ ---
                var mLeft = 80;   // Чуть больше места слева для чисел вроде "1200"
                var mRight = 10;  // ВАШ ОТСТУП 10
                var mTop = 40;
                var mBottom = 80;

                var drawW = width - mLeft - mRight;
                var drawH = height - mTop - mBottom;

                // --- 3. СЕТКА (ПО ВЕРТИКАЛИ - PPM) ---
                ctx.lineWidth = 1;
                ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
                ctx.fillStyle = "rgba(255, 255, 255, 0.7)";
                ctx.font = "16px sans-serif";
                ctx.textAlign = "right";
                ctx.textBaseline = "middle";

                // Шаг сетки: 200 если разброс большой, иначе 100
                var step = (range > 800) ? 200 : 100;
                var startVal = Math.floor(viewMin / step) * step;

                for (var v = startVal; v <= viewMax; v += step) {
                    var gridY = mTop + (viewMax - v) / range * drawH;
                    if (gridY < mTop || gridY > height - mBottom) continue;

                    ctx.beginPath();
                    ctx.moveTo(mLeft, gridY);
                    ctx.lineTo(width - mRight, gridY);
                    ctx.stroke();
                    ctx.fillText(v, mLeft - 10, gridY); // Без значка градуса
                }

                // --- 4. СЕТКА (ПО ГОРИЗОНТАЛИ - ВРЕМЯ) ---
                var now = new Date();
                ctx.textBaseline = "top";
                for (var i = 0; i <= 24; i += 6) {
                    var gridX = mLeft + (i / 24) * drawW;
                    ctx.beginPath();
                    ctx.moveTo(gridX, mTop);
                    ctx.lineTo(gridX, height - mBottom);
                    ctx.stroke();

                    if (i === 24) {
                        ctx.textAlign = "right";
                        ctx.fillText("Сейчас", gridX, height - mBottom + 10);
                    } else {
                        var labelHour = new Date(now.getTime() - (24 - i) * 3600000).getHours();
                        var timeStr = (labelHour < 10 ? "0" : "") + labelHour + ":00";
                        ctx.textAlign = (i === 0) ? "left" : "center";
                        ctx.fillText(timeStr, gridX, height - mBottom + 10);
                    }
                }

                // --- 5. ОТРИСОВКА ЛИНИИ (ГРАДИЕНТНАЯ) ---
                var points = [];
                for (var j = 0; j < history.length; j++) {
                    if (history[j] === null || isNaN(history[j])) continue;
                    points.push({
                        x: mLeft + (j / (history.length - 1)) * drawW,
                        y: mTop + (viewMax - history[j]) / range * drawH
                    });
                }

                if (points.length > 1) {
                    ctx.beginPath();
                    ctx.strokeStyle = "#00FFCC"; // Цвет для CO2 (бирюзовый/зеленоватый)
                    ctx.lineWidth = 4;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    ctx.moveTo(points[0].x, points[0].y);
                    for (var l = 1; l < points.length; l++) {
                        ctx.lineTo(points[l].x, points[l].y);
                    }
                    ctx.stroke();

                    // Последняя точка (текущее значение)
                    var last = points[points.length-1];
                    ctx.fillStyle = "#00FFCC";
                    ctx.beginPath();
                    ctx.arc(last.x, last.y, 5, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        Button {
            id: exitBtn
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 200
            Layout.preferredHeight: 60
            contentItem: Text { text: "ЗАКРЫТЬ"; color: "white"; font.pixelSize: 22; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: exitBtn.pressed ? "#CC3300" : "transparent"; border.color: "white"; border.width: 2; radius: 30 }
            onClicked: root.close()
        }
    }
    onOpened: chartCanvas.requestPaint()
}
