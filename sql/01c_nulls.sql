--- CHECK NULL order TABLE
SELECT tbl,column_name , null_count,
  ROUND(100*null_count/(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.orders`),2) AS null_pct
FROM
(SELECT
  'order' as tbl,
  COUNTIF(order_id is NULL) AS order_id,
  COUNTIF(customer_id is NULL) AS customer_id,
  COUNTIF(order_status is NULL) AS order_status,
  COUNTIF(order_purchase_timestamp is NULL) AS order_purchase_timestamp,
  COUNTIF(order_approved_at is NULL) AS order_approved_at,
  COUNTIF(order_delivered_carrier_date is NULL) AS order_delivered_carrier_date,
  COUNTIF(order_delivered_customer_date is NULL) AS order_delivered_customer_date,
  COUNTIF(order_estimated_delivery_date is NULL) AS order_estimated_delivery_date
FROM `myprojectolist.Olist_stg.orders`)
UNPIVOT (null_count FOR column_name IN (
  order_id,customer_id,order_status,order_purchase_timestamp,
  order_approved_at, order_delivered_carrier_date,
  order_delivered_customer_date,order_estimated_delivery_date
))
ORDER BY null_count DESC;

SELECT
  COUNTIF(order_delivered_carrier_date IS NULL
    AND order_delivered_customer_date IS NOT NULL) AS delivered_without_carrier,
  COUNTIF(order_approved_at IS NULL
    AND order_delivered_customer_date IS NOT NULL) AS delivered_without_approval
FROM `myprojectolist.Olist.orders`;

--- CHECK NULL order_items TABLE
SELECT tbl,column_name , null_count,
  ROUND(100*null_count/(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.orders`),2) AS null_pct
FROM
(SELECT
  'order_items' as tbl,
  COUNTIF(order_id is NULL) AS order_id,
  COUNTIF(order_item_id is NULL) AS order_item_id,
  COUNTIF(product_id is NULL) AS product_id,
  COUNTIF(seller_id is NULL) AS seller_id,
  COUNTIF(shipping_limit_date is NULL) AS shipping_limit_date,
  COUNTIF(price is NULL) AS price,
  COUNTIF(freight_value is NULL) AS freight_value
FROM `myprojectolist.Olist_stg.order_items`)
UNPIVOT (null_count FOR column_name IN (
  order_id,order_item_id,product_id,seller_id,
  shipping_limit_date, price,freight_value
))
ORDER BY null_count DESC;

--- CHECK NULL order_reviews TABLE
SELECT STRING_AGG(
  FORMAT('| %s | %s | %d | %.2f |', tbl, column_name, null_count, null_pct),
  '\n' ORDER BY null_count DESC
) AS md
FROM ( 
SELECT tbl,column_name , null_count,
  ROUND(100*null_count/(SELECT COUNT(*) FROM `myprojectolist.Olist_stg.orders`),2) AS null_pct
FROM
(SELECT
  'order_reviews' as tbl,
  COUNTIF(review_id is NULL) AS review_id,
  COUNTIF(order_id is NULL) AS order_id,
  COUNTIF(review_score is NULL) AS review_score,
  COUNTIF(review_comment_title is NULL) AS review_comment_title,
  COUNTIF(review_comment_message is NULL) AS review_comment_message,
  COUNTIF(review_creation_date is NULL) AS review_creation_date,
  COUNTIF(review_answer_timestamp is NULL) AS review_answer_timestamp
FROM `myprojectolist.Olist_stg.order_reviews`)
UNPIVOT (null_count FOR column_name IN (
  review_id,order_id,review_score,review_comment_title,
  review_comment_message, review_creation_date,review_answer_timestamp
))
ORDER BY null_count DESC);

--- CHECK NULL customers, products, sellers TABLE

SELECT tbl, column_name, null_count,
       ROUND(100 * null_count / total_rows, 2) AS null_pct
FROM (
  SELECT 'customers' AS tbl, 'customer_id' AS column_name,
         COUNTIF(customer_id IS NULL) AS null_count,
         COUNT(*) AS total_rows
  FROM `myprojectolist.Olist_stg.customers`
  UNION ALL
  SELECT 'customers', 'customer_unique_id',
         COUNTIF(customer_unique_id IS NULL), COUNT(*)
  FROM `myprojectolist.Olist_stg.customers`
  UNION ALL
  SELECT 'products', 'product_id',
         COUNTIF(product_id IS NULL), COUNT(*)
  FROM `myprojectolist.Olist_stg.products`
  UNION ALL
  SELECT 'sellers', 'seller_id',
         COUNTIF(seller_id IS NULL), COUNT(*)
  FROM `myprojectolist.Olist_stg.sellers`
)
ORDER BY null_count DESC;
