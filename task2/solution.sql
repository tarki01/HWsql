-- Задание 1 ----------------------------------------------------------------------------------------------------------------

WITH car_stats AS (
    SELECT
        c.name,
        c.class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
min_per_class AS (
    SELECT
        class,
        MIN(average_position) AS min_avg_position
    FROM car_stats
    GROUP BY class
)
SELECT
    cs.name,
    cs.class,
    cs.average_position,
    cs.race_count
FROM car_stats cs
JOIN min_per_class mpc ON cs.class = mpc.class
    AND cs.average_position = mpc.min_avg_position
ORDER BY cs.average_position;

-- Задание 2 ---------------------------------------------------------------------------------------------------------------- +

WITH car_statistics AS (
    SELECT
        cars.name AS car_name,
        cars.class AS car_class,
        AVG(results.position) AS avg_position,
        COUNT(results.race) AS race_count
    FROM cars
    JOIN results ON cars.name = results.car
    GROUP BY cars.name, cars.class
)
SELECT
    car_statistics.car_name,
    car_statistics.car_class,
    car_statistics.avg_position,
    car_statistics.race_count,
    classes.country AS class_country
FROM car_statistics
JOIN classes ON car_statistics.car_class = classes.class
ORDER BY car_statistics.avg_position ASC, car_statistics.car_name ASC
LIMIT 1;

-- Задание 3 ---------------------------------------------------------------------------------------------------------------- +

WITH car_statistics AS (
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
    SELECT
        car_class AS class,
        AVG(avg_position) AS class_avg_position
    FROM car_statistics
    GROUP BY car_class
),
min_class_avg AS (
    SELECT MIN(class_avg_position) AS min_avg_position
    FROM class_statistics
),
selected_classes AS (
    SELECT class
    FROM class_statistics
    WHERE class_avg_position = (SELECT min_avg_position FROM min_class_avg)
),
class_race_counts AS (
    SELECT
        c.class,
        COUNT(DISTINCT r.race) AS total_class_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    WHERE c.class IN (SELECT class FROM selected_classes)
    GROUP BY c.class
)
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
    SELECT
        car_class,
        AVG(avg_position) AS class_avg_position,
        COUNT(car_name) AS cars_in_class
    FROM car_statistics
    GROUP BY car_class
    HAVING COUNT(car_name) >= 2
)
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
        cars.name,
        cars.class,
        AVG(r.position) AS avg_position,
        COUNT(*) AS race_count
    FROM cars
             JOIN results r ON cars.name = r.car
    GROUP BY cars.name, cars.class
),
     class_stats AS (
         SELECT
             class,
             COUNT(*) FILTER (WHERE avg_position > 3) AS low_position_count,
             SUM(race_count) AS total_races
         FROM car_stats
         GROUP BY class
     )
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
WHERE car_stats.avg_position > 3
ORDER BY class_stats.low_position_count DESC;

-- --------------------------------------------------------------------------------------------------------------------------