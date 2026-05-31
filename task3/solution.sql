-- Задание 1 ----------------------------------------------------------------------------------------------------------------

WITH customer_bookings AS (
    -- Получаем данные о бронированиях клиентов с информацией об отелях
    SELECT
        c.ID_customer,
        c.name,
        c.email,
        c.phone,
        h.name AS hotel_name,
        b.ID_booking,
        (b.check_out_date - b.check_in_date) AS stay_duration
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
),
customer_stats AS (
    -- Агрегируем данные по каждому клиенту
    SELECT
        ID_customer,
        name,
        email,
        phone,
        COUNT(DISTINCT ID_booking) AS total_bookings,
        COUNT(DISTINCT hotel_name) AS unique_hotels,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS hotel_list,
        AVG(stay_duration) AS avg_stay_days
    FROM customer_bookings
    GROUP BY ID_customer, name, email, phone
)
SELECT
    name,
    email,
    phone,
    total_bookings,
    hotel_list,
    ROUND(avg_stay_days, 2) AS avg_stay_days
FROM customer_stats
WHERE total_bookings > 2
  AND unique_hotels > 1
ORDER BY total_bookings DESC;

-- Задание 2 ----------------------------------------------------------------------------------------------------------------

WITH customer_analytics AS (
    SELECT
        c.ID_customer,
        c.name,
        COUNT(DISTINCT b.ID_booking) AS total_bookings,
        COUNT(DISTINCT h.ID_hotel) AS unique_hotels,
        SUM(r.price * (b.check_out_date - b.check_in_date)) AS total_spent
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name
),
customers_multi_bookings AS (
    SELECT
        ID_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    FROM customer_analytics
    WHERE total_bookings > 2
      AND unique_hotels > 1
),
customers_high_spenders AS (
    SELECT
        ID_customer,
        name,
        total_bookings,
        unique_hotels,
        total_spent
    FROM customer_analytics
    WHERE total_spent > 500
)
SELECT
    ID_customer,
    name,
    total_bookings,
    total_spent,
    unique_hotels
FROM customers_multi_bookings
WHERE ID_customer IN (SELECT ID_customer FROM customers_high_spenders)
ORDER BY total_spent ASC;

-- Задание 3 ----------------------------------------------------------------------------------------------------------------

WITH hotel_categories AS (
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
SELECT
    c.ID_customer,
    c.name,
    CASE
        WHEN MAX(CASE WHEN hc.category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 'Дорогой'
        WHEN MAX(CASE WHEN hc.category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 'Средний'
        ELSE 'Дешевый'
    END AS preferred_hotel_type,
    STRING_AGG(DISTINCT hc.hotel_name, ', ' ORDER BY hc.hotel_name) AS visited_hotels
FROM Customer c
JOIN Booking b ON c.ID_customer = b.ID_customer
JOIN Room r ON r.ID_room = b.ID_room
JOIN hotel_categories hc ON r.ID_hotel = hc.ID_hotel
GROUP BY c.ID_customer, c.name
ORDER BY
    CASE
        WHEN MAX(CASE WHEN hc.category = 'Дорогой' THEN 1 ELSE 0 END) = 1 THEN 3
        WHEN MAX(CASE WHEN hc.category = 'Средний' THEN 1 ELSE 0 END) = 1 THEN 2
        ELSE 1
    END,
    c.ID_customer;

-----------------------------------------------------------------------------------------------------------------------------