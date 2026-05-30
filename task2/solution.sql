-- Задание 1 ----------------------------------------------------------------------------------------------------------------

select cars.name, cars.class, avg(results.position) as average_position, count(races.name)
from cars
join results on cars.name = results.car
join races on races.name = results.race
group by cars.name, cars.class
ORDER BY average_position;

-- Задание 2 ---------------------------------------------------------------------------------------------------------------- +

WITH car_statistics AS (
    -- Рассчитываем среднюю позицию и количество гонок для каждого автомобиля
    SELECT
        cars.name AS car_name,
        cars.class AS car_class,
        AVG(results.position) AS avg_position,
        COUNT(results.race) AS race_count
    FROM cars
    JOIN results ON cars.name = results.car
    GROUP BY cars.name, cars.class
)
-- Выбираем автомобиль с наименьшей средней позицией
SELECT TOP 1
    car_statistics.car_name,
    car_statistics.car_class,
    car_statistics.avg_position,
    car_statistics.race_count,
    classes.country AS class_country
FROM car_statistics
JOIN classes ON car_statistics.car_class = classes.class
ORDER BY car_statistics.avg_position ASC, car_statistics.car_name ASC;

-- Задание 3 ---------------------------------------------------------------------------------------------------------------- +

WITH car_statistics AS (
    -- Рассчитываем среднюю позицию для каждого автомобиля
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
    -- Рассчитываем среднюю позицию для каждого класса
    SELECT
        car_class AS class,
        AVG(avg_position) AS class_avg_position
    FROM car_statistics
    GROUP BY car_class
),
min_class_avg AS (
    -- Находим минимальную среднюю позицию среди всех классов
    SELECT MIN(class_avg_position) AS min_avg_position
    FROM class_statistics
),
selected_classes AS (
    -- Выбираем классы с наименьшей средней позицией
    SELECT class
    FROM class_statistics
    WHERE class_avg_position = (SELECT min_avg_position FROM min_class_avg)
),
class_race_counts AS (
    -- Рассчитываем общее количество гонок для каждого выбранного класса
    SELECT
        c.class,
        COUNT(DISTINCT r.race) AS total_class_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    WHERE c.class IN (SELECT class FROM selected_classes)
    GROUP BY c.class
)
-- Выводим информацию о каждом автомобиле из выбранных классов
SELECT
    cs.car_name,
    cs.car_class,
    cs.avg_position,
    cs.car_race_count,
    cl.country AS class_country,
    crc.total_class_races
FROM car_statistics cs
JOIN classes cl ON cs.car_class = cl.class
JOIN selected_classes sc ON cs.car_class = sc.class
JOIN class_race_counts crc ON cs.car_class = crc.class
ORDER BY cs.car_class, cs.avg_position, cs.car_name;

-- Задание 4 ---------------------------------------------------------------------------------------------------------------- +

WITH car_statistics AS (
    -- Рассчитываем среднюю позицию и количество гонок для каждого автомобиля
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
    -- Рассчитываем среднюю позицию для каждого класса (только для классов с минимум 2 автомобилями)
    SELECT
        car_class,
        AVG(avg_position) AS class_avg_position,
        COUNT(car_name) AS cars_in_class
    FROM car_statistics
    GROUP BY car_class
    HAVING COUNT(car_name) >= 2
)
-- Выбираем автомобили, у которых средняя позиция лучше средней по классу
SELECT
    cs.car_name,
    cs.car_class,
    cs.avg_position,
    cs.race_count,
    cl.country AS class_country
FROM car_statistics cs
JOIN class_statistics cls ON cs.car_class = cls.car_class
JOIN classes cl ON cs.car_class = cl.class
WHERE cs.avg_position < cls.class_avg_position
ORDER BY cs.car_class, cs.avg_position;

-- Задание 5 ---------------------------------------------------------------------------------------------------------------- +

WITH car_stats AS (
    SELECT
        c.name,
        c.class,
        AVG(r.position) AS avg_position,
        COUNT(*) AS race_count
    FROM cars c
             JOIN results r ON c.name = r.car
    GROUP BY c.name, c.class
),
     class_stats AS (
         SELECT
             class,
             COUNT(*) FILTER (WHERE avg_position >= 3) AS low_position_count,
             SUM(race_count) AS total_races
         FROM car_stats
         GROUP BY class
     )
SELECT
    cs.name,
    cs.avg_position,
    cs.race_count,
    cl.country,
    cls.total_races,
    cls.low_position_count
FROM car_stats cs
         JOIN class_stats cls ON cs.class = cls.class
         JOIN classes cl ON cl.class = cs.class
WHERE cs.avg_position > 3
ORDER BY cls.low_position_count DESC;

-- --------------------------------------------------------------------------------------------------------------------------