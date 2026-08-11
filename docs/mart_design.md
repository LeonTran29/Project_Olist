# Mart Design — Olist Delivery Risk

**Layer:** `olist_mart` &nbsp;|&nbsp; **Two fact tables:** order grain (99,441) + line grain (112,650) &nbsp;|&nbsp; **Focus:** operational delivery flow (purchase → delivery)

This doc defines *what to build and why*. It translates the analytical questions into the columns each fact table carries, lists the build rules profiling already decided, and records the validation actually run.

---

## Analytical questions (operational / delivery-flow focus)

The mart answers these five. Scope is deliberately operational — the flow of an order from purchase to delivery — not financial/payment analysis.

1. **Lead time** — how long do orders take to deliver end-to-end? (distribution, median, tail)
2. **Lateness** — what share of delivered orders arrive later than promised, and where does lateness concentrate (customer state, seller state)?
3. **Delivery → satisfaction** — does late delivery pull review scores down?
4. **Category risk** — which product categories carry the most delivery risk (highest late rate / longest delay)? Framed as a risk dimension, not sales volume or value.
5. **Stuck orders** — how many orders never arrive, and where do they stall (state, funnel stage)?

### Out of scope (stated deliberately)
- **Why a score is low** — the reason lives in review comment text, which is 58–88% null. Score-vs-delivery correlation is answerable; stated reasons are not.
- **Payment / installment analysis** — deferred to a future project.

---
## Fact table columns
### For fct_order_delivery (Q1, 2, 3, 5)

Grain = one order. Row count = 99,441.
Q4 (category risk) lives at item grain — see fct_order_items below.

| Column                          | Role   | Source / derivation                         | Serves        |
|---------------------------------|--------|---------------------------------------------|---------------|
| order_id                        | anchor | orders (PK)                                 | key — all     |
| customer_id                     | anchor | orders (FK)                                 | key           |
| customer_state                  | anchor | customers (join on customer_id)             | Q2, Q5        |
| order_status                    | anchor | orders                                      | Q5            |
| order_purchase_timestamp        | anchor | orders                                      | Q1, Q5        |
| order_approved_at               | anchor | orders                                      | Q5            |
| order_delivered_carrier_date    | anchor | orders                                      | Q5            |
| order_delivered_customer_date   | anchor | orders                                      | Q1, Q2, Q3, Q5|
| order_estimated_delivery_date   | anchor | orders                                      | Q2, Q3, Q5    |
| lead_time                       | derive | TIMESTAMP_DIFF(delivered_customer, purchase, DAY)  | Q1     |
| days_vs_promise                 | derive | TIMESTAMP_DIFF(delivered_customer, estimated, DAY) | Q2, Q3 |
| review_score                    | derive | order_reviews: AVG(score) per order,        | Q3            |
|                                 |        | aggregate BEFORE left join (DQ-001 fan-out) |               |
| stall_stage                     | derive | last non-null milestone in funnel chain     | Q5            |

Backbone: `order_delivered_customer_date` (all four questions) and `order_estimated_delivery_date` (three) — every question turns on "did it arrive" and "vs the promise".

### For fct_order_items (Q4: category delivery risk)

Grain = one order-line: (order_id, order_item_id). Row count = 112,650.
Delay values are INHERITED from the parent order — this table does not recompute delivery timing.

| Column                        | Role   | Source / derivation                            | Serves  |
|-------------------------------|--------|------------------------------------------------|---------|
| order_id                      | anchor | order_items (grain key, part 1)                | Q4 key  |
| order_item_id                 | anchor | order_items (grain key, part 2 — NOT unique    | Q4 key  |
|                               |        | alone; sequence no. within an order)           |         |
| product_id                    | anchor | order_items (FK → products)                    | Q4      |
| product_category_name_english | anchor | product_category_name (N:1 on category_name;   | Q4 slice|
|                               |        | COALESCE untranslated → 'uncategorized', keep) |         |
| days_vs_promise               | derive | inherited from parent order (N:1 on order_id)  | Q4      |
| is_late                       | derive | CASE: Not_delivered / Late / Good              | Q4      |

`is_late` logic (ordered so null-timestamp lines are caught first):
```sql
CASE
  WHEN order_delivered_customer_date IS NULL THEN 'Not_delivered'
  WHEN days_vs_promise > 0 THEN 'Late'
  ELSE 'Good'
END
```

---
## Build rules (decided in profiling — do not re-derive)

### For fct_order_delivery
- **review_score:** aggregate to one row per order BEFORE the left join (review_id not unique — 814 dups, 547 orders multi-review; raw join fans out).
- **stall_stage:** derive from the LAST non-null milestone in the funnel chain, ordered latest→earliest so a mid-funnel gap can't mislabel a completed order.
- **Durations:** endpoint difference only, never sum of per-stage gaps (milestones out-of-order/null in some orders — DQ-002).
- **Left-join** items/reviews onto the orders spine, never inner-join (775 orders have no items; would drop and reintroduce survivor bias).

### For fct_order_items
- Grain is the COMPOSITE (order_id, order_item_id); order_item_id alone is a within-order sequence number, not a table-wide PK.
- Source is order_items; the 775 no-item orders are absent by construction (nothing to filter — no line to carry a category). Correct for Q4.
- All joins are N:1 (products, translation, parent order) → no fan-out. Left-join throughout so unmatched products / untranslated categories stay.
- is_late CASE ordered Not_delivered → Late → Good, so null-timestamp lines are caught first, never mislabeled 'Good'.
- Delay inherited from the parent order, not recomputed here.

---
## Metric rules (constrain how each question is measured)

### For fct_order_delivery
Populations differ from table grain (99,441); state the denominator per question:
- **Q1 lead time:** delivered orders (~96k).
- **Q2 late rate:** delivered late / all delivered.
- **Q3 correlation:** all delivered orders — on-time orders are the control group, not noise to filter out.
- **Q5 stuck:** delivered_customer_date IS NULL, excluding status = 'canceled'.
- **"Delivered" = order_delivered_customer_date IS NOT NULL, NOT order_status.** 8 orders have status='delivered' but null timestamp (DQ-007) — excluded from time-based measures, retained in table. Same rule drops any lead_time < 0 (out-of-order timestamps, DQ-002).

### For fct_order_items
- Grouping by category counts ORDER-LINES, not orders. A 3-item late order contributes 3 to its categories' late counts. State this explicitly.
- Late rate = Late / (Late + Good); exclude Not_delivered from the denominator (undelivered lines have no known late/on-time outcome yet).
- Apply a minimum-volume threshold per category before trusting a late rate (a 5-order category at 40% is noise, not risk).
- COALESCE untranslated/uncategorized products to 'uncategorized' so they stay in the ranking (610 no-category, 13 no-translation).

---
## Validation (run after build — results recorded)

### For fct_order_delivery
- Row count = 99,441 exactly — grain preserved, no fan-out. ✓ **99,441**
- COUNT(DISTINCT order_id) = row count — one row per order. ✓ **99,441 = 99,441**
- review_score: no order >1 row after aggregate-then-join (DQ-001 dedup). ✓
- stall_stage 'delivered' ≈ profiling delivered count. ✓ **96,476**
- lead_time >= 0 for delivered orders — chronology holds at endpoints (any negative → bad timestamp, investigate not clip).
- Edge case verified: orders with null approved_at but non-null carrier/customer still label 'delivered' (14 orders inspected) — latest→earliest ordering holds. ✓

### For fct_order_items
- Row count = order_items source count from profiling — no line lost or added across all joins. ✓ **112,650 = 112,650**
- COUNT(DISTINCT (order_id, order_item_id)) = row count — composite grain. ✓
- is_late distribution: Not_delivered **2,454** / Good **102,931** / Late **7,265** (sums to 112,650). Late rate ≈ **6.6%** of delivered order-lines.
- No category null after COALESCE — untranslated stay visible. ✓

---
## Cross-table note

The same undelivered condition appears in both tables at different grains:
- **fct_order_delivery:** 8 orders status='delivered' but null timestamp (DQ-007), plus the broader never-delivered set surfaced via stall_stage.
- **fct_order_items:** 2,454 order-lines labeled 'Not_delivered'.

One phenomenon, two grains — not two separate issues.

---
## Tooling

- Mart built as SQL in BigQuery (`olist_mart`), three-layer (`olist_raw → olist_stg → olist_mart`).
- Analyze: SQL in BigQuery (browser — any device, incl. Mac).
- Dashboard: Power BI Desktop (Windows PC — required, Windows-only).
- Mart lives in BigQuery (cloud), reachable from any device; only the dashboard authoring step is device-bound.
