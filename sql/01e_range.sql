--- order_items: check price + freight (quantile)
WITH items AS (
  SELECT APPROX_QUANTILES(freight_value, 100) AS freight,
         APPROX_QUANTILES(price, 100) AS price
  FROM `myprojectolist.Olist_stg.order_items`
)
SELECT 'freight_value' AS col,
       freight[OFFSET(0)] AS min_val, freight[OFFSET(50)] AS median,
       freight[OFFSET(90)] AS p90, freight[OFFSET(99)] AS p99, freight[OFFSET(100)] AS max_val
FROM items
UNION ALL
SELECT 'price', price[OFFSET(0)], price[OFFSET(50)],
       price[OFFSET(90)], price[OFFSET(99)], price[OFFSET(100)]
FROM items;

--- orders: check dates
SELECT
  MIN(order_purchase_timestamp) AS first_order,
  MAX(order_purchase_timestamp) AS last_order,
  COUNTIF(order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase
FROM `myprojectolist.Olist_stg.orders`;
