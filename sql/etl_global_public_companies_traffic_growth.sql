-- Vytvorenie databázy
CREATE DATABASE falcon_mallard_db;
USE DATABASE falcon_mallard_db;

-- Vytvorenie schémy
CREATE SCHEMA project_sch;
USE SCHEMA project_sch;

-- Vytvorenie staging tabuľky pre dataset
CREATE OR REPLACE TABLE table_staging AS
SELECT * FROM GLOBAL_PUBLIC_COMPANIES_TRAFFIC_GROWTH.DATAFEEDS.GLOBAL_GROWTH;

-- Vytvorenie dim tabuľky pre dim_site
CREATE OR REPLACE TABLE dim_site AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CLEAN_SITE) AS dim_siteId,
    CLEAN_SITE AS site
FROM (
    SELECT DISTINCT CLEAN_SITE
    FROM TABLE_STAGING
);

-- Vytvorenie dim tabuľky dim_category
CREATE OR REPLACE TABLE dim_category AS
SELECT
    ROW_NUMBER() OVER (ORDER BY MAIN_CATEGORY, SITE_CATEGORY) AS dim_categoryId,
    MAIN_CATEGORY AS main_category,
    SITE_CATEGORY AS full_category
FROM (
    SELECT DISTINCT MAIN_CATEGORY, SITE_CATEGORY
    FROM TABLE_STAGING
);

-- Vytvorenie dim tabuľky pre dim_date
CREATE OR REPLACE TABLE dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY year, month) AS dim_dateId,
    YEAR AS year,
    MONTH AS month
FROM (
    SELECT DISTINCT YEAR, MONTH
    FROM TABLE_STAGING
);

-- Vytvorenie dim tabuľky pre dim_age_group
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

-- Vytvorenie fact tabuľky pre fact_rank
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

-- Vytvorenie fact tabuľky pre fact_audience_share
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

-- Vytvorenie fact tabuľky pre fact_visits
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

-- DROP stagging tabuľky table_staging
DROP TABLE IF EXISTS table_staging;