
USE SkyTrackDB;



SELECT f.Flight_no,
       o.Name  AS Origin_airport,
       d.Name  AS Destination_airport,
       m.Model AS Aircraft_model,
       COUNT(DISTINCT b.Passenger_id) AS Total_passengers
FROM   FLIGHT f
JOIN   AIRPORT o        ON f.Origin_airport_id      = o.Airport_id
JOIN   AIRPORT d        ON f.Destination_airport_id = d.Airport_id
JOIN   AIRCRAFT a       ON f.Aircraft_id            = a.Aircraft_id
JOIN   AIRCRAFT_MODEL m ON a.Model_id               = m.Model_id
LEFT JOIN BOOKING b     ON b.Flight_id              = f.Flight_id
GROUP BY f.Flight_id, f.Flight_no, o.Name, d.Name, m.Model
ORDER BY f.Flight_no;




SELECT p.Passenger_id,
       p.Full_name,
       p.Email,
       p.Nationality
FROM   PASSENGER p
WHERE  NOT EXISTS (SELECT 1 FROM BOOKING b WHERE b.Passenger_id = p.Passenger_id);




SELECT f.Flight_no,
       SUM(b.Price_paid) AS Total_revenue
FROM   FLIGHT f
JOIN   BOOKING b ON b.Flight_id = f.Flight_id
GROUP BY f.Flight_id, f.Flight_no
HAVING SUM(b.Price_paid) > 500
ORDER BY Total_revenue DESC;




SELECT c.Full_name,
       c.Role,
       COUNT(fc.Flight_id) AS Total_flights
FROM   CREW_MEMBER c
JOIN   FLIGHT_CREW fc ON fc.Crew_id = c.Crew_id
GROUP BY c.Crew_id, c.Full_name, c.Role
HAVING COUNT(fc.Flight_id) > 1
ORDER BY Total_flights DESC, c.Full_name;




SELECT f.Flight_no,
       CAST(AVG(b.Price_paid) AS DECIMAL(10,2)) AS Avg_price_per_flight,
       CAST((SELECT AVG(Price_paid) FROM BOOKING) AS DECIMAL(10,2)) AS Overall_avg_price
FROM   FLIGHT f
JOIN   BOOKING b ON b.Flight_id = f.Flight_id
GROUP BY f.Flight_id, f.Flight_no
HAVING AVG(b.Price_paid) > (SELECT AVG(Price_paid) FROM BOOKING)
ORDER BY Avg_price_per_flight DESC;



SELECT TOP 1 WITH TIES
       f.Flight_no,
       o.Name AS Origin_airport,
       d.Name AS Destination_airport,
       COUNT(b.Booking_id) AS Total_bookings
FROM   FLIGHT f
JOIN   AIRPORT o ON f.Origin_airport_id      = o.Airport_id
JOIN   AIRPORT d ON f.Destination_airport_id = d.Airport_id
JOIN   BOOKING b ON b.Flight_id              = f.Flight_id
GROUP BY f.Flight_id, f.Flight_no, o.Name, d.Name
ORDER BY Total_bookings DESC;




SELECT Class,
       SUM(Price_paid)                        AS Total_revenue,
       COUNT(*)                               AS Number_of_bookings,
       CAST(AVG(Price_paid) AS DECIMAL(10,2)) AS Average_price,
       MAX(Price_paid)                        AS Highest_price,
       MIN(Price_paid)                        AS Lowest_price
FROM   BOOKING
GROUP BY Class
ORDER BY Total_revenue DESC;



SELECT p.Full_name AS Passenger_name,
       f.Flight_no,
       b.Booking_date
FROM   BOOKING b
JOIN   PASSENGER p ON b.Passenger_id = p.Passenger_id
JOIN   FLIGHT    f ON b.Flight_id    = f.Flight_id
WHERE  f.Status = 'Cancelled'
ORDER BY f.Flight_no, p.Full_name;




SELECT f.Flight_no,
       COUNT(fc.Crew_id) AS Total_crew,
       f.Departure_datetime
FROM   FLIGHT f
JOIN   FLIGHT_CREW fc ON fc.Flight_id = f.Flight_id
JOIN   CREW_MEMBER c  ON c.Crew_id    = fc.Crew_id
GROUP BY f.Flight_id, f.Flight_no, f.Departure_datetime
HAVING SUM(CASE WHEN c.Role = 'Pilot'            THEN 1 ELSE 0 END) >= 1
   AND SUM(CASE WHEN c.Role = 'Flight Attendant' THEN 1 ELSE 0 END) >= 1
ORDER BY f.Departure_datetime;




SELECT f.Flight_no,
       oc.City_name                     AS Origin_city,
       dc.City_name                     AS Destination_city,
       m.Model                          AS Aircraft_model,
       m.Manufacturer                   AS Aircraft_manufacturer,
       ISNULL(bk.Total_passengers, 0)   AS Total_passengers,
       ISNULL(cr.Total_crew, 0)         AS Total_crew,
       ISNULL(bk.Total_revenue, 0)      AS Total_revenue
FROM   FLIGHT f
JOIN   AIRPORT o        ON f.Origin_airport_id      = o.Airport_id
JOIN   CITY oc          ON o.City_id                = oc.City_id
JOIN   AIRPORT d        ON f.Destination_airport_id = d.Airport_id
JOIN   CITY dc          ON d.City_id                = dc.City_id
JOIN   AIRCRAFT a       ON f.Aircraft_id            = a.Aircraft_id
JOIN   AIRCRAFT_MODEL m ON a.Model_id               = m.Model_id
LEFT JOIN (SELECT Flight_id,
                  COUNT(DISTINCT Passenger_id) AS Total_passengers,
                  SUM(Price_paid)              AS Total_revenue
           FROM   BOOKING
           GROUP BY Flight_id) bk ON bk.Flight_id = f.Flight_id
LEFT JOIN (SELECT Flight_id,
                  COUNT(*) AS Total_crew
           FROM   FLIGHT_CREW
           GROUP BY Flight_id) cr ON cr.Flight_id = f.Flight_id
ORDER BY Total_revenue DESC;

