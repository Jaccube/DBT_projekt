# Dokumentácia k implementácii ETL procesu v Snowflake

## 1. Úvod a popis zdrojových dát

### 1.1 Krátke vysvetlenie témy, typ dát a účel analýzy

V rámci tohto projektu sme sa rozhodli analyzovať údaje z predajov hudobných nahrávok. Cieľom je zistiť, **ktorí umelci** a **ktoré albumy** prinášajú najväčší zisk, aký je **trend predajov** v čase a ďalšie dôležité metriky súvisiace s predajmi skladieb.
Dáta obsahujú **informácie o umelcoch, albumoch, skladbách**, ako aj **fakturačné údaje** o predaji (faktúry, riadky faktúr). Tieto údaje sa využijú na zostavenie **hviezdicového (star) modelu** a následné analytické spracovanie.
![ERD schéma
](https://github.com/Jaccube/DBT_projekt/blob/main/ERD_Smondrk_chinook.png?raw=true)

### 1.2 Základný popis každej tabuľky zo zdrojových dát

1. **Artist**  
   - Stĺpce: `ArtistId`, `Name`, …  
   - Obsahuje informácie o umelcoch (hudobných skupinách alebo jednotlivcoch).  
   - `ArtistId` je jedinečný identifikátor každého umelca.

2. **Album**  
   - Stĺpce: `AlbumId`, `Title`, `ArtistId`, …  
   - Obsahuje údaje o albumoch. Každý album je spojený s jedným umelcom.  
   - `ArtistId` je cudzí kľúč na tabuľku `Artist`.

3. **Track**  
   - Stĺpce: `TrackId`, `Name`, `AlbumId`, `MediaTypeId`, `GenreId`, `Composer`, `Milliseconds`, `Bytes`, `UnitPrice`, …  
   - Obsahuje údaje o skladbách (názov, dĺžka, žáner…).  
   - `AlbumId` odkazuje na konkrétny album.

4. **Invoice**  
   - Stĺpce: `InvoiceId`, `CustomerId`, `InvoiceDate`, `Total`, …  
   - Predstavuje faktúru s dátumom vystavenia, zákazníkom a celkovou sumou.  
   - Slúži ako hlavička predajných transakcií.

5. **InvoiceLine**  
   - Stĺpce: `InvoiceLineId`, `InvoiceId`, `TrackId`, `UnitPrice`, `Quantity`, …  
   - Obsahuje konkrétne predané položky (skladby) v rámci danej faktúry.  
   - `InvoiceId` je cudzí kľúč na tabuľku `Invoice`, `TrackId` je cudzí kľúč na tabuľku `Track`.

### 1.3 ERD diagram

Nižšie je jednoduchý ERD diagram ukazujúci základné vzťahy:


- `Artist` a `Album` majú vzťah 1:N (jeden umelec môže mať viac albumov).  
- `Album` a `Track` majú vzťah 1:N (jeden album môže obsahovať viac skladieb).  
- `Invoice` a `InvoiceLine` majú vzťah 1:N (jedna faktúra môže mať viac riadkov).  
- `Track` a `InvoiceLine` majú vzťah 1:N (jedna skladba sa môže objaviť vo viacerých riadkoch faktúry, v rôznych faktúrach).


## 2. Návrh dimenzionálneho modelu

### 2.1 Multi-dimenzionálny model typu hviezda

Pre účely OLAP (analytické spracovanie) sme navrhli **hviezdicovú (star) schému**, kde máme **jednu faktovú tabuľku** a niekoľko **dimenzných tabuliek**:

- **Fact**: `factSales`  
- **Dimensions**:  
  - `dimDate` (časové údaje)  
  - `dimArtist` (umelci)  
  - `dimAlbum` (albumy)  
  - `dimTrack` (skladby)  
  - `dimCustomer` (zákazníci)  
  
  ![Star scheme
  ](https://github.com/Jaccube/DBT_projekt/blob/main/ERD_StarScheme_Smondrk.png?raw=true)

### 2.2 Popis tabuliek

#### Faktová tabuľka: `factSales`

- **Kľúče**:  
  - `SalesKey` (surrogate key, jedinečný identifikátor záznamu vo fakte)  
  - `DateKey` (odkaz na `dimDate`)  
  - `ArtistKey` (odkaz na `dimArtist`)  
  - `AlbumKey` (odkaz na `dimAlbum`)  
  - `TrackKey` (odkaz na `dimTrack`)  
  - `CustomerKey` (odkaz na `dimCustomer`)  
- **Hlavné metriky**:  
  - `Quantity` (počet predaných kusov skladby)  
  - `UnitPrice` (cena za kus)  
  - `Revenue` (celkový príjem za predanú skladbu – `Quantity * UnitPrice`)

#### Dimenzia: `dimDate` (SCD Typ 0)

- Uchováva údaje o dátumoch (deň, mesiac, rok, štvrťrok, deň v týždni, …).  
- SCD Typ 0 znamená, že dáta sa nemenia, len rozširujú o nové dátumy.

#### Dimenzia: `dimArtist` (SCD Typ 1)

- Obsahuje informácie o umelcovi (Name, prípadne ďalšie atribúty).  
- SCD Typ 1: ak je potrebné meniť názov umelca, starý sa prepíše novým (história sa neuchováva).

#### Dimenzia: `dimAlbum` (SCD Typ 0 alebo 1)

- Obsahuje názov albumu, prípadne žáner albumu, rok vydania, atď.  
- Väčšinou sa názov albumu nemení, takže SCD0 alebo SCD1.

#### Dimenzia: `dimTrack` (SCD Typ 0)

- Obsahuje podrobnosti o skladbe (názov, dĺžka, žáner, …).  
- SCD0, lebo typicky názov skladby, dĺžka atď. sa nemenia.

#### Dimenzia: `dimCustomer` (SCD Typ 1 alebo 2)

- Obsahuje údaje o zákazníkovi (meno, prípadne adresa, email).  
- Ak chceme uchovávať históriu zmien adries, je to SCD2. Ak nám stačí prepísať starú adresu, je to SCD1.  

V našom zjednodušenom modeli môže byť `dimCustomer` spracovaná ako SCD1.

## 3. ETL proces v nástroji Snowflake

### 3.1 Hlavné kroky ETL procesu

1. **Extract**: Načítanie zdrojových dát (Artist, Album, Track, Invoice, InvoiceLine) z externého systému alebo CSV súborov do staging tabuliek v Snowflake.  
2. **Transform**:  
   - Vyčistenie a obohatenie dát (napr. spracovanie chýbajúcich hodnôt, formátovanie dátumov).  
   - Vytvorenie dimenzií (dimArtist, dimAlbum, dimTrack, dimDate, dimCustomer) a faktovej tabuľky (factSales) v Snowflake.  
   - Logika na generovanie surrogate key, výpočet `Revenue = Quantity * UnitPrice`, rozdelenie date/time.  
3. **Load**: Vloženie vyčistených a transformovaných dát do finálnych **dim** a **fact** tabuliek.

### 3.2 Hlavné SQL príkazy pre ETL

Príklad (zjednodušená verzia):


1. **Vytvorenie a naplnenie dimenzií**:
   ```sql
   CREATE OR REPLACE TABLE dimArtist AS
   SELECT DISTINCT
       a.ArtistId AS ArtistKey,
       a.Name     AS ArtistName
   FROM artist_staging a;
2. **Vytvorenie a naplnenie dimAlbum**:
	  ```sql
   CREATE OR REPLACE TABLE dimAlbum AS
   SELECT DISTINCT
       al.AlbumId AS AlbumKey,
       al.Title   AS AlbumTitle
   FROM album_staging al;
3. **Vytvorenie a naplnenie dimDate**:
	  ```sql
   CREATE OR REPLACE TABLE dimDate AS
   SELECT DISTINCT
       TO_VARCHAR(i.InvoiceDate, 'YYYYMMDD') AS DateKey,
       CAST(i.InvoiceDate AS DATE)           AS FullDate,
       EXTRACT(YEAR    FROM i.InvoiceDate)   AS Year,
       EXTRACT(QUARTER FROM i.InvoiceDate)   AS Quarter,
       EXTRACT(MONTH   FROM i.InvoiceDate)   AS Month,
       EXTRACT(DAY     FROM i.InvoiceDate)   AS DayOfMonth,
       EXTRACT(DOW     FROM i.InvoiceDate)   AS DayOfWeek
   FROM invoice_staging i
   WHERE i.InvoiceDate IS NOT NULL;
4. **Vytvorenie a naplnenie factsales**:
	  ```sql
   CREATE OR REPLACE TABLE factSales AS 
   SELECT il.InvoiceLineId AS SalesKey, 
   TO_VARCHAR(i.InvoiceDate, 'YYYYMMDD') AS DateKey, 
   a.ArtistId AS ArtistKey, al.AlbumId AS AlbumKey,
    t.TrackId AS TrackKey, i.CustomerId AS CustomerKey, 
    il.Quantity AS Quantity, il.UnitPrice AS UnitPrice,
     il.Quantity * il.UnitPrice AS Revenue 
    FROM invoice_staging i 
   JOIN invoiceline_staging il ON i.InvoiceId = il.InvoiceId 
   JOIN track_staging t ON il.TrackId = t.TrackId 
   JOIN album_staging al ON t.AlbumId = al.AlbumId
   JOIN artist_staging a ON al.ArtistId = a.ArtistId 
   WHERE i.InvoiceDate IS NOT NULL;
   ## 4. Vizualizácia dát

### 4. 5 vizualizácií s krátkym popisom

![](https://github.com/Jaccube/DBT_projekt/blob/main/grafy.png?raw=true)
1. **Najpredávanejší umelci podľa obratu**  
   - **Čo zobrazuje**: Usporiadaný zoznam umelcov (osi X = umelec, osi Y = celkový obrat).  
   - **Otázka**: „Ktorí umelci generujú najväčší obrat?“  

2. **Najpredávanejšie albumy**  
   - **Čo zobrazuje**: Podiel albumov na celkovom predaji (napr. sumár Revenue alebo Quantity).  
   - **Otázka**: „Ktorý album má najväčší podiel na predaji?“  

3. **Vývoj predaja v čase**  
   - **Čo zobrazuje**: Trend predaja (Revenue alebo Quantity) podľa mesiaca/roka.  
   - **Otázka**: „Ako sa mení predaj (napr. mesačne)? Sú tam sezónne výkyvy?“  

4. **Detaily predaja pre konkrétne albumy**  
   - **Čo zobrazuje**: Predaje jednotlivých skladieb (Track) patriacich do vybraného albumu.  
   - **Otázka**: „Ktoré skladby z jedného albumu sú najobľúbenejšie (podľa obratu alebo počtu predaných kusov)?“  

5. **Výkon umelcov v rôznych časových obdobiach**  
   - **Čo zobrazuje**: Dvojrozmerná matica – jeden rozmer je umelec, druhý rozmer je obdobie (napr. mesiac). Hodnota = Revenue.  
   - **Otázka**: „Ktorí umelci sa presadzujú v ktorých mesiacoch, prípadne sú tam zaujímavé trendy?“  
  

   





