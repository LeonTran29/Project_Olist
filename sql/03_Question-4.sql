--- Q4a
WITH delivered_lines AS (
  SELECT
    COALESCE(product_category_name_english, 'uncategorized') AS category,
    is_late
  FROM `myprojectolist.Olist_mart.fct_order_items`
  WHERE is_late != 'Not_delivered'   -- chỉ order-line đã giao (Late + Good)
)
SELECT
  category,
  COUNTIF(is_late = 'Late') AS late_lines,
  COUNT(*) AS total_lines,
  ROUND(COUNTIF(is_late = 'Late') * 100 / COUNT(*), 2) AS late_rate_pct
FROM delivered_lines
GROUP BY category
HAVING total_lines >=250
ORDER BY late_rate_pct DESC;

--- Q4b
WITH delivered_lines AS (
  SELECT
    seller_state,
    is_late
  FROM `myprojectolist.Olist_mart.fct_order_items`
  WHERE is_late != 'Not_delivered'
)
SELECT
  seller_state,
  COUNTIF(is_late = 'Late') AS late_lines,
  COUNT(*) AS total_lines,
  ROUND(COUNTIF(is_late = 'Late') * 100 / COUNT(*), 2) AS late_rate_pct
FROM delivered_lines
GROUP BY seller_state
HAVING total_lines > 144
ORDER BY late_rate_pct DESC;
