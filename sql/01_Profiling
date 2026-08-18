--- QUERY DATATYPE OF ALL COLUMNS IN TABLES
SELECT table_name, column_name, data_type
FROM `myprojectolist.Olist.INFORMATION_SCHEMA.COLUMNS`
ORDER BY table_name, ordinal_position;

--- QUERY LOCATION
SELECT schema_name, location
FROM `myprojectolist.INFORMATION_SCHEMA.SCHEMATA`;

--- FIX DATATYPES
----- Create schema Olist_stage
CREATE SCHEMA IF NOT EXISTS `myprojectolist.Olist_stg` OPTIONS (location = 'US');

----- Check column names in list
SELECT STRING_AGG(column_name, ',\n  ')
FROM `myprojectolist.Olist.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'sellers';

----- RECREATE TABLES
CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.customers` AS
SELECT
  customer_id,
  customer_unique_id,
  LPAD(CAST(customer_zip_code_prefix AS STRING),5,'0') AS customer_zip_code_prefix,
  customer_city,
  customer_state
FROM `myprojectolist.Olist.customers`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.geolocation` AS
SELECT
  LPAD(CAST(geolocation_zip_code_prefix AS STRING),5,'0') AS geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state
FROM `myprojectolist.Olist.geolocation`;


CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.sellers` AS
SELECT
  seller_id,
  LPAD(CAST(seller_zip_code_prefix AS STRING),5,'0') AS seller_zip_code_prefix,
  seller_city,
  seller_state
FROM `myprojectolist.Olist.sellers`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.order_items` AS
SELECT *
FROM `myprojectolist.Olist.order_items`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.order_payments` AS
SELECT *
FROM `myprojectolist.Olist.order_payments`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.order_reviews` AS
SELECT *
FROM `myprojectolist.Olist.order_reviews`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.orders` AS
SELECT *
FROM `myprojectolist.Olist.orders`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.product_category_name` AS
SELECT 
  string_field_0 AS product_category_name,
  string_field_1 AS product_category_name_English
FROM `myprojectolist.Olist.product_category_name`;

CREATE OR REPLACE TABLE `myprojectolist.Olist_stg.products` AS
SELECT *
FROM `myprojectolist.Olist.products`;

