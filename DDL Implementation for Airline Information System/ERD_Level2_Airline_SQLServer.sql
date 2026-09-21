/* =====================================================================
   AIRLINE INFORMATION SYSTEM  -  SQL IMPLEMENTATION (SQL Server / T-SQL)
   Source : ERD Level 2 (Airline) and its relational mapping

   Tables (11): FLIGHT, Flight_weekdays, FARE, AIRPORT, FLIGHT_LEG,
                AIRPLANE_TYPE, Airport_can_land, AIRPLANE, LEG_INSTANCE,
                CUSTOMER, RESERVATION

   How to run : SSMS -> File > Open > File... -> pick this file ->
                make sure NOTHING is selected -> press Execute (F5).
                (GO lines split the script into batches; SSMS understands them.)

   File layout
     PART 1  Create the database
     PART 2  Drop old objects (so the script can be re-run safely)
     PART 3  Create the tables
     PART 4  Insert sample data (every table has at least 5 rows)
     PART 5  Queries (SELECT / UPDATE / DELETE)
   ===================================================================== */


/* =====================================================================
   PART 1 : DATABASE
   ===================================================================== */
IF DB_ID('airline_db') IS NULL
    CREATE DATABASE airline_db;
GO

USE airline_db;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


/* =====================================================================
   PART 2 : DROP OLD OBJECTS  (children first, parents last)
   ===================================================================== */
IF OBJECT_ID('dbo.RESERVATION',      'U') IS NOT NULL DROP TABLE dbo.RESERVATION;
IF OBJECT_ID('dbo.LEG_INSTANCE',     'U') IS NOT NULL DROP TABLE dbo.LEG_INSTANCE;
IF OBJECT_ID('dbo.FARE',             'U') IS NOT NULL DROP TABLE dbo.FARE;
IF OBJECT_ID('dbo.Flight_weekdays',  'U') IS NOT NULL DROP TABLE dbo.Flight_weekdays;
IF OBJECT_ID('dbo.Airport_can_land', 'U') IS NOT NULL DROP TABLE dbo.Airport_can_land;
IF OBJECT_ID('dbo.FLIGHT_LEG',       'U') IS NOT NULL DROP TABLE dbo.FLIGHT_LEG;
IF OBJECT_ID('dbo.AIRPLANE',         'U') IS NOT NULL DROP TABLE dbo.AIRPLANE;
IF OBJECT_ID('dbo.CUSTOMER',         'U') IS NOT NULL DROP TABLE dbo.CUSTOMER;
IF OBJECT_ID('dbo.AIRPLANE_TYPE',    'U') IS NOT NULL DROP TABLE dbo.AIRPLANE_TYPE;
IF OBJECT_ID('dbo.AIRPORT',          'U') IS NOT NULL DROP TABLE dbo.AIRPORT;
IF OBJECT_ID('dbo.FLIGHT',           'U') IS NOT NULL DROP TABLE dbo.FLIGHT;
GO


/* =====================================================================
   PART 3 : CREATE TABLES
   Rules used (same as the example):
     - 1:M                   -> PK of the "one" side becomes FK in the "many" side
     - M:M                   -> new table, the 2 FKs form a composite PK
     - Multivalued attribute -> new table, (owner FK + value) = composite PK
     - Weak entity           -> owner PK + its own partial key = composite PK

   SQL Server note: plain foreign keys use the default (NO ACTION) because
   SQL Server refuses SET NULL / CASCADE chains that reach the same table by
   more than one path (error 1785). ON DELETE CASCADE is used only on the
   weak entities, the multivalued table and the M:M table, where it is safe.
   ===================================================================== */

/* ---------- Independent tables (no foreign keys) ---------- */

CREATE TABLE AIRPORT (
    airport_code  CHAR(3)       NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    city          VARCHAR(50)   NOT NULL,
    state         VARCHAR(50),
    CONSTRAINT pk_airport PRIMARY KEY (airport_code)
);

CREATE TABLE FLIGHT (
    flight_no     VARCHAR(10)   NOT NULL,
    Airline       VARCHAR(50)   NOT NULL,
    Restrictions  VARCHAR(200),
    CONSTRAINT pk_flight PRIMARY KEY (flight_no)
);

CREATE TABLE AIRPLANE_TYPE (
    type_name  VARCHAR(30)  NOT NULL,
    company    VARCHAR(50)  NOT NULL,
    max_seats  INT          NOT NULL,
    CONSTRAINT pk_airplane_type PRIMARY KEY (type_name),
    CONSTRAINT ck_airplane_type_seats CHECK (max_seats > 0)
);

CREATE TABLE CUSTOMER (
    customer_id  INT           NOT NULL,
    name         VARCHAR(100)  NOT NULL,
    phone        VARCHAR(20),
    CONSTRAINT pk_customer PRIMARY KEY (customer_id)
);
GO

/* ---------- Multivalued attribute Weekdays (double oval) -> new table ---------- */
CREATE TABLE Flight_weekdays (
    flight_no  VARCHAR(10)  NOT NULL,        -- FK -> FLIGHT
    Weekdays   VARCHAR(10)  NOT NULL,
    CONSTRAINT pk_flight_weekdays PRIMARY KEY (flight_no, Weekdays),
    CONSTRAINT fk_fw_flight FOREIGN KEY (flight_no)
        REFERENCES FLIGHT (flight_no) ON DELETE CASCADE,
    CONSTRAINT ck_fw_day CHECK (Weekdays IN ('Sunday', 'Monday', 'Tuesday', 'Wednesday',
                                             'Thursday', 'Friday', 'Saturday'))
);

/* ---------- FARE : weak entity of FLIGHT (Has fare, 1:M) ---------- */
CREATE TABLE FARE (
    flight_no  VARCHAR(10)    NOT NULL,      -- FK -> FLIGHT (part of the key)
    Code       VARCHAR(10)    NOT NULL,      -- partial key
    Amount     DECIMAL(10,2)  NOT NULL,
    CONSTRAINT pk_fare PRIMARY KEY (flight_no, Code),
    CONSTRAINT fk_fare_flight FOREIGN KEY (flight_no)
        REFERENCES FLIGHT (flight_no) ON DELETE CASCADE,
    CONSTRAINT ck_fare_amount CHECK (Amount >= 0)
);

/* ---------- AIRPLANE : Is of type (AIRPLANE_TYPE 1 : M AIRPLANE) ---------- */
CREATE TABLE AIRPLANE (
    airplane_id        INT          NOT NULL,
    total_no_of_seats  INT          NOT NULL,
    type_name          VARCHAR(30)  NOT NULL,   -- FK -> AIRPLANE_TYPE
    CONSTRAINT pk_airplane PRIMARY KEY (airplane_id),
    CONSTRAINT fk_airplane_type FOREIGN KEY (type_name)
        REFERENCES AIRPLANE_TYPE (type_name),
    CONSTRAINT ck_airplane_seats CHECK (total_no_of_seats > 0)
);

/* ---------- Can land (AIRPORT M : M AIRPLANE_TYPE) -> new table ---------- */
CREATE TABLE Airport_can_land (
    airport_code  CHAR(3)      NOT NULL,     -- FK -> AIRPORT
    type_name     VARCHAR(30)  NOT NULL,     -- FK -> AIRPLANE_TYPE
    CONSTRAINT pk_airport_can_land PRIMARY KEY (airport_code, type_name),
    CONSTRAINT fk_acl_airport FOREIGN KEY (airport_code)
        REFERENCES AIRPORT (airport_code) ON DELETE CASCADE,
    CONSTRAINT fk_acl_type FOREIGN KEY (type_name)
        REFERENCES AIRPLANE_TYPE (type_name) ON DELETE CASCADE
);
GO

/* ---------- FLIGHT_LEG ----------
   Includes      (FLIGHT  1 : M FLIGHT_LEG) -> flight_no
   Departs from  (AIRPORT 1 : M FLIGHT_LEG) -> departure_airport_code
   Arrives at    (AIRPORT 1 : M FLIGHT_LEG) -> arrival_airport_code */
CREATE TABLE FLIGHT_LEG (
    leg_no                  INT          NOT NULL,
    scheduled_dep_time      TIME         NOT NULL,
    scheduled_arr_time      TIME         NOT NULL,
    flight_no               VARCHAR(10)  NOT NULL,   -- FK -> FLIGHT
    departure_airport_code  CHAR(3)      NOT NULL,   -- FK -> AIRPORT
    arrival_airport_code    CHAR(3)      NOT NULL,   -- FK -> AIRPORT
    CONSTRAINT pk_flight_leg PRIMARY KEY (leg_no),
    CONSTRAINT fk_leg_flight FOREIGN KEY (flight_no)
        REFERENCES FLIGHT (flight_no),
    CONSTRAINT fk_leg_departure FOREIGN KEY (departure_airport_code)
        REFERENCES AIRPORT (airport_code),
    CONSTRAINT fk_leg_arrival FOREIGN KEY (arrival_airport_code)
        REFERENCES AIRPORT (airport_code),
    CONSTRAINT ck_leg_airports CHECK (departure_airport_code <> arrival_airport_code)
);
GO

/* ---------- LEG_INSTANCE : weak entity of FLIGHT_LEG (Instance of, 1:M) ----------
   Key = (leg_no, Date).   Assigned to (AIRPLANE 1 : M LEG_INSTANCE) -> airplane_id */
CREATE TABLE LEG_INSTANCE (
    leg_no                     INT   NOT NULL,       -- FK -> FLIGHT_LEG (part of the key)
    [Date]                     DATE  NOT NULL,       -- partial key
    Arrival_time               TIME,
    Departure_time             TIME,
    Number_of_available_seats  INT   NOT NULL,
    airplane_id                INT,                  -- FK -> AIRPLANE (assigned airplane)
    CONSTRAINT pk_leg_instance PRIMARY KEY (leg_no, [Date]),
    CONSTRAINT fk_li_leg FOREIGN KEY (leg_no)
        REFERENCES FLIGHT_LEG (leg_no) ON DELETE CASCADE,
    CONSTRAINT fk_li_airplane FOREIGN KEY (airplane_id)
        REFERENCES AIRPLANE (airplane_id),
    CONSTRAINT ck_li_seats CHECK (Number_of_available_seats >= 0)
);
GO

/* ---------- RESERVATION : weak entity of LEG_INSTANCE ----------
   Reserves ties together LEG_INSTANCE, CUSTOMER and the seat number.
   Key = (leg_no, Date, Seat_no)  ->  a seat can be reserved once per leg instance.
   (leg_no, Date) is one composite foreign key to LEG_INSTANCE. */
CREATE TABLE RESERVATION (
    leg_no       INT         NOT NULL,
    [Date]       DATE        NOT NULL,
    Seat_no      VARCHAR(5)  NOT NULL,               -- partial key
    customer_id  INT         NOT NULL,               -- FK -> CUSTOMER
    CONSTRAINT pk_reservation PRIMARY KEY (leg_no, [Date], Seat_no),
    CONSTRAINT fk_res_leg_instance FOREIGN KEY (leg_no, [Date])
        REFERENCES LEG_INSTANCE (leg_no, [Date]) ON DELETE CASCADE,
    CONSTRAINT fk_res_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
);
GO


/* =====================================================================
   PART 4 : SAMPLE DATA  (parents first, then children)
   ===================================================================== */

INSERT INTO AIRPORT (airport_code, name, city, state) VALUES
('MCT', 'Muscat International Airport',    'Muscat',     'Muscat Governorate'),
('DXB', 'Dubai International Airport',     'Dubai',      'Dubai'),
('RUH', 'King Khalid International Airport','Riyadh',    'Riyadh Province'),
('BAH', 'Bahrain International Airport',   'Manama',     'Capital Governorate'),
('DOH', 'Hamad International Airport',     'Doha',       'Ad Dawhah'),
('KWI', 'Kuwait International Airport',    'Kuwait City','Al Asimah');

INSERT INTO FLIGHT (flight_no, Airline, Restrictions) VALUES
('WY101', 'Oman Air',       'No refund on economy fares'),
('WY202', 'Oman Air',       NULL),
('EK803', 'Emirates',       'Baggage limit 30 kg'),
('QR304', 'Qatar Airways',  NULL),
('GF505', 'Gulf Air',       'Non-transferable ticket'),
('KU606', 'Kuwait Airways', NULL);

INSERT INTO AIRPLANE_TYPE (type_name, company, max_seats) VALUES
('Boeing 737',   'Boeing',  180),
('Boeing 787',   'Boeing',  300),
('Airbus A320',  'Airbus',  170),
('Airbus A380',  'Airbus',  500),
('Embraer E190', 'Embraer', 100);

INSERT INTO CUSTOMER (customer_id, name, phone) VALUES
(1, 'Ahmed Salim',   '5550001'),
(2, 'Fatma Nasser',  '5550002'),
(3, 'Khalid Hamad',  '5550003'),
(4, 'Mariam Yousef', '5550004'),
(5, 'Said Rashid',   '5550005'),
(6, 'Noor Ali',      '5550006');

INSERT INTO Flight_weekdays (flight_no, Weekdays) VALUES
('WY101', 'Sunday'),
('WY101', 'Tuesday'),
('WY202', 'Monday'),
('EK803', 'Friday'),
('QR304', 'Wednesday'),
('GF505', 'Thursday'),
('KU606', 'Saturday');

INSERT INTO FARE (flight_no, Code, Amount) VALUES
('WY101', 'Y',  85.00),
('WY101', 'J', 210.00),
('WY202', 'Y', 120.00),
('EK803', 'Y', 150.00),
('QR304', 'Y', 140.00),
('GF505', 'Y',  95.50),
('KU606', 'Y', 110.00);

INSERT INTO AIRPLANE (airplane_id, total_no_of_seats, type_name) VALUES
(101, 180, 'Boeing 737'),
(102, 296, 'Boeing 787'),
(103, 168, 'Airbus A320'),
(104, 489, 'Airbus A380'),
(105,  98, 'Embraer E190'),
(106, 180, 'Boeing 737');

INSERT INTO Airport_can_land (airport_code, type_name) VALUES
('MCT', 'Boeing 737'),
('MCT', 'Boeing 787'),
('DXB', 'Airbus A380'),
('DXB', 'Boeing 787'),
('DOH', 'Airbus A320'),
('BAH', 'Embraer E190'),
('RUH', 'Boeing 737');

INSERT INTO FLIGHT_LEG (leg_no, scheduled_dep_time, scheduled_arr_time, flight_no, departure_airport_code, arrival_airport_code) VALUES
(1, '08:00', '09:15', 'WY101', 'MCT', 'DXB'),
(2, '10:30', '11:30', 'WY101', 'DXB', 'DOH'),
(3, '14:00', '15:20', 'WY202', 'MCT', 'BAH'),
(4, '07:45', '09:30', 'EK803', 'DXB', 'RUH'),
(5, '18:00', '20:10', 'QR304', 'DOH', 'MCT'),
(6, '12:15', '13:40', 'GF505', 'BAH', 'RUH');

INSERT INTO LEG_INSTANCE (leg_no, [Date], Arrival_time, Departure_time, Number_of_available_seats, airplane_id) VALUES
(1, '2026-10-01', '09:20', '08:05', 150, 101),
(1, '2026-10-03', '09:15', '08:00', 170, 106),
(2, '2026-10-01', '11:35', '10:35', 280, 102),
(3, '2026-10-05', '15:25', '14:05', 120, 103),
(4, '2026-10-06', '09:30', '07:50', 400, 104),
(5, '2026-10-07', '20:15', '18:05',  90, 105),
(6, '2026-10-08', '13:45', '12:20',  75, 105);

INSERT INTO RESERVATION (leg_no, [Date], Seat_no, customer_id) VALUES
(1, '2026-10-01', '12A', 1),
(1, '2026-10-01', '12B', 2),
(1, '2026-10-03', '5C',  3),
(2, '2026-10-01', '9B',  1),
(3, '2026-10-05', '7D',  4),
(4, '2026-10-06', '1A',  5),
(5, '2026-10-07', '20F', 6);
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
WHERE TABLE_NAME = 'FLIGHT_LEG'
ORDER BY ORDINAL_POSITION;

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS Max_length, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'LEG_INSTANCE'
ORDER BY ORDINAL_POSITION;

-- Q3. All rows of each table
SELECT * FROM AIRPORT;
SELECT * FROM FLIGHT;
SELECT * FROM Flight_weekdays;
SELECT * FROM FARE;
SELECT * FROM AIRPLANE_TYPE;
SELECT * FROM AIRPLANE;
SELECT * FROM Airport_can_land;
SELECT * FROM FLIGHT_LEG;
SELECT * FROM LEG_INSTANCE;
SELECT * FROM CUSTOMER;
SELECT * FROM RESERVATION;

-- Q4. Every flight leg with its flight and the departure / arrival airports (Includes, Departs from, Arrives at)
SELECT fl.leg_no,
       fl.flight_no,
       f.Airline,
       dep.city AS From_city,
       arr.city AS To_city,
       fl.scheduled_dep_time,
       fl.scheduled_arr_time
FROM FLIGHT_LEG fl
JOIN FLIGHT  f   ON fl.flight_no = f.flight_no
JOIN AIRPORT dep ON fl.departure_airport_code = dep.airport_code
JOIN AIRPORT arr ON fl.arrival_airport_code   = arr.airport_code
ORDER BY fl.leg_no;

-- Q5. Leg instances with route, airplane, type and free seats (Instance of, Assigned to, Is of type)
SELECT li.leg_no, li.[Date], fl.flight_no,
       a.airplane_id, a.type_name,
       a.total_no_of_seats,
       li.Number_of_available_seats
FROM LEG_INSTANCE li
JOIN FLIGHT_LEG fl ON li.leg_no = fl.leg_no
LEFT JOIN AIRPLANE a ON li.airplane_id = a.airplane_id
ORDER BY li.[Date], li.leg_no;

-- Q6. Airplane types that may land at each airport (Can land, M:M)
SELECT ap.city AS Airport_city, acl.type_name, t.company, t.max_seats
FROM Airport_can_land acl
JOIN AIRPORT ap       ON acl.airport_code = ap.airport_code
JOIN AIRPLANE_TYPE t  ON acl.type_name    = t.type_name
ORDER BY ap.city, acl.type_name;

-- Q7. Operating weekdays of each flight (multivalued attribute)
SELECT f.flight_no, f.Airline, w.Weekdays
FROM FLIGHT f
JOIN Flight_weekdays w ON f.flight_no = w.flight_no
ORDER BY f.flight_no, w.Weekdays;

-- Q8. Fares of each flight (Has fare, weak entity)
SELECT f.flight_no, f.Airline, fa.Code, fa.Amount
FROM FLIGHT f
JOIN FARE fa ON f.flight_no = fa.flight_no
ORDER BY f.flight_no, fa.Amount;

-- Q9. Cheapest and most expensive fare per flight
SELECT flight_no, MIN(Amount) AS Cheapest_fare, MAX(Amount) AS Highest_fare, COUNT(*) AS Fare_classes
FROM FARE
GROUP BY flight_no
ORDER BY flight_no;

-- Q10. Every reservation with customer, flight, route, date and seat (Reserves)
SELECT r.leg_no, r.[Date], r.Seat_no,
       c.name  AS Customer,
       c.phone,
       fl.flight_no,
       dep.city AS From_city,
       arr.city AS To_city
FROM RESERVATION r
JOIN CUSTOMER    c   ON r.customer_id = c.customer_id
JOIN FLIGHT_LEG  fl  ON r.leg_no      = fl.leg_no
JOIN AIRPORT     dep ON fl.departure_airport_code = dep.airport_code
JOIN AIRPORT     arr ON fl.arrival_airport_code   = arr.airport_code
ORDER BY r.[Date], r.leg_no, r.Seat_no;

-- Q11. Number of reserved seats on each leg instance
SELECT li.leg_no, li.[Date],
       COUNT(r.Seat_no) AS Reserved_seats,
       li.Number_of_available_seats
FROM LEG_INSTANCE li
LEFT JOIN RESERVATION r ON r.leg_no = li.leg_no AND r.[Date] = li.[Date]
GROUP BY li.leg_no, li.[Date], li.Number_of_available_seats
ORDER BY li.[Date], li.leg_no;

-- Q12. Number of reservations of each customer
SELECT c.customer_id, c.name, COUNT(r.Seat_no) AS Reservations
FROM CUSTOMER c
LEFT JOIN RESERVATION r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY Reservations DESC, c.name;

-- Q13. Customers with more than one reservation
SELECT c.name, COUNT(*) AS Reservations
FROM CUSTOMER c
JOIN RESERVATION r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(*) > 1;

-- Q14. Number of departing legs per airport
SELECT ap.airport_code, ap.city, COUNT(fl.leg_no) AS Departing_legs
FROM AIRPORT ap
LEFT JOIN FLIGHT_LEG fl ON fl.departure_airport_code = ap.airport_code
GROUP BY ap.airport_code, ap.city
ORDER BY Departing_legs DESC, ap.city;

-- Q15. Leg instances with fewer than 100 free seats
SELECT leg_no, [Date], Number_of_available_seats
FROM LEG_INSTANCE
WHERE Number_of_available_seats < 100
ORDER BY Number_of_available_seats;

-- Q16. Airplane types that are not allowed to land anywhere yet
SELECT t.type_name
FROM AIRPLANE_TYPE t
WHERE NOT EXISTS (SELECT 1 FROM Airport_can_land acl WHERE acl.type_name = t.type_name);

-- Q17. Example UPDATE and DELETE
--      (a customer books one more seat -> one less available seat)
INSERT INTO RESERVATION (leg_no, [Date], Seat_no, customer_id) VALUES (6, '2026-10-08', '3A', 2);
UPDATE LEG_INSTANCE
SET Number_of_available_seats = Number_of_available_seats - 1
WHERE leg_no = 6 AND [Date] = '2026-10-08';

--      (a reservation is cancelled -> the seat is free again)
DELETE FROM RESERVATION WHERE leg_no = 1 AND [Date] = '2026-10-03' AND Seat_no = '5C';
UPDATE LEG_INSTANCE
SET Number_of_available_seats = Number_of_available_seats + 1
WHERE leg_no = 1 AND [Date] = '2026-10-03';

UPDATE CUSTOMER SET phone = '5559999' WHERE customer_id = 6;

-- Q18. Check the changes
SELECT * FROM RESERVATION ORDER BY [Date], leg_no, Seat_no;
SELECT leg_no, [Date], Number_of_available_seats FROM LEG_INSTANCE ORDER BY [Date], leg_no;
SELECT * FROM CUSTOMER WHERE customer_id = 6;
