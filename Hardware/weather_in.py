import os
import time
import serial

BME_DEVICE = "/dev/bme280"
CO2_DEVICE = "/dev/serial0"
OUT_PATH = "/tmp/weather/in"
UPDATE_INTERVAL = 1  # Обновлять файлы раз в 1 секунд

# Команда запроса данных для MH-Z19C
CO2_CMD = b'\xff\x01\x86\x00\x00\x00\x00\x00\x79'

os.makedirs(OUT_PATH, exist_ok=True)
last_update = 0

# Инициализация UART для CO2
try:
    ser = serial.Serial(CO2_DEVICE, 9600, timeout=1)
    ser.flushInput()
    time.sleep(0.1)
except:
    ser = None
    print(f"Ошибка: Не удалось открыть {CO2_DEVICE}")

def write_to_file(name, value):
    try:
        # Используем временный файл для атомарности
        full_path = os.path.join(OUT_PATH, name)
        with open(full_path + ".tmp", "w") as f:
            f.write(str(value))
        os.rename(full_path + ".tmp", full_path)
    except:
        pass

def get_co2_data():
    if not ser: return None, None
    try:
        ser.reset_input_buffer()
        time.sleep(0.05)
        ser.write(CO2_CMD)
        res = ser.read(9)
        if len(res) == 9 and res[0] == 0xff and res[1] == 0x86:
            co2 = res[2] * 256 + res[3]
            temp_co2 = res[4] - 40
            return co2, temp_co2
    except:
        pass
    return None, None

def parse_line(line):
    global last_update
    current_time = time.time()

    if current_time - last_update < UPDATE_INTERVAL:
        return

    try:
        # Парсинг данных BME280
        t_idx, p_idx, h_idx = line.find('T'), line.find('P'), line.find('H')
        t_raw = int(line[t_idx+1:p_idx])
        p_raw = int(line[p_idx+1:h_idx])
        h_raw = int(line[h_idx+1:])

        t_bme = t_raw / 100.0
        pressure = p_raw / 256.0 * 0.00750061561303
        humidity = h_raw / 1024.0

        # Чтение данных с датчика CO2
        co2_val, t_co2 = get_co2_data()

        # Усреднение температуры (BME + MH-Z19C)
        if t_co2 is not None:
            avg_temp = (t_bme + t_co2) / 2.0
        else:
            avg_temp = t_bme

        # Сохранение всех параметров
        write_to_file("temp_indoor", f"{avg_temp:.2f}")
        write_to_file("hum_indoor", f"{humidity:.0f}")
        write_to_file("press_indoor", f"{pressure:.2f}")

        if co2_val is not None:
            write_to_file("co2_indoor", str(co2_val))
            co2_str = f"{co2_val} ppm"
        else:
            co2_str = "N/A"

        print(f"[{time.strftime('%H:%M:%S')}] In: {avg_temp:.2f}°C, {humidity:.0f}%, {pressure:.2f}mmHg, CO2: {co2_str}")
        last_update = current_time

    except Exception as e:
        print(f"Ошибка парсинга: {e}")

print(f"Мониторинг запущен (BME: {BME_DEVICE}, CO2: {CO2_DEVICE})...")

try:
    with open(BME_DEVICE, "r") as dev:
        for line in dev:
            if line.strip():
                parse_line(line.strip())
except KeyboardInterrupt:
    print("\nОстановка...")
finally:
    if ser: ser.close()
