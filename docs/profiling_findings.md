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

## Shared evidence

Raw output from batched queries, stored once and referenced by ID from the table sections below. Findings cite the source (e.g. `source: E1`) instead of repeating the numbers.

### E1 — Row counts, all tables
`sql/01a_structure.sql` · `Olist_stg.__TABLES__`

| Table | Rows |
|---|---:|
| geolocation | 1,000,163 |
| order_items | 112,650 |
| order_payments | 103,886 |
| orders | 99,441 |
| customers | 99,441 |
| order_reviews | 99,224 |
| products | 32,951 |
| sellers | 3,095 |
| product_category_name | 72 |

**|TABLE|Tier|Value|**
|order_payments|	-	|103886|
|order_items|	A	|112650|
|order_reviews|	A	|99224|
|orders|	A	|99441|
|customers|	B	|99441|
|products|	B	|32951|
|sellers|	B	|3095|
|geolocation|	C	|1000163|
|product_category_name|C|72|

*Anchor ≈ 99.4k across the three order-related tables. Deviations from this anchor are structural (one-to-many relationships or coverage gaps), not random.*

### E2 — PK uniqueness & key nulls
`sql/01b_keys.sql` · *pending*

### E3 — Null rates, all columns
`sql/01c_nulls.sql` · *pending*

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
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

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
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 2. Uniqueness / PK
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

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

## `order_reviews`

> PK: `review_id` · join key: `order_id` · `review_score` is the numeric consequence metric of the delivery flow

### 1. Volume
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 2. Uniqueness / PK
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

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
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 3. Completeness / Null (keys)
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

## `sellers`

> PK: `seller_id`

### 2. Uniqueness / PK
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 3. Completeness / Null (keys)
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

---

## `products`

> PK: `product_id`

### 2. Uniqueness / PK
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

### 3. Completeness / Null (keys)
- **Numbers:**
- **Reading:**
- **So what:**
- **Limits:**

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
