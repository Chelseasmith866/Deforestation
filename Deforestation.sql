SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE country_name = 'World' AND year = '1990'

--------------------------------------------------------------

SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE country_name = 'World' AND year = '2016'

--------------------------------------------------------------

SELECT country_name, forest_area_sqkm, year, LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm) AS lead, LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm) - forest_area_sqkm AS lead_difference
FROM
(SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE country_name = 'World' AND year = '2016' OR country_name = 'World' AND year = '1990') sub

--------------------------------------------------------------

WITH T1 AS
(SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE country_name = 'World' AND year = '2016'),

T2 AS (SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE country_name = 'World' AND year = '1990')

SELECT (t1.forest_area_sqkm-t2.forest_area_sqkm) *100/t2.forest_area_sqkm AS percentage_change
FROM t1
JOIN t2
ON t1.country_name = t2.country_name

----------------Regional Outlook queries--------------------------------------------------------------

SELECT f.country_name, f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100 AS forest_percentage
FROM forest_area f
JOIN land_area l
ON f.country_name = l.country_name
WHERE f.country_name = 'World' AND f.year = '2016' AND l.country_name = 'World' AND l.year = '2016'

--------------------------------------------------------------


SELECT total_forest_area/total_area*100 AS forest_percentage, region, year
FROM
(SELECT SUM(forest_area_sqkm) AS total_forest_area, region, SUM(total_area_sq_mi*2.59) AS total_area, year
FROM
(SELECT f.country_name, f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100 AS forest_percentage, r.region, f.forest_area_sqkm, l.total_area_sq_mi, f.year
FROM forest_area f
JOIN land_area l
ON f.country_name = l.country_name
JOIN regions r
ON l.country_name = r.country_name
WHERE f.year = '1990' OR f.year = '2016'
ORDER BY region, forest_percentage DESC) sub
GROUP BY region, year) sub2
ORDER BY year, forest_percentage

-------------Country-Level Detail queries----------------------

WITH t1 AS (SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE year = '2016'
ORDER BY country_name),

t2 AS (SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE year = '1990'
ORDER BY country_name)

SELECT t1.country_name, t2.forest_area_sqkm - t1.forest_area_sqkm AS area_change, r.region
FROM t1
JOIN t2
ON t1.country_name = t2.country_name
JOIN regions r
ON t2.country_name = r.country_name
ORDER BY area_change DESC, country_name

----------------------------------------------------------------

WITH t1 AS (SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE year = '2016'
ORDER BY country_name),

t2 AS (SELECT country_name, forest_area_sqkm, year
FROM forest_area
WHERE year = '1990'
ORDER BY country_name)

SELECT t1.country_name, (t1.forest_area_sqkm-t2.forest_area_sqkm)*100/t2.forest_area_sqkm AS percent_area_change, r.region
FROM t1
JOIN t2
ON t1.country_name = t2.country_name
JOIN regions r
ON t2.country_name = r.country_name
ORDER BY percent_area_change, country_name

------------------------------------------------------------------

SELECT country_name, CASE WHEN percent_forest_area <25 THEN '1st'
  WHEN percent_forest_area >=25 AND percent_forest_area <50 THEN '2rd'
  WHEN percent_forest_area >=50 AND percent_forest_area <75 THEN '3rd'
  ELSE '4th' END AS quartile, percent_forest_area
FROM (SELECT l.country_name, f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100 AS percent_forest_area
FROM land_area l
JOIN forest_area f
ON f.country_name = l.country_name
WHERE l.year = '2016' AND f.year = '2016') sub
WHERE percent_forest_area IS NOT NULL
ORDER BY quartile

-----------------------------------------------------------------


SELECT COUNT(quartile), quartile
FROM (SELECT country_name, CASE WHEN percent_forest_area <25 THEN '1st'
      WHEN percent_forest_area >=25 AND percent_forest_area <50 THEN '2rd'
      WHEN percent_forest_area >=50 AND percent_forest_area <75 THEN '3rd'
      ELSE '4th' END AS quartile, percent_forest_area
FROM (SELECT l.country_name, f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100 AS percent_forest_area
      FROM land_area l
      JOIN forest_area f
      ON f.country_name = l.country_name
      WHERE l.year = '2016' AND f.year = '2016') sub
      WHERE percent_forest_area IS NOT NULL AND country_name <> 'World'
      ORDER BY quartile) sub2
GROUP BY 2

-------------------------------------------------------------------


SELECT country_name, region, CASE WHEN percent_forest_area <25 THEN '1st' WHEN percent_forest_area >=25 AND percent_forest_area <50 THEN '2rd' WHEN percent_forest_area >=50 AND percent_forest_area <75 THEN '3rd' ELSE '4th' END AS quartile, percent_forest_area
FROM (SELECT l.country_name, r.region, f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100 AS percent_forest_area
FROM land_area l
JOIN forest_area f
ON f.country_name = l.country_name
JOIN regions r
ON l.country_name = r.country_name
WHERE l.year = '2016' AND f.year = '2016') sub
WHERE percent_forest_area IS NOT NULL
ORDER BY quartile DESC, percent_forest_area DESC


-----------------CREATE VIEW-----------------------------------


CREATE VIEW combined_tables AS
SELECT f.country_name, f.year, f.forest_area_sqkm, l.total_area_sq_mi, r.region
FROM forest_area f
JOIN land_area l
ON f.country_name = l.country_name
JOIN regions r
ON r.country_name = l.country_name
