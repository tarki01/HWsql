-- Задание 1 ----------------------------------------------------------------------------------------------------------------

WITH RECURSIVE employee_hierarchy AS (
    SELECT
        emp.employeeid,
        emp.managerid,
        emp.departmentid,
        emp.roleid
    FROM employees emp
    WHERE emp.employeeid = 1

    UNION ALL

    SELECT
        emp.employeeid,
        emp.managerid,
        emp.departmentid,
        emp.roleid
    FROM employees emp
    JOIN employee_hierarchy hier ON emp.managerid = hier.employeeid
),
employee_projects AS (
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names
    FROM tasks t
    GROUP BY t.assignedto
)
SELECT
    hier.employeeid,
    e.name,
    hier.managerid,
    d.departmentname,
    r.rolename,
    (SELECT STRING_AGG(DISTINCT ep.projectname, ', ')
     FROM employee_projects ep WHERE ep.employeeid = hier.employeeid) AS project_names,
    et.task_names
FROM employee_hierarchy hier
JOIN employees e ON hier.employeeid = e.employeeid
LEFT JOIN departments d ON hier.departmentid = d.departmentid
LEFT JOIN roles r ON e.roleid = r.roleid
LEFT JOIN employee_tasks et ON hier.employeeid = et.employeeid
ORDER BY e.name;

-- Задание 2 ----------------------------------------------------------------------------------------------------------------

WITH RECURSIVE employee_hierarchy AS (
    SELECT employeeid, managerid, departmentid, roleid
    FROM employees
    WHERE employeeid = 1

    UNION ALL

    SELECT e.employeeid, e.managerid, e.departmentid, e.roleid
    FROM employees e
    JOIN employee_hierarchy eh ON e.managerid = eh.employeeid
),
employee_projects AS (
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names,
        COUNT(*) AS total_tasks
    FROM tasks t
    GROUP BY t.assignedto
),
subordinates_count AS (
    SELECT managerid, COUNT(*) AS total_subordinates
    FROM employees
    WHERE managerid IS NOT NULL
    GROUP BY managerid
)
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
    COALESCE(sc.total_subordinates, 0) AS total_subordinates
FROM employee_hierarchy eh
JOIN employees e ON eh.employeeid = e.employeeid
LEFT JOIN departments d ON eh.departmentid = d.departmentid
LEFT JOIN roles r ON e.roleid = r.roleid
LEFT JOIN employee_tasks et ON eh.employeeid = et.employeeid
LEFT JOIN subordinates_count sc ON eh.employeeid = sc.managerid
ORDER BY e.name;

-- Задание 3 ----------------------------------------------------------------------------------------------------------------

WITH RECURSIVE subordinates_count AS (
    SELECT managerid, COUNT(*) AS total_subordinates
    FROM (
        WITH RECURSIVE all_subs AS (
            SELECT employeeid, managerid
            FROM employees
            WHERE managerid IS NOT NULL

            UNION ALL

            SELECT e.employeeid, e.managerid
            FROM employees e
            JOIN all_subs a ON e.managerid = a.employeeid
        )
        SELECT * FROM all_subs
    ) AS all_relationships
    GROUP BY managerid
),
employee_projects AS (
    SELECT DISTINCT
        t.assignedto AS employeeid,
        p.projectname
    FROM tasks t
    JOIN projects p ON t.projectid = p.projectid
),
employee_tasks AS (
    SELECT
        t.assignedto AS employeeid,
        STRING_AGG(t.taskname, ', ' ORDER BY t.taskname) AS task_names,
        COUNT(*) AS total_tasks
    FROM tasks t
    GROUP BY t.assignedto
)
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
WHERE r.rolename = 'Менеджер'
  AND COALESCE(sc.total_subordinates, 0) > 0
ORDER BY e.name;

-----------------------------------------------------------------------------------------------------------------------------