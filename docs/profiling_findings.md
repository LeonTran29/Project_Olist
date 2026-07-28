# Data Profiling Findings — Olist E-Commerce

**Layer profiled:** `Olist_stg` &nbsp;|&nbsp; **Phase:** Profiling (`sql/01*`) &nbsp;|&nbsp; **Grain focus:** delivery flow (purchase → delivery)

---

## Scope & relationship to other docs

This file is the **systematic characterization** of each table under the 8-point framework. It records what the data *is* — baselines, distributions, cardinality, coverage — not only what is wrong. It is the evidence trail behind the modeling decisions in `strategy.md`.

| Doc | Answers | Contains |
|---|---|---|
| `strategy.md` | *What did we decide and why?* | Architecture & modeling decisions (stable) |
| `profiling_findings.md` *(this file)* | *What is the data actually like?* | 8-point observations per table (accumulating) |
| `data_quality_log` | *What is broken and what did we do about it?* | Defect register: issue, severity, status, resolution |

**Rule:** when profiling surfaces a genuine defect, write one line in the finding's *So what* and link to its `data_quality_log` entry (`DQ-###`). Do **not** duplicate the defect detail here.

---

## Finding template

Every finding follows the fixed shape:

- **Numbers** — the raw metric / query output.
- **Reading** — what it says literally.
- **So what** — implication for the mart, dashboard, or analysis (link `DQ-###` if it's a defect).
- **Limits** — what this metric does *not* tell us; caveats.

---

## The 8 points

| # | Point | Question |
|---|---|---|
| 1 | **Volume** | Row count per table — does it match expectation? (baseline for later comparison) |
| 2 | **Uniqueness / PK** | Is the primary key actually unique? *(grain trap: `customer_id` is per-order, not per-person)* |
| 3 | **Completeness / Null** | Null rate per column — especially join keys and delivery-logic columns |
| 4 | **Cardinality** | Distinct-value count — spot near-constant columns or fake identifiers |
| 5 | **Range / Distribution** | min/max/quantiles for numeric & date (`APPROX_QUANTILES`) — negative, future, or impossible dates? |
| 6 | **Domain validity** | Do categorical values sit in the allowed set? (`order_status`, `review_score` 1–5) |
| 7 | **Referential integrity** | Orphans across tables — does every FK resolve? *(critical for the star schema)* |
| 8 | **Anomaly / business rule** | Business-rule violations (delivered but no delivery date, empty order_items…) *(keep all statuses — avoid survivor bias)* |

---

## Table tiers & status

| Table | Tier | Treatment | Status |
|---|---|---|---|
| `orders` | A | Full 8-point | ☐ |
| `order_items` | A | Full 8-point | ☐ |
| `order_reviews` | A | Full 8-point | ☐ |
| `customers` | B | PK + join-key nulls (pts 2, 3) | ☐ |
| `sellers` | B | PK + join-key nulls (pts 2, 3) | ☐ |
| `products` | B | PK + join-key nulls (pts 2, 3) | ☐ |
| `geolocation` | C | Coverage only (pt 7) | ☐ |
| `product_category_name` | C | Coverage only (pt 7) | ☐ |
| `order_payments` | — | **Deferred** (payment flow = future project) | ⏸ |

> Mark ☑ when the section below is filled and committed.

---

## Coverage matrix

Rows = tables · Columns = the 8 points · **☐** applicable, not yet done · **☑** done · **–** not applicable

| Table | Tier | 1 Vol | 2 PK | 3 Null | 4 Card | 5 Range | 6 Domain | 7 RefInt | 8 Rule |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `orders` | A | ☑ | ☑ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| `order_items` | A | ☑ | ☑ | ☑ | ☐ | ☐ | ☐ | ☐ | ☐ |
| `order_reviews` | A | ☑ | ☑ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| `customers` | B | – | ☑ | ☑ | – | – | – | – | – |
| `sellers` | B | – | ☑ | ☑ | – | – | – | – | – |
| `products` | B | – | ☑ | ☑ | – | – | – | – | – |
| `geolocation` | C | – | – | – | – | – | – | ☐ | – |
| `product_category_name` | C | – | – | – | – | – | – | ☐ | – |
| `order_payments` | ⏸ | – | – | – | – | – | – | – | – |

**Why the blanks:** Tier B tables are dimensions — their only job is to join cleanly, so key integrity (2, 3) is sufficient. Tier C tables are lookups where the sole risk is incomplete coverage (7); `geolocation` in particular has no primary key by design, making point 2 inapplicable rather than unmeasured. `order_payments` is deferred: its grain is payment-level, not order-level, and the payment flow is scoped to a future project.

Point 1 is closed for all three Tier A tables *(source: E1)*.

---

## Shared evidence

Raw output from batched queries, stored once and referenced by ID from the table sections below. Findings cite the source (e.g. `source: E1`) instead of repeating the numbers.

### E1 — Row counts, all tables
`sql/01a_structure.sql` · `Olist_stg.__TABLES__`

|TABLE|Tier|Value|
|---|---|---:|
|order_payments|	-	|103,886|
|order_items|	A	|112,650|
|order_reviews|	A	|99,224|
|orders|	A	|99,441|
|customers|	B	|99,441|
|products|	B	|32,951|
|sellers|	B	|3,095|
|geolocation|	C	|1,000,163|
|product_category_name|C|72|

*Anchor ≈ 99.4k across the three order-related tables. Deviations from this anchor are structural (one-to-many relationships or coverage gaps), not random.*

### E2 — PK uniqueness & key nulls
`sql/01b_keys.sql` · `Olist_stg.__TABLES__`

|TABLE|Tier|Size|PK|
|---|---|---|---:|
|order_items|A|112650|112650|
|order_reviews|A|99224|98410|
|orders|A|99441|99441|
|customers|B|99441|99441|
|products|B|32951|32951|
|sellers|B|3095|3095|

### E3 — Null rates, all columns
`sql/01c_nulls.sql` · *pending*

|TABLE: orders|tbl|column_name|null_count|null_pct|
|---|---|---|---|---:|
|1|orders|order_delivered_customer_date|2965|2.98|
|2|orders|order_delivered_carrier_date|1783|1.79|
|3|orders|order_approved_at|160|0.16|
|4|orders|order_id|0|0.0|
|5|orders|customer_id|0|0.0|
|6|orders|order_status|0|0.0|
|7|orders|order_purchase_timestamp|0|0.0|
|8|orders|order_estimated_delivery_date|0|0.0|

|TABLE: order_items|tbl|column_name|null_count|null_pct|
|---|---|---|---|---:|
|1|order_items|order_id|0|0.0|
|2|order_items|order_item_id|0|0.0|
|3|order_items|product_id|0|0.0|
|4|order_items|seller_id|0|0.0|
|5|order_items|shipping_limit_date|0|0.0|
|6|order_items|price|0|0.0|
|7|order_items|freight_value|0|0.0|

|TABLE: order_items|tbl|column_name|null_count|null_pct|
|---|---|---|---|---:|
|1| order_reviews | review_comment_title | 87656 | 88.15 |
|2| order_reviews | review_comment_message | 58247 | 58.57 |
|3| order_reviews | review_id | 0 | 0.00 |
|4| order_reviews | order_id | 0 | 0.00 |
|5| order_reviews | review_score | 0 | 0.00 |
|6| order_reviews | review_creation_date | 0 | 0.00 |
|7| order_reviews | review_answer_timestamp | 0 | 0.00 |

|TABLEs|tbl|column_name|null_count|null_pct|
|---|---|---|---|---:|
|1|customers|customer_id|0|0.0|
|2|customers|customer_unique_id|0|0.0|
|3|products|product_id|0|0.0|
|4|sellers|seller_id|0|0.0|

---

# Tier A — full 8-point

## `orders`

> PK: `order_id` · join keys: `customer_id` · key dates drive `is_late` / `days_vs_promise`

### 1. Volume
- **Numbers:** 99,441 rows *(source: E1)*
- **Reading:** The anchor volume for the whole model — one row per order. Exactly equal to `customers`, which places the per-order interpretation of `customer_id` under suspicion rather than the per-person one.
- **So what:** The order-grain fact table must land on exactly 99,441 rows. Any other figure after joins signals fan-out or dropped rows, not a change in the business. Repeat-buyer analysis must route through `customer_unique_id`.
- **Limits:** Row count describes volume only — it says nothing about duplicate IDs, nulls, or row validity. The match with `customers` is *consistent with* the per-order reading but does not prove it; confirmed via cardinality in point 4.

### 2. Uniqueness / PK
- **Numbers:** 99441 (source: E2)
- **Reading:** The same number of PK and Volume. Every order_id is unique, no null, no duplication.
- **So what:** It's safe to join spine in star schema, every fan-out is from the other boards, not the orders dataset.
- **Limits:** N/A

### 3. Completeness / Null
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 4. Cardinality
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 5. Range / Distribution
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 6. Domain validity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 7. Referential integrity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 8. Anomaly / business rule
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

## `order_items`

> PK: (`order_id`, `order_item_id`) — composite · join keys: `order_id`, `product_id`, `seller_id` · one-to-many with `orders` (double-count trap)

### 1. Volume
- **Numbers:** 112,650 rows (source: E1). Max items per order = 21.
- **Reading:** 112,650 units sold across 99,441 orders — 1.13 units per order. The table is one-to-many with orders: most orders carry a single line, but one reaches 21. Each row is one unit sold, not one distinct product; products holds 32,951 SKUs.
- **So what:** 112,650 is the baseline for units sold in this period; any other figure signals a problem upstream. When joining to orders, order counts must use COUNT(DISTINCT order_id) — the raw join returns 112,650 rows and would inflate order volume by 13%. The gap between the two figures is itself measurable as an add-on purchase rate.
- **Limits:** Fulfilment outcome per line is unknown — how many units were delivered, stalled, or cancelled cannot be determined from this table. The 1.13 average hides the shape of the distribution between 1 and 21. It is also computed against all orders, including 775 that carry no line at all (quantified in point 7); measured only against orders that do have lines, the figure is 1.14.

### 2. Uniqueness / PK
- **Numbers:** dup_rows = 0 (source: E2)
- **Reading:** Each PK is fully unique - row count equal distinct-key count. This confirm the compiste (order_id, order_item_id) holds.
- **So what:** Being safe join anchor, no fan-out on its own. Their role as the "one" or "many size is fixed per relationship, verified in point 7.
- **Limits:** Uniqueness of the key does not guarantee each row is a disintct business event.

### 3. Completeness / Null
- **Numbers:** 0 nulls in all columns (source: E3)
- **Reading:** Every column is null-free — both the keys (order_id, product_id, seller_id) and the value fields (price, freight_value).
- **So what:** The table joins cleanly on all three foreign keys, and revenue metrics can be computed without null-handling. Joining to orders must preserve exactly 112,650 rows — fewer means items were dropped, more means the order side duplicated.
- **Limits:** Zero nulls confirms presence, not correctness — a price or key can be non-null yet wrong. Value ranges are checked in point 5.

### 4. Cardinality
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 5. Range / Distribution
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 6. Domain validity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 7. Referential integrity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 8. Anomaly / business rule
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

## `order_reviews`

> PK: `review_id` · join key: `order_id` · `review_score` is the numeric consequence metric of the delivery flow

### 1. Volume
- **Numbers:** 99,224 rows (source: E1)
- **Reading:** 217 fewer rows than the 99,441 order anchor — a 0.22% gap. One row per review record.
- **So what:** Review coverage is high enough that review_score is usable as the consequence metric for delivery analysis without weighting for missingness. The join to orders must be left-joined from the order spine and cannot be assumed 1:1 until uniqueness is verified.
- **Limits:** A net difference of 217 does not identify its cause. Three scenarios produce the same total: 217 orders genuinely -unreviewed, duplicate review_id values, or some orders carrying multiple reviews offset by more orders carrying none. Fan-out risk on join is therefore unresolved, not excluded — see points 2 and 7.

### 2. Uniqueness / PK
- **Numbers:** 98410 vs 99224, dup_rows 814 (source: E2)
- **Reading:** review_id is not unique — 814 rows violate it. Both 789 review_ids repeat and 547 orders carry more than one review, so duplication runs in both directions, not one.
- **So what:** review_id cannot be the join key to orders. The review dimension must be aggregated to order grain before joining (AVG(review_score), COUNT reviews) or it fans out. Logged as DQ-003.
- **Limits:** dup_rows alone does not separate exact-duplicate rows from genuine multi-order reviews; resolution depends on that split (pending query).

### 3. Completeness / Null
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 4. Cardinality
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 5. Range / Distribution
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 6. Domain validity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 7. Referential integrity
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 8. Anomaly / business rule
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

# Tier B — PK & join-key nulls only

## `customers`

> PK: `customer_id` (per-order) · `customer_unique_id` = the real person key for repeat-buyer analysis

### 2. Uniqueness / PK
- **Numbers:** dup_rows = 0 (source: E2)
- **Reading:** Each PK is fully unique - row count equal distinct-key count.
- **So what:** Being safe join anchor, no fan-out on its own. Their role as the "one" or "many size is fixed per relationship, verified in point 7.
- **Limits:** Uniqueness of the key does not guarantee each row is a disintct business event.

### 3. Completeness / Null (keys)
- **Numbers:** 0 nulls across all keys (source: E3)
- **Reading:** All primary and foreign keys return 0 nulls.
- **So what:** It serve as dimension joins without dropping rows; no defensive null-handling is needed when attaching them to the fact table.
- **Limits:** Only key columns were checked — non-key attributes are intentionally out of scope for delivery analysis. Null-free keys guarantee clean joins, not full completeness of every column.

---

## `sellers`

> PK: `seller_id`

### 2. Uniqueness / PK
- **Numbers:** dup_rows = 0 (source: E2)
- **Reading:** Each PK is fully unique - row count equal distinct-key count.
- **So what:** Being safe join anchor, no fan-out on its own. Their role as the "one" or "many size is fixed per relationship, verified in point 7.
- **Limits:** Uniqueness of the key does not guarantee each row is a disintct business event.

### 3. Completeness / Null (keys)
- **Numbers:** 0 nulls across all keys (source: E3)
- **Reading:** The primary key return 0 nulls.
- **So what:** It serve as dimension joins without dropping rows; no defensive null-handling is needed when attaching them to the fact table.
- **Limits:** Only key columns were checked — non-key attributes are intentionally out of scope for delivery analysis. Null-free keys guarantee clean joins, not full completeness of every column.

---

## `products`

> PK: `product_id`

### 2. Uniqueness / PK
- **Numbers:** dup_rows = 0 (source: E2)
- **Reading:** Each PK is fully unique - row count equal distinct-key count.
- **So what:** Being safe join anchor, no fan-out on its own. Their role as the "one" or "many size is fixed per relationship, verified in point 7.
- **Limits:** Uniqueness of the key does not guarantee each row is a disintct business event.

### 3. Completeness / Null (keys)
- **Numbers:** 0 nulls across all keys (source: E3)
- **Reading:** The primary key return 0 nulls.
- **So what:** It serve as dimension joins without dropping rows; no defensive null-handling is needed when attaching them to the fact table.
- **Limits:** Only key columns were checked — non-key attributes are intentionally out of scope for delivery analysis. Null-free keys guarantee clean joins, not full completeness of every column.

---

# Tier C — coverage confirmation only

## `geolocation`

> Join key: `geolocation_zip_code_prefix` — many-to-one against customer/seller zip; multiple rows per prefix expected

### 7. Referential integrity / coverage
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

## `product_category_name`

> Translation lookup: `product_category_name` → `product_category_name_english`

### 7. Referential integrity / coverage
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

# Deferred

## `order_payments`
⏸ Payment / installment flow is scoped to a future project. Not profiled in this pass.

---

## Open hypotheses to confirm

Known Olist quirks are treated as hypotheses to **confirm by query**, not assumed:

- [ ] Zip-code prefix loses leading zeros when stored as INT64 *(handled at stg via `LPAD`)*
- [ ] Timestamp columns imported as STRING → would break `is_late` / `days_vs_promise` *(verify `orders` date columns before building mart)*
- [ ] `customer_id` is per-order, not per-person → use `customer_unique_id` for repeat-buyer logic
- [ ] `geolocation` has multiple rows per zip prefix → aggregate before joining to avoid fan-out
