

    CREATE DATABASE SkyTrackDB;


USE SkyTrackDB;


CREATE TABLE CITY (
    City_id     INT IDENTITY(1,1) NOT NULL,
    City_name   NVARCHAR(100)     NOT NULL,
    Country     NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_CITY PRIMARY KEY (City_id),
    CONSTRAINT UQ_CITY_Name_Country UNIQUE (City_name, Country)
);



CREATE TABLE AIRCRAFT_MODEL (
    Model_id      INT IDENTITY(1,1) NOT NULL,
    Model         NVARCHAR(50)      NOT NULL,
    Manufacturer  NVARCHAR(100)     NOT NULL,
    CONSTRAINT PK_AIRCRAFT_MODEL PRIMARY KEY (Model_id),
    CONSTRAINT UQ_AIRCRAFT_MODEL_Model UNIQUE (Model)
);



CREATE TABLE AIRPORT (
    Airport_id  INT IDENTITY(1,1) NOT NULL,
    IATA_code   CHAR(3)           NOT NULL,
    Name        NVARCHAR(150)     NOT NULL,
    City_id     INT               NOT NULL,
    CONSTRAINT PK_AIRPORT PRIMARY KEY (Airport_id),
    CONSTRAINT UQ_AIRPORT_IATA UNIQUE (IATA_code),
    CONSTRAINT FK_AIRPORT_CITY FOREIGN KEY (City_id)
        REFERENCES CITY (City_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);



CREATE TABLE AIRCRAFT (
    Aircraft_id          INT IDENTITY(1,1) NOT NULL,
    Registration_no      VARCHAR(20)       NOT NULL,
    Model_id             INT               NOT NULL,
    Total_capacity       INT               NOT NULL,
    Year_of_manufacture  INT               NULL,
    CONSTRAINT PK_AIRCRAFT PRIMARY KEY (Aircraft_id),
    CONSTRAINT UQ_AIRCRAFT_Registration UNIQUE (Registration_no),
    CONSTRAINT CK_AIRCRAFT_Capacity CHECK (Total_capacity > 0),
    CONSTRAINT FK_AIRCRAFT_MODEL FOREIGN KEY (Model_id)
        REFERENCES AIRCRAFT_MODEL (Model_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);



CREATE TABLE PASSENGER (
    Passenger_id  INT IDENTITY(1,1) NOT NULL,
    National_id   VARCHAR(20)       NOT NULL,
    Full_name     NVARCHAR(150)     NOT NULL,
    Email         VARCHAR(150)      NOT NULL,
    Phone         VARCHAR(20)       NULL,
    Nationality   NVARCHAR(60)      NOT NULL,
    DOB           DATE              NOT NULL,
    CONSTRAINT PK_PASSENGER PRIMARY KEY (Passenger_id),
    CONSTRAINT UQ_PASSENGER_NationalID UNIQUE (National_id),
    CONSTRAINT UQ_PASSENGER_Email UNIQUE (Email)
);



CREATE TABLE CREW_MEMBER (
    Crew_id     INT IDENTITY(1,1) NOT NULL,
    License_no  VARCHAR(30)       NOT NULL,
    Full_name   NVARCHAR(150)     NOT NULL,
    Role        VARCHAR(20)       NOT NULL,
    CONSTRAINT PK_CREW_MEMBER PRIMARY KEY (Crew_id),
    CONSTRAINT UQ_CREW_License UNIQUE (License_no),
    CONSTRAINT CK_CREW_Role CHECK (Role IN ('Pilot', 'Co-Pilot', 'Flight Attendant', 'Engineer'))
);



CREATE TABLE FLIGHT (
    Flight_id               INT IDENTITY(1,1) NOT NULL,
    Flight_no               VARCHAR(10)       NOT NULL,
    Departure_datetime      DATETIME          NOT NULL,
    Arrival_datetime        DATETIME          NOT NULL,
    Status                  VARCHAR(20)       NOT NULL
        CONSTRAINT DF_FLIGHT_Status DEFAULT ('Scheduled'),
    Aircraft_id             INT               NOT NULL,
    Origin_airport_id       INT               NOT NULL,
    Destination_airport_id  INT               NOT NULL,
    CONSTRAINT PK_FLIGHT PRIMARY KEY (Flight_id),
    CONSTRAINT UQ_FLIGHT_No UNIQUE (Flight_no),
    CONSTRAINT CK_FLIGHT_Status CHECK (Status IN ('Scheduled', 'Delayed', 'Cancelled', 'Completed')),
    CONSTRAINT CK_FLIGHT_Times CHECK (Arrival_datetime > Departure_datetime),
    CONSTRAINT FK_FLIGHT_AIRCRAFT FOREIGN KEY (Aircraft_id)
        REFERENCES AIRCRAFT (Aircraft_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FLIGHT_ORIGIN FOREIGN KEY (Origin_airport_id)
        REFERENCES AIRPORT (Airport_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
  

    CONSTRAINT FK_FLIGHT_DESTINATION FOREIGN KEY (Destination_airport_id)
        REFERENCES AIRPORT (Airport_id)
        ON DELETE NO ACTION ON UPDATE NO ACTION
);



CREATE TABLE BOOKING (
    Booking_id    INT IDENTITY(1,1) NOT NULL,
    Seat_no       VARCHAR(5)        NOT NULL,
    Class         VARCHAR(10)       NOT NULL,
    Price_paid    DECIMAL(10,2)     NOT NULL,
    Booking_date  DATE              NOT NULL
        CONSTRAINT DF_BOOKING_Date DEFAULT (CAST(GETDATE() AS DATE)),
    Passenger_id  INT               NOT NULL,
    Flight_id     INT               NOT NULL,
    CONSTRAINT PK_BOOKING PRIMARY KEY (Booking_id),
    CONSTRAINT CK_BOOKING_Class CHECK (Class IN ('Economy', 'Business', 'First')),
    CONSTRAINT CK_BOOKING_Price CHECK (Price_paid > 0),
    CONSTRAINT FK_BOOKING_PASSENGER FOREIGN KEY (Passenger_id)
        REFERENCES PASSENGER (Passenger_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_BOOKING_FLIGHT FOREIGN KEY (Flight_id)
        REFERENCES FLIGHT (Flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);



CREATE TABLE FLIGHT_CREW (
    Flight_id  INT NOT NULL,
    Crew_id    INT NOT NULL,
    CONSTRAINT PK_FLIGHT_CREW PRIMARY KEY (Flight_id, Crew_id),
    CONSTRAINT FK_FLIGHT_CREW_FLIGHT FOREIGN KEY (Flight_id)
        REFERENCES FLIGHT (Flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_FLIGHT_CREW_CREW FOREIGN KEY (Crew_id)
        REFERENCES CREW_MEMBER (Crew_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

