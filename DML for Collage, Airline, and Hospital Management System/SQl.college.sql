/* =====================================================================
   ERD MAPPING  ->  SQL IMPLEMENTATION
   Source ERD : Task1.drawio  (STUDENT, FACULTY, COURSE, SUBJECT,
                               EXAMS, HOSTEL, DEPARTMENT)
   Dialect    : Microsoft SQL Server (T-SQL)  (SSMS / Azure Data Studio)
   How to run : SSMS -> File > Open > File... -> pick this file ->
                make sure NOTHING is selected -> press Execute (F5).
                (GO lines split the script into batches; SSMS understands them.)

   File layout
     PART 1  Create the database
     PART 2  Drop old tables (so the script can be re-run safely)
     PART 3  Create the 13 tables (parents first, children after)
     PART 4  Insert sample data
     PART 5  Queries (SELECT) to test the design
   ===================================================================== */


/* =====================================================================
   PART 1 : DATABASE
   ===================================================================== */
IF DB_ID('university_db') IS NULL
    CREATE DATABASE university_db;
GO

USE university_db;
GO


/* =====================================================================
   PART 2 : DROP OLD TABLES  (children first, parents last)
   ===================================================================== */
IF OBJECT_ID('dbo.Student_Age', 'V') IS NOT NULL DROP VIEW dbo.Student_Age;

IF OBJECT_ID('dbo.Department_conducted', 'U') IS NOT NULL DROP TABLE dbo.Department_conducted;
IF OBJECT_ID('dbo.Course_handled_by', 'U') IS NOT NULL DROP TABLE dbo.Course_handled_by;
IF OBJECT_ID('dbo.Student_have_multiple', 'U') IS NOT NULL DROP TABLE dbo.Student_have_multiple;
IF OBJECT_ID('dbo.Student_takes', 'U') IS NOT NULL DROP TABLE dbo.Student_takes;
IF OBJECT_ID('dbo.EXAMS', 'U') IS NOT NULL DROP TABLE dbo.EXAMS;
IF OBJECT_ID('dbo.COURSE', 'U') IS NOT NULL DROP TABLE dbo.COURSE;
IF OBJECT_ID('dbo.STUDENT', 'U') IS NOT NULL DROP TABLE dbo.STUDENT;
IF OBJECT_ID('dbo.SUBJECT', 'U') IS NOT NULL DROP TABLE dbo.SUBJECT;
IF OBJECT_ID('dbo.Hostel_No_of_seats', 'U') IS NOT NULL DROP TABLE dbo.Hostel_No_of_seats;
IF OBJECT_ID('dbo.Faculty_department', 'U') IS NOT NULL DROP TABLE dbo.Faculty_department;
IF OBJECT_ID('dbo.HOSTEL', 'U') IS NOT NULL DROP TABLE dbo.HOSTEL;
IF OBJECT_ID('dbo.DEPARTMENT', 'U') IS NOT NULL DROP TABLE dbo.DEPARTMENT;
IF OBJECT_ID('dbo.FACULTY', 'U') IS NOT NULL DROP TABLE dbo.FACULTY;
GO


/* =====================================================================
   PART 3 : CREATE TABLES
   SQL Server note: plain foreign keys use the default (NO ACTION) because
   SQL Server refuses SET NULL / CASCADE chains that reach the same table by
   more than one path (error 1785). ON DELETE CASCADE is used only on the
   multivalued tables and the M:M tables, where it is safe.

   Rules used (same as the example):
     - Entity                    -> its own table
     - 1:M                       -> PK of the "one" side becomes FK in the "many" side
     - 1:1                       -> PK of the lower side is put into the bigger table
     - M:M                       -> new table, the 2 FKs form a composite PK
     - Multivalued attribute     -> new table, (owner FK + value) = composite PK
     - Composite attribute       -> split into columns (Name, Address)
     - Derived attribute (Age)   -> not stored (see the view Student_Age)
   ===================================================================== */

/* ---------- Independent tables (no foreign keys) ---------- */

CREATE TABLE FACULTY (
    F_id       INT           NOT NULL,
    Mobile_no  VARCHAR(20),
    Name       VARCHAR(100)  NOT NULL,
    Salary     DECIMAL(10,2),
    CONSTRAINT pk_faculty PRIMARY KEY (F_id)
);

CREATE TABLE DEPARTMENT (
    Department_id INT          NOT NULL,
    D_name        VARCHAR(100) NOT NULL,
    CONSTRAINT pk_department PRIMARY KEY (Department_id)
);

CREATE TABLE HOSTEL (
    Hostel_id    INT          NOT NULL,
    Hostel_name  VARCHAR(100) NOT NULL,
    City         VARCHAR(50),               -- part of composite attribute Address
    State        VARCHAR(50),               -- part of composite attribute Address
    Pin_code     VARCHAR(10),
    CONSTRAINT pk_hostel PRIMARY KEY (Hostel_id)
);

/* ---------- Multivalued attributes (double oval) -> new tables ---------- */

CREATE TABLE Faculty_department (
    F_id        INT          NOT NULL,      -- FK -> FACULTY
    Department  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_faculty_department PRIMARY KEY (F_id, Department),
    CONSTRAINT fk_fd_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id) ON DELETE CASCADE
);

CREATE TABLE Hostel_No_of_seats (
    Hostel_id    INT NOT NULL,              -- FK -> HOSTEL
    No_of_seats  INT NOT NULL,
    CONSTRAINT pk_hostel_seats PRIMARY KEY (Hostel_id, No_of_seats),
    CONSTRAINT fk_hs_hostel FOREIGN KEY (Hostel_id)
        REFERENCES HOSTEL (Hostel_id) ON DELETE CASCADE
);

/* ---------- Entities that receive foreign keys ---------- */

-- Handles (FACULTY 1 : M SUBJECT)  -> F_id goes into SUBJECT
CREATE TABLE SUBJECT (
    Subject_id    INT          NOT NULL,
    Subject_name  VARCHAR(100) NOT NULL,
    F_id          INT,                      -- FK -> FACULTY
    CONSTRAINT pk_subject PRIMARY KEY (Subject_id),
    CONSTRAINT fk_subject_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id)
);

-- Teaches       (FACULTY    1 : M STUDENT)  -> F_id          goes into STUDENT
-- Belong to     (STUDENT    1 : 1 DEPARTMENT) -> Department_id goes into STUDENT
-- Can leave in  (STUDENT    1 : 1 HOSTEL)     -> Hostel_id     goes into STUDENT
-- (Name is a composite attribute -> F_Name + L_Name ; Age is derived -> not stored)
CREATE TABLE STUDENT (
    S_id           INT          NOT NULL,
    F_Name         VARCHAR(50)  NOT NULL,
    L_Name         VARCHAR(50)  NOT NULL,
    Phone_no       VARCHAR(20),
    DOB            DATE,
    F_id           INT,                     -- FK -> FACULTY
    Department_id  INT,                     -- FK -> DEPARTMENT
    Hostel_id      INT,                     -- FK -> HOSTEL
    CONSTRAINT pk_student PRIMARY KEY (S_id),
    CONSTRAINT fk_student_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id),
    CONSTRAINT fk_student_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id),
    CONSTRAINT fk_student_hostel FOREIGN KEY (Hostel_id)
        REFERENCES HOSTEL (Hostel_id)
    /* The ERD draws "Belong to" and "Can leave in" as 1:1.
       To enforce a strict 1:1 in the database, remove the comment marks
       around the two lines below (a department/hostel can then have only
       ONE student, so it is normally left off):
    , CONSTRAINT uq_student_department UNIQUE (Department_id)
    , CONSTRAINT uq_student_hostel     UNIQUE (Hostel_id)
    */
);

-- enrolls (STUDENT 1 : M COURSE)  -> S_id goes into COURSE
CREATE TABLE COURSE (
    Course_id    INT          NOT NULL,
    Course_name  VARCHAR(100) NOT NULL,
    Duration     VARCHAR(30),
    S_id         INT,                       -- FK -> STUDENT
    CONSTRAINT pk_course PRIMARY KEY (Course_id),
    CONSTRAINT fk_course_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id)
);

-- Can take (STUDENT 1 : M EXAMS)  -> S_id goes into EXAMS
CREATE TABLE EXAMS (
    Exam_code  INT NOT NULL,
    [Date]     DATE,
    [Time]     TIME,
    Room       VARCHAR(20),
    S_id       INT,                         -- FK -> STUDENT
    CONSTRAINT pk_exams PRIMARY KEY (Exam_code),
    CONSTRAINT fk_exams_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id)
);

/* ---------- M:M relationships -> new tables (2 FK = composite PK) ---------- */

-- Takes (STUDENT M : M SUBJECT)
CREATE TABLE Student_takes (
    S_id        INT NOT NULL,               -- FK -> STUDENT
    Subject_id  INT NOT NULL,               -- FK -> SUBJECT
    CONSTRAINT pk_student_takes PRIMARY KEY (S_id, Subject_id),
    CONSTRAINT fk_st_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id) ON DELETE CASCADE,
    CONSTRAINT fk_st_subject FOREIGN KEY (Subject_id)
        REFERENCES SUBJECT (Subject_id) ON DELETE CASCADE
);

-- Have multiple (STUDENT M : M COURSE)
CREATE TABLE Student_have_multiple (
    S_id       INT NOT NULL,                -- FK -> STUDENT
    Course_id  INT NOT NULL,                -- FK -> COURSE
    CONSTRAINT pk_student_have_multiple PRIMARY KEY (S_id, Course_id),
    CONSTRAINT fk_shm_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id) ON DELETE CASCADE,
    CONSTRAINT fk_shm_course FOREIGN KEY (Course_id)
        REFERENCES COURSE (Course_id) ON DELETE CASCADE
);

-- Handled by (DEPARTMENT M : M COURSE)
CREATE TABLE Course_handled_by (
    Course_id      INT NOT NULL,            -- FK -> COURSE
    Department_id  INT NOT NULL,            -- FK -> DEPARTMENT
    CONSTRAINT pk_course_handled_by PRIMARY KEY (Course_id, Department_id),
    CONSTRAINT fk_chb_course FOREIGN KEY (Course_id)
        REFERENCES COURSE (Course_id) ON DELETE CASCADE,
    CONSTRAINT fk_chb_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id) ON DELETE CASCADE
);

-- Conducted (DEPARTMENT M : M EXAMS)
CREATE TABLE Department_conducted (
    Department_id  INT NOT NULL,            -- FK -> DEPARTMENT
    Exam_code      INT NOT NULL,            -- FK -> EXAMS
    CONSTRAINT pk_department_conducted PRIMARY KEY (Department_id, Exam_code),
    CONSTRAINT fk_dc_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id) ON DELETE CASCADE,
    CONSTRAINT fk_dc_exams FOREIGN KEY (Exam_code)
        REFERENCES EXAMS (Exam_code) ON DELETE CASCADE
);

GO

/* ---------- Derived attribute Age : calculated, never stored ----------
   (CREATE VIEW must be the first statement in its batch, hence the GO lines) */
CREATE VIEW Student_Age AS
SELECT S_id,
       CONCAT(F_Name, ' ', L_Name) AS Full_name,
       DOB,
       DATEDIFF(YEAR, DOB, GETDATE())
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DOB, GETDATE()), DOB) > CAST(GETDATE() AS DATE)
                THEN 1 ELSE 0 END      AS Age
FROM STUDENT;
GO


/* =====================================================================
   PART 4 : SAMPLE DATA  (parents first, then children)
   ===================================================================== */

INSERT INTO FACULTY (F_id, Mobile_no, Name, Salary) VALUES
(1, '5550101', 'Dr. Ahmed Nasser',  1500.00),
(2, '5550102', 'Dr. Laila Hamad',   1650.00),
(3, '5550103', 'Dr. Yousef Karim',  1400.00);

INSERT INTO DEPARTMENT (Department_id, D_name) VALUES
(1, 'Computer Science'),
(2, 'Business'),
(3, 'Engineering');

INSERT INTO HOSTEL (Hostel_id, Hostel_name, City, State, Pin_code) VALUES
(1, 'Green Hostel', 'Springfield', 'State A', '10001'),
(2, 'Blue Hostel',  'Riverside',   'State B', '20002');

INSERT INTO Faculty_department (F_id, Department) VALUES
(1, 'Computer Science'),
(1, 'Engineering'),
(2, 'Business'),
(3, 'Engineering');

INSERT INTO Hostel_No_of_seats (Hostel_id, No_of_seats) VALUES
(1, 200),
(1, 250),
(2, 150);

INSERT INTO SUBJECT (Subject_id, Subject_name, F_id) VALUES
(1, 'Databases',   1),
(2, 'Programming', 1),
(3, 'Accounting',  2),
(4, 'Mathematics', 3);

INSERT INTO STUDENT (S_id, F_Name, L_Name, Phone_no, DOB, F_id, Department_id, Hostel_id) VALUES
(1, 'Ali',  'Khan',   '5551001', '2004-03-12', 1, 1, 1),
(2, 'Sara', 'Ahmed',  '5551002', '2003-07-25', 1, 1, 2),
(3, 'Omar', 'Salim',  '5551003', '2005-01-09', 2, 2, NULL),
(4, 'Mona', 'Hassan', '5551004', '2004-11-30', 3, 3, 1);

INSERT INTO COURSE (Course_id, Course_name, Duration, S_id) VALUES
(1, 'BSc Computer Science', '4 years', 1),
(2, 'BBA Business',         '3 years', 3),
(3, 'BEng Engineering',     '4 years', 4);

INSERT INTO EXAMS (Exam_code, [Date], [Time], Room, S_id) VALUES
(1, '2026-12-10', '09:00:00', 'A101', 1),
(2, '2026-12-12', '13:30:00', 'B202', 2),
(3, '2026-12-15', '10:00:00', 'C303', 3);

INSERT INTO Student_takes (S_id, Subject_id) VALUES
(1, 1), (1, 2), (2, 1), (3, 3), (4, 4);

INSERT INTO Student_have_multiple (S_id, Course_id) VALUES
(1, 1), (1, 2), (2, 1), (3, 2), (4, 3);

INSERT INTO Course_handled_by (Course_id, Department_id) VALUES
(1, 1), (2, 2), (3, 3), (3, 1);

INSERT INTO Department_conducted (Department_id, Exam_code) VALUES
(1, 1), (2, 2), (3, 3), (1, 3);


/* =====================================================================
   PART 5 : QUERIES
   ===================================================================== */
GO

-- Q1. Show every table
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Q2. Structure of the main tables
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'STUDENT'
ORDER BY ORDINAL_POSITION;

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EXAMS'
ORDER BY ORDINAL_POSITION;

-- Q3. All rows of each entity table
SELECT * FROM STUDENT;
SELECT * FROM FACULTY;
SELECT * FROM DEPARTMENT;
SELECT * FROM HOSTEL;
SELECT * FROM SUBJECT;
SELECT * FROM COURSE;
SELECT * FROM EXAMS;

-- Q4. Student full name + department + hostel + faculty (Belong to / Can leave in / Teaches)
SELECT s.S_id,
       CONCAT(s.F_Name, ' ', s.L_Name) AS Student,
       d.D_name                        AS Department,
       h.Hostel_name                   AS Hostel,
       f.Name                          AS Faculty
FROM STUDENT s
LEFT JOIN DEPARTMENT d ON s.Department_id = d.Department_id
LEFT JOIN HOSTEL     h ON s.Hostel_id     = h.Hostel_id
LEFT JOIN FACULTY    f ON s.F_id          = f.F_id
ORDER BY s.S_id;

-- Q5. Derived attribute Age (calculated from DOB)
SELECT * FROM Student_Age;

-- Q6. Subjects taken by each student (Takes, M:M)
SELECT CONCAT(s.F_Name, ' ', s.L_Name) AS Student,
       sb.Subject_name                 AS Subject
FROM Student_takes st
JOIN STUDENT s  ON st.S_id       = s.S_id
JOIN SUBJECT sb ON st.Subject_id = sb.Subject_id
ORDER BY Student, Subject;

-- Q7. Courses each student has (Have multiple, M:M)
SELECT CONCAT(s.F_Name, ' ', s.L_Name) AS Student,
       c.Course_name                   AS Course
FROM Student_have_multiple shm
JOIN STUDENT s ON shm.S_id      = s.S_id
JOIN COURSE  c ON shm.Course_id = c.Course_id
ORDER BY Student, Course;

-- Q8. Which departments handle which courses (Handled by, M:M)
SELECT c.Course_name, d.D_name AS Department
FROM Course_handled_by chb
JOIN COURSE     c ON chb.Course_id     = c.Course_id
JOIN DEPARTMENT d ON chb.Department_id = d.Department_id
ORDER BY c.Course_name;

-- Q9. Exams with the student who takes them (Can take, 1:M)
SELECT e.Exam_code, e.[Date], e.[Time], e.Room,
       CONCAT(s.F_Name, ' ', s.L_Name) AS Student
FROM EXAMS e
LEFT JOIN STUDENT s ON e.S_id = s.S_id
ORDER BY e.[Date];

-- Q10. Which departments conducted which exams (Conducted, M:M)
SELECT d.D_name AS Department, e.Exam_code, e.[Date], e.Room
FROM Department_conducted dc
JOIN DEPARTMENT d ON dc.Department_id = d.Department_id
JOIN EXAMS      e ON dc.Exam_code     = e.Exam_code
ORDER BY d.D_name, e.Exam_code;

-- Q11. Faculty members with the subjects they handle (Handles, 1:M)
SELECT f.Name AS Faculty, sb.Subject_name AS Subject
FROM FACULTY f
LEFT JOIN SUBJECT sb ON sb.F_id = f.F_id
ORDER BY f.Name, sb.Subject_name;

-- Q12. Faculty members with all their departments (multivalued attribute)
SELECT f.Name AS Faculty, fd.Department
FROM FACULTY f
JOIN Faculty_department fd ON f.F_id = fd.F_id
ORDER BY f.Name, fd.Department;

-- Q13. Hostels with their seat numbers (multivalued attribute)
SELECT h.Hostel_name, h.City, h.State, h.Pin_code, hs.No_of_seats
FROM HOSTEL h
LEFT JOIN Hostel_No_of_seats hs ON h.Hostel_id = hs.Hostel_id
ORDER BY h.Hostel_name, hs.No_of_seats;

-- Q14. Number of students in each department
SELECT d.D_name AS Department, COUNT(s.S_id) AS Students
FROM DEPARTMENT d
LEFT JOIN STUDENT s ON s.Department_id = d.Department_id
GROUP BY d.Department_id, d.D_name
ORDER BY Students DESC, d.D_name;

-- Q15. Number of subjects each student takes
SELECT CONCAT(s.F_Name, ' ', s.L_Name) AS Student,
       COUNT(st.Subject_id)            AS Subjects_taken
FROM STUDENT s
LEFT JOIN Student_takes st ON st.S_id = s.S_id
GROUP BY s.S_id, s.F_Name, s.L_Name
ORDER BY Subjects_taken DESC, Student;

-- Q16. Students who do NOT live in any hostel
SELECT S_id, CONCAT(F_Name, ' ', L_Name) AS Student
FROM STUDENT
WHERE Hostel_id IS NULL;

-- Q17. Example UPDATE and DELETE
UPDATE FACULTY SET Salary = Salary + 100 WHERE F_id = 1;
DELETE FROM Student_takes WHERE S_id = 4 AND Subject_id = 4;

-- Q18. Check the update
SELECT F_id, Name, Salary FROM FACULTY WHERE F_id = 1;
