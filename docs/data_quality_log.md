# Data Quality Log - Project Olist

Log of data quality issues found during profiling.
Finding template: Numbers -> Reading -> So what -> Limits.
---

## DQ-001: zip_code_prefix stored as INT64 (leading zeros lost)
- **Numbers**: 'zip_code_prefix' is INT64 in 3 tables -customers, sellers, geolocation. (customer_zip_code_prefix, seller_zip_code_prefix, geolocation_zip_code_prefix) 
- **Reading**: CSV import auto-detected the column as integer. Brazilian postal code starting with 0 (e.g. 01310) are stored as 1310, dropping the leading zero.
- **So what / Action**: Cast to STRING in the staging layeer. Must be applied consistently across all 3 tables.
- **Fix location**: olist_stg
- **Status**: Open
---

## DQ-002: leading zeros lost in zip_code_prefix (stored as INT64)
- **Numbers**: 'zip_code_prefix' appeared in 4 or 5 characters in 3 tables -customers, sellers, geolocation. (customer_zip_code_prefix, seller_zip_code_prefix, geolocation_zip_code_prefix). Confirmed via LENGTH check.
- **Reading**: Brazilian postal code usually includes 8 characters with the first 5 for prefix, included possible the first '0'.
- **So what / Action**: LPAD to make sure the structure of 5 characters and the first character of '0' if needed. Must be applied consistently across all 3 tables.
- **Fix location**: olist_stg
- **Status**: Open
---




