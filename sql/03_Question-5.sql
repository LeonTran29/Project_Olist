--- Q5: Part 1
SELECT
  COUNT(*) AS Total_never_arrive,
  COUNTIF(order_status = 'canceled') AS Those_canceled,
  COUNT(*) - COUNTIF(order_status = 'canceled') AS Those_stucked
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL;

--- Q5: Part 2
SELECT
  stall_stage,
  COUNT(*) AS N
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled'
GROUP BY stall_stage
UNION ALL
SELECT
  'Total',
  COUNT(*) AS N
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled';

SELECT
  customer_state
  ,stall_stage
  ,COUNT(*) AS N
  ,ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled'
GROUP BY customer_state,stall_stage
ORDER BY customer_state ASC, stall_stage ASC;

--- Q5 add-on:
SELECT
  customer_state
  ,COUNTIF(order_delivered_customer_date IS NULL AND order_status != 'canceled') AS N
  ,ROUND(COUNTIF(order_delivered_customer_date IS NULL AND order_status != 'canceled') *100 / COUNT(*),2)AS pct
  ,COUNT(*) AS Total_orders
FROM `myprojectolist.Olist_mart.fct_order_delivery`
GROUP BY customer_state
HAVING N >= 11
ORDER BY pct DESC;
