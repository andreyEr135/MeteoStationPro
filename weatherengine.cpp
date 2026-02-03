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
    QDateTime now = QDateTime::currentDateTime();

    // --- 1. КОМНАТА ---
    QString rawInTemp = readFile("/tmp/weather/in/temp_indoor");
    if (rawInTemp != "--") {
        double inT = rawInTemp.toDouble();
        // Округляем для экрана
        m_indoorTemp = QString::number(qRound(inT));

        // Добавляем в историю (точное значение) раз в 60 сек
        if (m_indoorHistory.isEmpty() || m_indoorHistory.last().time.secsTo(now) >= 60) {
            m_indoorHistory.append({now, inT});
        }
    } else {
        m_indoorTemp = "--";
    }

    // Чистим историю (24 часа)
    while(!m_indoorHistory.isEmpty() && m_indoorHistory.first().time.secsTo(now) > 86400) {
        m_indoorHistory.removeFirst();
    }

    m_indoorHum = readFile("/tmp/weather/in/hum_indoor");

    // --- 2. CO2 ---
    m_co2 = readFile("/tmp/weather/in/co2_indoor");
    bool co2Ok;
    int currentCo2 = m_co2.toInt(&co2Ok);
    if (co2Ok && (m_co2History.isEmpty() || m_co2History.last().time.secsTo(now) >= 60)) {
        m_co2History.append({now, currentCo2});
    }
    while(!m_co2History.isEmpty() && m_co2History.first().time.secsTo(now) > 86400) {
        m_co2History.removeFirst();
    }

    // --- 3. УЛИЦА ---
    QString rawOutTemp = readFile("/tmp/weather/out/temp");
    if (rawOutTemp != "--") {
        double outT = rawOutTemp.toDouble();
        m_outdoorTemp = QString::number(qRound(outT));

        if (m_outdoorHistory.isEmpty() || m_outdoorHistory.last().time.secsTo(now) >= 60) {
            m_outdoorHistory.append({now, outT});
        }
    } else {
        m_outdoorTemp = "--";
    }

    while(!m_outdoorHistory.isEmpty() && m_outdoorHistory.first().time.secsTo(now) > 86400) {
        m_outdoorHistory.removeFirst();
    }

    m_outdoorHum = readFile("/tmp/weather/out/hum");

    // --- 4. СТАТУС И БАТАРЕЯ ---
    m_isBatteryLow = (readFile("/tmp/weather/out/battery") == "0");
    m_isOnline = (readFile("/tmp/weather/out/status") == "1");

    // --- 5. ДАВЛЕНИЕ И ПРОГНОЗ ---
    QString pStr = readFile("/tmp/weather/in/press_indoor");
    if (pStr != "--") {
        double p = pStr.toDouble();
        m_pressure = QString::number(qRound(p));

        m_history.append({now, p});
        while(!m_history.isEmpty() && m_history.first().time.secsTo(now) > 16200)
            m_history.removeFirst();

        runPrediction(p);
    } else {
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

QVariantList WeatherEngine::formatHistoryData(const QList<TempPoint>& history) const {
    QVariantList list;
    if (history.isEmpty()) return list;

    QDateTime now = QDateTime::currentDateTime();
    for (int i = 143; i >= 0; --i) {
        QDateTime targetTime = now.addSecs(-i * 600);
        double bestTemp = -999.0;

        for (const auto &point : history) {
            if (qAbs(point.time.secsTo(targetTime)) < 300) {
                bestTemp = point.temp;
                // Не делаем break сразу, чтобы найти САМУЮ близкую точку,
                // если их несколько в интервале
            }
        }

        if (bestTemp < -900.0) list.append(QVariant());
        else list.append(bestTemp);
    }
    return list;
}


QVariantList WeatherEngine::getOutdoorHistory() const {
    return formatHistoryData(m_outdoorHistory);
}

QVariantList WeatherEngine::getIndoorHistory() const {
    return formatHistoryData(m_indoorHistory);
}

QVariantList WeatherEngine::getCo2History() const {
    QVariantList list;
    //int totalPoints = 144; // 24 часа по 10 минут = 144 точки
    QDateTime now = QDateTime::currentDateTime();

    // Создаем сетку на 24 часа
    for (int i = 143; i >= 0; --i) {
        // Вычисляем время для каждой из 144 точек (назад в прошлое)
        QDateTime targetTime = now.addSecs(-i * 600);
        double bestVal = -1.0;

        // Ищем в собранной истории m_co2History подходящую точку
        for (const auto &point : m_co2History) {
            if (qAbs(point.time.secsTo(targetTime)) < 300) { // разница меньше 5 минут
                bestVal = point.ppm;
            }
        }

        // Если данных для этого времени еще нет, добавляем QVariant(nullptr) или NaN
        if (bestVal < 0) {
            list.append(QVariant());
        } else {
            list.append(bestVal);
        }
    }
    return list;
}
