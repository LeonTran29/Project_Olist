--- Q2: Share of late delivered orders
WITH delivered_order AS
(SELECT
  order_id,
  customer_state,
  days_vs_promise
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  "Late delivery" AS Share_of_late_delivery
  , COUNTIF(days_vs_promise > 0) AS late_orders
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),2) AS share_pct 
  , COUNT(*) AS total_orders
FROM delivered_order;
--- Q2: Concentrate customer-sideWITH delivered_order AS
(SELECT
  order_id,
  customer_state,
  days_vs_promise
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  customer_state
  , COUNTIF(days_vs_promise > 0) AS late_orders
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),3) AS share_pct 
  , COUNT(*) AS total_orders
  , 0 AS Sort_flag
FROM delivered_order
GROUP BY customer_state
UNION ALL
SELECT
  'Total'
  , COUNTIF(days_vs_promise > 0)
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),3)
  , COUNT(*)
  , 1 AS Sort_flag
FROM delivered_order
ORDER BY Sort_flag, share_pct DESC;
