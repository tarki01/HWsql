CREATE TABLE Departments (
                             DepartmentID SERIAL PRIMARY KEY,  -- Используем SERIAL для автоматической генерации идентификаторов
                             DepartmentName VARCHAR(100) NOT NULL
);

CREATE TABLE Roles (
                       RoleID SERIAL PRIMARY KEY,  -- Используем SERIAL для автоматической генерации идентификаторов
                       RoleName VARCHAR(100) NOT NULL
);

CREATE TABLE Employees (
                           EmployeeID SERIAL PRIMARY KEY,  -- Используем SERIAL для автоматической генерации идентификаторов
                           Name VARCHAR(100) NOT NULL,
                           Position VARCHAR(100),
                           ManagerID INT,
                           DepartmentID INT,
                           RoleID INT,
                           FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID) ON DELETE SET NULL,  -- Устанавливаем поведение при удалении
                           FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE CASCADE,  -- Устанавливаем поведение при удалении
                           FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE SET NULL  -- Устанавливаем поведение при удалении
);

CREATE TABLE Projects (
                          ProjectID SERIAL PRIMARY KEY,  -- Используем SERIAL для автоматической генерации идентификаторов
                          ProjectName VARCHAR(100) NOT NULL,
                          StartDate DATE,
                          EndDate DATE,
                          DepartmentID INT,
                          FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE CASCADE  -- Устанавливаем поведение при удалении
);

CREATE TABLE Tasks (
                       TaskID SERIAL PRIMARY KEY,  -- Используем SERIAL для автоматической генерации идентификаторов
                       TaskName VARCHAR(100) NOT NULL,
                       AssignedTo INT,
                       ProjectID INT,
                       FOREIGN KEY (AssignedTo) REFERENCES Employees(EmployeeID) ON DELETE SET NULL,  -- Устанавливаем поведение при удалении
                       FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON DELETE CASCADE  -- Устанавливаем поведение при удалении
);