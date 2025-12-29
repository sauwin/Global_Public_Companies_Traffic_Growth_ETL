# ELT proces datasetu Global Public Companies Traffic Growth

Tento repozitár predstavuje implementáciu ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star Schema na základe Global 
Public Companies Traffic Growth datasetu. Projekt je zameraný na obchodnú analýzu tempa rastu Alza.sk, návratnosti investícií, porovnanie
s lokálnymi aj globálnymi konkurentmi. Hodnotenie rastu spoločnosti na základe online výsledkov a porovnania s konkurentmi v odvetví.

---
## **1. Úvod a popis zdrojových dát**

**Prečo sme si vybrali dataset:**

Dataset poskytuje aktuálne dáta o návštevnosti, zdrojoch návštevnosti, angažovanosti používateľov a demografii, čo umožňuje analyzovať 
rast spoločností a ich online výkonnosť.

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
a demografie používateľov. Obsahuje aj globálny a kategóriový ranking, metriky engagementu (pages per visit, bounce rate, visit duration) 
a celkovú návštevnosť. Slúži na monitorovanie rastu, porovnanie s konkurenciou a hodnotenie efektívnosti online marketingu.

### **1.1 ERD diagram**

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/erd_scheme.png" alt="ERD Scheme">
    <br>
    <em>Obrázok 1 Entitno-relačná schéma GLOBAL GROWTH</em>
</p>

---
## **2. Návrh dimenzionálneho modelu**

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

### fact_rank
Obsah údajov:
- fact_rankId INT Primary key
- global_rank INT
- cz_sk_rank INT
- global_category_rank INT
- cz_sk_category_rank INT
- siteId INT Foreign key
- categoryId INT Foreign key
- dateId INT Foreign key

Vzťah k dim tabuľkám:
- 1:N dim_category
- 1:N dim_site
- 1:N dim_date

Tabuľka uchováva globálne a regionálne (CZ/SK) poradia webov, vrátane celkového aj kategóriového rankingu. Slúži ako centrálna faktová 
tabuľka pre analytické výpočty a porovnávanie výkonnosti webov v jednotlivých kategóriách a časových obdobiach.

### fact_audience_share
Obsah údajov:
- fact_audienceShareId INT Primary key
- total_rank_share FLOAT
- siteId INT Foreign key
- dateId INT Foreign key
- ageGroupId INt Foreign key

Vzťah k dim tabuľkám:
- 1:N dim_site
- 1:N dim_date
- 1:N dim_age_group

Tabuľka zachytáva mieru zastúpenia používateľov jednotlivých vekových kategórií na konkrétnych webových stránkach a umožňuje analyzovať 
demografické rozdelenie návštevnosti v čase.

### fact_visits
Obsah údajov:
- fact_visitsId INT Primary key
- total_visits INT
- unique_estimated_visits INT
- desktop_estimated_visits INT
- mobileweb_estimated_visits INT
- siteId INT Foreign key
- dateId INT Foreign key
- categoryId INT Foreign key

Vzťah k dim tabuľkám:
- 1:N dim_category
- 1:N dim_site
- 1:N dim_date

Tabuľka zaznamenáva celkový počet návštev, odhadovaný počet unikátnych návštev a rozdelenie návštevnosti podľa zariadení (desktop a 
mobileweb). Slúži na analýzu výkonnosti webov v rámci jednotlivých kategórií a časových období.

### **Dimenzné tabuľky:**

### dim_site
Obsah údajov:
- site VARCHAR(60)

Vzťah k fact tabuľkám:
- 1:N fact_rank
- 1:N fact_audience_share
- 1:N fact_visits

Typ SCD:
- Typ 2

Tabuľka uchováva názvy webových stránok a slúži ako spoločná dimenzia pre viaceré faktové tabuľky, čo umožňuje analyzovať rebríčky, 
návštevnosť a podiel publika pre jednotlivé weby.

### dim_category
Obsah údajov:
- main_category VARCHAR(60)
- full_category VARCHAR(120)

Vzťah k fact tabuľkám:
- 1:N fact_rank
- 1:N fact_visits

Typ SCD:
- Typ 1

Tabuľka uchováva hlavnú kategóriu a jej detailnejšie členenie, ktoré umožňuje analyzovať výkonnosť webov v rámci širších aj konkrétnych 
tematických oblastí.

### dim_date
Obsah údajov:
- year INT
- month INT

Vzťah k fact tabuľkám:
- 1:N fact_rank
- 1:N fact_audience_share
- 1:N fact_visits

Typ SCD:
- Typ 0

Tabuľka uchováva základné časové atribúty, ako rok a mesiac, ktoré umožňujú analyzovať trendy, sezónnosť a vývoj metrík v čase naprieč 
všetkými faktovými 
tabuľkami.

### dim_age_group
Obsah údajov:
- label VARCHAR(6)
- age_from INT
- age_to INT

Vzťah k fact tabuľkám:
- 1:N fact_audience_share

Typ SCD:
- Typ 0

Tabuľka definuje vekové intervaly používateľov prostredníctvom označenia skupiny a hraníc veku, čo umožňuje analyzovať podiel publika 
webových stránok z pohľadu 
demografie.

### **2.1 Matrix bus**

Na identifikáciu prepojení biznis procesov a dimenzií použili sme matrix bus

| **Business processes** | **Site** | **Category** | **Date** | **Age Group** |
|------------------------|----------|--------------|----------|---------------|
| **Site ranking**       | x        | x            | x        |               |
| **Web traffic**        | x        | x            | x        |               |
| **Audience**           | x        |              | x        | x             |

### **2.2 Star diagram**

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/star_scheme.png" alt="Star Scheme">
    <br>
    <em>Obrázok 2 Schéma hviezdy pre GLOBAL GROWTH</em>
</p>

---
## **3. ELT proces v Snowflake**

Dataset bol získaný zo Snowflake Marketplace:
Databáza: GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH
Schéma: DATAFEEDS
Tabuľka: GLOBAL_GROWTH

### **Extract**

Keďže Snowflake Marketplace poskytuje dáta už priamo uložené v Snowflake, nie je potrebné sťahovať CSV alebo JSON súbory.
Extract fáza spočíva v kopírovaní dát do staging tabuľky, ktorá slúži ako pracovná vrstva pre ďalšie spracovanie.
Dataset je dostupný na nasledujúcom odkaze: 

**https://app.snowflake.com/us-west-2/ekb34221/#/data/shared/SNOWFLAKE_DATA_MARKETPLACE/listing/GZT1ZA3NJL?originTab=databases&database=GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH**

#### **Vytvorenie staging tabuľky:**

```sql
CREATE OR REPLACE TABLE table_staging AS
SELECT * FROM GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH.DATAFEEDS.GLOBAL_GROWTH;
```

### **Load**

V Load fáze sú dáta zo staging tabuľky načítané do dimenzných a faktových tabuliek hviezdicového modelu.

#### **Naplnenie tabuliek:**

#### **dim_site**
```sql
CREATE OR REPLACE TABLE dim_site AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CLEAN_SITE) AS dim_siteId,
    CLEAN_SITE AS site
FROM (
    SELECT DISTINCT CLEAN_SITE
    FROM TABLE_STAGING
);
```
Dimenzia poskytuje kontext pre faktové tabuľky a obsahuje údaje o webových stránkach. Transformácia zahŕňa odstránenie duplicít a 
priradenie unikátneho ID pre každú stránku. Táto dimenzia je typu SCD 2, čo umožňuje sledovať historické zmeny informácií o stránkach.

#### **dim_category**
```sql
CREATE OR REPLACE TABLE dim_category AS
SELECT
    ROW_NUMBER() OVER (ORDER BY MAIN_CATEGORY, SITE_CATEGORY) AS dim_categoryId,
    MAIN_CATEGORY AS main_category,
    SITE_CATEGORY AS full_category
FROM (
    SELECT DISTINCT MAIN_CATEGORY, SITE_CATEGORY
    FROM TABLE_STAGING
);
```
Dimenzia poskytuje kontext pre faktové tabuľky a obsahuje kategórie webových stránok. Transformácia zahŕňa odstránenie duplicít a 
priradenie unikátneho ID pre každú kombináciu hlavnej a detailnej kategórie. Táto dimenzia je typu SCD 1, teda historické zmeny sa 
neuchovávajú.

#### **dim_date**
```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY year, month) AS dim_dateId,
    YEAR AS year,
    MONTH AS month
FROM (
    SELECT DISTINCT YEAR, MONTH
    FROM TABLE_STAGING
);
```
Dimenzia poskytuje časový kontext pre faktové tabuľky. Transformácia zahŕňa odstránenie duplicít a priradenie unikátneho ID pre každý rok 
a mesiac. Táto dimenzia je typu SCD 0, teda historické zmeny sa neuchovávajú.

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
Dimenzia poskytuje demografický kontext pre faktové tabuľky a obsahuje vekové skupiny používateľov. Transformácia zahŕňa vytvorenie 
preddefinovaných vekových intervalov a priradenie unikátneho ID pre každú skupinu. Táto dimenzia je typu SCD 0, historické zmeny sa 
neuchovávajú.

#### **fact_rank**
```sql
CREATE OR REPLACE TABLE fact_rank AS
WITH f AS (
    SELECT
        SITE,
        CLEAN_SITE,
        GLOBAL_RANK,
        CATEGORY_RANK,
        SITE_CATEGORY,
        YEAR,
        MONTH,
        
        CASE
            WHEN CLEAN_SITE LIKE '%cz'
              OR CLEAN_SITE LIKE '%sk'
            THEN 1
            ELSE 0
        END AS is_cz_sk
    FROM TABLE_STAGING
)
SELECT
    ROW_NUMBER() OVER (ORDER BY f.CLEAN_SITE) AS fact_rankId,

    CASE WHEN f.is_cz_sk = 1 
        THEN DENSE_RANK() OVER (
            PARTITION BY f.is_cz_sk
            ORDER BY f.GLOBAL_RANK
        )
        ELSE NULL
    END AS cz_sk_rank,

    f.GLOBAL_RANK AS global_rank,

    CASE 
        WHEN f.SITE_CATEGORY IS NULL OR f.is_cz_sk = 0 THEN NULL 
        ELSE 
            DENSE_RANK() OVER ( 
                PARTITION BY f.is_cz_sk, f.SITE_CATEGORY 
                ORDER BY f.CATEGORY_RANK 
            ) 
    END AS cz_sk_category_rank,

    f.CATEGORY_RANK AS global_category_rank,

    ds.dim_siteId AS siteId,
    dd.dim_dateId AS dateId,
    dc.dim_categoryId AS categoryId
FROM f
LEFT JOIN dim_site ds ON f.CLEAN_SITE = ds.site
LEFT JOIN dim_date dd ON f.YEAR = dd.year AND f.MONTH = dd.month
LEFT JOIN dim_category dc ON f.SITE_CATEGORY = dc.full_category;
```
Faktová tabuľka uchováva údaje o globálnom a lokálnom rebríčku webových stránok, vrátane kategóriových rankov pre CZ a SK trh. 
Transformácia zahŕňa výpočet miestnych a globálnych poradení (DENSE_RANK), filtrovanie CZ/SK stránok a priradenie cudzích kľúčov na 
dimenzie site, date a category.

#### **fact_audience_share**
```sql
CREATE OR REPLACE TABLE fact_audience_share AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY f.CLEAN_SITE) AS fact_audienceShareId,
    f.TOTAL_RANK_SHARE AS total_rank_share,
    ds.dim_siteid AS siteId,
    dd.dim_dateid AS dateId,
    dag.dim_ageGroupId AS ageGroupId
FROM (
    SELECT
        TOTAL_AGES_18_TO_24_SHARE AS TOTAL_RANK_SHARE,
        '18-24' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING UNION ALL
    SELECT
        TOTAL_AGES_25_TO_34_SHARE AS TOTAL_RANK_SHARE,
        '25-34' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING UNION ALL
    SELECT
        TOTAL_AGES_35_TO_44_SHARE AS TOTAL_RANK_SHARE,
        '35-44' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING UNION ALL
    SELECT
        TOTAL_AGES_45_TO_54_SHARE AS TOTAL_RANK_SHARE,
        '45-54' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING UNION ALL
    SELECT
        TOTAL_AGES_55_TO_64_SHARE AS TOTAL_RANK_SHARE,
        '55-64' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING UNION ALL
    SELECT
        TOTAL_AGES_65_PLUS_SHARE AS TOTAL_RANK_SHARE,
        '65+' AS age_group,
        YEAR,
        MONTH,
        CLEAN_SITE
    FROM TABLE_STAGING
) f
LEFT JOIN dim_site ds ON f.CLEAN_SITE = ds.site
LEFT JOIN dim_date dd ON f.YEAR = dd.year AND f.MONTH = dd.month
LEFT JOIN dim_age_group dag ON f.age_group = dag.label;
```
Faktová tabuľka uchováva podiel návštevnosti webových stránok podľa vekových skupín. Transformácia zahŕňa rozdelenie dát do 
preddefinovaných vekových kategórií a priradenie cudzích kľúčov na dimenzie site, date a age_group. Táto tabuľka umožňuje analyzovať 
demografické správanie používateľov a trend návštevnosti podľa veku.

#### **fact_visits**
```sql
CREATE OR REPLACE TABLE fact_visits AS
SELECT
    ROW_NUMBER() OVER (ORDER BY f.CLEAN_SITE) AS fact_visitsId,
    f.TOTAL_ESTIMATED_VISITS AS total_visits,
    f.TOTAL_ESTIMATED_UNIQUE AS unique_estimated_visits,
    f.DESKTOP_ESTIMATED_VISITS AS desktop_estimated_visits,
    f.MOBILEWEB_ESTIMATED_VISITS AS mobileweb_estimated_visits,
    ds.dim_siteId AS siteId,
    dd.dim_dateId AS dateId,
    dc.dim_categoryId AS categoryId
FROM TABLE_STAGING f
LEFT JOIN dim_site ds ON f.CLEAN_SITE = ds.site
LEFT JOIN dim_date dd ON f.YEAR = dd.year AND f.MONTH = dd.month
LEFT JOIN dim_category dc ON f.SITE_CATEGORY = dc.full_category;
```
Faktová tabuľka uchováva údaje o návštevnosti webových stránok vrátane celkových, unikátnych a odhadovaných návštev podľa typu zariadenia 
(desktop, mobilweb). Transformácia zahŕňa priradenie cudzích kľúčov na dimenzie site, date a category. Táto tabuľka umožňuje analyzovať 
trendy návštevnosti a porovnávať správanie používateľov medzi rôznymi kategóriami a zariadeniami.

### **Transform**

Transformačná fáza zahŕňa čistenie, deduplikáciu, typové konverzie a analytické výpočty.

Čistenie a deduplikácia:
- použitie SELECT DISTINCT
- odstránenie duplicitných kombinácií site + year + month

Tvorba dimenzií so správnym SCD typom:
- dim_date - SCD Typ 0
- dim_age_group - SCD Typ 0
- dim_category - SCD Typ 1
- dim_site - SCD Typ 2 

---
## **4. Vizualizácia dát**

Dashboard obsahuje **6 vizualizácií**, ktoré poskytujú prehľad o kľúčových metrikách a trendoch týkajúcich sa návštevnosti, hodnotení a 
demografie používateľov e-shopu alza.sk a konkurenčných webov. Tieto vizualizácie umožňujú lepšie porozumieť správaní používateľov, 
identifikovať trendy na trhu a podporujú rozhodovanie pri optimalizácii marketingu, obsahu a odporúčacích systémov.

<p align="center">
    <img src="https://github.com/sauwin/Global_Public_Companies_Traffic_Growth_ETL/blob/main/img/alza_dashboard.png" alt="Dashboard">
    <br>
    <em>Obrázok 3 Dashboard Global Public Companies Traffic Growth datasetu</em>
</p>

### **Graf 1: Porovnanie dynamiky zhľadnutí alza.cz a alza.sk**
Táto vizualizácia zobrazuje mesačný vývoj návštevnosti dvoch hlavných e-shopov, alza.sk a alza.cz. Umožňuje porovnávať dynamiku trhu v 
Slovenskej a Českej republike a identifikovať obdobia s nárastom alebo poklesom návštevnosti. Tieto informácie môžu byť využité na 
strategické rozhodovanie, optimalizáciu marketingových kampaní alebo plánovanie rozvoja webu.

```sql
SELECT 
    CONCAT(LPAD(dd.month, 2, '0'), '/', dd.year) AS month, 
    sk.total_visits AS alza_sk,
    cz.total_visits AS alza_cz,
FROM fact_visits sk
    JOIN dim_site ds ON sk.siteId = ds.dim_siteId
    JOIN dim_date dd ON sk.dateId = dd.dim_dateId
    JOIN (
        SELECT
            f.total_visits,
            f.dateId
        FROM fact_visits f 
        JOIN dim_site ds ON f.siteId = ds.dim_siteId
        WHERE ds.site = 'alza.cz'
    ) cz ON sk.dateId = cz.dateId
    
WHERE ds.site = 'alza.sk'
ORDER BY dd.month ASC;
```
---
### **Graf 2: Kumulatívny počet unikátnych zhľadnutí alza.sk v čase**
Táto vizualizácia zobrazuje kumulatívny rast unikátnych návštevníkov webu alza.sk v priebehu času. Umožňuje sledovať trend rastu publika a 
identifikovať obdobia s najväčším prírastkom nových návštevníkov. Tieto údaje sú užitočné pre plánovanie marketingových aktivít, 
optimalizáciu obsahu a lepšie porozumenie správania používateľov.

```sql
SELECT 
    ROUND(SUM(f.unique_estimated_visits) OVER (ORDER BY dd.month), 2) AS unique_visits,
    CONCAT(LPAD(dd.month, 2, '0'), '/', dd.year) AS month, 
FROM fact_visits f
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_date dd ON f.dateId = dd.dim_dateId
WHERE ds.site = 'alza.sk'
ORDER BY dd.month ASC;
```
---
### **Graf 3: Analýza dynamiky ratingu alza.sk v rámci kategórie v čase**
Táto vizualizácia sleduje vývoj globálneho kategóriového poradia webu alza.sk v priebehu času. Umožňuje identifikovať zmeny pozície v 
rámci konkrétnej kategórie a porovnávať výkonnosť oproti konkurencii. Tieto informácie sú užitočné pre benchmarking, optimalizáciu obsahu 
a strategické rozhodovanie o marketingových aktivitách.

```sql
SELECT 
    CONCAT(LPAD(dd.month, 2, '0'), '/', dd.year) AS month, 
    f.global_category_rank AS global_category_rank
FROM fact_rank f 
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_date dd ON f.dateId = dd.dim_dateId
WHERE ds.site = 'alza.sk'
ORDER BY dd.month ASC;
```
---
### **Graf 4: Celkový počet návštev webu alza.sk podľa typu zariadenia**
Táto vizualizácia zobrazuje rozdelenie návštevnosti webu alza.sk podľa typu zariadenia – desktop a mobilný web. Umožňuje pochopiť, aké 
zariadenia používatelia preferujú pri návšteve e-shopu. Tieto údaje sú užitočné pri optimalizácii používateľského rozhrania, mobilnej 
verzie webu a pri plánovaní marketingových kampaní zameraných na konkrétne zariadenia.

```sql
SELECT 
    ROUND(SUM(f.desktop_estimated_visits), 2) AS desktop,
    ROUND(SUM(f.mobileweb_estimated_visits), 2) AS mobile_web
FROM fact_visits f 
JOIN dim_site ds ON f.siteId = ds.dim_siteId
WHERE ds.site = 'alza.sk';
```
---
### **Graf 5: Top 10 slovenských a českých e-shopov podľa priemerného ratingu**
Táto vizualizácia zobrazuje desať najlepšie hodnotených e-shopov na Slovensku a v Českej republike v rámci vybraných kategórií (shopping a 
consumer electronics). Umožňuje identifikovať najvýkonnejšie weby a porovnávať ich priemerné ratingy. Tieto informácie sú užitočné pri 
analýze konkurencie a plánovaní marketingových stratégií.

```sql
SELECT 
    ds.site AS site, 
    ROUND(AVG(f.cz_sk_rank), 2) AS avg_ranking
FROM fact_rank f 
JOIN dim_site ds ON f.siteid = ds.dim_siteid
JOIN dim_category dc ON f.categoryid = dc.dim_categoryid
WHERE 
    f.cz_sk_rank IS NOT NULL
    AND dc.full_category ILIKE '%shopping%' OR dc.full_category ILIKE '%consumer_electronics%'
GROUP BY site
ORDER BY avg_ranking ASC
LIMIT 10;
```
---
### **Graf 6: Priemerný počet zhľadnutí alza.sk podľa vekových kategórií**
Táto vizualizácia zobrazuje priemerný počet návštev webu alza.sk rozdelený podľa vekových skupín používateľov. Umožňuje analyzovať, ktoré 
vekové kategórie tvoria najväčšiu časť publika, a poskytuje cenné informácie pre cielenie marketingových kampaní, odporúčacie systémy a 
optimalizáciu obsahu pre rôzne demografické skupiny.

```sql
SELECT 
    dag.label AS age_group,
    ROUND(AVG(f.total_rank_share), 2) AS avg_visits
FROM fact_audience_share f
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_age_group dag ON f.ageGroupId = dag.dim_ageGroupId
WHERE ds.site = 'alza.sk'
GROUP BY dag.label
ORDER BY avg_visits ASC;
```
---
Táto vizualizácia zobrazuje mesačný vývoj návštevnosti dvoch hlavných e-shopov, alza.sk a alza.cz. Umožňuje porovnávať dynamiku trhu v 
Slovenskej a Českej republike a identifikovať obdobia s nárastom alebo poklesom návštevnosti. Tieto informácie môžu byť využité na 
strategické rozhodovanie, optimalizáciu marketingových kampaní alebo plánovanie rozvoja webu.