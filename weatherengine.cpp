#include "weatherengine.h"
#include <QtMath>
#include <QFile>
#include <QTextStream>
#include <QDebug>

WeatherEngine::WeatherEngine(QObject *parent) : QObject(parent) {
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &WeatherEngine::updateData);
    m_timer->start(2000); // Обновляем раз в 2 секунды
    updateData();
}

QString WeatherEngine::readFile(const QString &path) {
    QFile file(path);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QTextStream(&file).readAll().trimmed();
    }
    return "--";
}

void WeatherEngine::updateData() {
    // 1. Читаем данные из комнаты
    m_indoorTemp = readFile("/tmp/weather/in/temp_indoor");
    m_indoorHum = readFile("/tmp/weather/in/hum_indoor");
    m_co2 = readFile("/tmp/weather/in/co2_indoor");

    // 2. Читаем данные с улицы
    // Округляем уличную температуру для красоты
    QString rawOutTemp = readFile("/tmp/weather/out/temp");
    if (rawOutTemp != "--") {
        double currentT = rawOutTemp.toDouble();
        m_outdoorTemp = QString::number(qRound(rawOutTemp.toDouble()));
        // СОХРАНЯЕМ В ИСТОРИЮ
        m_tempHistory.append({QDateTime::currentDateTime(), currentT});

        // Храним историю ровно 24 часа (86400 секунд)
        QDateTime now = QDateTime::currentDateTime();
        while(!m_tempHistory.isEmpty() && m_tempHistory.first().time.secsTo(now) > 86400) {
            m_tempHistory.removeFirst();
        }
    } else {
        m_outdoorTemp = "--";
    }

    // Добавили чтение влажности на улице
    m_outdoorHum = readFile("/tmp/weather/out/hum");

    // 3. Читаем статус системы
    // Предполагаем, что 1 - ок, 0 - плохо
    m_isBatteryLow = (readFile("/tmp/weather/out/battery") == "0");
    //qDebug() << m_isBatteryLow;
    // Если файл существует и там не "--", считаем что мы онлайн
    m_isOnline = (readFile("/tmp/weather/out/status") == "1");

    // 4. Читаем давление и считаем прогноз
    QString pStr = readFile("/tmp/weather/in/press_indoor");
    if (pStr != "--") {
        double p = pStr.toDouble();
        m_pressure = QString::number(qRound(p));

        m_history.append({QDateTime::currentDateTime(), p});

        // ВНИМАНИЕ: Храним историю 4.5 часа (16200 сек), чтобы точка "-4 часа" всегда была в наличии
        while(m_history.size() > 0 && m_history.first().time.secsTo(QDateTime::currentDateTime()) > 16200)
            m_history.removeFirst();

        runPrediction(p);
    }
    else {
        m_pressure = "--";
    }

    emit dataChanged();
}

void WeatherEngine::runPrediction(double currentP) {
    if (m_history.isEmpty()) return;

    // Считаем разницу давления с началом истории (трендовая дельта)
    double delta = currentP - m_history.first().pressure;

    // Устанавливаем стрелочку тренда
    if (delta > 0.5) m_pressureTrend = "↗️";
    else if (delta < -0.5) m_pressureTrend = "↘️";
    else m_pressureTrend = "→";

    // Логика прогноза
    double outT = m_outdoorTemp == "--" ? 20.0 : m_outdoorTemp.toDouble();

    if (delta < -1.2) {
        if (outT < 2) {
            m_forecastText = "СНЕГОПАД";
            m_forecastMainIcon = "qrc:/icons/SnowMain.png";
            m_forecastStatusIcon = "qrc:/icons/Snow.svg";
        } else {
            m_forecastText = "ДОЖДЬ";
            m_forecastMainIcon = "qrc:/icons/RainMain.png";
            m_forecastStatusIcon = "qrc:/icons/Rain.svg";
        }
    } else if (delta > 1.2) {
        m_forecastText = "ЯСНО";
        m_forecastMainIcon = "qrc:/icons/SunMain.png";
        m_forecastStatusIcon = "qrc:/icons/Sun.svg";
    } else {
        m_forecastText = "ОБЛАЧНО";
        m_forecastMainIcon = "qrc:/icons/CloudyMain.png";
        m_forecastStatusIcon = "qrc:/icons/Cloudy.svg";
    }
}

// --- Реализация получения истории для графика ---
QVariantList WeatherEngine::pressureHistory() const {
    QVariantList pillsList;
    QDateTime now = QDateTime::currentDateTime();

    // Временные метки, которые нам нужны (в секундах назад)
    QVector<int> offsets = {14400, 10800, 7200, 3600, 0}; // -4ч, -3ч, -2ч, -1ч, сейчас

    for (int offset : offsets) {
        QDateTime targetTime = now.addSecs(-offset);
        double foundPressure = -1.0;

        // Ищем в истории ближайшую точку к целевому времени
        for (const auto &point : m_history) {
            // Если точка в диапазоне +/- 10 минут от целевого часа, берем её
            if (qAbs(point.time.secsTo(targetTime)) < 600) {
                foundPressure = point.pressure;
                break;
            }
        }

        // Если данных еще нет (программа только запустилась), ставим среднее значение 4
        if (foundPressure < 0) {
            pillsList.append(0);
        } else {
            pillsList.append(mapPressureToPills(foundPressure));
        }
    }
    return pillsList;
}


// Вспомогательная функция: превращает давление в количество полосок (1-8)
int WeatherEngine::mapPressureToPills(double p) const {
    // Допустим, 740 мм.рт.ст - это 1 полоска, 760 - это 8 полосок.
    // Вы можете подправить этот диапазон под свой регион
    int pills = qRound((p - 740.0) / (765.0 - 740.0) * 7.0) + 1;
    return qBound(1, pills, 8); // Ограничиваем от 1 до 8
}

QVariantList WeatherEngine::getTemperatureHistory() const {
    QVariantList list;
    if (m_tempHistory.isEmpty()) return list;

    QDateTime now = QDateTime::currentDateTime();
    // Мы хотим получить 144 точки (по одной на каждые 10 минут за 24 часа)
    for (int i = 143; i >= 0; --i) {
        QDateTime targetTime = now.addSecs(-i * 600); // 600 сек = 10 мин
        double bestTemp = -999.0;

        // Ищем ближайшую точку в истории к этому времени
        for (const auto &point : m_tempHistory) {
            if (qAbs(point.time.secsTo(targetTime)) < 300) { // допуск 5 минут
                bestTemp = point.temp;
                break;
            }
        }

        // Если данных для этого времени еще нет, пишем последнее известное или 0
        if (bestTemp < -900.0) {
            list.append(QVariant()); // Добавляем "пустое" значение вместо текущей температуры
        } else {
            list.append(bestTemp);
        }
    }
    return list;
}
