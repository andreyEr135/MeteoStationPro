#ifndef WEATHERENGINE_H
#define WEATHERENGINE_H

#include <QObject>
#include <QTimer>
#include <QDateTime>
#include <QList>
#include <QVariant>
#include <QVariantList>

struct PressurePoint {
    QDateTime time;
    double pressure;
};

class WeatherEngine : public QObject {
    Q_OBJECT

    // Температуры и влажность
    Q_PROPERTY(QString outdoorTemp READ outdoorTemp NOTIFY dataChanged)
    Q_PROPERTY(QString outdoorHum READ outdoorHum NOTIFY dataChanged)
    Q_PROPERTY(QString indoorTemp READ indoorTemp NOTIFY dataChanged)
    Q_PROPERTY(QString indoorHum READ indoorHum NOTIFY dataChanged)

    // Воздух и давление
    Q_PROPERTY(QString co2 READ co2 NOTIFY dataChanged)
    Q_PROPERTY(QString pressure READ pressure NOTIFY dataChanged)
    Q_PROPERTY(QString pressureTrend READ pressureTrend NOTIFY dataChanged)

    // Прогноз
    Q_PROPERTY(QString forecastText READ forecastText NOTIFY dataChanged)
    Q_PROPERTY(QString forecastMainIcon READ forecastMainIcon NOTIFY dataChanged)
    Q_PROPERTY(QString forecastStatusIcon READ forecastStatusIcon NOTIFY dataChanged)

    // Статус системы
    Q_PROPERTY(bool isOnline READ isOnline NOTIFY dataChanged)
    Q_PROPERTY(bool isBatteryLow READ isBatteryLow NOTIFY dataChanged) // Изменили на bool

    Q_PROPERTY(QVariantList pressureHistory READ pressureHistory NOTIFY dataChanged)

public:
    explicit WeatherEngine(QObject *parent = nullptr);

    // Геттеры
    QString outdoorTemp() const { return m_outdoorTemp; }
    QString outdoorHum() const { return m_outdoorHum; }
    QString indoorTemp() const { return m_indoorTemp; }
    QString indoorHum() const { return m_indoorHum; }

    QString co2() const { return m_co2; }
    QString pressure() const { return m_pressure; }
    QString pressureTrend() const { return m_pressureTrend; }

    QString forecastText() const { return m_forecastText; }
    QString forecastMainIcon() const { return m_forecastMainIcon; }
    QString forecastStatusIcon() const { return m_forecastStatusIcon; }

    QVariantList pressureHistory() const;

    bool isOnline() const { return m_isOnline; }
    bool isBatteryLow() const { return m_isBatteryLow; } // Геттер для батареи

    Q_INVOKABLE QVariantList getTemperatureHistory() const;

signals:
    void dataChanged();

private slots:
    void updateData();

private:
    QString readFile(const QString &path);
    void runPrediction(double currentP);
    int mapPressureToPills(double p) const; // Вспомогательная функция

    // Переменные
    QString m_outdoorTemp = "--";
    QString m_outdoorHum = "--";
    QString m_indoorTemp = "--";
    QString m_indoorHum = "--";

    QString m_co2 = "0";
    QString m_pressure = "--";
    QString m_pressureTrend = "--";

    QString m_forecastText = "АНАЛИЗ...";
    QString m_forecastMainIcon = "qrc:/icons/SunMain.png";
    QString m_forecastStatusIcon = "qrc:/icons/Sun.svg";

    bool m_isOnline = false;
    bool m_isBatteryLow = true; // false - батарея ОК (1), true - плохая (0)

    QList<PressurePoint> m_history;
    QTimer *m_timer;

    struct TempPoint {
        QDateTime time;
        double temp;
    };
    QList<TempPoint> m_tempHistory;


};

#endif // WEATHERENGINE_H
