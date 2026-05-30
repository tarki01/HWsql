-- Задание 1 ----------------------------------------------------------------------------------------------------------------

SELECT
    v.maker,
    v.model
FROM Vehicle v
JOIN Motorcycle m ON v.model = m.model
WHERE m.horsepower > 150
  AND m.price < 20000.00
  AND m.type = 'Sport'
ORDER BY m.horsepower DESC;

-- Задание 2 ----------------------------------------------------------------------------------------------------------------

with a as (
    select v.maker, v.model, c.engine_capacity, c.horsepower, 'Car' as Тип
    from car as c
    join vehicle as v on v.model = c.model
    where c.horsepower > 150 and c.engine_capacity < 3
      and c.price < 35000
),
m as (
    select v.maker, v.model, m.engine_capacity, m.horsepower, 'Motorcycle' as Тип
    from motorcycle as m
    join vehicle as v on v.model = m.model
    where m.horsepower > 150 and m.engine_capacity < 1.5
      and m.price < 20000
),
b as (
    select v.maker, v.model, cast(null as numeric) as engine_capacity,
           cast(null as numeric) as horsepower, 'Bicycle' as Тип
    from bicycle as b
    join vehicle as v on v.model = b.model
    where b.gear_count > 18 and b.price < 4000
),
u as (
    select * from a
    union all
    select * from m
    union all
    select * from b
    order by horsepower desc nulls last
)
select * from u;

-----------------------------------------------------------------------------------------------------------------------------