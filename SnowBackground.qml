import QtQuick 2.12

Item {
    id: snowRoot
    width: window.width
    height: window.height
    clip: true
    z: 100
    enabled: false // Чтобы не мешать кликам

    property bool active: true
    property int flakesCount: 150

    Repeater {
        model: active ? flakesCount : 0
        delegate: Rectangle {
            id: flake

            // --- ОБЪЯВЛЯЕМ ВСЕ СВОЙСТВА ЗДЕСЬ ---
            readonly property real initialX: Math.random()
            readonly property real initialY: Math.random()
            readonly property int fallDuration: Math.random() * 7000 + 4000
            readonly property real flakeSize: Math.random() * 6 + 2

            // Свойства для раскачивания
            readonly property int drift: Math.random() * 40 + 20
            readonly property int driftDuration: Math.random() * 2000 + 2000

            width: flakeSize
            height: width
            radius: width / 2
            color: "white"
            opacity: (flakeSize / 8) * 0.8

            x: initialX * snowRoot.width
            y: initialY * snowRoot.height

            // Анимация падения
            NumberAnimation on y {
                from: -20
                to: snowRoot.height + 20
                duration: flake.fallDuration
                loops: Animation.Infinite
                running: snowRoot.active
            }

            // Анимация раскачивания (drift теперь виден)
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: snowRoot.active

                NumberAnimation {
                    to: flake.x + flake.drift
                    duration: flake.driftDuration
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: flake.x - flake.drift
                    duration: flake.driftDuration
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
