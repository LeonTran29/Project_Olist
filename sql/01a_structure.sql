WITH k AS(
  SELECT 'customers' as tbl,'B' as tier, COUNT(*) as n
  FROM `myprojectolist.Olist_stg.customers`
  UNION ALL
  SELECT 'geolocation','C', COUNT(*)
  FROM `myprojectolist.Olist_stg.geolocation`
  UNION ALL
  SELECT 'order_items','A', COUNT(*)
  FROM `myprojectolist.Olist_stg.order_items`
  UNION ALL
  SELECT 'order_payments','-', COUNT(*)
  FROM `myprojectolist.Olist_stg.order_payments`
  UNION ALL
  SELECT 'order_reviews','A', COUNT(*)
  FROM `myprojectolist.Olist_stg.order_reviews`
  UNION ALL
  SELECT 'orders','A', COUNT(*)
  FROM `myprojectolist.Olist_stg.orders`
  UNION ALL
  SELECT 'product_category_name','C', COUNT(*)
  FROM `myprojectolist.Olist_stg.product_category_name`
  UNION ALL
  SELECT 'products','B', COUNT(*)
  FROM `myprojectolist.Olist_stg.products`
  UNION ALL
  SELECT 'sellers','B', COUNT(*)
  FROM `myprojectolist.Olist_stg.sellers`
)
SELECT tbl as TABLE,tier as Tier, n as Value
FROM k
ORDER BY Tier
