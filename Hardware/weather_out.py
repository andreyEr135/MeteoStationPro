import pigpio
import time
import os

GPIO_PIN = 27
OUT_PATH = "/tmp/weather/out"
TIMEOUT = 180  # 3 минуты в секундах

os.makedirs(OUT_PATH, exist_ok=True)

pi = pigpio.pi()
pi.set_glitch_filter(GPIO_PIN, 150)

last_tick = None
buffer = []
capturing = False

# Переменная для отслеживания последнего приема данных
# Инициализируем текущим временем, чтобы не получить '0' сразу при запуске
last_reception_time = time.time() 

def write_to_file(filename, value):
    try:
        with open(os.path.join(OUT_PATH, filename), "w") as f:
            f.write(str(value))
    except Exception as e:
        print(f"Ошибка записи в {filename}: {e}")

def decode_inFactory(pulses):
    global last_reception_time # Объявляем как global
    bits = ""
    for i in range(0, len(pulses) - 1, 2):
        gap = pulses[i+1]
        bits += "1" if gap > 3000 else "0"

    if len(bits) < 40: return

    try:
        b = [int(bits[i:i+8], 2) for i in range(0, 40, 8)]
        id_val = b[0]
        if id_val != 127: return

        # Данные успешно декодированы
        last_reception_time = time.time() # Обновляем время приема
        write_to_file("status", 1)        # Записываем статус "ОК"

        battery_low = (b[1] >> 2) & 1
        battery_stat = 0 if battery_low else 1
        temp_raw = (b[2] << 4) | (b[3] >> 4)
        temp_f = (temp_raw - 900) * 0.1
        temperature = (temp_f - 32) * 5 / 9
        hum_high = b[3] & 0x0F
        hum_low = b[4] >> 4
        humidity = hum_high * 10 + hum_low

        write_to_file("temp", f"{temperature:.2f}")
        write_to_file("hum", humidity)
        write_to_file("battery", battery_stat)

        print(f"\n[{time.strftime('%H:%M:%S')}] Данные обновлены. Статус: 1")
        print(f"T: {temperature:.2f}°C, H: {humidity}%")

    except Exception as e:
        pass

def cb(g, level, tick):
    global last_tick, buffer, capturing
    if last_tick is not None:
        duration = pigpio.tickDiff(last_tick, tick)
        if duration > 5000:
            if 78 < len(buffer) < 85:
                decode_inFactory(buffer)
            buffer = []
            capturing = True
        elif capturing:
            buffer.append(duration)
    last_tick = tick

pi.callback(GPIO_PIN, pigpio.EITHER_EDGE, cb)

print(f"Сервис погоды запущен. Мониторинг таймаута: {TIMEOUT}с.")

try:
    while True:
        # Проверяем, как давно были данные
        if time.time() - last_reception_time > TIMEOUT:
            write_to_file("status", 0)
            # Чтобы не спамить в консоль, можно выводить сообщение раз в минуту
            # print(f"[{time.strftime('%H:%M:%S')}] Внимание: данных нет более 3 минут! Статус: 0")

        time.sleep(5) # Проверка раз в 5 секунд достаточно для статуса
except:
    pi.stop()
