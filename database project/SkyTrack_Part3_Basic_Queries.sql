
USE SkyTrackDB;



SELECT Flight_no,
       Departure_datetime,
       Arrival_datetime,
       Status
FROM   FLIGHT
ORDER BY Departure_datetime ASC;




SELECT Passenger_id,
       Full_name,
       National_id,
       Email,
       Phone,
       Nationality,
       DOB
FROM   PASSENGER
ORDER BY Full_name ASC;




SELECT a.Registration_no,
       m.Model,
       a.Total_capacity
FROM   AIRCRAFT a
JOIN   AIRCRAFT_MODEL m ON a.Model_id = m.Model_id
ORDER BY a.Total_capacity DESC;



SELECT DISTINCT Class
FROM   BOOKING;




SELECT Flight_no,
       Departure_datetime,
       Arrival_datetime,
       Status
FROM   FLIGHT
WHERE  Status IN ('Delayed', 'Cancelled');



SELECT Passenger_id,
       Full_name,
       National_id,
       Email,
       Phone,
       Nationality
FROM   PASSENGER
WHERE  Nationality = 'Omani';



SELECT c.Country,
       c.City_name,
       ap.IATA_code,
       ap.Name AS Airport_name
FROM   AIRPORT ap
JOIN   CITY c ON ap.City_id = c.City_id
ORDER BY c.Country ASC;

