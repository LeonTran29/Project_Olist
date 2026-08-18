WITH dataraw AS
(SELECT
  APPROX_QUANTILES(days_vs_promise,100) as pct
  ,COUNT(*) AS N
  ,AVG(days_vs_promise) AS AVG
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  'days_vs_promise' AS column
  ,d.pct[OFFSET(0)] AS min
  ,d.pct[OFFSET(25)] AS Q25
  ,d.pct[OFFSET(50)] AS median
  ,d.AVG AS mean
  ,d.pct[OFFSET(75)] AS Q75
  ,d.pct[OFFSET(100)] AS max
  ,d.pct[OFFSET(90)] AS P90
  ,d.pct[OFFSET(99)] AS P99
  ,d.N AS Total
FROM dataraw AS d;

---
WITH Q3_DB AS
(SELECT
  days_vs_promise
  , review_score
  , CASE
    WHEN days_vs_promise <0 THEN "1.Early"
    WHEN days_vs_promise = 0 THEN "2.On-time"
    WHEN days_vs_promise <= 5 THEN "3.Slightly Late"
    WHEN days_vs_promise <= 10 THEN "4.Late"
    ELSE "5.Severe Late"
  END AS Type
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  Type
  , COUNT(*) AS N
  , ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
  , ROUND(AVG(review_score),2) AS AVG
FROM Q3_DB
GROUP BY Type
UNION ALL
SELECT
  'Total'
  , COUNT(*) AS N
  , ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
  , ROUND(AVG(review_score),2) AS AVG
FROM Q3_DB
ORDER BY Type;
---
SELECT
  COUNTIF(review_score IS NOT NULL) AS with_review,
  COUNT(*) AS total_delivered,
  ROUND(COUNTIF(review_score IS NOT NULL) * 100 / COUNT(*), 2) AS pct_with_review
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL;
