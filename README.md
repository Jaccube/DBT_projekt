# Dokumentácia k implementácii ETL procesu v Snowflake

## 1. Úvod a popis zdrojových dát

### 1.1 Krátke vysvetlenie témy, typ dát a účel analýzy

V rámci tohto projektu som sa rozhodol analyzovať údaje z predajov hudobných nahrávok. Cieľom je zistiť, **ktorí umelci** a **ktoré albumy** prinášajú najväčší zisk, aký je **trend predajov** v čase a ďalšie dôležité metriky súvisiace s predajmi skladieb.
Dáta obsahujú **informácie o umelcoch, albumoch, skladbách**, ako aj **fakturačné údaje** o predaji (faktúry, riadky faktúr). Tieto údaje sa využijú na zostavenie **hviezdicového (star) modelu** a následné analytické spracovanie.
![ERD schéma
](https://github.com/Jaccube/DBT_projekt/blob/main/ERD_pr.png?raw=true)

### 1.2 Základný popis každej tabuľky zo zdrojových dát

-   **Artist**
    
    -   Táto tabuľka obsahuje informácie o umelcoch. Každý umelec je identifikovaný unikátnym identifikátorom (`ArtistId`) a má meno (`Name`).
-   **Album**
    
    -   Táto tabuľka uchováva albumy, kde každý album má jedinečný identifikátor (`AlbumId`), názov (`Title`) a odkaz na umelca (`ArtistId`), ktorý je cudzím kľúčom na tabuľku **Artist**.
-   **MediaType**
    
    -   Táto tabuľka obsahuje rôzne typy médií, ktoré sú priradené k skladbám. Každý typ médií má unikátny identifikátor (`MediaTypeId`) a názov typu médií (`Name`).
-   **Genre**
    
    -   Táto tabuľka uchováva informácie o žánroch hudby. Každý žáner je identifikovaný unikátnym identifikátorom (`GenreId`) a názvom žánru (`Name`).
-   **Track**
    
    -   Táto tabuľka obsahuje skladby, kde každá skladba má jedinečný identifikátor (`TrackId`), názov skladby (`Name`), odkaz na album (`AlbumId`), typ médií (`MediaTypeId`), žáner (`GenreId`), skladateľa (`Composer`), dĺžku skladby v milisekundách (`Milliseconds`), veľkosť v bajtoch (`Bytes`) a cenu za jednotku (`UnitPrice`). Táto tabuľka má cudzí kľúč na tabuľky **Album**, **MediaType** a **Genre**.
-   **Playlist**
    
    -   Táto tabuľka obsahuje informácie o playlistoch. Každý playlist má unikátny identifikátor (`PlaylistId`) a názov (`Name`).
-   **PlaylistTrack**
    
    -   Táto tabuľka spája playlisty a skladby. Každý záznam obsahuje identifikátor playlistu (`PlaylistId`) a identifikátor skladby (`TrackId`). Tento záznam je primárnym kľúčom v kombinácii týchto dvoch identifikátorov a odkazuje na tabuľky **Playlist** a **Track**.
-   **Employee**
    
    -   Táto tabuľka obsahuje informácie o zamestnancoch. Každý zamestnanec má unikátny identifikátor (`EmployeeId`), priezvisko (`LastName`), meno (`FirstName`), titul (`Title`), odkaz na nadriadeného (`ReportsTo`), dátum narodenia (`BirthDate`), dátum nástupu do práce (`HireDate`), adresu (`Address`), mesto (`City`), štát (`State`), krajinu (`Country`), PSČ (`PostalCode`), telefón (`Phone`), fax (`Fax`) a email (`Email`). `ReportsTo` je cudzí kľúč na tabuľku **Employee**.
-   **Customer**
    
    -   Táto tabuľka obsahuje informácie o zákazníkoch. Každý zákazník má unikátny identifikátor (`CustomerId`), meno (`FirstName`), priezvisko (`LastName`), názov firmy (`Company`), adresu (`Address`), mesto (`City`), štát (`State`), krajinu (`Country`), PSČ (`PostalCode`), telefón (`Phone`), fax (`Fax`), email (`Email`) a odkaz na podporu (`SupportRepId`), ktorý je cudzím kľúčom na tabuľku **Employee**.
-   **Invoice**
    
    -   Táto tabuľka obsahuje faktúry. Každá faktúra má unikátny identifikátor (`InvoiceId`), odkaz na zákazníka (`CustomerId`), dátum faktúry (`InvoiceDate`), fakturačnú adresu (`BillingAddress`), mesto (`BillingCity`), štát (`BillingState`), krajinu (`BillingCountry`), PSČ (`BillingPostalCode`) a celkovú sumu faktúry (`Total`).
-   **InvoiceLine**
    
    -   Táto tabuľka obsahuje detaily o položkách na faktúrach. Každý záznam má unikátny identifikátor (`InvoiceLineId`), odkaz na faktúru (`InvoiceId`), odkaz na skladbu (`TrackId`), cenu za jednotku (`UnitPrice`) a množstvo (`Quantity`). Táto tabuľka má cudzí kľúč na tabuľky **Invoice** a **Track**.

## 2. Návrh dimenzionálneho modelu

### 2.1 Multi-dimenzionálny model typu hviezda

Pre účely analytického spracovania som navrhol **hviezdicovú schému**, kde mám **jednu faktovú tabuľku** a niekoľko **dimenzných tabuliek**:

- **Fact**: `factSales`  
- **Dimensions**: `Employee_dim`, `Customer_dim`, `Track_dim`, `Invoice_dim`, `Date_dim`  
 
  
  ![Star scheme
  ](https://github.com/Jaccube/DBT_projekt/blob/main/ERD_starscheme_pr.png?raw=true)

### 2.2 Popis tabuliek


-   **Employee_dim**
    
    -   Táto tabuľka obsahuje dimenziu zamestnancov. Uchováva jedinečné záznamy o zamestnancoch s informáciami ako identifikátor (`EmployeeId`), priezvisko (`LastName`), meno (`FirstName`), titul (`Title`), dátum narodenia (`BirthDate`), dátum nástupu do práce (`HireDate`), adresa (`Address`), mesto (`City`), štát (`State`), krajina (`Country`), PSČ (`PostalCode`), telefón (`Phone`), fax (`Fax`) a email (`Email`).
-   **Customer_dim**
    
    -   Táto tabuľka uchováva dimenziu zákazníkov. Obsahuje jedinečné záznamy o zákazníkoch s informáciami ako identifikátor (`CustomerId`), meno (`FirstName`), priezvisko (`LastName`), názov firmy (`Company`), adresa (`Address`), mesto (`City`), štát (`State`), krajina (`Country`), PSČ (`PostalCode`), telefón (`Phone`), fax (`Fax`) a email (`Email`).
-   **Track_dim**
    
    -   Táto tabuľka obsahuje dimenziu skladieb. Uchováva informácie o skladbách s jedinečnými identifikátormi (`TrackId`), názvom skladby (`Name`), albumom (`AlbumId`), typom média (`MediaTypeId`), žánrom (`GenreId`), skladateľom (`Composer`), dĺžkou skladby (`Milliseconds`), veľkosťou v bajtoch (`Bytes`), cenou za jednotku (`UnitPrice`), názvom albumu (`Album`), menom umelca (`Artist`), názvom média (`MediaType`) a názvom žánru (`Genre`).
-   **Invoice_dim**
    
    -   Táto tabuľka uchováva dimenziu faktúr. Obsahuje jedinečné záznamy o faktúrach s identifikátorom faktúry (`InvoiceId`), dátumom faktúry (`InvoiceDate`), fakturačnou adresou (`BillingAddress`), fakturačným mestom (`BillingCity`), fakturačným štátom (`BillingState`), fakturačnou krajinou (`BillingCountry`), fakturačným PSČ (`BillingPostalCode`) a celkovou sumou faktúry (`Total`).
-   **Date_dim**
    
    -   Táto tabuľka uchováva dimenziu dátumov, ktoré sú spojené s faktúrami. Pre každý záznam faktúry sa vytvára dátumová dimenzia s informáciami ako identifikátor (`idDate_dim`), timestamp (`Timestamp`), deň v mesiaci (`Day`), deň v týždni (`DayOfWeek`), názov dňa v týždni (`DayOfWeekString`), mesiac (`Month`), názov mesiaca (`MonthString`), rok (`Year`), týždeň v roku (`Week`) a štvrťrok (`Quarter`).
-   **FactSales**
    
    -   Táto tabuľka obsahuje faktické údaje o predaji, ktoré kombinujú informácie z faktúr, fakturačných položiek, zamestnancov a zákazníkov. Každý záznam obsahuje identifikátor položky faktúry (`InvoiceLineId`), identifikátor faktúry (`InvoiceId`), identifikátor skladby (`TrackId`), cenu za jednotku (`UnitPrice`), množstvo (`Quantity`), identifikátor zamestnanca (`Employee_EmployeeId`), identifikátor zákazníka (`Customer_CustomerId`) a identifikátor dátumu (`Date_dim_idDate_dim`).

## 3. ETL proces v nástroji Snowflake

### 3.1 Hlavné kroky ETL procesu

1. **Extract**: Načítanie zdrojových dát z externého systému alebo CSV súborov do staging tabuliek v Snowflake.  
2. **Transform**:  
   - Vyčistenie a obohatenie dát (napr. spracovanie chýbajúcich hodnôt, formátovanie dátumov).  
   - Vytvorenie dimenzií  a faktovej tabuľky (FactSales) v Snowflake.    
3. **Load**: Vloženie vyčistených a transformovaných dát do finálnych **dim** a **fact** tabuliek.

### 3.2 Hlavné SQL príkazy pre ETL 
### Extract
```sql
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
```



1. **Vytvorenie a naplnenie Employee_dim**:
```sql
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
```
2. **Vytvorenie a naplnenie Customer_dim**:
```sql
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
```
3. **Vytvorenie a naplnenie Track_dim**:
```sql
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
   ```
4. **Vytvorenie a naplnenie Invoice_dim**:
```sql
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
 ```
5. **Vytvorenie a naplnenie Date_dim**:
```sql
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
 ```
 6. **Vytvorenie a naplnenie FactSales**:
```sql
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
 ```
###  3.3 Load
```sql
DROP TABLE Artist;
DROP TABLE Album;
DROP TABLE Track;
DROP TABLE Genre;
DROP TABLE MediaType;
DROP TABLE Employee;
DROP TABLE Customer;
DROP TABLE Playlist;
DROP TABLE PlaylistTrack;
DROP TABLE Invoice;
DROP TABLE InvoiceLine;
 ```

### 5 vizualizácií s krátkym popisom

![](https://github.com/Jaccube/DBT_projekt/blob/main/grafy_dbt.png?raw=true)
Dashboard obsahuje 5 vizualizácií, ktoré poskytujú štruktúrovaný pohľad na dôležité metriky a trendy týkajúce sa predaja hudobných albumov, skladieb a umelcov. Tieto vizualizácie odpovedajú na kľúčové otázky a pomáhajú lepšie pochopiť preferencie poslucháčov a ich nákupné správanie.

----------

**Graf 1: Najpredávanejšie albumy**  
Tento graf zobrazuje 10 najpredávanejších albumov zoradených podľa celkového obratu (TOTALREVENUE).  
Z grafu vyplýva, že album _Battlestar Galactica (Classic), Season 1_ výrazne prevyšuje ostatné albumy v obratoch. Táto vizualizácia poskytuje prehľad o tom, ktoré albumy sú medzi poslucháčmi najpopulárnejšie a môžu byť využité na propagáciu či vytváranie podobného obsahu.

```sql
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
 ```

**Graf 2: Najpredávanejšie skladby podľa umelcov**  
Vizualizácia znázorňuje top skladby od jednotlivých umelcov podľa ich celkových tržieb.  
Najviac zárobkových skladieb patrí interpretovi _The Office_, nasledujú _Heroes_ a _Iron Maiden_. Tieto dáta poskytujú široký pohľad na to, ktorí umelci dominujú trhu so skladbami a ktoré skladby oslovujú široké publikum.

```sql
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
 ```

**Graf 3: Najpredávanejší umelci podľa obratu**  
Tento graf sumarizuje umelcov zoradených podľa celkového obratu generovaného ich hudobnými dielami.  
Najvyšší obrat dosiahol umelec s ID _139_. Táto vizualizácia poskytuje informácie o najziskovejších umelcoch, ktorí dominujú na trhu a môžu byť prioritizovaní v marketingových stratégiách.

```sql
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
 ```

**Graf 4: Najpredávanejšie skladby v rámci albumov**  
Graf ukazuje skladby, ktoré dominujú v rámci svojich albumov podľa celkových predajov.  
Najvyšší predaj dosiahla skladba s ID _0.990_, čo naznačuje jej vysokú popularitu. Ostatné skladby z toho istého albumu vykazujú nižšie predaje, čo poskytuje užitočný pohľad na preferencie poslucháčov.

```sql
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
 ```

**Graf 5: Trend predaja albumov v čase**  
Tento graf sleduje vývoj predaja albumov v priebehu rokov.  
Z grafu vyplýva, že najvýraznejšie predaje boli zaznamenané okolo roku _1980_, zatiaľ čo následne došlo k poklesu. Tento trend poskytuje prehľad o zmenách v preferenciách poslucháčov v rôznych obdobiach a pomáha predpovedať budúce trendy.

```sql
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
 ```

----------

Dashboard poskytuje komplexný prehľad o predaji hudobných albumov, skladieb a analytický pohľad na úspechy jednotlivých umelcov. Vizualizácie sú dôležité pre tvorbu stratégií zameraných na predaj a marketing v hudobnom priemysle. 
  

autor: Jakub Šmondrk
  

   





