--- Order_items --- Order
SELECT 'order_items -> orders' AS relationship ,COUNT(*) AS orphan_items
FROM `myprojectolist.Olist_stg.order_items` i
LEFT JOIN `myprojectolist.Olist_stg.orders` o USING (order_id)
WHERE o.order_id IS NULL;

SELECT 'order_items <- orders' AS relationship, COUNT(*) AS orders_without_items
FROM `myprojectolist.Olist_stg.orders` o
LEFT JOIN `myprojectolist.Olist_stg.order_items` i USING (order_id)
WHERE i.order_id IS NULL;

--- Order_items --- Product
SELECT 'order_items -> product' AS relationship, COUNT(*) AS orphan_items
FROM `myprojectolist.Olist_stg.order_items` i
LEFT JOIN `myprojectolist.Olist_stg.products` o USING (product_id)
WHERE o.product_id IS NULL;

SELECT 'order_items <- product' AS relationship, COUNT(*) AS products_without_items
FROM `myprojectolist.Olist_stg.products` o
LEFT JOIN `myprojectolist.Olist_stg.order_items` i USING (product_id)
WHERE i.product_id IS NULL;

--- Order_items --- Seller
SELECT 'order_items -> seller' AS relationship, COUNT(*) AS orphan_items
FROM `myprojectolist.Olist_stg.order_items` i
LEFT JOIN `myprojectolist.Olist_stg.sellers` o USING (seller_id)
WHERE o.seller_id IS NULL;

SELECT 'order_items <- seller' AS relationship, COUNT(*) AS sellers_without_items
FROM `myprojectolist.Olist_stg.sellers` o
LEFT JOIN `myprojectolist.Olist_stg.order_items` i USING (seller_id)
WHERE i.seller_id IS NULL;

--- Orders --- Customers
SELECT 'orders -> customers' AS relationship, COUNT(*) AS orphan_orders
FROM `myprojectolist.Olist_stg.orders` i
LEFT JOIN `myprojectolist.Olist_stg.customers` o USING (customer_id)
WHERE o.customer_id IS NULL;

SELECT 'orders <- customers' AS relationship, COUNT(*) AS customers_without_orders
FROM `myprojectolist.Olist_stg.customers` o
LEFT JOIN `myprojectolist.Olist_stg.orders` i USING (customer_id)
WHERE i.customer_id IS NULL;

--- Order_reviews --- Orders
SELECT 'order_reviews -> orders' AS relationship, COUNT(*) AS orphan_reviews
FROM `myprojectolist.Olist_stg.order_reviews` i
LEFT JOIN `myprojectolist.Olist_stg.orders` o USING (order_id)
WHERE o.order_id IS NULL;

SELECT 'order_reviews <- orders' AS relationship, COUNT(*) AS orders_without_reviews
FROM `myprojectolist.Olist_stg.orders` o
LEFT JOIN `myprojectolist.Olist_stg.order_reviews` i USING (order_id)
WHERE i.order_id IS NULL;

--- Check status 775 orders without items
SELECT IFNULL(o.order_status,'Total') AS order_status, COUNT(*) AS n
FROM `myprojectolist.Olist_stg.orders` o
LEFT JOIN `myprojectolist.Olist_stg.order_items` i USING (order_id)
WHERE i.order_id IS NULL
GROUP BY ROLLUP(o.order_status);

--- Check Tier C
--- Check product_name
SELECT 
  COUNT(DISTINCT p.product_category_name) AS total_categories,
  COUNT(DISTINCT t.product_category_name) AS translated_cat
FROM `myprojectolist.Olist_stg.products` p
LEFT JOIN `myprojectolist.Olist_stg.product_category_name` t
USING (product_category_name);

---
SELECT DISTINCT p.product_category_name
FROM `myprojectolist.Olist_stg.products` p
LEFT JOIN `myprojectolist.Olist_stg.product_category_name` t
  USING (product_category_name)
WHERE t.product_category_name IS NULL;

---
SELECT
  CASE WHEN p.product_category_name IS NULL THEN 'no_category'
       ELSE p.product_category_name END AS category,
  COUNT(*) AS products
FROM `myprojectolist.Olist_stg.products` p
LEFT JOIN `myprojectolist.Olist_stg.product_category_name` t
  USING (product_category_name)
WHERE t.product_category_name IS NULL
GROUP BY 1
ORDER BY products DESC;

--- Check geolocation
-- Customers → geolocation coverage
SELECT
  COUNT(DISTINCT c.customer_zip_code_prefix) AS total_zip,
  COUNT(DISTINCT g.zip) AS matched_zip
FROM `myprojectolist.Olist_stg.customers` c
LEFT JOIN (
  SELECT DISTINCT geolocation_zip_code_prefix AS zip
  FROM `myprojectolist.Olist_stg.geolocation`
) g ON c.customer_zip_code_prefix = g.zip;

-- Sellers → geolocation coverage
SELECT
  COUNT(DISTINCT c.seller_zip_code_prefix) AS total_zip,
  COUNT(DISTINCT g.zip) AS matched_zip
FROM `myprojectolist.Olist_stg.sellers` c
LEFT JOIN (
  SELECT DISTINCT geolocation_zip_code_prefix AS zip
  FROM `myprojectolist.Olist_stg.geolocation`
) g ON c.seller_zip_code_prefix = g.zip;
