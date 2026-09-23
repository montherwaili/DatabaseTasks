
USE SkyTrackDB;


SELECT f.Flight_no,
       o.Name AS Origin_airport,
       d.Name AS Destination_airport
FROM   FLIGHT f
JOIN   AIRPORT o ON f.Origin_airport_id      = o.Airport_id
JOIN   AIRPORT d ON f.Destination_airport_id = d.Airport_id
ORDER BY f.Flight_no;



SELECT b.Booking_id,
       p.Full_name AS Passenger_name,
       f.Flight_no
FROM   BOOKING b
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
ORDER BY b.Booking_id;




SELECT c.Full_name,
       c.Role
FROM   FLIGHT f
JOIN   FLIGHT_CREW fc ON f.Flight_id = fc.Flight_id
JOIN   CREW_MEMBER c  ON fc.Crew_id  = c.Crew_id
WHERE  f.Flight_no = 'SK101';




SELECT f.Flight_no,
       f.Departure_datetime,
       a.Registration_no,
       m.Model,
       m.Manufacturer
FROM   FLIGHT f
JOIN   AIRCRAFT a       ON f.Aircraft_id = a.Aircraft_id
JOIN   AIRCRAFT_MODEL m ON a.Model_id    = m.Model_id
WHERE  f.Status = 'Completed'
ORDER BY f.Departure_datetime;



SELECT p.Full_name,
       COUNT(b.Booking_id) AS Total_bookings
FROM   PASSENGER p
LEFT JOIN BOOKING b ON p.Passenger_id = b.Passenger_id
GROUP BY p.Passenger_id, p.Full_name
ORDER BY Total_bookings DESC, p.Full_name;


SELECT Class,
       COUNT(*)        AS Number_of_bookings,
       SUM(Price_paid) AS Total_revenue
FROM   BOOKING
GROUP BY Class
ORDER BY Total_revenue DESC;




SELECT a.Registration_no,
       m.Model,
       COUNT(f.Flight_id) AS Number_of_flights
FROM   AIRCRAFT a
JOIN   AIRCRAFT_MODEL m ON a.Model_id = m.Model_id
LEFT JOIN FLIGHT f      ON f.Aircraft_id = a.Aircraft_id
GROUP BY a.Aircraft_id, a.Registration_no, m.Model
ORDER BY Number_of_flights DESC, a.Registration_no;




SELECT f.Flight_no,
       COUNT(b.Booking_id) AS Number_of_bookings
FROM   FLIGHT f
JOIN   BOOKING b ON f.Flight_id = b.Flight_id
GROUP BY f.Flight_id, f.Flight_no
HAVING COUNT(b.Booking_id) > 1
ORDER BY Number_of_bookings DESC, f.Flight_no;




SELECT p.Full_name  AS Passenger_name,
       f.Flight_no,
       o.Name       AS Origin_airport,
       d.Name       AS Destination_airport,
       b.Class,
       b.Price_paid
FROM   BOOKING b
JOIN   PASSENGER p ON b.Passenger_id           = p.Passenger_id
JOIN   FLIGHT    f ON b.Flight_id              = f.Flight_id
JOIN   AIRPORT   o ON f.Origin_airport_id      = o.Airport_id
JOIN   AIRPORT   d ON f.Destination_airport_id = d.Airport_id
ORDER BY f.Flight_no, p.Full_name;


