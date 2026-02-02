#ifndef SYSTEMHELPER_H
#define SYSTEMHELPER_H

#include <QObject>
#include <QProcess>
#include <QDebug>

class SystemHelper : public QObject
{
    Q_OBJECT
public:
    explicit SystemHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void setSystemDate(int year, int month, int day, int hour, int minute) {
        // 1. Формируем строку даты в правильном формате
        QString dateString = QString("%1-%2-%3 %4:%5:00")
                .arg(year)
                .arg(month, 2, 10, QLatin1Char('0'))
                .arg(day, 2, 10, QLatin1Char('0'))
                .arg(hour, 2, 10, QLatin1Char('0'))
                .arg(minute, 2, 10, QLatin1Char('0'));

        qDebug() << "Setting system date to:" << dateString;

        // 2. Используем современный метод: программа отдельно, список аргументов отдельно
        QString program = "sudo date";
        QStringList arguments;
        arguments << "-s" << dateString; // Аргумент "-s" и значение даты

        // Теперь вызываем метод без предупреждений
        QProcess::startDetached(program, arguments);
    }
};


#endif // SYSTEMHELPER_H
