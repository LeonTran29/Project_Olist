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


