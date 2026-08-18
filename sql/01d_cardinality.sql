SELECT 'orders' AS tbl, 'order_status' AS col, COUNT(DISTINCT order_status) AS card
FROM `myprojectolist.Olist_stg.orders`
UNION ALL
SELECT 'order_reviews','review_score', COUNT(DISTINCT review_score)
FROM `myprojectolist.Olist_stg.order_reviews`;

--- CHECK CARDINALITY OF orders and order_reviews

SELECT DISTINCT(order_status)
FROM `myprojectolist.Olist_stg.orders`;

SELECT DISTINCT(review_score)
FROM `myprojectolist.Olist_stg.order_reviews`;
