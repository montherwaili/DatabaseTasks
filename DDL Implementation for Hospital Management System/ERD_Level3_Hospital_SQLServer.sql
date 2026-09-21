/* =====================================================================
   HOSPITAL MANAGEMENT SYSTEM  -  SQL IMPLEMENTATION (SQL Server / T-SQL)
   Source : ERD Level 3 (Hospital) and its relational mapping

   Tables (9): DEPARTMENT, DOCTOR, SERVICE, PATIENT, Patient_phone,
               APPOINTMENT, Appointment_includes, MEDICAL_RECORD, BILL
   Views  (2): Patient_Age, Bill_Summary   (derived attributes: never stored)

   How to run : SSMS -> File > Open > File... -> pick this file ->
                make sure NOTHING is selected -> press Execute (F5).
                (GO lines split the script into batches; SSMS understands them.)

   File layout
     PART 1  Create the database
     PART 2  Drop old objects (so the script can be re-run safely)
     PART 3  Create the tables and views
     PART 4  Insert sample data (every table has at least 5 rows)
     PART 5  Queries (SELECT / UPDATE / DELETE)
   ===================================================================== */


/* =====================================================================
   PART 1 : DATABASE
   ===================================================================== */
IF DB_ID('hospital_db') IS NULL
    CREATE DATABASE hospital_db;
GO

USE hospital_db;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


/* =====================================================================
   PART 2 : DROP OLD OBJECTS
   DEPARTMENT and DOCTOR point at each other (Works in / Heads), so the
   foreign key DEPARTMENT.Head_doctor_id -> DOCTOR is dropped first.
   ===================================================================== */
IF OBJECT_ID('dbo.Patient_Age',   'V') IS NOT NULL DROP VIEW dbo.Patient_Age;
IF OBJECT_ID('dbo.Bill_Summary',  'V') IS NOT NULL DROP VIEW dbo.Bill_Summary;

IF OBJECT_ID('dbo.DEPARTMENT', 'U') IS NOT NULL
   AND OBJECT_ID('dbo.fk_department_head', 'F') IS NOT NULL
    ALTER TABLE dbo.DEPARTMENT DROP CONSTRAINT fk_department_head;

IF OBJECT_ID('dbo.BILL',                 'U') IS NOT NULL DROP TABLE dbo.BILL;
IF OBJECT_ID('dbo.MEDICAL_RECORD',       'U') IS NOT NULL DROP TABLE dbo.MEDICAL_RECORD;
IF OBJECT_ID('dbo.Appointment_includes', 'U') IS NOT NULL DROP TABLE dbo.Appointment_includes;
IF OBJECT_ID('dbo.APPOINTMENT',          'U') IS NOT NULL DROP TABLE dbo.APPOINTMENT;
IF OBJECT_ID('dbo.SERVICE',              'U') IS NOT NULL DROP TABLE dbo.SERVICE;
IF OBJECT_ID('dbo.Patient_phone',        'U') IS NOT NULL DROP TABLE dbo.Patient_phone;
IF OBJECT_ID('dbo.PATIENT',              'U') IS NOT NULL DROP TABLE dbo.PATIENT;
IF OBJECT_ID('dbo.DOCTOR',               'U') IS NOT NULL DROP TABLE dbo.DOCTOR;
IF OBJECT_ID('dbo.DEPARTMENT',           'U') IS NOT NULL DROP TABLE dbo.DEPARTMENT;
GO


/* =====================================================================
   PART 3 : CREATE TABLES
   Rules used (same as the example):
     - 1:1                   -> PK of the lower side goes into the bigger table
     - 1:M                   -> PK of the "one" side becomes FK in the "many" side
     - M:M                   -> new table, the 2 FKs form a composite PK
     - Multivalued attribute -> new table, (owner FK + value) = composite PK
     - Composite attribute   -> split into columns (Name -> F_name, L_name)
     - Derived attribute     -> not stored (Age, Total_amount -> see the views)

   SQL Server note: plain foreign keys use the default (NO ACTION);
   ON DELETE CASCADE is used only on Patient_phone and Appointment_includes,
   where it is safe (no multiple cascade paths).
   ===================================================================== */

/* ---------- PATIENT ----------
   Name is composite -> F_name + L_name ; Age is derived -> view Patient_Age */
CREATE TABLE PATIENT (
    Patient_id   INT           NOT NULL,
    F_name       VARCHAR(50)   NOT NULL,
    L_name       VARCHAR(50)   NOT NULL,
    Gender       CHAR(1),
    DOB          DATE,
    Blood_group  VARCHAR(3),
    Address      VARCHAR(150),
    CONSTRAINT pk_patient PRIMARY KEY (Patient_id),
    CONSTRAINT ck_patient_gender CHECK (Gender IN ('M', 'F')),
    CONSTRAINT ck_patient_blood CHECK (Blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);
GO

/* ---------- Patient_phone : multivalued attribute Phone_no -> new table ---------- */
CREATE TABLE Patient_phone (
    Patient_id  INT          NOT NULL,       -- FK -> PATIENT
    Phone_no    VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_patient_phone PRIMARY KEY (Patient_id, Phone_no),
    CONSTRAINT fk_pp_patient FOREIGN KEY (Patient_id)
        REFERENCES PATIENT (Patient_id) ON DELETE CASCADE
);
GO

/* ---------- DEPARTMENT ----------
   Heads (DOCTOR 1 : 1 DEPARTMENT) -> Head_doctor_id goes into DEPARTMENT.
   The head is mandatory in the design, but the column stays NULL-able in SQL
   because DEPARTMENT and DOCTOR reference each other (a department is
   created first, its head is set after the doctors exist).
   The foreign key is added with ALTER TABLE after DOCTOR exists. */
CREATE TABLE DEPARTMENT (
    Department_id   INT           NOT NULL,
    Dept_name       VARCHAR(100)  NOT NULL,
    Head_doctor_id  INT,                      -- FK -> DOCTOR (added below)
    CONSTRAINT pk_department PRIMARY KEY (Department_id)
);
GO

/* ---------- DOCTOR : Works in (DEPARTMENT 1 : M DOCTOR) ---------- */
CREATE TABLE DOCTOR (
    Doctor_id       INT           NOT NULL,
    F_name          VARCHAR(50)   NOT NULL,
    L_name          VARCHAR(50)   NOT NULL,
    Specialization  VARCHAR(100),
    License_no      VARCHAR(30)   NOT NULL,   -- candidate key
    Phone_no        VARCHAR(20),
    Qualification   VARCHAR(100),
    Department_id   INT           NOT NULL,   -- FK -> DEPARTMENT
    CONSTRAINT pk_doctor PRIMARY KEY (Doctor_id),
    CONSTRAINT uq_doctor_license UNIQUE (License_no),
    CONSTRAINT fk_doctor_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id)
);
GO

/* Close the circle: Heads (1:1) */
ALTER TABLE DEPARTMENT
    ADD CONSTRAINT fk_department_head FOREIGN KEY (Head_doctor_id)
        REFERENCES DOCTOR (Doctor_id);
GO

/* 1:1 rule: one doctor can head at most ONE department.
   (A filtered unique index is used so several departments can still have
   no head yet, because a normal UNIQUE allows only one NULL in SQL Server.) */
CREATE UNIQUE INDEX uq_department_head
    ON DEPARTMENT (Head_doctor_id)
    WHERE Head_doctor_id IS NOT NULL;
GO

/* ---------- SERVICE : Offers (DEPARTMENT 1 : M SERVICE) ---------- */
CREATE TABLE SERVICE (
    Service_id     INT            NOT NULL,
    Service_name   VARCHAR(100)   NOT NULL,
    Service_type   VARCHAR(50),
    Price          DECIMAL(10,2)  NOT NULL,
    Department_id  INT            NOT NULL,   -- FK -> DEPARTMENT
    CONSTRAINT pk_service PRIMARY KEY (Service_id),
    CONSTRAINT fk_service_department FOREIGN KEY (Department_id)
        REFERENCES DEPARTMENT (Department_id),
    CONSTRAINT ck_service_price CHECK (Price >= 0)
);
GO

/* ---------- APPOINTMENT ----------
   Books   (PATIENT 1 : M APPOINTMENT) -> Patient_id
   Handles (DOCTOR  1 : M APPOINTMENT) -> Doctor_id */
CREATE TABLE APPOINTMENT (
    Appointment_id  INT          NOT NULL,
    [Date]          DATE         NOT NULL,
    [Time]          TIME         NOT NULL,
    Status          VARCHAR(20)  NOT NULL,
    Type            VARCHAR(30),
    Patient_id      INT          NOT NULL,    -- FK -> PATIENT
    Doctor_id       INT          NOT NULL,    -- FK -> DOCTOR
    CONSTRAINT pk_appointment PRIMARY KEY (Appointment_id),
    CONSTRAINT fk_appointment_patient FOREIGN KEY (Patient_id)
        REFERENCES PATIENT (Patient_id),
    CONSTRAINT fk_appointment_doctor FOREIGN KEY (Doctor_id)
        REFERENCES DOCTOR (Doctor_id),
    CONSTRAINT ck_appointment_status CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled', 'No-show'))
);
GO

/* ---------- Appointment_includes : Includes (APPOINTMENT M : M SERVICE) ----------
   Quantity is a relationship attribute, so it lives in this table
   (how many times the service was used in that appointment). */
CREATE TABLE Appointment_includes (
    Appointment_id  INT  NOT NULL,            -- FK -> APPOINTMENT
    Service_id      INT  NOT NULL,            -- FK -> SERVICE
    Quantity        INT  NOT NULL DEFAULT 1,
    CONSTRAINT pk_appointment_includes PRIMARY KEY (Appointment_id, Service_id),
    CONSTRAINT fk_ai_appointment FOREIGN KEY (Appointment_id)
        REFERENCES APPOINTMENT (Appointment_id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_service FOREIGN KEY (Service_id)
        REFERENCES SERVICE (Service_id) ON DELETE CASCADE,
    CONSTRAINT ck_ai_quantity CHECK (Quantity > 0)
);
GO

/* ---------- MEDICAL_RECORD ----------
   Has record  (PATIENT     1 : M MEDICAL_RECORD) -> Patient_id
   Creates     (DOCTOR      1 : M MEDICAL_RECORD) -> Doctor_id
   Results in  (APPOINTMENT 1 : 1 MEDICAL_RECORD) -> Appointment_id (UNIQUE) */
CREATE TABLE MEDICAL_RECORD (
    Record_id       INT           NOT NULL,
    Diagnosis       VARCHAR(200),
    Treatment       VARCHAR(200),
    Patient_id      INT           NOT NULL,   -- FK -> PATIENT
    Doctor_id       INT           NOT NULL,   -- FK -> DOCTOR
    Appointment_id  INT           NOT NULL,   -- FK -> APPOINTMENT
    CONSTRAINT pk_medical_record PRIMARY KEY (Record_id),
    CONSTRAINT uq_record_appointment UNIQUE (Appointment_id),
    CONSTRAINT fk_record_patient FOREIGN KEY (Patient_id)
        REFERENCES PATIENT (Patient_id),
    CONSTRAINT fk_record_doctor FOREIGN KEY (Doctor_id)
        REFERENCES DOCTOR (Doctor_id),
    CONSTRAINT fk_record_appointment FOREIGN KEY (Appointment_id)
        REFERENCES APPOINTMENT (Appointment_id)
);
GO

/* ---------- BILL ----------
   Has bill   (PATIENT     1 : M BILL) -> Patient_id
   Generates  (APPOINTMENT 1 : 1 BILL) -> Appointment_id (UNIQUE)
   Total_amount is derived (sum of Quantity x Price) -> view Bill_Summary.
   Amount_paid + Payment_status allow partial payments. */
CREATE TABLE BILL (
    Bill_id         INT            NOT NULL,
    Payment_method  VARCHAR(20),
    Payment_status  VARCHAR(20)    NOT NULL,
    Amount_paid     DECIMAL(10,2)  NOT NULL DEFAULT 0,
    Patient_id      INT            NOT NULL,   -- FK -> PATIENT
    Appointment_id  INT            NOT NULL,   -- FK -> APPOINTMENT
    CONSTRAINT pk_bill PRIMARY KEY (Bill_id),
    CONSTRAINT uq_bill_appointment UNIQUE (Appointment_id),
    CONSTRAINT fk_bill_patient FOREIGN KEY (Patient_id)
        REFERENCES PATIENT (Patient_id),
    CONSTRAINT fk_bill_appointment FOREIGN KEY (Appointment_id)
        REFERENCES APPOINTMENT (Appointment_id),
    CONSTRAINT ck_bill_amount CHECK (Amount_paid >= 0),
    CONSTRAINT ck_bill_status CHECK (Payment_status IN ('Unpaid', 'Partial', 'Paid'))
);
GO

/* ---------- Derived attribute Age : calculated, never stored ---------- */
CREATE VIEW Patient_Age AS
SELECT Patient_id,
       CONCAT(F_name, ' ', L_name) AS Full_name,
       DOB,
       DATEDIFF(YEAR, DOB, GETDATE())
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DOB, GETDATE()), DOB) > CAST(GETDATE() AS DATE)
                THEN 1 ELSE 0 END      AS Age
FROM PATIENT;
GO

/* ---------- Derived attribute Total_amount : calculated from the services ---------- */
CREATE VIEW Bill_Summary AS
SELECT b.Bill_id,
       b.Appointment_id,
       b.Payment_status,
       ISNULL(SUM(ai.Quantity * s.Price), 0)                AS Total_amount,
       b.Amount_paid,
       ISNULL(SUM(ai.Quantity * s.Price), 0) - b.Amount_paid AS Balance_due
FROM BILL b
LEFT JOIN Appointment_includes ai ON ai.Appointment_id = b.Appointment_id
LEFT JOIN SERVICE s               ON s.Service_id      = ai.Service_id
GROUP BY b.Bill_id, b.Appointment_id, b.Payment_status, b.Amount_paid;
GO


/* =====================================================================
   PART 4 : SAMPLE DATA
   Order matters:
     1) DEPARTMENT without heads   2) DOCTOR   3) set the heads   4) the rest
   ===================================================================== */

INSERT INTO DEPARTMENT (Department_id, Dept_name, Head_doctor_id) VALUES
(1, 'Cardiology',  NULL),
(2, 'Neurology',   NULL),
(3, 'Pediatrics',  NULL),
(4, 'Orthopedics', NULL),
(5, 'Radiology',   NULL);

INSERT INTO DOCTOR (Doctor_id, F_name, L_name, Specialization, License_no, Phone_no, Qualification, Department_id) VALUES
(1, 'Omar',   'Nasser', 'Cardiologist',       'LIC-1001', '5550101', 'MD Cardiology',   1),
(2, 'Laila',  'Hamad',  'Neurologist',        'LIC-1002', '5550102', 'MD Neurology',    2),
(3, 'Yousef', 'Karim',  'Pediatrician',       'LIC-1003', '5550103', 'MD Pediatrics',   3),
(4, 'Sara',   'Ahmed',  'Orthopedic Surgeon', 'LIC-1004', '5550104', 'MS Orthopedics',  4),
(5, 'Khalid', 'Salim',  'Radiologist',        'LIC-1005', '5550105', 'MD Radiology',    5),
(6, 'Mona',   'Hassan', 'Cardiologist',       'LIC-1006', '5550106', 'MD Cardiology',   1);

-- Heads (1:1) : every department gets a different head doctor
UPDATE DEPARTMENT SET Head_doctor_id = 1 WHERE Department_id = 1;
UPDATE DEPARTMENT SET Head_doctor_id = 2 WHERE Department_id = 2;
UPDATE DEPARTMENT SET Head_doctor_id = 3 WHERE Department_id = 3;
UPDATE DEPARTMENT SET Head_doctor_id = 4 WHERE Department_id = 4;
UPDATE DEPARTMENT SET Head_doctor_id = 5 WHERE Department_id = 5;

INSERT INTO PATIENT (Patient_id, F_name, L_name, Gender, DOB, Blood_group, Address) VALUES
(1, 'Ali',    'Khan',    'M', '1990-03-12', 'O+',  '12 Palm Street'),
(2, 'Fatma',  'Said',    'F', '1985-07-25', 'A+',  '45 Garden Road'),
(3, 'Hassan', 'Rashid',  'M', '2015-01-09', 'B+',  '8 Hill View'),
(4, 'Noor',   'Ali',     'F', '1972-11-30', 'AB-', '23 Lake Avenue'),
(5, 'Yusuf',  'Mahmood', 'M', '1960-06-18', 'O-',  '77 Market Street'),
(6, 'Mariam', 'Yousef',  'F', '2001-09-02', 'A-',  '5 Sunrise Lane');

INSERT INTO Patient_phone (Patient_id, Phone_no) VALUES
(1, '5551001'),
(1, '5551011'),
(2, '5551002'),
(3, '5551003'),
(4, '5551004'),
(5, '5551005'),
(6, '5551006');

INSERT INTO SERVICE (Service_id, Service_name, Service_type, Price, Department_id) VALUES
(1, 'Cardiology Consultation', 'Consultation',    30.00, 1),
(2, 'ECG',                     'Diagnostic Test', 20.00, 1),
(3, 'MRI Scan',                'Imaging',        250.00, 5),
(4, 'Neurology Consultation',  'Consultation',    35.00, 2),
(5, 'Child Checkup',           'Consultation',    20.00, 3),
(6, 'Physiotherapy Session',   'Therapy',         45.00, 4),
(7, 'X-Ray',                   'Imaging',         40.00, 5);

INSERT INTO APPOINTMENT (Appointment_id, [Date], [Time], Status, Type, Patient_id, Doctor_id) VALUES
(1, '2026-09-01', '09:00', 'Completed', 'Checkup',      1, 1),
(2, '2026-09-02', '10:30', 'Completed', 'Consultation', 2, 2),
(3, '2026-09-03', '11:00', 'Completed', 'Follow-up',    3, 3),
(4, '2026-09-04', '13:15', 'Completed', 'Consultation', 4, 4),
(5, '2026-09-05', '08:45', 'Completed', 'Checkup',      5, 1),
(6, '2026-09-06', '15:30', 'Completed', 'Imaging',      6, 5),
(7, '2026-09-10', '12:00', 'Cancelled', 'Consultation', 1, 6),
(8, '2026-10-01', '09:30', 'Scheduled', 'Checkup',      2, 1);

-- Includes (M:M) : Quantity = how many times the service was used in the appointment
INSERT INTO Appointment_includes (Appointment_id, Service_id, Quantity) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 4, 1),
(2, 3, 1),
(3, 5, 1),
(4, 6, 3),
(5, 1, 1),
(5, 2, 2),
(6, 3, 1),
(8, 1, 1);

INSERT INTO MEDICAL_RECORD (Record_id, Diagnosis, Treatment, Patient_id, Doctor_id, Appointment_id) VALUES
(1, 'Mild hypertension',        'Lifestyle advice and medication', 1, 1, 1),
(2, 'Migraine',                 'Pain relief and rest',            2, 2, 2),
(3, 'Seasonal flu',             'Fluids and rest',                 3, 3, 3),
(4, 'Knee ligament strain',     'Physiotherapy sessions',          4, 4, 4),
(5, 'Stable angina',            'ECG monitoring and medication',   5, 1, 5),
(6, 'No abnormalities detected','None',                            6, 5, 6);

INSERT INTO BILL (Bill_id, Payment_method, Payment_status, Amount_paid, Patient_id, Appointment_id) VALUES
(1, 'Cash',      'Paid',     50.00, 1, 1),
(2, 'Card',      'Partial', 100.00, 2, 2),
(3, 'Cash',      'Paid',     20.00, 3, 3),
(4, 'Insurance', 'Unpaid',    0.00, 4, 4),
(5, 'Card',      'Paid',     70.00, 5, 5),
(6, 'Cash',      'Partial', 150.00, 6, 6);
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
WHERE TABLE_NAME = 'APPOINTMENT'
ORDER BY ORDINAL_POSITION;

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'BILL'
ORDER BY ORDINAL_POSITION;

-- Q3. All rows of each table
SELECT * FROM DEPARTMENT;
SELECT * FROM DOCTOR;
SELECT * FROM SERVICE;
SELECT * FROM PATIENT;
SELECT * FROM Patient_phone;
SELECT * FROM APPOINTMENT;
SELECT * FROM Appointment_includes;
SELECT * FROM MEDICAL_RECORD;
SELECT * FROM BILL;

-- Q4. Each department with its head doctor (Heads, 1:1)
SELECT d.Department_id, d.Dept_name,
       CONCAT(h.F_name, ' ', h.L_name) AS Head_doctor
FROM DEPARTMENT d
LEFT JOIN DOCTOR h ON d.Head_doctor_id = h.Doctor_id
ORDER BY d.Department_id;

-- Q5. Doctors with their department (Works in, 1:M)
SELECT doc.Doctor_id,
       CONCAT(doc.F_name, ' ', doc.L_name) AS Doctor,
       doc.Specialization,
       d.Dept_name AS Department
FROM DOCTOR doc
JOIN DEPARTMENT d ON doc.Department_id = d.Department_id
ORDER BY d.Dept_name, doc.Doctor_id;

-- Q6. Services offered by each department (Offers, 1:M)
SELECT d.Dept_name, s.Service_name, s.Service_type, s.Price
FROM SERVICE s
JOIN DEPARTMENT d ON s.Department_id = d.Department_id
ORDER BY d.Dept_name, s.Service_name;

-- Q7. Every appointment with patient, doctor and department (Books, Handles)
SELECT a.Appointment_id, a.[Date], a.[Time], a.Status, a.Type,
       CONCAT(p.F_name, ' ', p.L_name)     AS Patient,
       CONCAT(doc.F_name, ' ', doc.L_name) AS Doctor,
       d.Dept_name                         AS Department
FROM APPOINTMENT a
JOIN PATIENT    p   ON a.Patient_id    = p.Patient_id
JOIN DOCTOR     doc ON a.Doctor_id     = doc.Doctor_id
JOIN DEPARTMENT d   ON doc.Department_id = d.Department_id
ORDER BY a.[Date], a.[Time];

-- Q8. Services used in each appointment with quantity and line total (Includes, M:M)
SELECT ai.Appointment_id,
       s.Service_name,
       ai.Quantity,
       s.Price,
       ai.Quantity * s.Price AS Line_total
FROM Appointment_includes ai
JOIN SERVICE s ON ai.Service_id = s.Service_id
ORDER BY ai.Appointment_id, s.Service_name;

-- Q9. Bill totals (derived) and balance due -> shows partial payments
SELECT * FROM Bill_Summary ORDER BY Bill_id;

-- Q10. How many times each service was used (Quantity tracked in the M:M table)
SELECT s.Service_id, s.Service_name,
       COUNT(ai.Appointment_id)      AS Appointments_using_it,
       ISNULL(SUM(ai.Quantity), 0)   AS Times_used
FROM SERVICE s
LEFT JOIN Appointment_includes ai ON ai.Service_id = s.Service_id
GROUP BY s.Service_id, s.Service_name
ORDER BY Times_used DESC, s.Service_name;

-- Q11. Medical records with patient, doctor and appointment date (Has record, Creates, Results in)
SELECT m.Record_id,
       CONCAT(p.F_name, ' ', p.L_name)     AS Patient,
       CONCAT(doc.F_name, ' ', doc.L_name) AS Doctor,
       a.[Date] AS Appointment_date,
       m.Diagnosis, m.Treatment
FROM MEDICAL_RECORD m
JOIN PATIENT     p   ON m.Patient_id     = p.Patient_id
JOIN DOCTOR      doc ON m.Doctor_id      = doc.Doctor_id
JOIN APPOINTMENT a   ON m.Appointment_id = a.Appointment_id
ORDER BY m.Record_id;

-- Q12. Number of appointments for each doctor
SELECT CONCAT(doc.F_name, ' ', doc.L_name) AS Doctor,
       COUNT(a.Appointment_id)             AS Appointments
FROM DOCTOR doc
LEFT JOIN APPOINTMENT a ON a.Doctor_id = doc.Doctor_id
GROUP BY doc.Doctor_id, doc.F_name, doc.L_name
ORDER BY Appointments DESC, Doctor;

-- Q13. Appointments that did NOT result in a medical record
SELECT a.Appointment_id, a.[Date], a.Status
FROM APPOINTMENT a
WHERE NOT EXISTS (SELECT 1 FROM MEDICAL_RECORD m WHERE m.Appointment_id = a.Appointment_id);

-- Q14. Bills that are not fully paid
SELECT * FROM Bill_Summary WHERE Balance_due > 0 ORDER BY Balance_due DESC;

-- Q15. Patients with their age (derived attribute) and phone numbers (multivalued)
SELECT pa.Patient_id, pa.Full_name, pa.DOB, pa.Age,
       pp.Phone_no
FROM Patient_Age pa
LEFT JOIN Patient_phone pp ON pp.Patient_id = pa.Patient_id
ORDER BY pa.Patient_id, pp.Phone_no;

-- Q16. Total billed and paid for each patient
SELECT CONCAT(p.F_name, ' ', p.L_name) AS Patient,
       SUM(bs.Total_amount)            AS Total_billed,
       SUM(bs.Amount_paid)             AS Total_paid
FROM PATIENT p
JOIN BILL b           ON b.Patient_id = p.Patient_id
JOIN Bill_Summary bs  ON bs.Bill_id   = b.Bill_id
GROUP BY p.Patient_id, p.F_name, p.L_name
ORDER BY Total_billed DESC;

-- Q17. Example UPDATE and DELETE
--      (the patient pays the rest of bill 2 -> the bill becomes Paid)
UPDATE BILL
SET Amount_paid = 285.00, Payment_status = 'Paid'
WHERE Bill_id = 2;

--      (the cancelled appointment 7 is removed; it has no services, record or bill)
DELETE FROM APPOINTMENT WHERE Appointment_id = 7;

--      (a service is used one more time in appointment 4)
UPDATE Appointment_includes SET Quantity = Quantity + 1 WHERE Appointment_id = 4 AND Service_id = 6;

-- Q18. Check the changes
SELECT * FROM Bill_Summary WHERE Bill_id = 2;
SELECT * FROM APPOINTMENT ORDER BY Appointment_id;
SELECT * FROM Appointment_includes WHERE Appointment_id = 4;
