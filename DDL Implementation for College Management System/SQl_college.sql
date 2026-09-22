-- COLLEGE DATABASE
-- Table creation script (SQL Server)

IF DB_ID('university_db') IS NULL
    CREATE DATABASE university_db;


USE university_db;




-- FACULTY
CREATE TABLE FACULTY (
    F_id       INT           NOT NULL,
    Mobile_no  VARCHAR(20),
    Name       VARCHAR(100)  NOT NULL,
    Salary     DECIMAL(10,2),
    CONSTRAINT pk_faculty PRIMARY KEY (F_id)
);


-- DEPARTMENT
CREATE TABLE DEPARTMENT (
    Department_id INT          NOT NULL,
    D_name        VARCHAR(100) NOT NULL,
    CONSTRAINT pk_department PRIMARY KEY (Department_id)
);


-- HOSTEL
CREATE TABLE HOSTEL (
    Hostel_id    INT          NOT NULL,
    Hostel_name  VARCHAR(100) NOT NULL,
    City         VARCHAR(50),
    State        VARCHAR(50),
    Pin_code     VARCHAR(10),
    CONSTRAINT pk_hostel PRIMARY KEY (Hostel_id)
);


-- Faculty_department (multivalued attribute)
CREATE TABLE Faculty_department (
    F_id        INT          NOT NULL,
    Department  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_faculty_department PRIMARY KEY (F_id, Department),
    CONSTRAINT fk_fd_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id) ON DELETE CASCADE
);


-- Hostel_No_of_seats (multivalued attribute)
CREATE TABLE Hostel_No_of_seats (
    Hostel_id    INT NOT NULL,
    No_of_seats  INT NOT NULL,
    CONSTRAINT pk_hostel_seats PRIMARY KEY (Hostel_id, No_of_seats),
    CONSTRAINT fk_hs_hostel FOREIGN KEY (Hostel_id)
        REFERENCES HOSTEL (Hostel_id) ON DELETE CASCADE
);


-- SUBJECT
CREATE TABLE SUBJECT (
    Subject_id    INT          NOT NULL,
    Subject_name  VARCHAR(100) NOT NULL,
    F_id          INT,
    CONSTRAINT pk_subject PRIMARY KEY (Subject_id),
    CONSTRAINT fk_subject_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id)
);


-- STUDENT
CREATE TABLE STUDENT (
    S_id           INT          NOT NULL,
    F_Name         VARCHAR(50)  NOT NULL,
    L_Name         VARCHAR(50)  NOT NULL,
    Phone_no       VARCHAR(20),
    DOB            DATE,
    F_id           INT,
    Department_id  INT,
    Hostel_id      INT,
    CONSTRAINT pk_student PRIMARY KEY (S_id),
    CONSTRAINT fk_student_faculty FOREIGN KEY (F_id)
        REFERENCES FACULTY (F_id),
    CONSTRAINT fk_student_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id),
    CONSTRAINT fk_student_hostel FOREIGN KEY (Hostel_id)
        REFERENCES HOSTEL (Hostel_id)
);


-- COURSE
CREATE TABLE COURSE (
    Course_id    INT          NOT NULL,
    Course_name  VARCHAR(100) NOT NULL,
    Duration     VARCHAR(30),
    S_id         INT,
    CONSTRAINT pk_course PRIMARY KEY (Course_id),
    CONSTRAINT fk_course_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id)
);


-- EXAMS
CREATE TABLE EXAMS (
    Exam_code  INT NOT NULL,
    [Date]     DATE,
    [Time]     TIME,
    Room       VARCHAR(20),
    S_id       INT,
    CONSTRAINT pk_exams PRIMARY KEY (Exam_code),
    CONSTRAINT fk_exams_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id)
);


-- Student_takes (M:M)
CREATE TABLE Student_takes (
    S_id        INT NOT NULL,
    Subject_id  INT NOT NULL,
    CONSTRAINT pk_student_takes PRIMARY KEY (S_id, Subject_id),
    CONSTRAINT fk_st_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id) ON DELETE CASCADE,
    CONSTRAINT fk_st_subject FOREIGN KEY (Subject_id)
        REFERENCES SUBJECT (Subject_id) ON DELETE CASCADE
);


-- Student_have_multiple (M:M)
CREATE TABLE Student_have_multiple (
    S_id       INT NOT NULL,
    Course_id  INT NOT NULL,
    CONSTRAINT pk_student_have_multiple PRIMARY KEY (S_id, Course_id),
    CONSTRAINT fk_shm_student FOREIGN KEY (S_id)
        REFERENCES STUDENT (S_id) ON DELETE CASCADE,
    CONSTRAINT fk_shm_course FOREIGN KEY (Course_id)
        REFERENCES COURSE (Course_id) ON DELETE CASCADE
);


-- Course_handled_by (M:M)
CREATE TABLE Course_handled_by (
    Course_id      INT NOT NULL,
    Department_id  INT NOT NULL,
    CONSTRAINT pk_course_handled_by PRIMARY KEY (Course_id, Department_id),
    CONSTRAINT fk_chb_course FOREIGN KEY (Course_id)
        REFERENCES COURSE (Course_id) ON DELETE CASCADE,
    CONSTRAINT fk_chb_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id) ON DELETE CASCADE
);


-- Department_conducted (M:M)
CREATE TABLE Department_conducted (
    Department_id  INT NOT NULL,
    Exam_code      INT NOT NULL,
    CONSTRAINT pk_department_conducted PRIMARY KEY (Department_id, Exam_code),
    CONSTRAINT fk_dc_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id) ON DELETE CASCADE,
    CONSTRAINT fk_dc_exams FOREIGN KEY (Exam_code)
        REFERENCES EXAMS (Exam_code) ON DELETE CASCADE
);

