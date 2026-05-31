-- ===================================================================
-- ЗАДАНИЕ 1: Активные клиенты с бронированиями в разных отелях
-- Условия: более 2 бронирований, более 1 уникального отеля
-- Результат: имя, email, телефон, число бронирований, список отелей, средняя длина проживания
-- ===================================================================

WITH customer_bookings AS (
    -- Шаг 1: Денормализация - собираем все данные о бронированиях
    SELECT
        c.ID_customer,
        c.name,
        c.email,
        c.phone,
        h.name AS hotel_name,                       -- Название отеля
        b.ID_booking,
        (b.check_out_date - b.check_in_date) AS stay_duration  -- Длительность проживания (дни)
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
),
customer_stats AS (
    -- Шаг 2: Агрегация данных по каждому клиенту
    SELECT
        ID_customer,
        name,
        email,
        phone,
        COUNT(DISTINCT ID_booking) AS total_bookings,          -- Общее число бронирований
        COUNT(DISTINCT hotel_name) AS unique_hotels,           -- Количество уникальных отелей
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS hotel_list,  -- Список отелей через запятую
        AVG(stay_duration) AS avg_stay_days                    -- Средняя длительность проживания
    FROM customer_bookings
    GROUP BY ID_customer, name, email, phone
)
-- Шаг 3: Фильтрация и вывод
SELECT
    name,
    email,
    phone,
    total_bookings,
    hotel_list,
    ROUND(avg_stay_days, 2) AS avg_stay_days        -- Округляем до 2 знаков
FROM customer_stats
WHERE total_bookings > 2                            -- Больше 2 бронирований
  AND unique_hotels > 1                             -- И больше 1 отеля
ORDER BY total_bookings DESC;                       -- Сортировка: сначала самые активные

-- ===================================================================
-- ЗАДАНИЕ 2: Клиенты с бронированиями в разных отелях и большими тратами
-- Условия: >2 бронирований, >1 отеля, общие траты >500
-- Результат: ID, имя, число бронирований, сумма трат, число отелей (сортировка по тратам)
-- ===================================================================

WITH customer_analytics AS (
    -- Базовая аналитика по клиентам
    SELECT
        c.ID_customer,
        c.name,
        COUNT(DISTINCT b.ID_booking) AS total_bookings,         -- Всего бронирований
        COUNT(DISTINCT h.ID_hotel) AS unique_hotels,            -- Уникальных отелей
        SUM(r.price * (b.check_out_date - b.check_in_date)) AS total_spent  -- Общая сумма трат (цена * дни)
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name
),
customers_multi_bookings AS (
    -- Клиенты с множественными бронированиями в разных отелях
    SELECT
        ID_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    FROM customer_analytics
    WHERE total_bookings > 2 AND unique_hotels > 1
),
customers_high_spenders AS (
    -- Клиенты с высокими тратами
    SELECT
        ID_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    FROM customer_analytics
    WHERE total_spent > 500
)
-- Пересечение двух множеств: активные И много тратящие
SELECT
    ID_customer,
    name,
    total_bookings,
    total_spent,
    unique_hotels
FROM customers_multi_bookings
WHERE ID_customer IN (SELECT ID_customer FROM customers_high_spenders)
ORDER BY total_spent ASC;                          -- Сортировка: сначала меньшие траты

-- ===================================================================
-- ЗАДАНИЕ 3: Классификация клиентов по предпочитаемым отелям
-- Категории отелей:
--   - Дешевый: средняя цена номера < 175
--   - Средний: средняя цена номера от 175 до 300
--   - Дорогой: средняя цена номера > 300
-- Правило классификации клиента: если был в дорогом → 'Дорогой',
--   иначе если в среднем → 'Средний', иначе 'Дешевый'
-- Результат: ID, имя, категория, список посещенных отелей
-- ===================================================================

WITH hotel_categories AS (
    -- Определяем категорию каждого отеля на основе средней цены номера
    SELECT
        h.ID_hotel,
        h.name AS hotel_name,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            WHEN AVG(r.price) > 300 THEN 'Дорогой'
        END AS category
    FROM Hotel h
    JOIN Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY h.ID_hotel, h.name
)
-- Классифицируем клиентов по максимальной категории отеля, который они посещали
SELECT
    c.ID_customer,
    c.name,
    CASE
        -- Если клиент когда-либо был в дорогом отеле → 'Дорогой'
        WHEN MAX(CASE WHEN hc.category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 'Дорогой'
        -- Иначе если был в среднем → 'Средний'
        WHEN MAX(CASE WHEN hc.category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 'Средний'
        -- Иначе → 'Дешевый'
        ELSE 'Дешевый'
    END AS preferred_hotel_type,
    STRING_AGG(DISTINCT hc.hotel_name, ', ' ORDER BY hc.hotel_name) AS visited_hotels  -- Список посещенных отелей
FROM Customer c
JOIN Booking b ON c.ID_customer = b.ID_customer
JOIN Room r ON r.ID_room = b.ID_room
JOIN hotel_categories hc ON r.ID_hotel = hc.ID_hotel
GROUP BY c.ID_customer, c.name
ORDER BY
    -- Сортировка по "престижности" категории: Дорогой (3), Средний (2), Дешевый (1)
    CASE
        WHEN MAX(CASE WHEN hc.category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 3
        WHEN MAX(CASE WHEN hc.category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 2
        ELSE 1
    END,
    c.ID_customer;                                 -- Вторичная сортировка по ID