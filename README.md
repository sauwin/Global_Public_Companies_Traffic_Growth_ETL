# ELT proces datasetu Global Public Companies Traffic Growth

Tento repozitár predstavuje implementáciu ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star Schema na základe Global Public Companies Traffic 
Growth datasetu. Projekt je zameraný na obchodnú analýzu tempa rastu Alza.sk, návratnosti investícií, porovnanie s lokálnymi aj globálnymi konkurentmi. Hodnotenie 
rastu spoločnosti na základe online výsledkov a porovnania s lídrami v odvetví.

---
## **1.Úvod a popis zdrojových dát**

**Prečo sme si vybrali dataset:**

Dataset poskytuje aktuálne dáta o návštevnosti, zdrojoch návštevnosti, angažovanosti používateľov a demografii, čo umožňuje analyzovať 
rast spoločností 
a ich online výkonnosť.

**Biznis proces, ktorý dáta podporujú:**

- Analýza rastu návštevnosti a angažovanosti.
- Hodnotenie návratnosti investícií do marketingu.
- Benchmarking konkurencie. Detekcia trendov a rizík v dopyte.

**Typy údajov:**

- Číselné (Float, Number) - návštevnosť, bounce rate, pages per visit, duration, rank.
- Kategórie (Varchar) - site, kategória, hlavná kategória.
- Demografické údaje (Varchar) - vekové skupiny, pohlavie.
- Časové údaje (Number) - mesiac, rok.

**Predstavenie tabuľky GLOBAL_GROWTH:**

Obsahuje mesačné údaje o návštevnosti webov, rozdelené podľa platformy (desktop/mobile), kanálov (organic, paid, social, mail, referrals), 
a demografie 
používateľov. Obsahuje aj globálny a kategóriový ranking, metriky engagementu (pages per visit, bounce rate, visit duration) a celkovú 
návštevnosť. Slúži na 
monitorovanie rastu, porovnanie s konkurenciou a hodnotenie efektívnosti online marketingu.

### **1.1 Dátová architektúra. ERD diagram**

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/erd_scheme.png" alt="ERD Scheme">
    <br>
    <em>Obrázok 1 Entitno-relačná schéma GLOBAL GROWTH</em>
</p>

---
## **2.Návrh dimenzionálneho modelu**

Star schema obsahuje 3 tabuľky faktov a 4 tabuľky dimenzií.

Faktové tabuľky:
- fact_rank
- fact_audience_share
- fact_visits

Dimenzné tabuľky:
- dim_site
- dim_category
- dim_date
- dim_age_group

### **Faktové tabuľky:**



### **Dimenzné tabuľky:**

### dim_site
Obsah údajov:
- site VARCHAR(60)
Vzťah k fact tabuľkám:
- 1:N ku všetkým faktom
Typ SCD:
- Typ 2

### dim_category
Obsah údajov:
- main_category VARCHAR(60)
- site_category VARCHAR(120)
Vzťah k fact tabuľkám:
- 1:N k fact_visits, fact_rank
Typ SCD:
- Typ 1

### dim_date
Obsah údajov:
- year INT
- month INT
Vzťah k fact tabuľkám:
- 1:N ku všetkým faktom
Typ SCD:
- Typ 0

### dim_age_group
Obsah údajov:
- label VARCHAR(6)
- age_from INT
- age_to INT
Vzťah k fact tabuľkám:
- 1:N k fact_audience_share
Typ SCD:
- Typ 0

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/star_scheme.png" alt="Star Scheme">
    <br>
    <em>Obrázok 2 Schéma hviezdy pre GLOBAL GROWTH</em>
</p>

---
## **3.ELT proces v Snowflake**

Dataset bol získaný zo Snowflake Marketplace:
Databáza: GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH
Schéma: DATAFEEDS
Tabuľka: GLOBAL_GROWTH

### **Extract**

Keďže Snowflake Marketplace poskytuje dáta už priamo uložené v Snowflake, nie je potrebné sťahovať CSV alebo JSON súbory.
Extract fáza spočíva v kopírovaní dát do staging tabuľky, ktorá slúži ako pracovná vrstva pre ďalšie spracovanie.

**Vytvorenie staging tabuľky:**

```sql
CREATE OR REPLACE TABLE table_staging AS
SELECT * FROM GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH.DATAFEEDS.GLOBAL_GROWTH;
```

### **Load**

V Load fáze sú dáta zo staging tabuľky načítané do dimenzných a faktových tabuliek hviezdicového modelu.

**Naplnenie tabuliek:**

**dim_site**
```sql
CREATE OR REPLACE TABLE dim_site AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY SITE) AS dim_siteId,
    SITE AS site
FROM table_staging;
```

**dim_category**
```sql
CREATE OR REPLACE TABLE dim_category AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY MAIN_CATEGORY, SITE_CATEGORY) AS dim_categoryId,
    MAIN_CATEGORY AS main_category,
    SITE_CATEGORY AS full_category
FROM table_staging;
```

**dim_date**
```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY year, month) AS dim_dateId,
    YEAR AS year,
    MONTH AS month
FROM table_staging;
```

**dim_age_group**
```sql
CREATE OR REPLACE TABLE dim_age_group AS
SELECT
    ROW_NUMBER() OVER (ORDER BY age_from) AS dim_ageGroupId,
    label,
    age_from,
    age_to
FROM (
    SELECT '18-24' AS label, 18 AS age_from, 24 AS age_to UNION ALL
    SELECT '25-34', 25, 34 UNION ALL
    SELECT '35-44', 35, 44 UNION ALL
    SELECT '45-54', 45, 54 UNION ALL
    SELECT '55-64', 55, 64 UNION ALL
    SELECT '65+', 65, NULL
);
```

**fact_rank**
```sql

```

**fact_audience_share**
```sql

```

**fact_visits**
```sql

```

### **Transform**

Transformačná fáza zahŕňa čistenie, deduplikáciu, typové konverzie a analytické výpočty.

Čistenie a deduplikácia:
- použitie SELECT DISTINCT
- odstránenie duplicitných kombinácií site + year + month

Typové konverzie:
- TOTAL_ESTIMATED_VISITS::INT
- DESKTOP_ESTIMATED_VISITS::INT
- MOBILEWEB_ESTIMATED_VISITS::INT

Tvorba dimenzií so správnym SCD typom:
- dim_date - SCD Typ 0
- dim_age_group - SCD Typ 0
- dim_category - SCD Typ 1
- dim_site - SCD Typ 2 

---
## **4.Vizualizácia dát**