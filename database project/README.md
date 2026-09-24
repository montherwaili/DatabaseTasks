# SkyTrack Airline System

## About the project

SkyTrack is a database I built for a small regional airline. It keeps track of the airports the airline flies to, the aircraft in the fleet, the flights, the passengers and their bookings, and which crew members work on each flight. I used Microsoft SQL Server for the implementation.

The files should be run in this order: first SkyTrack_DB.sql to create the database and tables, then SkyTrack_Indexes.sql, then SkyTrack_Insert_Data.sql for the sample data, then the Part 2 file (updates and deletes), and finally the three Part 3 query files (basic, medium and advanced). The two draw.io files contain the ERD and the mapping.

## ERD summary

The ERD has six entities. Airport is identified by its IATA code and has a name, city and country. Aircraft is identified by its registration number and has a model, manufacturer, capacity and year of manufacture. Flight has a flight number, departure and arrival times, and a status. Passenger is identified by national ID and has a full name, email, phone, nationality and date of birth. Booking stores the seat, class, price and booking date. Crew Member has a full name, role and license number.

For the relationships, one aircraft can be assigned to many flights, but each flight uses only one aircraft. Flight is connected to Airport twice, once for departure and once for arrival. I drew these as two separate relationships because a single relationship could not show which airport is the origin and which is the destination. A passenger can make many bookings and a flight can have many bookings, but each booking belongs to one passenger and one flight. Crew members and flights are many to many, since one crew member works on many flights and one flight has several crew members.

For participation, I made Flight total in its relationships with Aircraft and Airport, because a flight can't exist without an aircraft, an origin and a destination. Booking is also total on both sides, since every booking needs a passenger and a flight. Everything else is partial. For example, an airport can exist without any flights yet. I left the crew relationship partial on both sides because the requirements didn't say that a flight must have crew.

One decision I spent some time on was whether Booking should be an entity or just a relationship between Passenger and Flight. I went with an entity. The description talks about the booking as its own thing with its own details. It also says clearly that the crew relationship is many to many but doesn't say that about bookings. Giving it its own ID also means the same passenger can book the same flight again, for example after cancelling.

## Mapping decisions

For every one to many relationship I put the foreign key on the many side, since that's the only side where a single value makes sense. So Flight holds the aircraft ID, the origin airport ID and the destination airport ID. Booking holds the passenger ID and the flight ID. These foreign keys are NOT NULL because of the total participation. For the crew relationship I created a new table, FLIGHT_CREW, that has only the flight ID and the crew ID, and the two together make the primary key.

During normalization everything was already fine for 1NF and 2NF. All the values are atomic, and the only composite key is in FLIGHT_CREW, which has no other columns, so partial dependency is not possible. For 3NF I found two transitive dependencies. The manufacturer depends on the model and not on the aircraft itself, so I moved model and manufacturer into a separate AIRCRAFT_MODEL table. In the same way, the country depends on the city, so I created a CITY table. That's why the final design has 9 tables instead of 7.

In the physical schema the assignment asked for all IDs to be IDENTITY, so I added an ID column to every table and used it as the primary key. The original keys like flight number, registration number, national ID, email and license number became UNIQUE and NOT NULL so they still can't be repeated.

## Errors I faced and how I fixed them

The first problem was when creating the tables. SQL Server refused to create the Flight table because both foreign keys to Airport had ON DELETE CASCADE. It gave error 1785 about multiple cascade paths, since it doesn't allow two cascade paths from the same table. I fixed it by keeping cascade on the origin airport and using NO ACTION on the destination airport. The side effect is that you can't delete an airport while it is still the destination of a flight. I tested this and got error 547, which is what I expected.

The second problem came after I ran my test script. It inserted test data and then rolled everything back, but the IDENTITY counters didn't go back to 1. I reset them using DBCC CHECKIDENT. I also wrote the insert script so it finds the foreign keys by their real values, like the registration number or the IATA code, instead of typing the ID numbers directly. That way it works no matter what the IDs are.

I also wrote the dates in the format 2026-09-15 08:00:00. The normal format with a space can be read differently depending on the language setting of the server, and that could break the arrival after departure check.

For the deletes, when I tried to delete a passenger who had bookings, there was no error at all. Because of the cascade, SQL Server deleted the passenger together with all of his bookings. If the foreign key was NO ACTION it would have failed. I ran this one inside a transaction and rolled it back so I still have the data for the queries. I also had to be careful with the order of the delete tasks. Deleting a cancelled flight also removes its bookings, so I deleted flight SK110 first and then deleted a booking from a different cancelled flight, SK606.

## WHERE vs HAVING

The way I understand it, WHERE filters the rows before they are grouped, and HAVING filters the groups after they are made. That's why you can't write something like WHERE SUM(price) > 500. At the moment WHERE runs, the sum hasn't been calculated yet. HAVING is there exactly for conditions on COUNT, SUM, AVG and so on. In my query for flights with revenue above 500, I used GROUP BY on the flight and then HAVING SUM(Price_paid) > 500. If I wanted to leave out cancelled flights too, that part would go in the WHERE because it's about single rows.

## The most useful query

I think the most useful one is the last query, the full flight summary. It shows for each flight the origin and destination cities, the aircraft model and manufacturer, how many passengers booked, how many crew are on it, and the total revenue. It uses almost all the tables at once, and it's the kind of report someone running the airline would actually want to look at.

It was also the hardest one. My first idea was to join Booking and Flight_Crew directly to Flight, but then the numbers came out wrong. Each booking gets repeated once for every crew member, so a flight with 3 bookings and 5 crew shows the revenue five times. I fixed it by counting the bookings and the crew separately in subqueries first, and then joining those results to the flights. I also used LEFT JOIN so flights with no bookings still show up with zero.
