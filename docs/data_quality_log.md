# Data Quality Log - Project Olist

Log of data quality issues found during profiling.
Finding template: Numbers -> Reading -> So what -> Limits.

---

## DQ-001: zip_code_prefix stored as INT64 (leading zeros lost)
- **Numbers**: `zip_code_prefix` is INT64 in 3 tables — customers, sellers, geolocation (customer_zip_code_prefix, seller_zip_code_prefix, geolocation_zip_code_prefix).
- **Reading**: CSV import auto-detected the column as integer. Brazilian postal codes starting with 0 (e.g. 01310) are stored as 1310, dropping the leading zero.
- **So what / Action**: Cast to STRING in the staging layer. Must be applied consistently across all 3 tables.
- **Fix location**: olist_stg
- **Status**: RESOLVED (CAST AS STRING applied in staging)

---

## DQ-002: leading zeros lost in zip_code_prefix (stored as INT64)
- **Numbers**: `zip_code_prefix` appeared as 4 or 5 characters in 3 tables — customers, sellers, geolocation (customer_zip_code_prefix, seller_zip_code_prefix, geolocation_zip_code_prefix). Confirmed via LENGTH check.
- **Reading**: Brazilian postal codes usually include 8 characters, with the first 5 as the prefix, possibly including a leading '0'.
- **So what / Action**: LPAD to enforce a 5-character structure with a leading '0' where needed. Must be applied consistently across all 3 tables.
- **Fix location**: olist_stg
- **Status**: RESOLVED (LPAD(..., 5, '0') applied in staging)

---

## DQ-003: 814 non-unique rows in order_reviews table
- **Numbers**: 814 dup_rows, 789 review_ids repeat, 547 orders carry multiple reviews.
- **Reading**: `review_id` is not unique. Duplication runs both ways — 789 review_ids repeat and 547 orders carry more than one review. This is a genuine primary-key defect, not expected behaviour.
- **So what / Action**: Cannot join order_reviews to orders on review_id — it will fan out. Aggregate reviews to one row per order (AVG score / COUNT reviews) before joining. This is the one DQ that changes mart design.
- **Fix location**: mart logic (aggregate before join)
- **Status**: OPEN

---

## DQ-004 · orders · timestamp chronology (missing milestones)
- **Numbers**: 15 issue orders.
- **Reading**: 15 orders have a delivery date while an earlier milestone is null: 1 missing carrier handoff, 14 missing approval. Below materiality for aggregates.
- **Impact**: Milestone timestamps are not guaranteed complete-in-sequence — compute durations from endpoint dates directly, not by summing per-stage gaps.
- **Fix location**: none — handle in mart logic (endpoint-based duration)
- **Status**: OPEN, no correction planned

---

## DQ-005 · orders · status–delivery date consistency
- **Numbers**: 14 contradicting orders.
- **Reading**: 14 orders show a mismatch between order_status and delivery date: 8 marked delivered with a null delivery date, 6 non-delivered carrying a delivery date. Below materiality for aggregates (14 of 99,441).
- **Impact**: order_status and delivery timestamps are not fully consistent — where they disagree, trust the timestamp (the measured event) over the status label; delivered-status orders without a date drop out of duration metrics naturally.
- **Fix location**: none — handle in mart logic
- **Status**: OPEN, no correction planned

---

## DQ-006 · orders · milestone order reversal
- **Numbers**: 23 orders where delivered_customer_date is earlier than delivered_carrier_date.
- **Reading**: The customer received the item before it was handed to the carrier — physically impossible, with gaps up to several days. A genuine logical inconsistency, not rounding. (Note: 1,359 orders with carrier_date earlier than approved_at were also found, but are NOT a defect — small, systematic gaps consistent with approval and carrier handoff running as parallel processes rather than a strict sequence.)
- **Impact**: Reinforces endpoint-based duration (delivered_customer − purchase); the carrier timestamp is unreliable for these orders. Immaterial to aggregates (23 of 99,441).
- **Fix location**: none — handle in mart logic
- **Status**: OPEN, no correction planned

---

### DQ-007 — Status/timestamp mismatch: delivered without timestamp

**Numbers:** 8 orders with `order_status = 'delivered'` but null `order_delivered_customer_date`.
Identification:
```sql
order_status = 'delivered'
AND order_delivered_customer_date IS NULL
```

**Reading:** Status marks the order as delivered, but the delivery timestamp is missing — a status/timestamp contradiction, not a delivery that never happened. Likely a status-update gap at the source, not a data-model defect.

**Impact:** All time-based measures (`lead_time`, `days_vs_promise`, Q3 correlation) are computed from timestamps. These 8 orders yield no valid duration, so counting "delivered" by status overstates the measurable population vs counting by timestamp. Same condition surfaces at item grain in `fct_order_items` as `is_late = 'Not_delivered'` (2,454 order-lines), kept as a distinct label rather than folded into `'Good'`.

**Fix location:** Metric layer, not the build. Define "delivered" = `order_delivered_customer_date IS NOT NULL` (not `order_status`); exclude this group from time-based measures (Q1/Q2/Q3). Rows are retained in the table (grain preserved, still visible to Q5). The `order_id` list is reproducible from the identification rule — not enumerated (store the rule, not the list).

**Status:** Resolved — handled by the timestamp-based "delivered" definition.







