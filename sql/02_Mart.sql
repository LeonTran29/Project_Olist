--- Create fct_order_delivery
CREATE OR REPLACE TABLE `myprojectolist.Olist_mart.fct_order_delivery` AS
SELECT
  o.order_id,
  o.customer_id,
  c.customer_state,
  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY) AS lead_time,
  TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date, DAY) AS days_vs_promise,

  r.review_score AS review_score,

  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL THEN 'delivered'
    WHEN o.order_delivered_carrier_date  IS NOT NULL THEN 'stuck_at_carrier'
    WHEN o.order_approved_at             IS NOT NULL THEN 'stuck_after_approval'
    ELSE 'stuck_at_purchase'
  END AS stall_stage

FROM `myprojectolist.Olist_stg.orders` o
LEFT JOIN `myprojectolist.Olist_stg.customers` c USING (customer_id)
LEFT JOIN (
  SELECT
    order_id,
    AVG(review_score) AS review_score
  FROM `myprojectolist.Olist_stg.order_reviews`
  GROUP BY order_id
) r USING (order_id);

--- Create fct_order_items
CREATE OR REPLACE TABLE `myprojectolist.Olist_mart.fct_order_items` AS
SELECT
  i.order_id,
  i.order_item_id,
  i.product_id,
  c.product_category_name_english,
  i.seller_id,
  s.seller_state,
  TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date, DAY) AS days_vs_promise,
  CASE
    WHEN o.order_delivered_customer_date IS NULL THEN 'Not_delivered'
    WHEN TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date, DAY) > 0 THEN 'Late'
    ELSE 'Good'
  END AS is_late
FROM `myprojectolist.Olist_stg.order_items` i
LEFT JOIN `myprojectolist.Olist_stg.products` p USING (product_id)
LEFT JOIN `myprojectolist.Olist_stg.product_category_name` c USING (product_category_name)
LEFT JOIN `myprojectolist.Olist_stg.orders` o USING (order_id)
LEFT JOIN `myprojectolist.Olist_stg.sellers` s USING (seller_id);
