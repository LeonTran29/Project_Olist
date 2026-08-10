# Mart Design — Olist Delivery Risk

**Layer:** `olist_mart` &nbsp;|&nbsp; **Grain:** one row per order (99,441) &nbsp;|&nbsp; **Focus:** delivery flow (purchase → delivery)

This doc defines *what to build and why* before writing SQL. It translates the analytical questions into the columns the fact table must carry, and lists the build rules that profiling already decided.

---

## Analytical questions (operational / delivery-flow focus)

The mart answers these five. Scope is deliberately operational — the flow of an order from purchase to delivery — not financial/payment analysis.

1. **Lead time** — how long do orders take to deliver end-to-end? (distribution, median, tail)
2. **Lateness** — what share of delivered orders arrive later than promised, and where does lateness concentrate (customer state, seller state)?
3. **Delivery** → satisfaction — does late delivery pull review scores down?
4. **Category risk** — which product categories carry the most delivery risk (highest late rate / longest delay)? Framed as a risk dimension, not sales volume or value.
5. **Stuck orders** — how many orders never arrive, and where do they stall (state, funnel stage)?
   
### Out of scope (stated deliberately)
- **Why a score is low** — the reason lives in review comment text, which is 58–88% null (point 3). Score-vs-delivery correlation is answerable; stated reasons are not.
- **Payment / installment analysis** — deferred to a future project.

---
## Fact table columns
### For fct_order_delivery (Q1,2,3,5)

Grain = one order. Scope: operational delivery flow (purchase → delivery).
Q4 (category risk) deferred — lives at item grain, handled separately.

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
| lead_time                       | derive | delivered_customer − purchase               | Q1            |
| days_vs_promise                 | derive | delivered_customer − estimated              | Q2, Q3        |
| review_score                    | derive | order_reviews: AVG(score) per order,        | Q3            |
|                                 |        | aggregate BEFORE left join (DQ-001 fan-out) |               |
| stall_stage                     | derive | last non-null milestone in funnel chain     | Q5            |

##### Notes
Populations differ from table grain (99,441); state the denominator per question:
- Q1 lead time: delivered orders (~96k).
- Q2 late rate: delivered late / all delivered.
- Q3 correlation: all delivered orders — on-time orders are the control group,
  not noise to filter out.
- Q5 stuck: delivered_customer_date IS NULL, excluding order_status = 'canceled'.

### For fct_order_items (Q4: category delivery risk)

Grain = one order-line: (order_id, order_item_id). Row count = order_items (~112k).
Scope: category-level delivery risk. Delay values are INHERITED from the parent
order — this table does not recompute them.

| Column                        | Role   | Source / derivation                            | Serves |
|-------------------------------|--------|------------------------------------------------|--------|
| order_id                      | anchor | order_items (grain key, part 1)                | Q4 key |
| order_item_id                 | anchor | order_items (grain key, part 2 — NOT unique    | Q4 key |
|                               |        | alone; sequence no. within an order)           |        |
| product_id                    | anchor | order_items (FK → products)                     | Q4     |
| product_category_name         | anchor | products (N:1 on product_id)                   | Q4 slice|
| product_category_name_english | anchor | category_translation (N:1 on category_name;    | Q4 slice|
|                               |        | COALESCE untranslated → keep, not drop)        |        |
| days_vs_promise               | derive | inherited from parent order (N:1 on order_id)  | Q4     |
| is_late                       | derive | inherited: days_vs_promise > 0                 | Q4     |

Optional (only if computing delay inside this table instead of inheriting):
| order_delivered_customer_date | anchor | orders (N:1 on order_id)                        | Q4     |
| order_estimated_delivery_date | anchor | orders (N:1 on order_id)                        | Q4     |

##### Notes
- Grouping by category counts ORDER-LINES, not orders. A 3-item late order
  contributes 3 to its categories' late counts. State this explicitly.
- Apply a minimum-volume threshold per category before trusting a late rate
  (a 5-order category at 40% is noise, not risk).
---

## Build rules (decided in profiling — do not re-derive)

These are the traps profiling already found. The build must honour each.

### For fct_order_delivery
- review_score: aggregate to one row per order BEFORE the left join
  (review_id not unique — 814 dups, 547 orders multi-review; raw join fans out).
- stall_stage: derive from the LAST non-null milestone in the funnel chain.
- Durations use endpoint difference only, never sum of per-stage gaps
  (milestones out-of-order/null in some orders — DQ-002).
- Left-join items/reviews onto the orders spine, never inner-join
  (775 orders have no items; would drop and reintroduce survivor bias).

### For fct_order_items
- Grain is the COMPOSITE (order_id, order_item_id); order_item_id alone is
  a within-order sequence number, not a table-wide PK.
- Source table is order_items; the 775 no-item orders are absent by
  construction (nothing to filter — they have no line to carry a category).
- All joins are N:1 (products, translation, parent order) → no fan-out.
  Left-join throughout so unmatched products/untranslated categories stay.
- Delay is inherited from the parent order, not recomputed here.
---

## Validation (after build)

### For fct_order_delivery (run immediately after build)
- Row count = 99,441 exactly — grain preserved, no fan-out from joins.
- COUNT(DISTINCT order_id) = row count — one row per order.
- review_score: no order has >1 row after aggregate-then-join (DQ-001 dedup worked).
- lead_time >= 0 for all delivered orders — chronology holds at endpoints
  (any negative → bad timestamp, investigate not clip).
- SUM(delivered_customer_date IS NOT NULL) ≈ delivered-status count —
  sanity-checks the ~96k population Q1/Q2/Q3 rely on.
- stall_stage null for ALL delivered orders, non-null for the stuck population —
  confirms Q5's population is clean.

### For fct_order_items
- Row count = order_items row count (~112k) exactly — N:1 joins added no rows.
- COUNT(DISTINCT order_id, order_item_id) = row count — composite grain holds.
- No category is null after COALESCE — untranslated stay visible.
---

## Tooling

- Mart built as SQL in BigQuery (`olist_mart` dataset or views).
- Dashboard: **Power BI Desktop** (Windows PC at home). Connect to BigQuery mart.
- Cross-device note: mart lives in BigQuery (cloud), so it's reachable from any device; only the Power BI build step is Windows-bound.
