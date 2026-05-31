-- ===================================================================
-- ЗАДАНИЕ 1: Лучшие автомобили в каждом классе
-- Что делаем: для каждого класса находим авто с минимальной средней позицией
-- Результат: название, класс, средняя позиция, количество гонок
-- ===================================================================

WITH car_stats AS (
    -- Шаг 1: Считаем статистику по каждому автомобилю
    SELECT
        c.name,                                    -- Название автомобиля
        c.class,                                   -- Класс автомобиля
        AVG(r.position) AS average_position,       -- Средняя позиция во всех гонках
        COUNT(r.race) AS race_count                -- Количество участий в гонках
    FROM Cars c
    JOIN Results r ON c.name = r.car               -- Соединяем авто с результатами
    GROUP BY c.name, c.class                       -- Группируем по автомобилю
),
min_per_class AS (
    -- Шаг 2: Для каждого класса находим минимальную среднюю позицию
    SELECT
        class,
        MIN(average_position) AS min_avg_position  -- Лучшая средняя позиция в классе
    FROM car_stats
    GROUP BY class
)
-- Шаг 3: Выводим автомобили, чья средняя позиция равна минимальной в классе
SELECT
    cs.name,                                       -- Название автомобиля-лидера
    cs.class,                                      -- Его класс
    cs.average_position,                           -- Лучшая средняя позиция
    cs.race_count                                  -- Количество гонок
FROM car_stats cs
JOIN min_per_class mpc ON cs.class = mpc.class
    AND cs.average_position = mpc.min_avg_position  -- Только лучшие в классе
ORDER BY cs.average_position;                       -- Сортировка по позиции

-- ===================================================================
-- ЗАДАНИЕ 2: Абсолютный лучший автомобиль
-- Что делаем: находим один автомобиль с лучшей средней позицией
-- Результат: авто, класс, сред.позиция, кол-во гонок, страна класса
-- ===================================================================

WITH car_statistics AS (
    -- Статистика по каждому автомобилю
    SELECT
        cars.name AS car_name,                     -- Название автомобиля
        cars.class AS car_class,                   -- Класс автомобиля
        AVG(results.position) AS avg_position,     -- Средняя позиция
        COUNT(results.race) AS race_count          -- Количество гонок
    FROM cars
    JOIN results ON cars.name = results.car
    GROUP BY cars.name, cars.class
)
-- Выбираем лучший автомобиль (LIMIT 1 после сортировки)
SELECT
    car_statistics.car_name,                       -- Название лучшего авто
    car_statistics.car_class,                      -- Его класс
    car_statistics.avg_position,                   -- Лучшая средняя позиция
    car_statistics.race_count,                     -- Количество гонок
    classes.country AS class_country               -- Страна производитель класса
FROM car_statistics
JOIN classes ON car_statistics.car_class = classes.class
ORDER BY car_statistics.avg_position ASC,          -- Сначала лучшая позиция (меньше = лучше)
         car_statistics.car_name ASC               -- При равенстве по имени
LIMIT 1;                                            -- Только один лучший

-- ===================================================================
-- ЗАДАНИЕ 3: Все автомобили из классов с минимальной средней позицией
-- Что делаем: находим классы с лучшей средней позицией, выводим все их авто
-- Результат: авто, класс, позиция, кол-во гонок, страна, общее число гонок класса
-- ===================================================================

WITH car_statistics AS (
    -- Индивидуальная статистика автомобилей
    SELECT
        cars.name AS car_name,
        cars.class AS car_class,
        AVG(results.position) AS avg_position,
        COUNT(results.race) AS car_race_count
    FROM cars
    JOIN results ON cars.name = results.car
    GROUP BY cars.name, cars.class
),
class_statistics AS (
    -- Средняя позиция по классу в целом
    SELECT
        car_class AS class,
        AVG(avg_position) AS class_avg_position     -- Средняя арифметическая средних позиций авто
    FROM car_statistics
    GROUP BY car_class
),
min_class_avg AS (
    -- Минимальная средняя позиция среди всех классов
    SELECT MIN(class_avg_position) AS min_avg_position
    FROM class_statistics
),
selected_classes AS (
    -- Классы, показавшие лучший результат
    SELECT class
    FROM class_statistics
    WHERE class_avg_position = (SELECT min_avg_position FROM min_class_avg)
),
class_race_counts AS (
    -- Общее количество уникальных гонок, в которых участвовал класс
    SELECT
        c.class,
        COUNT(DISTINCT r.race) AS total_class_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    WHERE c.class IN (SELECT class FROM selected_classes)
    GROUP BY c.class
)
-- Финальный вывод: все автомобили из лучших классов
SELECT
    cs.car_name,
    cs.car_class,
    cs.avg_position,
    cs.car_race_count,
    cl.country AS class_country,                   -- Страна класса
    crc.total_class_races                          -- Общее число гонок класса
FROM car_statistics cs
JOIN classes cl ON cs.car_class = cl.class
JOIN selected_classes sc ON cs.car_class = sc.class
JOIN class_race_counts crc ON cs.car_class = crc.class
ORDER BY cs.car_class, cs.avg_position, cs.car_name;

-- ===================================================================
-- ЗАДАНИЕ 4: Автомобили, выступающие лучше среднего по классу
-- Что делаем: сравниваем среднюю позицию авто со средней по классу
-- Условие: в классе минимум 2 автомобиля
-- Результат: авто, у которых позиция лучше средней по классу
-- ===================================================================

WITH car_statistics AS (
    -- Статистика по каждому автомобилю
    SELECT
        cars.name AS car_name,
        cars.class AS car_class,
        AVG(results.position) AS avg_position,
        COUNT(results.race) AS race_count
    FROM cars
    JOIN results ON cars.name = results.car
    GROUP BY cars.name, cars.class
),
class_statistics AS (
    -- Статистика по классам (только с >=2 автомобилями)
    SELECT
        car_class,
        AVG(avg_position) AS class_avg_position,    -- Средняя позиция по классу
        COUNT(car_name) AS cars_in_class            -- Количество авто в классе
    FROM car_statistics
    GROUP BY car_class
    HAVING COUNT(car_name) >= 2                     -- Исключаем классы с 1 авто
)
-- Выбираем автомобили, чья позиция ЛУЧШЕ (меньше) средней по классу
SELECT
    cs.car_name,
    cs.car_class,
    cs.avg_position,
    cs.race_count,
    cl.country AS class_country
FROM car_statistics cs
JOIN class_statistics cls ON cs.car_class = cls.car_class
JOIN classes cl ON cs.car_class = cl.class
WHERE cs.avg_position < cls.class_avg_position      -- Условие: лучше среднего
ORDER BY cs.car_class, cs.avg_position;

-- ===================================================================
-- ЗАДАНИЕ 5: Автомобили с плохими выступлениями
-- Что делаем: находим автомобили со средней позицией > 3
-- Результат: авто, позиция, гонки, страна, общее число гонок класса,
--           количество плохих авто в классе (сортировка по убыванию)
-- ===================================================================

WITH car_stats AS (
    -- Базовая статистика автомобилей
    SELECT
        cars.name,
        cars.class,
        AVG(r.position) AS avg_position,            -- Средняя позиция
        COUNT(*) AS race_count                      -- Количество гонок
    FROM cars
    JOIN results r ON cars.name = r.car
    GROUP BY cars.name, cars.class
),
class_stats AS (
    -- Агрегированная статистика по классам
    SELECT
        class,
        COUNT(*) FILTER (WHERE avg_position > 3) AS low_position_count,  -- Кол-во "плохих" авто
        SUM(race_count) AS total_races               -- Общее количество гонок в классе
    FROM car_stats
    GROUP BY class
)
-- Вывод: только "плохие" автомобили (avg_position > 3)
SELECT
    car_stats.name,
    car_stats.avg_position,
    car_stats.race_count,
    classes.country,
    class_stats.total_races,
    class_stats.low_position_count
FROM car_stats
JOIN class_stats ON car_stats.class = class_stats.class
JOIN classes ON classes.class = car_stats.class
WHERE car_stats.avg_position > 3                    -- Только плохие выступления
ORDER BY class_stats.low_position_count DESC;       -- Сортировка: классы с большинством плохих авто