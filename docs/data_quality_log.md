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

## DQ-003: 814 noted rows (Not unique) in order_reviews table
- **Numbers**: 814 dup_rows, 789 review_ids repeat, 547 orders carry multiple reviws.
- **Reading**: 
- **So what / Action**: Joining order_reviews to orders on reviews_id will fan-out.
- **Fix location**: olist_stg
- **Status**: Open
---

## DQ-004 · orders · timestamp chronology
- **Numbers**: 15 issue orders
- **Reading**: 15 orders have a delivery date while an earlier milestone is null: 1 missing carrier handoff, 14 missing approval. Below materiality for aggregates
- **Impact**: milestone timestamps are not guaranteed complete-in-sequence — compute durations from endpoint dates directly, not by summing per-stage gaps. 
- **Fix location**: olist_stg
- **Status**: OPEN, no correction planned.
---

## DQ-005 · orders · status–delivery date consistency
- **Numbers**: 14 contradicting orders
- **Reading**: 14 orders show a mismatch between order_status and delivery date: 8 marked delivered with a null delivery date, 6 non-delivered carrying a delivery date. Below materiality for aggregates (14 of 99,441).
- **Impact**: order_status and delivery timestamps are not fully consistent — where they disagree, trust the timestamp (the measured event) over the status label; delivered-status orders without a date drop out of duration metrics naturally.
- **Fix location**: olist_stg
- **Status**: OPEN, no correction planned

