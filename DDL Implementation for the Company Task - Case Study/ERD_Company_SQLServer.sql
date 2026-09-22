
CREATE DATABASE company_db;


USE company_db;

-- EMPLOYEE
CREATE TABLE EMPLOYEE (
    SSN       CHAR(9)      NOT NULL,
    F_name    VARCHAR(50)  NOT NULL,
    L_name    VARCHAR(50)  NOT NULL,
    Gender    CHAR(1),
    DB        DATE,
    D_no      INT,
    Super_id  CHAR(9),
    CONSTRAINT pk_employee PRIMARY KEY (SSN),
    CONSTRAINT ck_employee_gender CHECK (Gender IN ('M', 'F')),
    CONSTRAINT fk_employee_supervisor FOREIGN KEY (Super_id)
        REFERENCES EMPLOYEE (SSN)
);


-- DEPARTMENT
CREATE TABLE DEPARTMENT (
    D_no        INT          NOT NULL,
    manager_id  CHAR(9),
    Dname       VARCHAR(100) NOT NULL,
    hire_date   DATE,
    CONSTRAINT pk_department PRIMARY KEY (D_no),
    CONSTRAINT fk_department_manager FOREIGN KEY (manager_id)
        REFERENCES EMPLOYEE (SSN)
);


-- a manager can only manage one department
CREATE UNIQUE INDEX uq_department_manager
    ON DEPARTMENT (manager_id)
    WHERE manager_id IS NOT NULL;


-- link EMPLOYEE to DEPARTMENT (added after DEPARTMENT is created)
ALTER TABLE EMPLOYEE
    ADD CONSTRAINT fk_employee_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no);


-- Department_location
CREATE TABLE Department_location (
    D_no      INT          NOT NULL,
    location  VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_department_location PRIMARY KEY (D_no, location),
    CONSTRAINT fk_deptloc_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no) ON DELETE CASCADE
);


-- PROJECT
CREATE TABLE PROJECT (
    P_no      INT          NOT NULL,
    Pname     VARCHAR(100) NOT NULL,
    City      VARCHAR(50),
    location  VARCHAR(50),
    D_no      INT          NOT NULL,
    CONSTRAINT pk_project PRIMARY KEY (P_no),
    CONSTRAINT fk_project_department FOREIGN KEY (D_no)
        REFERENCES DEPARTMENT (D_no)
);


-- Employee_work
CREATE TABLE Employee_work (
    SSN            CHAR(9)      NOT NULL,
    P_no           INT          NOT NULL,
    working_hours  DECIMAL(4,1),
    CONSTRAINT pk_employee_work PRIMARY KEY (SSN, P_no),
    CONSTRAINT fk_ew_employee FOREIGN KEY (SSN)
        REFERENCES EMPLOYEE (SSN) ON DELETE CASCADE,
    CONSTRAINT fk_ew_project FOREIGN KEY (P_no)
        REFERENCES PROJECT (P_no) ON DELETE CASCADE,
    CONSTRAINT ck_ew_hours CHECK (working_hours >= 0)
);


-- DEPENDENT
CREATE TABLE DEPENDENT (
    SSN     CHAR(9)      NOT NULL,
    D_name  VARCHAR(50)  NOT NULL,
    Gender  CHAR(1),
    DB      DATE,
    CONSTRAINT pk_dependent PRIMARY KEY (SSN, D_name),
    CONSTRAINT fk_dependent_employee FOREIGN KEY (SSN)
        REFERENCES EMPLOYEE (SSN) ON DELETE CASCADE,
    CONSTRAINT ck_dependent_gender CHECK (Gender IN ('M', 'F'))
);

