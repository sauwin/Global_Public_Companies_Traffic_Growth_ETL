# ELT proces datasetu Global Public Companies Traffic Growth

Tento repozitár predstavuje implementáciu ELT procesu v Snowflake a vytvorenie dátového skladu so schémou Star Schema na základe Global Public Companies Traffic 
Growth datasetu. Projekt je zameraný na obchodnú analýzu tempa rastu Alza.sk, návratnosti investícií, porovnanie s lokálnymi aj globálnymi konkurentmi. Hodnotenie 
rastu spoločnosti na základe online výsledkov a porovnania s lídrami v odvetví.

---
## **1. Úvod a popis zdrojových dát**

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
SELECT
    ROW_NUMBER() OVER (ORDER BY CLEAN_SITE) AS dim_siteId,
    CLEAN_SITE AS site
FROM (
    SELECT DISTINCT CLEAN_SITE
    FROM TABLE_STAGING
);
```

**dim_category**
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

**dim_date**
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

**fact_audience_share**
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

**fact_visits**
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
## **4. Vizualizácia dát**
