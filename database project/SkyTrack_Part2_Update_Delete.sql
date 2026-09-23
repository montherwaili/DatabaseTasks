/* =========================================================
   SkyTrack Airline System - Part 2: UPDATE and DELETE
   SQL Server - run AFTER SkyTrack_Insert_Data.sql
   Each task shows the row(s) BEFORE and AFTER the change.
   ========================================================= */
USE SkyTrackDB;
GO

/* =========================================================
   UPDATE TASKS
   ========================================================= */

/* ---------- UPDATE 1: flight SK808 from 'Scheduled' to 'Completed' ---------- */
SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK808';   -- before: Scheduled

UPDATE FLIGHT
SET    Status = 'Completed'
WHERE  Flight_no = 'SK808'
  AND  Status = 'Scheduled';

SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK808';   -- after: Completed
GO

/* ---------- UPDATE 2: flight SK505 from 'Delayed' to 'Cancelled' ---------- */
SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK505';   -- before: Delayed

UPDATE FLIGHT
SET    Status = 'Cancelled'
WHERE  Flight_no = 'SK505'
  AND  Status = 'Delayed';

SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK505';   -- after: Cancelled
GO

/* ---------- UPDATE 3: increase all Economy prices by 10% ---------- */
SELECT Booking_id, Seat_no, Class, Price_paid FROM BOOKING WHERE Class = 'Economy';   -- before

UPDATE BOOKING
SET    Price_paid = Price_paid * 1.10
WHERE  Class = 'Economy';

SELECT Booking_id, Seat_no, Class, Price_paid FROM BOOKING WHERE Class = 'Economy';   -- after (+10%)
GO

/* ---------- UPDATE 4: change the phone number of passenger Ahmed Al-Balushi ---------- */
SELECT National_id, Full_name, Phone FROM PASSENGER WHERE National_id = 'OM1029384';   -- before

UPDATE PASSENGER
SET    Phone = '+96899887766'
WHERE  National_id = 'OM1029384';

SELECT National_id, Full_name, Phone FROM PASSENGER WHERE National_id = 'OM1029384';   -- after
GO

/* ---------- UPDATE 5: move crew member Rahul Mehta from 'Co-Pilot' to 'Pilot' ---------- */
-- A Co-Pilot is promoted, so every flight still keeps at least one Pilot and one Flight Attendant.
SELECT License_no, Full_name, Role FROM CREW_MEMBER WHERE License_no = 'LIC-C-2002';   -- before: Co-Pilot

UPDATE CREW_MEMBER
SET    Role = 'Pilot'
WHERE  License_no = 'LIC-C-2002';

SELECT License_no, Full_name, Role FROM CREW_MEMBER WHERE License_no = 'LIC-C-2002';   -- after: Pilot
GO


/* =========================================================
   DELETE TASKS  (SELECT first to confirm the row exists)
   ========================================================= */

/* ---------- DELETE 1: delete one cancelled flight (SK110) ---------- */
-- 1a) Confirm the flight exists and is cancelled
SELECT Flight_id, Flight_no, Status, Departure_datetime
FROM   FLIGHT
WHERE  Flight_no = 'SK110' AND Status = 'Cancelled';

-- 1b) Rows linked to it (they will be removed automatically by ON DELETE CASCADE)
SELECT b.Booking_id, b.Seat_no, b.Class
FROM   BOOKING b JOIN FLIGHT f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK110';

SELECT fc.Flight_id, fc.Crew_id
FROM   FLIGHT_CREW fc JOIN FLIGHT f ON fc.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK110';

-- 1c) Delete
DELETE FROM FLIGHT
WHERE  Flight_no = 'SK110' AND Status = 'Cancelled';

-- 1d) Confirm: flight is gone (0 rows)
SELECT Flight_no FROM FLIGHT WHERE Flight_no = 'SK110';
/* Result: the flight was deleted, and because BOOKING and FLIGHT_CREW reference
   FLIGHT with ON DELETE CASCADE, its booking and crew assignments were deleted too. */
GO

/* ---------- DELETE 2: delete one booking linked to a cancelled flight (SK606, seat 9D) ---------- */
-- 2a) Confirm the booking exists and its flight is cancelled
SELECT b.Booking_id, b.Seat_no, b.Class, b.Price_paid, p.Full_name, f.Flight_no, f.Status
FROM   BOOKING b
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
WHERE  f.Flight_no = 'SK606' AND f.Status = 'Cancelled' AND b.Seat_no = '9D';

-- 2b) Delete
DELETE b
FROM   BOOKING b
JOIN   FLIGHT  f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK606' AND f.Status = 'Cancelled' AND b.Seat_no = '9D';

-- 2c) Confirm: booking is gone (0 rows), the flight itself still exists
SELECT b.Booking_id
FROM   BOOKING b JOIN FLIGHT f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK606' AND b.Seat_no = '9D';
GO

/* ---------- DELETE 3: try to delete a passenger who has bookings (James Wilson) ---------- */
-- 3a) Confirm the passenger exists and has bookings
SELECT Passenger_id, National_id, Full_name FROM PASSENGER WHERE National_id = 'GB8812345';

SELECT b.Booking_id, f.Flight_no, b.Seat_no, b.Class
FROM   BOOKING b
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
WHERE  p.National_id = 'GB8812345';        -- 2 bookings (SK202, SK707)

-- 3b) Try the delete inside a transaction so the data can be kept for Part 3
BEGIN TRANSACTION;

DELETE FROM PASSENGER
WHERE  National_id = 'GB8812345';

-- 3c) Observe: passenger AND his bookings are gone (both SELECTs return 0 rows)
SELECT Passenger_id FROM PASSENGER WHERE National_id = 'GB8812345';
SELECT b.Booking_id
FROM   BOOKING b
WHERE  b.Passenger_id NOT IN (SELECT Passenger_id FROM PASSENGER);

/* ---------------------------------------------------------------
   RESULT / COMMENT:
   The DELETE succeeded without any error. SQL Server did NOT block it,
   because FK_BOOKING_PASSENGER was created with ON DELETE CASCADE.
   Deleting the passenger automatically deleted all of his bookings,
   so no orphan bookings are left (referential integrity is kept).
   If the foreign key had been NO ACTION (the default), the DELETE would
   have failed with error 547 (REFERENCE constraint conflict), and the
   bookings would have to be deleted first.
   Note: CASCADE is convenient but risky - one DELETE can silently remove
   the passenger's booking history.
   --------------------------------------------------------------- */

ROLLBACK TRANSACTION;   -- keep the passenger for Part 3 (change to COMMIT to make the delete permanent)

-- 3d) After ROLLBACK the passenger and his bookings are back
SELECT p.Full_name, COUNT(b.Booking_id) AS Bookings
FROM   PASSENGER p
LEFT JOIN BOOKING b ON b.Passenger_id = p.Passenger_id
WHERE  p.National_id = 'GB8812345'
GROUP BY p.Full_name;
GO
