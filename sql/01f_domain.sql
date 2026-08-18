--- Domain orders: General views
SELECT
  order_status,
  COUNT(order_status) AS count,
  ROUND(COUNT(order_status) * 100 /(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.orders`),2) AS pct
FROM `myprojectolist.Olist_stg.orders`
GROUP BY order_status

UNION ALL

SELECT
  'Total',
  COUNT(*),
  ROUND(COUNT(*)*100/COUNT(*),2)
FROM `myprojectolist.Olist_stg.orders`;

--- Domain orders: 
SELECT
  CASE WHEN order_status = 'delivered' THEN 'delivered'
  ELSE 'non-delivered' END AS group_name,
  COUNT(*) AS orders,
  ROUND(COUNT(*)*100/(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.orders`),2) AS pct
FROM `myprojectolist.Olist_stg.orders`
GROUP BY group_name
UNION ALL
SELECT
  'Total',
  COUNT(*),
  ROUND(COUNT(*)*100/COUNT(*),2)
FROM `myprojectolist.Olist_stg.orders`;
--- Check 2 missed orders
SELECT
  COUNTIF(order_status != 'delivered'
    AND order_delivered_customer_date IS NOT NULL) AS not_delivered_but_date,
  COUNTIF(order_status = 'delivered'
    AND order_delivered_customer_date IS NULL) AS delivered_but_no_date
FROM `myprojectolist.Olist_stg.orders`;

--- Domain order_reviews: General views
SELECT
  CAST(review_score AS STRING) AS review_score,
  COUNT(review_score) AS count,
  ROUND(COUNT(review_score) * 100 /(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.order_reviews`),2) AS pct
FROM `myprojectolist.Olist_stg.order_reviews`
GROUP BY review_score
UNION ALL
SELECT
  'Total',
  COUNT(*),
  ROUND(COUNT(*)*100/(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.order_reviews`),2)
FROM `myprojectolist.Olist_stg.order_reviews`
