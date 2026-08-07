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
| `customers` | B | PK + join-key nulls (pts 2, 3) | ☑ |
| `sellers` | B | PK + join-key nulls (pts 2, 3) | ☑ |
| `products` | B | PK + join-key nulls (pts 2, 3) | ☑ |
| `geolocation` | C | Coverage only (pt 7) | ☑ |
| `product_category_name` | C | Coverage only (pt 7) | ☑ |
| `order_payments` | — | **Deferred** (payment flow = future project) | ⏸ |

> Mark ☑ when the section below is filled and committed.

---

## Coverage matrix

Rows = tables · Columns = the 8 points · **☐** applicable, not yet done · **☑** done · **–** not applicable

| Table | Tier | 1 Vol | 2 PK | 3 Null | 4 Card | 5 Range | 6 Domain | 7 RefInt | 8 Rule |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `orders` | A | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ |
| `order_items` | A | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☐ |
| `order_reviews` | A | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☑ | ☐ |
| `customers` | B | – | ☑ | ☑ | – | – | – | – | – |
| `sellers` | B | – | ☑ | ☑ | – | – | – | – | – |
| `products` | B | – | ☑ | ☑ | – | – | – | – | – |
| `geolocation` | C | – | – | – | – | – | – | ☑ | – |
| `product_category_name` | C | – | – | – | – | – | – | ☑ | – |
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

### E4 _ Cardinality
|tbl|column_name|card|
|---|---|---:|
|orders|order_status|8|
|order_reviews|review_score|5|

### E5 _ Range
|tbl|first_order|last_order|delivered_before_purchase|
|---|---|---|---:|
|orders|2016-09-04 21:15:19.000000 UTC|2018-10-17 17:30:18.000000 UTC|0|

|tbl|col|min_val|median|p90|p99|max_val|
|---|---|---|---|---|---|---:|
|order_items|price|0.85|74.99|229.8|890.0|6735.0|
|order_items|freight_value|0.0|16.26|34.04|84.38|409.68|

### E6 _ Domain Validity
|tbl|order_status|count|pct|
|---|---|---|---:|
|orders|canceled|625|0.63|
|orders|delivered|96478|97.02|
|orders|invoiced|314|0.32|
|orders|processing|301|0.3|
|orders|shipped|1107|1.11|
|orders|unavailable|609|0.61|
|orders|created|5|0.01|
|orders|approved|2|0.0|
|orders|Total|99441|100.0|

|tbl|review_score|count|pct|
|---|---|---|---:|
|order_reviews|1|11424|11.51|
|order_reviews|2|3151|3.18|
|order_reviews|3|8179|8.24|
|order_reviews|4|19142|19.29|
|order_reviews|5|57328|57.78|
|order_reviews|Total|99224|100.0|

## E7 _ Referential integrity
| Relationship | Direction | Metric | Count |
|---|---|---|---:|
| order_items → orders | forward | orphan items (item with no order) | 0 |
| orders → order_items | reverse | orders with no item | 775 |
| order_items → products | forward | orphan items (item with no product) | 0 |
| order_items → sellers | forward | orphan items (item with no seller) | 0 |
| order_reviews → orders | forward | orphan reviews (review with no order) | 0 |
| orders → order_reviews | reverse | orders with no review | 768 |
| orders → customers | forward | orders with no customer | 0 |

#### product_names_relationship
|total_categories|translated_cat|
|---|---:|
|73|71|

|category|products|
|---|---:|
|no_category|610|
|portateis_cozinha_e_preparadores_de_alimentos|10|
|pc_gamer|3|

#### geolocation_relationship
|relationship|total_zip|matched_zip|
|---|---|---:|
|customers-geo|14994|14837|
|sellers-geo|2246|2239|

## E8 _ Anomaly / business rule
|approved_before_purchase|carrier_before_approved|delivered_before_carrier|delivered_before_purchase|delivered_no_carrier|delivered_no_approval|delivered_no_purchase|
|---|---|---|---|---|---|---:|
|0|1359|23|0|1|14|0|

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
- **Numbers:** order_delivered_customer_date 2,965 null (2.98%) · order_delivered_carrier_date 1,783 (1.79%) · order_approved_at 160 (0.16%); all keys (order_id, customer_id), order_status, order_purchase_timestamp, order_estimated_delivery_date are null-free (source: E3)
- **Reading:** Keys and the purchase/estimate timestamps are complete. Nulls cluster in the delivery-milestone timestamps and thin out earlier in the funnel (2,965 → 1,783 → 160), consistent with orders that stopped partway through fulfilment rather than random data loss.
- **So what:** Delivery-time metrics can only be computed on orders that carry the relevant date, so the ~2,965 without a delivery date must be excluded from those calculations and the dashboard must state its denominator explicitly — otherwise on-time rate is silently measured on survivors. Durations must be computed from endpoint dates directly (customer_date − purchase_date), not by summing per-stage gaps, since milestones are not guaranteed complete-in-sequence (see DQ-004). These orders stay in the fact table — excluded from duration math, not from the dataset.
- **Limits:** A null delivery date does not distinguish an order still in transit from one that will never arrive — both are blank. Separating them requires cross-referencing order_status (point 6), so the cause of these nulls is unresolved, not excluded at this stage.

### 4. Cardinality
- **Numbers:** order_status = 8 distinct values (source: E4)
- **Reading:** Low cardinality — order_status is a small controlled vocabulary, not a free-text or identifier field.
- **So what:** Usable as a categorical filter and grouping dimension on the dashboard. The 8 values gate survivor-bias handling — the non-delivered states are the failure cases that must stay in the fact table.
- **Limits:** Cardinality confirms how many values exist, not which ones or whether any are invalid — the value list and its validity are checked in point 6.

### 5. Range / Distribution
- **Numbers:** Purchase window 2016-09-04 → 2018-10-17 (~25 months); delivered_before_purchase = 0 (source: E5)
- **Reading:** Orders span roughly two years with no chronology violation — no delivery precedes its purchase. Coverage is uneven at the edges: 2016 contributes very few orders (Olist's early ramp-up), and the series ends abruptly in late 2018.
- **So what:** Time-series charts must annotate or trim the sparse 2016 tail so it doesn't read as a volume collapse; the analysis window is effectively ~2017 to mid-2018. The zero chronology violations confirm delivery_days can be computed by straight date subtraction without guarding against negative values.
- **Limits:** Min/max define the boundaries, not the density — they don't reveal whether orders are evenly spread or clustered. Monthly volume distribution is a separate check, deferred to the dashboard build.

### 6. Domain validity
- **Numbers:** 8 valid statuses, no typos or casing variants. delivered 96,478 (97.02%); non-delivered tail 2,963 (2.98%): shipped 1,107, canceled 625, unavailable 609, invoiced 314, processing 301, created 5, approved 2. (source: E6)
- **Reading:** All values are legitimate Olist order states — the column is clean. Distribution is dominated by delivered.
- **So what:** Usable as a filter dimension with no cleaning. The 2.98% non-delivered tail must stay in the fact table — dropping it measures on-time rate on survivors only.
- **Limits:** Valid labels are not necessarily accurate — 14 orders contradict their delivery timestamp (see DQ-003). Where status and timestamp disagree, trust the timestamp.

### 7. Referential integrity
**7.1 orders ↔ customers**
- **Numbers:** 0 orphan orders (forward); 0 customers without orders (reverse) (source: E7)
- **Reading:** Every order resolves to a customer, and every customer has exactly one order — confirming the 1:1 relationship (customer_id is per-order, established in points 2 and 4).
- **So what:** Customer dimension joins without row loss in either direction.
- **Limits:** Existence only.

### 8. Anomaly / business rule
- **Numbers:** Tested 6 business rules on milestone ordering. Violations: delivered_before_purchase 0 · approved_before_purchase 0 · carrier_before_approved 1,359 · delivered_before_carrier 23 · delivered_no_carrier 1 · delivered_no_approval 14. (source: E8)
- **Reading:** Two clean rules (nothing delivered or approved before purchase) confirm the purchase timestamp is a reliable anchor. The 1,359 carrier < approved cases are systematic with small gaps (hours to ~1 day) — not errors, but evidence that approval and carrier handoff run as parallel processes, not a strict sequence. The 23 delivered < carrier cases are different: gaps of several days, physically impossible (customer received before carrier pickup), so a genuine inconsistency. The 15 missing-milestone cases (1 carrier, 14 approval) are gaps in recording, not sequence errors.
- **So what:** Milestones are not strictly sequential and not always complete, so delivery duration must be computed from endpoint dates only (delivered_customer_date − purchase_timestamp), never by summing per-stage gaps — intermediate stages can be out of order or null. The purchase and customer-delivery timestamps are the two trustworthy anchors. All anomalies are immaterial to aggregates (≤1.4%) and stay in the fact table.
- **Limits:** The data shows that milestones conflict, not why or which timestamp is wrong — resolving that needs Olist's process documentation, which isn't available. Rules tested cover ordering and completeness; a violation type not hypothesized would pass unnoticed.

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
- Not applicable — no categorical columns. The identifiers (order_id, product_id, seller_id) are covered in point 2; price and freight_value are continuous and profiled in point 5; order_item_id is a within-order sequence, not a category.

### 5. Range / Distribution
- **Numbers:** price median 74.99, p90 229.8, p99 890, max 6,735 (min 0.85). freight_value median 16.26, p99 84.38, max 409.68 (min 0) (source: E5)
- **Reading:** Both are heavily right-skewed. Price max is ~7.5× p99, so a tiny tail of high-value items sits far above a low typical value (~75). Freight follows the same shape; min freight = 0 (likely free-shipping, not missing).
- **So what:** Value and freight metrics must use median, not mean — the mean is dragged by the tail and would misstate the typical order. The high-value tail is legitimate (not a data error), so it stays in the fact table; it only needs awareness when averaging. Free-shipping (freight = 0) should be confirmed as intentional before treating it as a category.
- **Limits:** Quantiles describe the shape but not the cause of the tail — whether high prices concentrate in specific categories or sellers is a separate question for the analysis phase.

### 6. Domain validity
Not applicable — no categorical columns. Identifiers are covered in point 2, continuous fields in point 5; there is no fixed-vocabulary column to validate.
- **Numbers:** N/A
- **Reading:** N/A
- **So what:** N/A
- **Limits:** N/A

### 7. Referential integrity
**7.1 · order_items ↔ orders**
- **Numbers:** 0 orphans (forward); 775 orders without items (reverse) (source: E7)
- **Reading:** No item points to a non-existent order. Reverse side: 775 orders carry no line item — 99% unavailable (603) / canceled (164), expected for incomplete orders; 8 anomalous (created/invoiced/shipped) that reached later stages without items.
- **So what:** Mart must left-join order_items onto the orders spine — inner join drops the 775 and causes survivor bias. Revenue for them = 0, not missing. The 767 incomplete orders are kept as unmet-demand signal.
- **Limits:** The 8 anomalies have no confirmed cause; mid-process capture vs data-entry gap indistinguishable here.

**7.2 · order_items ↔ products**
- **Numbers:** 0 orphan orders (forward); 0 products (reverse) (source: E7)
- **Reading:** Every item resolves to an existing product.
- **So what:** Safe to join product attributes (category, dimensions) onto the item grain.
- **Limits:** Confirms the product exists, not that it's the correct one for the item.

**7.3 · order_items ↔ sellers**
- **Numbers:** 0 orphan orders (forward); 0 sellers (reverse) (source: E7)
- **Reading:** Every item resolves to an existing seller.
- **So what:** Safe to join seller attributes (state, location) onto the item grain — needed for the seller→customer distance analysis.
- **Limits:** Confirms the seller exists, not that the link is correct.

### 8. Anomaly / business rule
Not applicable — no multi-column business rule to test. order_items has no timestamp sequence or cross-field logic like orders. Value sanity (price/freight ≥ 0) was covered in point 5; identifiers in points 2 and 7.
- **Numbers:** N/A
- **Reading:** N/A
- **So what:** N/A
- **Limits:** N/A

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
- **Numbers:** review_comment_title 87,656 null (88.15%), review_comment_message 58,247 null (58.57%); review_score 0 null (source: E3)
- **Reading:** Comment text is mostly empty, yet every review carries a score. The gap is confined to free-text fields — the rating itself is always present.
- **So what:** Score is usable across all 99,224 reviews as the delivery consequence metric, with no missingness to weight for. Empty comments are normal user behaviour (rating without typing), not a defect — no DQ. Any future text analysis runs on a ~41k subset, not the full set.
- **Limits:** The data captures what customers rated but rarely why — the reason behind a score is available for fewer than half of reviews. This constrains qualitative analysis, not the score-based delivery analysis in scope.

### 4. Cardinality
- **Numbers:** review_score = 5 distinct values (source: E4)
- **Reading:** review_score is numeric but categorical — a fixed 1–5 rating scale, not a continuous measure.
- **So what:** Groupable as the delivery consequence metric (e.g. share of 1-star vs 5-star by delivery lateness). Its 5-level structure makes it a clean dimension to cross with delivery outcomes.
- **Limits:** 5 distinct values matches the expected scale, but cardinality alone does not confirm the values are exactly {1,2,3,4,5} with none outside range — verified in point 6.

### 5. Range / Distribution
Not applicable — no continuous columns. review_score is a discrete 1–5 scale (categorical, covered in points 4 and 6); the timestamp columns carry no analytical range in this project's scope, and the text/ID fields are non-numeric.
- **Numbers:** N/A
- **Reading:** N/A
- **So what:** N/A
- **Limits:** N/A

### 6. Domain validity
- **Numbers:** Exactly 5 values (1–5), none out of range or null. score 5 = 57.78%, 4 = 19.29%, 3 = 8.24%, 2 = 3.18%, 1 = 11.51%.
- **Reading:** review_score is fully valid within the 1–5 domain. Distribution skews high — 77% are 4–5 stars — with a notable 11.5% at 1 star.
- **So what:** Usable as the delivery consequence metric across all reviews. The high-skew baseline means the 1-star cluster is the signal to trace back against late deliveries — the core link of this project.
- **Limits:** Score captures that a review is bad, not why — reason is only in comment text, which is 58% null. Low scores can't be attributed to delivery vs product quality from this column alone.

### 7. Referential integrity
**7.1 · order_reviews ↔ orders**
- **Numbers:** 0 orphan reviews (forward); 768 orders with no review (reverse) (source: E7)
- **Reading:** Every review resolves to an existing order. Reverse side: 768 orders received no review at all — customers who completed a purchase but never rated it.
- **So what:** Reviews attach cleanly to the order grain (after DQ-001 aggregation to one row per order). The 768 unreviewed orders mean review_score covers 99.2% of orders — high enough to use as the delivery consequence metric without weighting, but the fact table must left-join reviews so these 768 keep a NULL score rather than dropping.
- **Limits:** Existence only — does not test whether a review belongs to the right order. The 768 gap is unreviewed orders, not missing data.

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
- **Numbers:** Keys (product_id) 0 nulls (source: E3). product_category_name 610 nulls (1.9%) — surfaced later during the point-7 translation join. (source: E7)
- **Reading:** The primary key is complete. But product_category_name — needed as a delivery-analysis dimension — has 610 products with no category assigned.
- **So what:** product_id serves as a clean dimension join with no null-handling. The 610 uncategorized products, however, would silently drop from any category-based breakdown; assign them an 'uncategorized' label in the mart so they stay visible.
- **Limits:** Other non-key attributes (weight, dimensions) remain unchecked — out of scope for delivery analysis. Category was initially treated the same but proved in-scope once it became a grouping dimension.

---

# Tier C — coverage confirmation only

## `geolocation`

> Join key: `geolocation_zip_code_prefix` — many-to-one against customer/seller zip; multiple rows per prefix expected

### 7. Referential integrity / coverage
- **Numbers:** customers 14,994 zip prefixes, 14,837 matched (98.95%), 157 unmatched. sellers 2,246 zip prefixes, 2,239 matched (99.69%), 7 unmatched. (source: E7)
- **Reading:** Both sides resolve almost fully to coordinates — 157 customer prefixes (1.05%) and 7 seller prefixes (0.31%) have none. Not random loss; likely remote or newer postal areas absent from the geolocation reference. Unit is zip prefix, not individual customers/sellers.
- **So what:** Seller-to-customer distance analysis is viable — ~99% of both sides geolocate. Unmatched prefixes yield NULL distance; handle with a state-level centroid fallback or exclude with a stated denominator, don't let them drop silently. Too few to distort geographic aggregates.
- **Limits:** Coverage confirms a coordinate exists for the prefix, not that it's accurate. Geolocation holds many points per prefix (1M rows / ~19K prefixes) — the mart must aggregate to one representative centroid per prefix before computing distance, or distance values are ambiguous.

---

## `product_category_name`

> Translation lookup: `product_category_name` → `product_category_name_english`

### 7. Referential integrity / coverage
- **Numbers:** 73 categories in products, 71 translated. 2 genuine categories lack an English translation: portateis_cozinha_e_preparadores_de_alimentos (10 products), pc_gamer (3 products) — 13 products total. (Source: E7)
- **Reading:** Translation coverage is 97% (71/73). The 2 gaps are specific, named categories the translation table simply doesn't include — not random loss. Impact is tiny: 13 products across both.
- **So what:** These 13 products return NULL on the English-name join. In the mart, use COALESCE(english_name, original_name) so they display the Portuguese label instead of blank, or tag them unmapped. Too few to distort any category-level aggregate.
- **Limits:** Coverage confirms which categories are untranslated and how many products they touch, but not why the translation table omits them. The 13-product impact is bounded and immaterial.

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
