/* =====================================================================
   COMPANY DATABASE  -  SQL IMPLEMENTATION (SQL Server / T-SQL)
   Source : the COMPANY relational-mapping image (handwritten example)

   Tables (6):  EMPLOYEE, DEPARTMENT, Department_location,
                PROJECT, Employee_work, DEPENDENT

   How to run : SSMS -> File > Open > File... -> pick this file ->
                make sure NOTHING is selected -> press Execute (F5).
                (GO lines split the script into batches; SSMS understands them.)

   File layout
     PART 1  Create the database
     PART 2  Drop old objects (so the script can be re-run safely)
     PART 3  Create the tables
     PART 4  Insert sample data
     PART 5  Queries (SELECT / UPDATE / DELETE)
   ===================================================================== */


/* =====================================================================
   PART 1 : DATABASE
   ===================================================================== */
IF DB_ID('company_db') IS NULL
    CREATE DATABASE company_db;
GO

USE company_db;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


/* =====================================================================
   PART 2 : DROP OLD OBJECTS
   EMPLOYEE and DEPARTMENT point at each other, so the foreign key
   EMPLOYEE.D_no -> DEPARTMENT is dropped first.
   ===================================================================== */
IF OBJECT_ID('dbo.EMPLOYEE', 'U') IS NOT NULL
   AND OBJECT_ID('dbo.fk_employee_department', 'F') IS NOT NULL
    ALTER TABLE dbo.EMPLOYEE DROP CONSTRAINT fk_employee_department;

IF OBJECT_ID('dbo.Employee_work',        'U') IS NOT NULL DROP TABLE dbo.Employee_work;
IF OBJECT_ID('dbo.DEPENDENT',            'U') IS NOT NULL DROP TABLE dbo.DEPENDENT;
IF OBJECT_ID('dbo.PROJECT',              'U') IS NOT NULL DROP TABLE dbo.PROJECT;
IF OBJECT_ID('dbo.Department_location',  'U') IS NOT NULL DROP TABLE dbo.Department_location;
IF OBJECT_ID('dbo.DEPARTMENT',           'U') IS NOT NULL DROP TABLE dbo.DEPARTMENT;
IF OBJECT_ID('dbo.EMPLOYEE',             'U') IS NOT NULL DROP TABLE dbo.EMPLOYEE;
GO


/* =====================================================================
   PART 3 : CREATE TABLES
   Rules used (same as the example):
     - 1:1                   -> PK of the lower side goes into the bigger table
     - 1:M                   -> PK of the "one" side becomes FK in the "many" side
     - M:M                   -> new table, the 2 FKs form a composite PK
     - Multivalued attribute -> new table, (owner FK + value) = composite PK
     - Weak entity           -> owner PK + its own key = composite PK
     - Recursive relation    -> FK that points back to the same table

   SQL Server note: plain foreign keys use the default (NO ACTION);
   ON DELETE CASCADE is used only on Department_location, Employee_work
   and DEPENDENT, where it is safe (no multiple cascade paths).
   ===================================================================== */

/* ---------- EMPLOYEE ----------
   supervise (recursive) : Super_id -> EMPLOYEE(SSN)
   work (DEPARTMENT 1 : M EMPLOYEE) : D_no -> DEPARTMENT(D_no)
   The D_no foreign key is added with ALTER TABLE after DEPARTMENT exists,
   because DEPARTMENT also points back to EMPLOYEE (circular reference). */
CREATE TABLE EMPLOYEE (
    SSN       CHAR(9)      NOT NULL,
    F_name    VARCHAR(50)  NOT NULL,
    L_name    VARCHAR(50)  NOT NULL,
    Gender    CHAR(1),
    DB        DATE,                          -- birth date
    D_no      INT,                           -- FK -> DEPARTMENT (added below)
    Super_id  CHAR(9),                       -- FK -> EMPLOYEE (supervisor)
    CONSTRAINT pk_employee PRIMARY KEY (SSN),
    CONSTRAINT ck_employee_gender CHECK (Gender IN ('M', 'F')),
    CONSTRAINT fk_employee_supervisor FOREIGN KEY (Super_id)
        REFERENCES EMPLOYEE (SSN)
);
GO

/* ---------- DEPARTMENT ----------
   manage (EMPLOYEE 1 : 1 DEPARTMENT) : manager_id -> EMPLOYEE(SSN)
   hire_date = the date the manager started managing the department */
CREATE TABLE DEPARTMENT (
    D_no        INT          NOT NULL,
    manager_id  CHAR(9),                     -- FK -> EMPLOYEE
    Dname       VARCHAR(100) NOT NULL,
    hire_date   DATE,
    CONSTRAINT pk_department PRIMARY KEY (D_no),
    CONSTRAINT fk_department_manager FOREIGN KEY (manager_id)
        REFERENCES EMPLOYEE (SSN)
);
GO

/* 1:1 rule: one employee can manage at most ONE department.
   (A filtered unique index is used so several departments can still have
   no manager yet, because a normal UNIQUE allows only one NULL in SQL Server.) */
CREATE UNIQUE INDEX uq_department_manager
    ON DEPARTMENT (manager_id)
    WHERE manager_id IS NOT NULL;
GO

/* Now close the circle: work (1 : M) */
ALTER TABLE EMPLOYEE
    ADD CONSTRAINT fk_employee_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no);
GO

/* ---------- Department_location (multivalued attribute) ---------- */
CREATE TABLE Department_location (
    D_no      INT          NOT NULL,         -- FK -> DEPARTMENT
    location  VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_department_location PRIMARY KEY (D_no, location),
    CONSTRAINT fk_deptloc_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no) ON DELETE CASCADE
);
GO

/* ---------- PROJECT ----------
   have (DEPARTMENT 1 : M PROJECT) : D_no -> DEPARTMENT(D_no)
   (In the picture the arrow ends at the D_no cell of Department_location.
   That column is not unique on its own, so SQL cannot reference it;
   the same D_no value is referenced from DEPARTMENT instead.) */
CREATE TABLE PROJECT (
    P_no      INT          NOT NULL,
    Pname     VARCHAR(100) NOT NULL,
    City      VARCHAR(50),
    location  VARCHAR(50),
    D_no      INT          NOT NULL,         -- FK -> DEPARTMENT
    CONSTRAINT pk_project PRIMARY KEY (P_no),
    CONSTRAINT fk_project_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no)
);
GO

/* ---------- Employee_work : work (EMPLOYEE M : M PROJECT) ---------- */
CREATE TABLE Employee_work (
    SSN            CHAR(9)      NOT NULL,    -- FK -> EMPLOYEE
    P_no           INT          NOT NULL,    -- FK -> PROJECT
    working_hours  DECIMAL(4,1),
    CONSTRAINT pk_employee_work PRIMARY KEY (SSN, P_no),
    CONSTRAINT fk_ew_employee FOREIGN KEY (SSN)
        REFERENCES EMPLOYEE (SSN) ON DELETE CASCADE,
    CONSTRAINT fk_ew_project FOREIGN KEY (P_no)
        REFERENCES PROJECT (P_no) ON DELETE CASCADE,
    CONSTRAINT ck_ew_hours CHECK (working_hours >= 0)
);
GO

/* ---------- DEPENDENT : have (EMPLOYEE 1 : M DEPENDENT), weak entity ---------- */
CREATE TABLE DEPENDENT (
    SSN     CHAR(9)      NOT NULL,           -- FK -> EMPLOYEE
    D_name  VARCHAR(50)  NOT NULL,
    Gender  CHAR(1),
    DB      DATE,                            -- birth date
    CONSTRAINT pk_dependent PRIMARY KEY (SSN, D_name),
    CONSTRAINT fk_dependent_employee FOREIGN KEY (SSN)
        REFERENCES EMPLOYEE (SSN) ON DELETE CASCADE,
    CONSTRAINT ck_dependent_gender CHECK (Gender IN ('M', 'F'))
);
GO


/* =====================================================================
   PART 4 : SAMPLE DATA
   Order matters:
     1) DEPARTMENT without managers   2) EMPLOYEE (boss first)
     3) set the managers              4) the rest
   ===================================================================== */

INSERT INTO DEPARTMENT (D_no, manager_id, Dname, hire_date) VALUES
(1, NULL, 'Headquarters',  NULL),
(2, NULL, 'Administration', NULL),
(3, NULL, 'Research',       NULL);

-- the boss (no supervisor) first, then people who report to him/her
INSERT INTO EMPLOYEE (SSN, F_name, L_name, Gender, DB, D_no, Super_id) VALUES
('111111111', 'Omar',   'Nasser', 'M', '1975-04-10', 1, NULL);

INSERT INTO EMPLOYEE (SSN, F_name, L_name, Gender, DB, D_no, Super_id) VALUES
('222222222', 'Laila',  'Hamad',  'F', '1980-09-21', 2, '111111111'),
('333333333', 'Yousef', 'Karim',  'M', '1985-02-14', 3, '111111111');

INSERT INTO EMPLOYEE (SSN, F_name, L_name, Gender, DB, D_no, Super_id) VALUES
('444444444', 'Sara',   'Ahmed',  'F', '1990-06-30', 3, '333333333'),
('555555555', 'Khalid', 'Salim',  'M', '1992-12-05', 3, '333333333'),
('666666666', 'Mona',   'Hassan', 'F', '1988-03-18', 2, '222222222');

-- manage (1:1)
UPDATE DEPARTMENT SET manager_id = '111111111', hire_date = '2015-01-01' WHERE D_no = 1;
UPDATE DEPARTMENT SET manager_id = '222222222', hire_date = '2018-05-15' WHERE D_no = 2;
UPDATE DEPARTMENT SET manager_id = '333333333', hire_date = '2019-09-01' WHERE D_no = 3;

INSERT INTO Department_location (D_no, location) VALUES
(1, 'North City'),
(2, 'East City'),
(3, 'East City'),
(3, 'South City');

INSERT INTO PROJECT (P_no, Pname, City, location, D_no) VALUES
(1, 'ProductX',        'East City',  'Lab 1',   3),
(2, 'ProductY',        'South City', 'Lab 2',   3),
(3, 'Computerization', 'North City', 'Floor 5', 1),
(4, 'Reorganization',  'East City',  'Floor 2', 2);

INSERT INTO Employee_work (SSN, P_no, working_hours) VALUES
('333333333', 1, 20.5),
('444444444', 1, 32.5),
('444444444', 2,  7.5),
('555555555', 2, 40.0),
('111111111', 3, 10.0),
('222222222', 4, 15.0),
('666666666', 4, 25.0);

INSERT INTO DEPENDENT (SSN, D_name, Gender, DB) VALUES
('333333333', 'Alice',   'F', '2010-04-05'),
('333333333', 'Theo',    'M', '2012-10-25'),
('222222222', 'Michael', 'M', '2014-01-04'),
('444444444', 'Nora',    'F', '2018-05-03');
GO


/* =====================================================================
   PART 5 : QUERIES
   ===================================================================== */

-- Q1. Show every table
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Q2. Structure of two tables
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EMPLOYEE'
ORDER BY ORDINAL_POSITION;

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DEPARTMENT'
ORDER BY ORDINAL_POSITION;

-- Q3. All rows of each table
SELECT * FROM EMPLOYEE;
SELECT * FROM DEPARTMENT;
SELECT * FROM Department_location;
SELECT * FROM PROJECT;
SELECT * FROM Employee_work;
SELECT * FROM DEPENDENT;

-- Q4. Each employee with department and supervisor (work 1:M + supervise)
SELECT e.SSN,
       CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       d.Dname                         AS Department,
       CONCAT(s.F_name, ' ', s.L_name) AS Supervisor
FROM EMPLOYEE e
LEFT JOIN DEPARTMENT d ON e.D_no     = d.D_no
LEFT JOIN EMPLOYEE   s ON e.Super_id = s.SSN
ORDER BY e.SSN;

-- Q5. Each department with its manager and hire date (manage 1:1)
SELECT d.D_no, d.Dname,
       CONCAT(m.F_name, ' ', m.L_name) AS Manager,
       d.hire_date
FROM DEPARTMENT d
LEFT JOIN EMPLOYEE m ON d.manager_id = m.SSN
ORDER BY d.D_no;

-- Q6. Department locations (multivalued attribute)
SELECT d.Dname, dl.location
FROM DEPARTMENT d
JOIN Department_location dl ON d.D_no = dl.D_no
ORDER BY d.Dname, dl.location;

-- Q7. Projects with their controlling department (have 1:M)
SELECT p.P_no, p.Pname, p.City, p.location, d.Dname AS Department
FROM PROJECT p
JOIN DEPARTMENT d ON p.D_no = d.D_no
ORDER BY p.P_no;

-- Q8. Who works on which project and for how many hours (work M:M)
SELECT CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       p.Pname                         AS Project,
       ew.working_hours
FROM Employee_work ew
JOIN EMPLOYEE e ON ew.SSN  = e.SSN
JOIN PROJECT  p ON ew.P_no = p.P_no
ORDER BY Employee, Project;

-- Q9. Total working hours per employee
SELECT CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       ISNULL(SUM(ew.working_hours), 0) AS Total_hours
FROM EMPLOYEE e
LEFT JOIN Employee_work ew ON e.SSN = ew.SSN
GROUP BY e.SSN, e.F_name, e.L_name
ORDER BY Total_hours DESC, Employee;

-- Q10. Total working hours per project
SELECT p.Pname, ISNULL(SUM(ew.working_hours), 0) AS Total_hours
FROM PROJECT p
LEFT JOIN Employee_work ew ON p.P_no = ew.P_no
GROUP BY p.P_no, p.Pname
ORDER BY Total_hours DESC;

-- Q11. Employees with their dependents (have 1:M)
SELECT CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       dp.D_name AS Dependent, dp.Gender, dp.DB AS Dependent_birth_date
FROM EMPLOYEE e
JOIN DEPENDENT dp ON e.SSN = dp.SSN
ORDER BY Employee, Dependent;

-- Q12. Employees who have NO dependents
SELECT e.SSN, CONCAT(e.F_name, ' ', e.L_name) AS Employee
FROM EMPLOYEE e
WHERE NOT EXISTS (SELECT 1 FROM DEPENDENT dp WHERE dp.SSN = e.SSN);

-- Q13. Number of employees in each department
SELECT d.Dname AS Department, COUNT(e.SSN) AS Employees
FROM DEPARTMENT d
LEFT JOIN EMPLOYEE e ON e.D_no = d.D_no
GROUP BY d.D_no, d.Dname
ORDER BY Employees DESC, d.Dname;

-- Q14. Supervisors and how many employees report to each one
SELECT CONCAT(s.F_name, ' ', s.L_name) AS Supervisor,
       COUNT(e.SSN)                    AS Subordinates
FROM EMPLOYEE s
JOIN EMPLOYEE e ON e.Super_id = s.SSN
GROUP BY s.SSN, s.F_name, s.L_name
ORDER BY Subordinates DESC, Supervisor;

-- Q15. Employees who work on more than one project
SELECT CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       COUNT(ew.P_no)                  AS Projects
FROM EMPLOYEE e
JOIN Employee_work ew ON e.SSN = ew.SSN
GROUP BY e.SSN, e.F_name, e.L_name
HAVING COUNT(ew.P_no) > 1;

-- Q16. Employees of the 'Research' department who work more than 30 hours in total
SELECT CONCAT(e.F_name, ' ', e.L_name) AS Employee,
       SUM(ew.working_hours)           AS Total_hours
FROM EMPLOYEE e
JOIN DEPARTMENT d      ON e.D_no = d.D_no
JOIN Employee_work ew  ON e.SSN  = ew.SSN
WHERE d.Dname = 'Research'
GROUP BY e.SSN, e.F_name, e.L_name
HAVING SUM(ew.working_hours) > 30;

-- Q17. Employee age (exact age from the birth date DB)
SELECT SSN,
       CONCAT(F_name, ' ', L_name) AS Employee,
       DB,
       DATEDIFF(YEAR, DB, GETDATE())
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DB, GETDATE()), DB) > CAST(GETDATE() AS DATE)
                THEN 1 ELSE 0 END AS Age
FROM EMPLOYEE
ORDER BY SSN;

-- Q18. Example UPDATE and DELETE
UPDATE Employee_work SET working_hours = working_hours + 5
WHERE SSN = '333333333' AND P_no = 1;

DELETE FROM DEPENDENT WHERE SSN = '444444444' AND D_name = 'Nora';

-- Q19. Check the changes
SELECT * FROM Employee_work WHERE SSN = '333333333';
SELECT * FROM DEPENDENT ORDER BY SSN, D_name;
