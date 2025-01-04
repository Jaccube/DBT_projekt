GRAF 1
SELECT 
    t.Album AS AlbumName,
    SUM(fs.Quantity * fs.UnitPrice) AS TotalRevenue
FROM 
    FactSales fs
JOIN 
    Track_dim t 
    ON fs.TrackId = t.TrackId
GROUP BY 
    t.Album
ORDER BY 
    TotalRevenue DESC
LIMIT 10;

GRAF 2
SELECT 
    t.Artist AS ArtistName,
    t.Name AS TrackName,
    SUM(fs.Quantity * fs.UnitPrice) AS TotalRevenue
FROM 
    FactSales fs
JOIN 
    Track_dim t 
    ON fs.TrackId = t.TrackId
GROUP BY 
    t.Artist, t.Name
ORDER BY 
    TotalRevenue DESC
LIMIT 10;

GRAF 3
SELECT 
    t.Artist AS ArtistName,
    SUM(fs.Quantity * fs.UnitPrice) AS TotalRevenue
FROM 
    FactSales fs
JOIN 
    Track_dim t 
    ON fs.TrackId = t.TrackId
GROUP BY 
    t.Artist
ORDER BY 
    TotalRevenue DESC
LIMIT 10;

GRAF 4
SELECT
      t.Album AS AlbumName,
      t.Name AS TrackName,
      SUM(fs.Quantity * fs.UnitPrice) AS TotalRevenue 
FROM
      FactSales fs 
JOIN
      Track_dim t      
      ON fs.TrackId = t.TrackId 
GROUP BY
      t.Album, t.Name 
ORDER BY
      t.Album, TotalRevenue DESC;
      
GRAF 5
SELECT 
    d.Year,
    d.MonthString,
    t.Album AS AlbumName,
    SUM(fs.Quantity * fs.UnitPrice) AS TotalRevenue
FROM 
    FactSales fs
JOIN 
    Track_dim t 
    ON fs.TrackId = t.TrackId
JOIN 
    Date_dim d 
    ON fs.Date_dim_idDate_dim = d.idDate_dim
GROUP BY 
    d.Year, d.MonthString, t.Album
ORDER BY 
    d.Year, d.MonthString, TotalRevenue DESC;
