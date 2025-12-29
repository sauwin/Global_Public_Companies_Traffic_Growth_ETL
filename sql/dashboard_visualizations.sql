-- Graf 1: Porovnanie dynamiky zhľadnutí alza.cz a alza.sk
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

-- Graf 2: Kumulatívny počet unikátnych zhľadnutí alza.sk v čase
SELECT 
    ROUND(SUM(f.unique_estimated_visits) OVER (ORDER BY dd.month), 2) AS unique_visits,
    CONCAT(LPAD(dd.month, 2, '0'), '/', dd.year) AS month, 
FROM fact_visits f
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_date dd ON f.dateId = dd.dim_dateId
WHERE ds.site = 'alza.sk'
ORDER BY dd.month ASC;

-- Graf 3: Analýza dynamiky ratingu alza.sk v rámci kategórie v čase
SELECT 
    CONCAT(LPAD(dd.month, 2, '0'), '/', dd.year) AS month, 
    f.global_category_rank AS global_category_rank
FROM fact_rank f 
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_date dd ON f.dateId = dd.dim_dateId
WHERE ds.site = 'alza.sk'
ORDER BY dd.month ASC;

-- Graf 4: Celkový počet návštev webu alza.sk podľa typu zariadenia
SELECT 
    ROUND(SUM(f.desktop_estimated_visits), 2) AS desktop,
    ROUND(SUM(f.mobileweb_estimated_visits), 2) AS mobile_web
FROM fact_visits f 
JOIN dim_site ds ON f.siteId = ds.dim_siteId
WHERE ds.site = 'alza.sk';

-- Graf 5: Top 10 slovenských a českých e-shopov podľa priemerného ratingu
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

-- Graf 6: Priemerný počet zhľadnutí alza.sk podľa vekových kategórií
SELECT 
    dag.label AS age_group,
    ROUND(AVG(f.total_rank_share), 2) AS avg_visits
FROM fact_audience_share f
    JOIN dim_site ds ON f.siteId = ds.dim_siteId
    JOIN dim_age_group dag ON f.ageGroupId = dag.dim_ageGroupId
WHERE ds.site = 'alza.sk'
GROUP BY dag.label
ORDER BY avg_visits ASC;