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

## Fact table columns — fct_order_delivery

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

### Notes
- Question populations differ from table grain (99,441):
  - Q1: delivered orders (~96k)
  - Q2: delivered orders; late rate = delivered late / all delivered
  - Q3: delivered orders (need on-time as control group for correlation)
  - Q5: never-arrived orders (delivered_customer_date IS NULL),
        excluding order_status = 'canceled'
- review_score: aggregate to one row per order before joining (review_id
  not unique — 814 dups, 547 orders with multiple reviews).
- Milestone timestamps feed stall_stage by "last non-null", NOT by summing
  per-stage gaps (durations use endpoints only).

---

## Build rules (decided in profiling — do not re-derive)

These are the traps profiling already found. The build must honour each.

---

## Validation (after build)

---

## Tooling

- Mart built as SQL in BigQuery (`olist_mart` dataset or views).
- Dashboard: **Power BI Desktop** (Windows PC at home). Connect to BigQuery mart.
- Cross-device note: mart lives in BigQuery (cloud), so it's reachable from any device; only the Power BI build step is Windows-bound.
