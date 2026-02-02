#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include <QLocale>
#include <QTranslator>

#include "weatherengine.h"
#include "systemhelper.h"

int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    WeatherEngine engine;
    QQmlApplicationEngine qmlEngine;

    // Создаем экземпляр помощника
    SystemHelper *sysHelper = new SystemHelper(&app);
    // Передаем его в QML под именем "systemHelper"
    qmlEngine.rootContext()->setContextProperty("systemHelper", sysHelper);

    // Регистрируем C++ класс в QML
    qmlEngine.rootContext()->setContextProperty("weatherEngine", &engine);

    qmlEngine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    return app.exec();
}
