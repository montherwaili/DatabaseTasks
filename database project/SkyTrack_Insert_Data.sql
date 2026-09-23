
USE SkyTrackDB;


SET NOCOUNT ON;
SET XACT_ABORT ON;   

IF EXISTS (SELECT 1 FROM CITY) OR EXISTS (SELECT 1 FROM FLIGHT) OR EXISTS (SELECT 1 FROM PASSENGER)
BEGIN
    RAISERROR('Tables already contain data. Insert script stopped to avoid duplicates.', 16, 1);
    RETURN;
END;

BEGIN TRANSACTION;


INSERT INTO CITY (City_name, Country) VALUES
(N'Muscat', N'Oman'),
(N'Dubai',  N'United Arab Emirates'),
(N'Doha',   N'Qatar'),
(N'Riyadh', N'Saudi Arabia'),
(N'London', N'United Kingdom'),
(N'Mumbai', N'India'),
(N'Cairo',  N'Egypt');


INSERT INTO AIRCRAFT_MODEL (Model, Manufacturer) VALUES
('A320neo',     'Airbus'),
('A330-300',    'Airbus'),
('737 MAX 8',   'Boeing'),
('E195-E2',     'Embraer'),
('ATR 72-600',  'ATR'),
('CRJ900',      'Bombardier');


INSERT INTO AIRPORT (IATA_code, Name, City_id)
SELECT v.IATA_code, v.Name, c.City_id
FROM (VALUES
    ('MCT', N'Muscat International Airport',                  N'Muscat', N'Oman'),
    ('DXB', N'Dubai International Airport',                   N'Dubai',  N'United Arab Emirates'),
    ('DOH', N'Hamad International Airport',                   N'Doha',   N'Qatar'),
    ('RUH', N'King Khalid International Airport',             N'Riyadh', N'Saudi Arabia'),
    ('LHR', N'London Heathrow Airport',                       N'London', N'United Kingdom'),
    ('BOM', N'Chhatrapati Shivaji Maharaj International Airport', N'Mumbai', N'India'),
    ('CAI', N'Cairo International Airport',                   N'Cairo',  N'Egypt')
) AS v (IATA_code, Name, City_name, Country)
JOIN CITY c ON c.City_name = v.City_name AND c.Country = v.Country;


INSERT INTO AIRCRAFT (Registration_no, Model_id, Total_capacity, Year_of_manufacture)
SELECT v.Registration_no, m.Model_id, v.Total_capacity, v.Year_of_manufacture
FROM (VALUES
    ('A4O-SA', 'A320neo',    162, 2019),
    ('A4O-SB', '737 MAX 8',  172, 2020),
    ('A4O-SC', 'E195-E2',    136, 2021),
    ('A4O-SD', 'ATR 72-600',  70, 2017),
    ('A4O-SE', 'CRJ900',      90, 2016),
    ('A4O-SF', 'A330-300',   289, 2015)
) AS v (Registration_no, Model, Total_capacity, Year_of_manufacture)
JOIN AIRCRAFT_MODEL m ON m.Model = v.Model;


INSERT INTO PASSENGER (National_id, Full_name, Email, Phone, Nationality, DOB) VALUES
('OM1029384', N'Ahmed Al-Balushi',   'ahmed.balushi@mail.com',  '+96892345678',  N'Omani',     '1990-03-14'),
('AE7845120', N'Fatima Al-Mansoori', 'fatima.mansoori@mail.com','+971501234567', N'Emirati',   '1994-07-22'),
('QA3321457', N'Khalid Al-Thani',    'khalid.thani@mail.com',   '+97455123456',  N'Qatari',    '1985-11-02'),
('SA5566120', N'Noura Al-Qahtani',   'noura.qahtani@mail.com',  '+966551234567', N'Saudi',     '1998-01-30'),
('GB8812345', N'James Wilson',       'james.wilson@mail.com',   '+447700900123', N'British',   '1979-09-18'),
('IN4456789', N'Priya Sharma',       'priya.sharma@mail.com',   '+919812345678', N'Indian',    '1992-05-05'),
('EG2234567', N'Omar Hassan',        'omar.hassan@mail.com',    '+201001234567', N'Egyptian',  '1988-12-11'),
('PK6678901', N'Ayesha Khan',        'ayesha.khan@mail.com',    '+923001234567', N'Pakistani', '2000-04-25'),
('JO9901234', N'Layla Haddad',       'layla.haddad@mail.com',   '+962791234567', N'Jordanian', '1996-08-09'),
('PH3345678', N'Maria Santos',       'maria.santos@mail.com',   '+639171234567', N'Filipino',  '1991-02-17');


INSERT INTO CREW_MEMBER (License_no, Full_name, Role) VALUES
('LIC-P-1001', N'Salim Al-Harthy',   'Pilot'),
('LIC-P-1002', N'Yousuf Al-Rawahi',  'Pilot'),
('LIC-P-1003', N'Daniel Carter',     'Pilot'),
('LIC-C-2001', N'Hamed Al-Busaidi',  'Co-Pilot'),
('LIC-C-2002', N'Rahul Mehta',       'Co-Pilot'),
('LIC-F-3001', N'Maryam Al-Saadi',   'Flight Attendant'),
('LIC-F-3002', N'Sofia Reyes',       'Flight Attendant'),
('LIC-F-3003', N'Hana Yousef',       'Flight Attendant'),
('LIC-E-4001', N'Tariq Al-Amri',     'Engineer'),
('LIC-E-4002', N'Michael Brown',     'Engineer');


INSERT INTO FLIGHT (Flight_no, Departure_datetime, Arrival_datetime, Status,
                    Aircraft_id, Origin_airport_id, Destination_airport_id)
SELECT v.Flight_no, v.Dep, v.Arr, v.Status, a.Aircraft_id, o.Airport_id, d.Airport_id
FROM (VALUES
    ('SK101', '2026-09-15T08:00:00', '2026-09-15T09:15:00', 'Completed', 'A4O-SD', 'MCT', 'DXB'),
    ('SK202', '2026-09-18T01:30:00', '2026-09-18T06:45:00', 'Completed', 'A4O-SF', 'MCT', 'LHR'),
    ('SK303', '2026-09-20T10:00:00', '2026-09-20T11:30:00', 'Completed', 'A4O-SC', 'DOH', 'RUH'),
    ('SK404', '2026-09-24T09:00:00', '2026-09-24T11:30:00', 'Delayed',   'A4O-SB', 'RUH', 'CAI'),
    ('SK505', '2026-09-24T22:00:00', '2026-09-25T02:45:00', 'Delayed',   'A4O-SA', 'DXB', 'BOM'),
    ('SK606', '2026-09-26T13:00:00', '2026-09-26T18:40:00', 'Cancelled', 'A4O-SE', 'CAI', 'MCT'),
    ('SK707', '2026-10-02T20:00:00', '2026-10-03T05:30:00', 'Scheduled', 'A4O-SF', 'LHR', 'DOH'),
    ('SK808', '2026-10-05T07:00:00', '2026-10-05T08:45:00', 'Scheduled', 'A4O-SA', 'BOM', 'MCT'),
    ('SK909', '2026-10-08T15:00:00', '2026-10-08T16:20:00', 'Scheduled', 'A4O-SC', 'MCT', 'DOH'),
    ('SK110', '2026-10-10T09:30:00', '2026-10-10T12:30:00', 'Cancelled', 'A4O-SB', 'DXB', 'CAI')
) AS v (Flight_no, Dep, Arr, Status, Registration_no, Origin, Destination)
JOIN AIRCRAFT a ON a.Registration_no = v.Registration_no
JOIN AIRPORT  o ON o.IATA_code       = v.Origin
JOIN AIRPORT  d ON d.IATA_code       = v.Destination;


INSERT INTO BOOKING (Seat_no, Class, Price_paid, Booking_date, Passenger_id, Flight_id)
SELECT v.Seat_no, v.Class, v.Price_paid, v.Booking_date, p.Passenger_id, f.Flight_id
FROM (VALUES
    ('12A', 'Economy',    85.00, '2026-08-20', 'OM1029384', 'SK101'),
    ('12B', 'Economy',    85.00, '2026-08-22', 'AE7845120', 'SK101'),
    ('1A',  'First',    1450.00, '2026-08-10', 'GB8812345', 'SK202'),
    ('4C',  'Business',  820.00, '2026-08-15', 'OM1029384', 'SK202'),
    ('24F', 'Economy',   390.00, '2026-09-01', 'IN4456789', 'SK202'),
    ('3A',  'Business',  310.00, '2026-09-05', 'QA3321457', 'SK303'),
    ('15D', 'Economy',   120.00, '2026-09-06', 'SA5566120', 'SK303'),
    ('2A',  'First',     690.00, '2026-09-10', 'EG2234567', 'SK404'),
    ('18C', 'Economy',   175.00, '2026-09-12', 'JO9901234', 'SK404'),
    ('5B',  'Business',  540.00, '2026-09-14', 'IN4456789', 'SK505'),
    ('22A', 'Economy',   210.00, '2026-09-15', 'PK6678901', 'SK505'),
    ('9D',  'Economy',   230.00, '2026-09-11', 'EG2234567', 'SK606'),
    ('1K',  'First',    1600.00, '2026-09-19', 'QA3321457', 'SK707'),
    ('30E', 'Economy',   420.00, '2026-09-20', 'GB8812345', 'SK707'),
    ('14C', 'Economy',   150.00, '2026-09-21', 'PH3345678', 'SK808'),
    ('4A',  'Business',  260.00, '2026-09-22', 'AE7845120', 'SK909'),
    ('20B', 'Economy',   190.00, '2026-09-18', 'JO9901234', 'SK110')
) AS v (Seat_no, Class, Price_paid, Booking_date, National_id, Flight_no)
JOIN PASSENGER p ON p.National_id = v.National_id
JOIN FLIGHT    f ON f.Flight_no   = v.Flight_no;


INSERT INTO FLIGHT_CREW (Flight_id, Crew_id)
SELECT f.Flight_id, c.Crew_id
FROM (VALUES
    ('SK101', 'LIC-P-1001'), ('SK101', 'LIC-C-2001'), ('SK101', 'LIC-F-3001'),
    ('SK202', 'LIC-P-1002'), ('SK202', 'LIC-C-2002'), ('SK202', 'LIC-F-3002'), ('SK202', 'LIC-F-3003'), ('SK202', 'LIC-E-4001'),
    ('SK303', 'LIC-P-1003'), ('SK303', 'LIC-C-2001'), ('SK303', 'LIC-F-3001'),
    ('SK404', 'LIC-P-1001'), ('SK404', 'LIC-C-2002'), ('SK404', 'LIC-F-3002'), ('SK404', 'LIC-E-4002'),
    ('SK505', 'LIC-P-1002'), ('SK505', 'LIC-C-2001'), ('SK505', 'LIC-F-3003'),
    ('SK606', 'LIC-P-1003'), ('SK606', 'LIC-C-2002'), ('SK606', 'LIC-F-3001'),
    ('SK707', 'LIC-P-1001'), ('SK707', 'LIC-C-2001'), ('SK707', 'LIC-F-3002'), ('SK707', 'LIC-F-3003'), ('SK707', 'LIC-E-4001'),
    ('SK808', 'LIC-P-1002'), ('SK808', 'LIC-C-2002'), ('SK808', 'LIC-F-3001'),
    ('SK909', 'LIC-P-1003'), ('SK909', 'LIC-C-2001'), ('SK909', 'LIC-F-3003'), ('SK909', 'LIC-E-4002'),
    ('SK110', 'LIC-P-1001'), ('SK110', 'LIC-C-2002'), ('SK110', 'LIC-F-3002')
) AS v (Flight_no, License_no)
JOIN FLIGHT      f ON f.Flight_no  = v.Flight_no
JOIN CREW_MEMBER c ON c.License_no = v.License_no;





SELECT 'CITY' AS Table_name, COUNT(*) AS Row_count FROM CITY
UNION ALL SELECT 'AIRCRAFT_MODEL', COUNT(*) FROM AIRCRAFT_MODEL
UNION ALL SELECT 'AIRPORT',        COUNT(*) FROM AIRPORT
UNION ALL SELECT 'AIRCRAFT',       COUNT(*) FROM AIRCRAFT
UNION ALL SELECT 'PASSENGER',      COUNT(*) FROM PASSENGER
UNION ALL SELECT 'CREW_MEMBER',    COUNT(*) FROM CREW_MEMBER
UNION ALL SELECT 'FLIGHT',         COUNT(*) FROM FLIGHT
UNION ALL SELECT 'BOOKING',        COUNT(*) FROM BOOKING
UNION ALL SELECT 'FLIGHT_CREW',    COUNT(*) FROM FLIGHT_CREW;


SELECT Status, COUNT(*) AS Flights FROM FLIGHT GROUP BY Status;


SELECT Class, COUNT(*) AS Bookings FROM BOOKING GROUP BY Class;


SELECT Role, COUNT(*) AS Crew_members FROM CREW_MEMBER GROUP BY Role;


SELECT f.Flight_no,
       SUM(CASE WHEN c.Role = 'Pilot'            THEN 1 ELSE 0 END) AS Pilots,
       SUM(CASE WHEN c.Role = 'Co-Pilot'         THEN 1 ELSE 0 END) AS Co_Pilots,
       SUM(CASE WHEN c.Role = 'Flight Attendant' THEN 1 ELSE 0 END) AS Flight_Attendants,
       SUM(CASE WHEN c.Role = 'Engineer'         THEN 1 ELSE 0 END) AS Engineers,
       CASE WHEN SUM(CASE WHEN c.Role = 'Pilot' THEN 1 ELSE 0 END) >= 1
             AND SUM(CASE WHEN c.Role = 'Flight Attendant' THEN 1 ELSE 0 END) >= 1
            THEN 'OK' ELSE 'MISSING' END AS [Check]
FROM FLIGHT f
LEFT JOIN FLIGHT_CREW fc ON fc.Flight_id = f.Flight_id
LEFT JOIN CREW_MEMBER c  ON c.Crew_id    = fc.Crew_id
GROUP BY f.Flight_no
ORDER BY f.Flight_no;

