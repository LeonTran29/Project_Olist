SELECT
  -- Type 1: Wrong steps
  COUNTIF(order_approved_at < order_purchase_timestamp) AS approved_before_purchase,
  COUNTIF(order_delivered_carrier_date < order_approved_at) AS carrier_before_approved,
  COUNTIF(order_delivered_customer_date < order_delivered_carrier_date) AS delivered_before_carrier,
  COUNTIF(order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase,
  -- Type 2: Break points
  COUNTIF(order_delivered_customer_date IS NOT NULL
          AND order_delivered_carrier_date IS NULL) AS delivered_no_carrier,
  COUNTIF(order_delivered_customer_date IS NOT NULL
          AND order_approved_at IS NULL) AS delivered_no_approval,
  COUNTIF(order_delivered_customer_date IS NOT NULL
        AND order_purchase_timestamp IS NULL) AS delivered_no_purchase
FROM `myprojectolist.Olist_stg.orders`;
--- Checking
SELECT order_approved_at, order_delivered_carrier_date
FROM `myprojectolist.Olist_stg.orders`
WHERE order_delivered_carrier_date < order_approved_at
LIMIT 20;

SELECT order_delivered_carrier_date, order_delivered_customer_date
FROM `myprojectolist.Olist_stg.orders`
WHERE order_delivered_customer_date < order_delivered_carrier_date
LIMIT 20;

SELECT COUNTIF(review_answer_timestamp < review_creation_date) AS timestamp_before_creation
FROM `myprojectolist.Olist_stg.order_reviews`;
