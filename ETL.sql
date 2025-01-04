USE DATABASE SPARROW_CHINOOK;
USE WAREHOUSE SPARROW_WH;

CREATE TABLE Artist (
    ArtistId INT NOT NULL,
    Name VARCHAR(120),
    PRIMARY KEY (ArtistId)
);

CREATE TABLE Album (
    AlbumId INT NOT NULL,
    Title VARCHAR(160),
    ArtistId INT,
    PRIMARY KEY (AlbumId),
    FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId)
);

CREATE TABLE MediaType (
    MediaTypeId INT NOT NULL,
    Name VARCHAR(120),
    PRIMARY KEY (MediaTypeId)
);

CREATE TABLE Genre (
    GenreId INT NOT NULL,
    Name VARCHAR(120),
    PRIMARY KEY (GenreId)
);

CREATE TABLE Track (
    TrackId INT NOT NULL,
    Name VARCHAR(200),
    AlbumId INT,
    MediaTypeId INT,
    GenreId INT,
    Composer VARCHAR(220),
    Milliseconds INT,
    Bytes INT,
    UnitPrice DECIMAL(10, 2),
    PRIMARY KEY (TrackId),
    FOREIGN KEY (AlbumId) REFERENCES Album(AlbumId),
    FOREIGN KEY (MediaTypeId) REFERENCES MediaType(MediaTypeId),
    FOREIGN KEY (GenreId) REFERENCES Genre(GenreId)
);

CREATE TABLE Playlist (
    PlaylistId INT NOT NULL,
    Name VARCHAR(120),
    PRIMARY KEY (PlaylistId)
);

CREATE TABLE PlaylistTrack (
    PlaylistId INT NOT NULL,
    TrackId INT NOT NULL,
    PRIMARY KEY (PlaylistId, TrackId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId),
    FOREIGN KEY (TrackId) REFERENCES Track(TrackId)
);

CREATE TABLE Employee (
    EmployeeId INT NOT NULL,
    LastName VARCHAR(20),
    FirstName VARCHAR(20),
    Title VARCHAR(30),
    ReportsTo INT,
    BirthDate DATETIME,
    HireDate DATETIME,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    PRIMARY KEY (EmployeeId),
    FOREIGN KEY (ReportsTo) REFERENCES Employee(EmployeeId)
);

CREATE TABLE Customer (
    CustomerId INT NOT NULL,
    FirstName VARCHAR(40),
    LastName VARCHAR(40),
    Company VARCHAR(80),
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    SupportRepId INT,
    PRIMARY KEY (CustomerId),
    FOREIGN KEY (SupportRepId) REFERENCES Employee(EmployeeId)
);

CREATE TABLE Invoice (
    InvoiceId INT NOT NULL,
    CustomerId INT,
    InvoiceDate DATETIME,
    BillingAddress VARCHAR(70),
    BillingCity VARCHAR(40),
    BillingState VARCHAR(40),
    BillingCountry VARCHAR(40),
    BillingPostalCode VARCHAR(10),
    Total DECIMAL(10, 2),
    PRIMARY KEY (InvoiceId),
    FOREIGN KEY (CustomerId) REFERENCES Customer(CustomerId)
);

CREATE TABLE InvoiceLine (
    InvoiceLineId INT NOT NULL,
    InvoiceId INT,
    TrackId INT,
    UnitPrice DECIMAL(10, 2),
    Quantity INT,
    PRIMARY KEY (InvoiceLineId),
    FOREIGN KEY (InvoiceId) REFERENCES Invoice(InvoiceId),
    FOREIGN KEY (TrackId) REFERENCES Track(TrackId)
);  

COPY INTO album
FROM @sparrow_stage/album.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO artist
FROM @sparrow_stage/artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO customer
FROM @sparrow_stage/customer.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO employee
FROM @sparrow_stage/employee.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
on_Error="continue";
COPY INTO genre
FROM @sparrow_stage/genre.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO invoice
FROM @sparrow_stage/invoice.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO invoiceline
FROM @sparrow_stage/invoiceline.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO mediatype
FROM @sparrow_stage/mediatype.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO playlist
FROM @sparrow_stage/playlist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO playlisttrack
FROM @sparrow_stage/playlisttrack.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO track
FROM @sparrow_stage/track.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);



CREATE TABLE Employee_dim AS
SELECT DISTINCT
    e.EmployeeId AS EmployeeId,
    e.LastName AS LastName,
    e.FirstName AS FirstName,
    e.Title AS Title,
    e.BirthDate AS BirthDate,
    e.HireDate AS HireDate,
    e.Address AS Address,
    e.City AS City,
    e.State AS State,
    e.Country AS Country,
    e.PostalCode AS PostalCode,
    e.Phone AS Phone,
    e.Fax AS Fax,
    e.Email AS Email
FROM Employee AS e;

CREATE TABLE Customer_dim AS
SELECT DISTINCT
    c.CustomerId AS CustomerId,
    c.FirstName AS FirstName,
    c.LastName AS LastName,
    c.Company AS Company,
    c.Address AS Address,
    c.City AS City,
    c.State AS State,
    c.Country AS Country,
    c.PostalCode AS PostalCode,
    c.Phone AS Phone,
    c.Fax AS Fax,
    c.Email AS Email
FROM Customer AS c;

CREATE TABLE Track_dim AS
SELECT DISTINCT
    t.TrackId AS TrackId,
    t.Name AS Name,
    t.AlbumId AS AlbumId,
    t.MediaTypeId AS MediaTypeId,
    t.GenreId AS GenreId,
    t.Composer AS Composer,
    t.Milliseconds AS Milliseconds,
    t.Bytes AS Bytes,
    t.UnitPrice AS UnitPrice,
    al.Title AS Album,
    ar.Name AS Artist,
    mt.Name AS MediaType,
    g.Name AS Genre
FROM Track AS t
LEFT JOIN Album AS al ON t.AlbumId = al.AlbumId
LEFT JOIN Artist AS ar ON al.ArtistId = ar.ArtistId
LEFT JOIN MediaType AS mt ON t.MediaTypeId = mt.MediaTypeId
LEFT JOIN Genre AS g ON t.GenreId = g.GenreId;

CREATE TABLE Invoice_dim AS
SELECT DISTINCT
    i.InvoiceId AS InvoiceId,
    i.InvoiceDate AS InvoiceDate,
    i.BillingAddress AS BillingAddress,
    i.BillingCity AS BillingCity,
    i.BillingState AS BillingState,
    i.BillingCountry AS BillingCountry,
    i.BillingPostalCode AS BillingPostalCode,
    i.Total AS Total
FROM Invoice AS i;

CREATE TABLE Date_dim AS
SELECT DISTINCT
    i.InvoiceId AS idDate_dim,
    i.InvoiceDate AS Timestamp,
    EXTRACT(DAY FROM i.InvoiceDate) AS Day,
    EXTRACT(DAYOFWEEK FROM i.InvoiceDate) AS DayOfWeek,
    CASE EXTRACT(DAYOFWEEK FROM i.InvoiceDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS DayOfWeekString,
    EXTRACT(MONTH FROM i.InvoiceDate) AS Month,
    TO_CHAR(i.InvoiceDate, 'Month') AS MonthString,
    EXTRACT(YEAR FROM i.InvoiceDate) AS Year,
    EXTRACT(WEEK FROM i.InvoiceDate) AS Week,
    CEIL(EXTRACT(MONTH FROM i.InvoiceDate) / 3) AS Quarter
FROM Invoice AS i;

CREATE TABLE FactSales AS
SELECT
    il.InvoiceLineId AS InvoiceLineId,
    il.InvoiceId AS InvoiceId,
    il.TrackId AS TrackId,
    il.UnitPrice AS UnitPrice,
    il.Quantity AS Quantity,
    e.EmployeeId AS Employee_EmployeeId,
    c.CustomerId AS Customer_CustomerId,
    i.InvoiceId AS Date_dim_idDate_dim
FROM InvoiceLine AS il
LEFT JOIN Invoice AS i ON il.InvoiceId = i.InvoiceId
LEFT JOIN Customer AS c ON i.CustomerId = c.CustomerId
LEFT JOIN Employee AS e ON c.SupportRepId = e.EmployeeId;