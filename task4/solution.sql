-- ===================================================================
-- ЗАДАНИЕ 1: Полная иерархия подчиненных генерального директора (EmployeeID = 1)
-- Что делаем: рекурсивно обходим дерево подчинения от CEO
-- Результат: все подчиненные (прямые и косвенные) с их проектами и задачами
-- ===================================================================

WITH RECURSIVE employee_hierarchy AS (
    -- Базовый случай: начинаем с генерального директора (EmployeeID = 1)
    SELECT
        emp.employeeid,
        emp.managerid,
        emp.departmentid,
        emp.roleid
    FROM employees emp
    WHERE emp.employeeid = 1                      -- Стартовая точка: CEO

    UNION ALL

    -- Рекурсивный случай: добавляем всех, чей managerid = employeeid из предыдущего уровня
    SELECT
        emp.employeeid,
        emp.managerid,
        emp.departmentid,
        emp.roleid
    FROM employees emp
    JOIN employee_hierarchy hier ON emp.managerid = hier.employeeid
),
employee_projects AS (
    -- Уникальные проекты, в которых участвует сотрудник (через задачи)
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    -- Список всех задач сотрудника (объединенных в строку через запятую)
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names
    FROM tasks t
    GROUP BY t.assignedto
)
-- Финальный вывод: все сотрудники в иерархии CEO
SELECT
    hier.employeeid,
    e.name,
    hier.managerid,
    d.departmentname,
    r.rolename,
    (SELECT STRING_AGG(DISTINCT ep.projectname, ', ')      -- Подзапрос: список проектов сотрудника
     FROM employee_projects ep WHERE ep.employeeid = hier.employeeid) AS project_names,
    et.task_names                                           -- Список задач сотрудника
FROM employee_hierarchy hier
JOIN employees e ON hier.employeeid = e.employeeid
LEFT JOIN departments d ON hier.departmentid = d.departmentid
LEFT JOIN roles r ON e.roleid = r.roleid
LEFT JOIN employee_tasks et ON hier.employeeid = et.employeeid
ORDER BY e.name;

-- ===================================================================
-- ЗАДАНИЕ 2: Расширенная иерархия с подсчетом прямых подчиненных
-- Что делаем: к предыдущему запросу добавляем количество прямых подчиненных
-- Результат: + поле total_subordinates (количество сотрудников, у которых managerid = текущий)
-- ===================================================================

WITH RECURSIVE employee_hierarchy AS (
    -- Та же рекурсивная иерархия от CEO
    SELECT employeeid, managerid, departmentid, roleid
    FROM employees
    WHERE employeeid = 1

    UNION ALL

    SELECT e.employeeid, e.managerid, e.departmentid, e.roleid
    FROM employees e
    JOIN employee_hierarchy eh ON e.managerid = eh.employeeid
),
employee_projects AS (
    -- Проекты сотрудников
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    -- Задачи сотрудников (с подсчетом количества)
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names,
        COUNT(*) AS total_tasks                     -- Общее количество задач
    FROM tasks t
    GROUP BY t.assignedto
),
subordinates_count AS (
    -- Подсчет прямых подчиненных (только непосредственные, не рекурсивные)
    SELECT managerid, COUNT(*) AS total_subordinates
    FROM employees
    WHERE managerid IS NOT NULL
    GROUP BY managerid
)
-- Финальный вывод с добавлением количества подчиненных
SELECT
    eh.employeeid,
    e.name,
    eh.managerid,
    d.departmentname,
    r.rolename,
    (SELECT STRING_AGG(DISTINCT ep.projectname, ', ')
     FROM employee_projects ep WHERE ep.employeeid = eh.employeeid) AS project_names,
    et.task_names,
    et.total_tasks,
    COALESCE(sc.total_subordinates, 0) AS total_subordinates   -- 0 если нет подчиненных
FROM employee_hierarchy eh
JOIN employees e ON eh.employeeid = e.employeeid
LEFT JOIN departments d ON eh.departmentid = d.departmentid
LEFT JOIN roles r ON e.roleid = r.roleid
LEFT JOIN employee_tasks et ON eh.employeeid = et.employeeid
LEFT JOIN subordinates_count sc ON eh.employeeid = sc.managerid
ORDER BY e.name;

-- ===================================================================
-- ЗАДАНИЕ 3: Все менеджеры, имеющие хотя бы одного подчиненного
-- Что делаем: находим сотрудников с ролью 'Менеджер', у которых есть подчиненные
-- Особенность: считаем ВСЕХ подчиненных (прямых и косвенных) через рекурсивный CTE
-- Результат: менеджеры, их проекты, задачи, общее количество подчиненных
-- ===================================================================

WITH RECURSIVE subordinates_count AS (
    -- Рекурсивный подсчет ВСЕХ подчиненных (включая косвенных)
    SELECT managerid, COUNT(*) AS total_subordinates
    FROM (
        -- Подзапрос: все отношения "начальник-подчиненный" (включая транзитивные)
        WITH RECURSIVE all_subs AS (
            -- Базовый случай: все сотрудники, у которых есть прямой начальник
            SELECT employeeid, managerid
            FROM employees
            WHERE managerid IS NOT NULL

            UNION ALL

            -- Рекурсивный случай: добавляем подчиненных подчиненных
            SELECT e.employeeid, e.managerid
            FROM employees e
            JOIN all_subs a ON e.managerid = a.employeeid
        )
        SELECT * FROM all_subs
    ) AS all_relationships
    GROUP BY managerid                                 -- Группируем по начальнику
),
employee_projects AS (
    -- Уникальные проекты сотрудников
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    -- Задачи сотрудников
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names,
        COUNT(*) AS total_tasks
    FROM tasks t
    GROUP BY t.assignedto
)
-- Финальный вывод: только менеджеры с подчиненными
SELECT
    e.employeeid,
    e.name,
    e.managerid,
    d.departmentname,
    r.rolename,
    (SELECT STRING_AGG(DISTINCT ep.projectname, ', ')
     FROM employee_projects ep WHERE ep.employeeid = e.employeeid) AS project_names,
    et.task_names,
    COALESCE(sc.total_subordinates, 0) AS total_subordinates
FROM employees e
LEFT JOIN departments d ON e.departmentid = d.departmentid
LEFT JOIN roles r ON e.roleid = r.roleid
LEFT JOIN employee_tasks et ON e.employeeid = et.employeeid
LEFT JOIN subordinates_count sc ON e.employeeid = sc.managerid
WHERE r.rolename = 'Менеджер'                        -- Только сотрудники с ролью "Менеджер"
  AND COALESCE(sc.total_subordinates, 0) > 0         -- У которых есть хотя бы один подчиненный
ORDER BY e.name;