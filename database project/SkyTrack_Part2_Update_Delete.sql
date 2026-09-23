
USE SkyTrackDB;





SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK808';  

UPDATE FLIGHT
SET    Status = 'Completed'
WHERE  Flight_no = 'SK808'
  AND  Status = 'Scheduled';

SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK808';   



SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK505';   

UPDATE FLIGHT
SET    Status = 'Cancelled'
WHERE  Flight_no = 'SK505'
  AND  Status = 'Delayed';

SELECT Flight_no, Status FROM FLIGHT WHERE Flight_no = 'SK505';   


SELECT Booking_id, Seat_no, Class, Price_paid FROM BOOKING WHERE Class = 'Economy';   

UPDATE BOOKING
SET    Price_paid = Price_paid * 1.10
WHERE  Class = 'Economy';

SELECT Booking_id, Seat_no, Class, Price_paid FROM BOOKING WHERE Class = 'Economy';   


SELECT National_id, Full_name, Phone FROM PASSENGER WHERE National_id = 'OM1029384';   

UPDATE PASSENGER
SET    Phone = '+96899887766'
WHERE  National_id = 'OM1029384';

SELECT National_id, Full_name, Phone FROM PASSENGER WHERE National_id = 'OM1029384';  



SELECT License_no, Full_name, Role FROM CREW_MEMBER WHERE License_no = 'LIC-C-2002';

UPDATE CREW_MEMBER
SET    Role = 'Pilot'
WHERE  License_no = 'LIC-C-2002';

SELECT License_no, Full_name, Role FROM CREW_MEMBER WHERE License_no = 'LIC-C-2002';  





SELECT Flight_id, Flight_no, Status, Departure_datetime
FROM   FLIGHT
WHERE  Flight_no = 'SK110' AND Status = 'Cancelled';


SELECT b.Booking_id, b.Seat_no, b.Class
FROM   BOOKING b JOIN FLIGHT f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK110';

SELECT fc.Flight_id, fc.Crew_id
FROM   FLIGHT_CREW fc JOIN FLIGHT f ON fc.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK110';


DELETE FROM FLIGHT
WHERE  Flight_no = 'SK110' AND Status = 'Cancelled';


SELECT Flight_no FROM FLIGHT WHERE Flight_no = 'SK110';



SELECT b.Booking_id, b.Seat_no, b.Class, b.Price_paid, p.Full_name, f.Flight_no, f.Status
FROM   BOOKING b
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
WHERE  f.Flight_no = 'SK606' AND f.Status = 'Cancelled' AND b.Seat_no = '9D';


DELETE b
FROM   BOOKING b
JOIN   FLIGHT  f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK606' AND f.Status = 'Cancelled' AND b.Seat_no = '9D';


SELECT b.Booking_id
FROM   BOOKING b JOIN FLIGHT f ON b.Flight_id = f.Flight_id
WHERE  f.Flight_no = 'SK606' AND b.Seat_no = '9D';



SELECT Passenger_id, National_id, Full_name FROM PASSENGER WHERE National_id = 'GB8812345';

SELECT b.Booking_id, f.Flight_no, b.Seat_no, b.Class
FROM   BOOKING b
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
WHERE  p.National_id = 'GB8812345';        
BEGIN TRANSACTION;

DELETE FROM PASSENGER
WHERE  National_id = 'GB8812345';


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

ROLLBACK TRANSACTION;   


SELECT p.Full_name, COUNT(b.Booking_id) AS Bookings
FROM   PASSENGER p
LEFT JOIN BOOKING b ON b.Passenger_id = p.Passenger_id
WHERE  p.National_id = 'GB8812345'
GROUP BY p.Full_name;

