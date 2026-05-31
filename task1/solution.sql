-- ===================================================================
-- ЗАДАНИЕ 1: Поиск спортивных мотоциклов
-- Условия: мощность > 150 л.с., цена < 20000, тип 'Sport'
-- Результат: производитель, модель, сортировка по убыванию мощности
-- ===================================================================

SELECT
    v.maker,      -- Производитель мотоцикла (например, Yamaha, Harley-Davidson)
    v.model       -- Модель мотоцикла (например, YZF-R1, Sportster)
FROM Vehicle v
JOIN Motorcycle m ON v.model = m.model   -- Соединяем Vehicle и Motorcycle по модели
WHERE m.horsepower > 150                 -- Только мощные мотоциклы (>150 л.с.)
  AND m.price < 20000.00                 -- Бюджетное ограничение (до $20000)
  AND m.type = 'Sport'                   -- Только спортивные мотоциклы
ORDER BY m.horsepower DESC;              -- Сортировка: сначала самые мощные

-- ===================================================================
-- ЗАДАНИЕ 2: Объединение всех типов транспортных средств
-- Условия:
--   - Авто: мощность >150 л.с., объем <3.0L, цена <35000
--   - Мото: мощность >150 л.с., объем <1.5L, цена <20000
--   - Вело: количество передач >18, цена <4000
-- Результат: общая таблица со всеми ТС, NULL для отсутствующих характеристик
-- ===================================================================

-- Блок A: Автомобили, соответствующие критериям
with a as (
    select
        v.maker,                          -- Производитель
        v.model,                          -- Модель
        c.engine_capacity,                -- Объем двигателя (литры)
        c.horsepower,                     -- Мощность (л.с.)
        'Car' as Тип                      -- Метка типа ТС
    from car as c
    join vehicle as v on v.model = c.model
    where c.horsepower > 150              -- Мощность выше 150 л.с.
      and c.engine_capacity < 3           -- Объем двигателя менее 3 литров
      and c.price < 35000                 -- Цена до $35000
),

-- Блок M: Мотоциклы, соответствующие критериям
m as (
    select
        v.maker,                          -- Производитель
        v.model,                          -- Модель
        m.engine_capacity,                -- Объем двигателя (литры)
        m.horsepower,                     -- Мощность (л.с.)
        'Motorcycle' as Тип               -- Метка типа ТС
    from motorcycle as m
    join vehicle as v on v.model = m.model
    where m.horsepower > 150              -- Мощность выше 150 л.с.
      and m.engine_capacity < 1.5         -- Объем двигателя менее 1.5 литра
      and m.price < 20000                 -- Цена до $20000
),

-- Блок B: Велосипеды, соответствующие критериям
b as (
    select
        v.maker,                          -- Производитель
        v.model,                          -- Модель
        cast(null as numeric) as engine_capacity,  -- У велосипедов нет двигателя → NULL
        cast(null as numeric) as horsepower,       -- У велосипедов нет л.с. → NULL
        'Bicycle' as Тип                  -- Метка типа ТС
    from bicycle as b
    join vehicle as v on v.model = b.model
    where b.gear_count > 18               -- Количество передач более 18
      and b.price < 4000                  -- Цена до $4000
),

-- Объединение всех трех блоков с сортировкой
u as (
    select * from a
    union all                             -- Объединяем все строки (без удаления дубликатов)
    select * from m
    union all
    select * from b
    order by horsepower desc nulls last   -- Сортировка: сначала мощные, NULL (вело) в конце
)

-- Финальный результат
select * from u;