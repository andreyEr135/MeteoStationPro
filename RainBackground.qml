import QtQuick 2.12

Item {
    id: rainRoot
    // Привязываемся напрямую к ID окна, чтобы точно иметь размеры
    width: window.width
    height: window.height
    clip: true
    z: 105 // Чуть выше снега
    enabled: false

    property bool active: true
    property int dropsCount: 150

    Repeater {
        model: active ? dropsCount : 0
        delegate: Rectangle {
            id: drop

            // Генерируем параметры
            readonly property real initialX: Math.random()
            readonly property real initialY: Math.random()
            readonly property real speedMult: Math.random() * 0.5 + 0.5 // Разброс скорости

            // Характеристики капли
            width: 2 // Сделаем чуть толще, чтобы точно было видно
            height: 30 * speedMult
            color: "#88CCFF" // Голубой
            opacity: 0.4 * speedMult

            // Фиксируем начальную позицию
            x: initialX * rainRoot.width
            y: initialY * rainRoot.height

            rotation: 15 // Наклон

            // Анимация падения
            NumberAnimation on y {
                from: -100
                to: rainRoot.height + 100
                duration: 800 / speedMult // Чем больше капля, тем быстрее летит
                loops: Animation.Infinite
                running: rainRoot.active
            }

            // Анимация смещения по X (косой дождь)
            NumberAnimation on x {
                from: drop.x
                to: drop.x + 150 // Смещение вправо
                duration: 800 / speedMult
                loops: Animation.Infinite
                running: rainRoot.active
            }
        }
    }
}
