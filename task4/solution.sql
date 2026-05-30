-- Задание 1 +

WITH RECURSIVE employee_hierarchy AS (
    SELECT
        emp.employeeid,
        emp.managerid,
        dep.departmentid,
        rol.roleid
    FROM employees emp
    JOIN roles rol ON rol.roleid = emp.roleid
    JOIN departments dep ON emp.departmentid = dep.departmentid
    WHERE emp.employeeid = 1

    UNION ALL

    SELECT
        emp.employeeid,
        emp.managerid,
        dep.departmentid,
        rol.roleid
    FROM employees emp
    JOIN roles rol ON rol.roleid = emp.roleid
    JOIN departments dep ON emp.departmentid = dep.departmentid
    JOIN employee_hierarchy hier ON emp.managerid = hier.employeeid
)
SELECT
    hier.employeeid,
    emp.name,
    hier.managerid,
    dep.departmentname,
    rol.rolename,
    STRING_AGG(DISTINCT proj.projectname, ', ') AS project_names,
    STRING_AGG(task.taskname, ', ') AS task_names
FROM employee_hierarchy hier
JOIN employees emp ON hier.employeeid = emp.employeeid
LEFT JOIN departments dep ON dep.departmentid = hier.departmentid
JOIN roles rol ON rol.roleid = hier.roleid
LEFT JOIN projects proj ON proj.departmentid = hier.departmentid
LEFT JOIN tasks task ON task.assignedto = hier.employeeid AND task.projectid = proj.projectid
GROUP BY
    hier.employeeid,
    emp.name,
    hier.managerid,
    dep.departmentid,
    rol.roleid
ORDER BY emp.name;

-- Задание 2 +

WITH RECURSIVE employeehierarchy AS (

    SELECT e.employeeid, e.managerid, d.departmentid, r.roleid
    FROM employees e
             join roles r on r.roleid = e.roleid
             join departments d on e.departmentid = d.departmentid
    WHERE employeeid = 1

    UNION ALL

    SELECT e.employeeid, e.managerid, d.departmentid, r.roleid

    FROM employees e
             join roles r on r.roleid = e.roleid
             join departments d on e.departmentid = d.departmentid
             join employeehierarchy eh on e.managerid = eh.employeeid
)
select eh.employeeid, e.name, eh.managerid, d.departmentname, r.rolename,
       string_agg(DISTINCT p.projectname, ',') as ProjectNames, string_agg(t.taskname, ',') as TaskNames,
       count(t.taskname) as TotalTasks, coalesce(tt.TotalSubordinates, 0)
from employeehierarchy eh
         join employees e on eh.employeeid = e.employeeid
         join departments d on d.departmentid = eh.departmentid
         join roles r on r.roleid = eh.roleid
         LEFT join projects p on p.departmentid = eh.departmentid
         LEFT join tasks t on t.assignedto = eh.employeeid and t.projectid = p.projectid
         LEFT join (
            select e.managerid, count(eh.employeeid) as TotalSubordinates
            from employees e join employeehierarchy eh on eh.employeeid = e.employeeid
            where e.managerid IS NOT NULL
            group by e.managerid

        ) tt on e.employeeid = tt.managerid
group by eh.employeeid, e.name, eh.managerid, d.departmentid, r.roleid, tt.TotalSubordinates
order by e.name;

-- Задание 3 +

WITH RECURSIVE employee_hierarchy AS (
    SELECT
        emp.employeeid,
        emp.managerid,
        dep.departmentid,
        rol.roleid
    FROM employees emp
    JOIN roles rol ON rol.roleid = emp.roleid
    JOIN departments dep ON emp.departmentid = dep.departmentid
    WHERE emp.employeeid = 1

    UNION ALL

    SELECT
        emp.employeeid,
        emp.managerid,
        dep.departmentid,
        rol.roleid
    FROM employees emp
    JOIN roles rol ON rol.roleid = emp.roleid
    JOIN departments dep ON emp.departmentid = dep.departmentid
    JOIN employee_hierarchy hier ON emp.managerid = hier.employeeid
)
SELECT
    hier.employeeid,
    emp.name,
    hier.managerid,
    dep.departmentname,
    rol.rolename,
    STRING_AGG(DISTINCT proj.projectname, ',') AS ProjectNames,
    STRING_AGG(task.taskname, ',') AS TaskNames,
    COALESCE(sub.TotalSubordinates, 0) AS TotalSubordinates
FROM employee_hierarchy hier
JOIN employees emp ON hier.employeeid = emp.employeeid
JOIN departments dep ON dep.departmentid = hier.departmentid
JOIN roles rol ON rol.roleid = hier.roleid
LEFT JOIN projects proj ON proj.departmentid = hier.departmentid
LEFT JOIN tasks task ON task.assignedto = hier.employeeid AND task.projectid = proj.projectid
LEFT JOIN (
    SELECT
        emp.managerid,
        COUNT(hier.employeeid) AS TotalSubordinates
    FROM employees emp
    JOIN employee_hierarchy hier ON hier.employeeid = emp.employeeid
    WHERE emp.managerid IS NOT NULL
    GROUP BY emp.managerid
) sub ON emp.employeeid = sub.managerid
WHERE COALESCE(sub.TotalSubordinates, 0) > 0
  AND rol.rolename = 'Менеджер'
GROUP BY
    hier.employeeid,
    emp.name,
    hier.managerid,
    dep.departmentid,
    rol.roleid,
    sub.TotalSubordinates
ORDER BY emp.name;