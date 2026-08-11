# Findings — Olist Delivery Risk

Analysis layer over `olist_mart`. Each question follows the same template:
**Question → Query → Numbers → Reading → So what → Limits.**

Conventions (from mart metric rules):
- "Delivered" = `order_delivered_customer_date IS NOT NULL`, not `order_status`.
- State the denominator explicitly per question.
- Exclude `lead_time < 0` (out-of-order timestamps, DQ-002).
- Q4 counts ORDER-LINES, not orders — 3-item order contributes 3 lines.

Tables: `fct_order_delivery` (order grain, 99,441) · `fct_order_items` (line grain, 112,650).

---

## Q1 — Lead time: how long do orders take to deliver end-to-end?

**Population:** delivered orders (~96k), lead_time >= 0.
**Shape wanted:** distribution — median, quartiles, tail, min/max (not a single number).

**Query:**
```sql
-- TODO
```

**Numbers:**
> _(fill after running)_

**Reading:**
>

**So what:**
>

**Limits:**
>

---

## Q2 — Lateness: what share of delivered orders arrive later than promised, and where does it concentrate?

**Population:** delivered orders. Late rate = delivered late / all delivered.
**Slice:** by customer_state, by seller_state.

**Query:**
```sql
-- TODO
```

**Numbers:**
>

**Reading:**
>

**So what:**
>

**Limits:**
>

---

## Q3 — Delivery → satisfaction: does late delivery pull review scores down?

**Population:** all delivered orders (on-time orders are the control group — do NOT filter to late only).
**Measure:** relationship between days_vs_promise (X) and review_score (Y) — correlation and/or group means (late vs on-time).

**Query:**
```sql
-- TODO
```

**Numbers:**
>

**Reading:**
>

**So what:**
>

**Limits:**
>

---

## Q4 — Category risk: which categories carry the most delivery risk?

**Population:** delivered order-lines (is_late in Late/Good; exclude Not_delivered from denominator).
**Measure:** per-category late rate = Late / (Late + Good), and/or avg days_vs_promise.
**Guardrail:** minimum-volume threshold per category before trusting a rate.
**Unit:** ORDER-LINES, not orders.

**Query:**
```sql
-- TODO
```

**Numbers:**
>

**Reading:**
>

**So what:**
>

**Limits:**
>

---

## Q5 — Stuck orders: how many never arrive, and where do they stall?

**Population:** never-delivered orders (delivered_customer_date IS NULL), excluding status = 'canceled'.
**Measure:** count by stall_stage, and by customer_state.

**Query:**
```sql
-- TODO
```

**Numbers:**
> _(from mart validation: stall_stage non-'delivered' ≈ 2,965 orders; break down here)_

**Reading:**
>

**So what:**
>

**Limits:**
>

---

## Synthesis (fill last)

One paragraph tying the five together: where does delivery risk live, and what
would an operations team act on first? This is the interview-facing summary.
