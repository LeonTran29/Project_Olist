WITH k AS(
  SELECT 'customers' as tbl,'B' as tier,COUNT(*) as r, COUNT(DISTINCT customer_id) as n
  FROM `myprojectolist.Olist_stg.customers`
  UNION ALL
  SELECT 'order_items','A',COUNT(*), COUNT(DISTINCT TO_JSON_STRING(STRUCT(order_id,order_item_id)))
  FROM `myprojectolist.Olist_stg.order_items`
  UNION ALL
  SELECT 'order_reviews','A',COUNT(*), COUNT(DISTINCT review_id)
  FROM `myprojectolist.Olist_stg.order_reviews`
  UNION ALL
  SELECT 'orders','A',COUNT(*), COUNT(DISTINCT order_id)
  FROM `myprojectolist.Olist_stg.orders`
  UNION ALL
  SELECT 'products','B',COUNT(*), COUNT(DISTINCT product_id)
  FROM `myprojectolist.Olist_stg.products`
  UNION ALL
  SELECT 'sellers','B',COUNT(*), COUNT(DISTINCT seller_id)
  FROM `myprojectolist.Olist_stg.sellers`
)
SELECT tbl as TABLE,tier as Tier,r as Size, n as PK
FROM k
ORDER BY Tier ASC, TABLE ASC
