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
WITH lead_quan AS
(SELECT
  APPROX_QUANTILES(lead_time,100) as pct
  ,COUNT(*) AS N
  ,ROUND(AVG(lead_time),2) AS AVG
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE lead_time >= 0)
SELECT 
  l.N as COUNT
  ,l.AVG as Average
  ,l.pct[OFFSET(0)] as min
  ,l.pct[OFFSET(25)] as Q25
  ,l.pct[OFFSET(50)] as median
  ,l.pct[OFFSET(75)] as Q75
  ,l.pct[OFFSET(100)] as max
  ,l.pct[OFFSET(90)] as P90
  ,l.pct[OFFSET(99)] as P99
FROM lead_quan l
```

**Numbers:**
> | COUNT | Average | min | Q25 | median | Q75 | P90 | P99 | max |
> |---|---|---|---|---|---|---|---|---|
> | 96,476 | 12.09 | 0 | 6 | 10 | 15 | 23 | 46 | 209 |

**Reading:**
> 96,476 orders have a completed `order_delivered_customer_date` timestamp
> (the measurable population for lead time).
> Lead time ranges from 0 days (same-day) to 209 days (max).
> The typical order is delivered in ~10 days (median); the middle 50% of orders
> fall between 6 and 15 days (Q25–Q75).
> Average is 12.09 days — higher than the median, an early sign of right-skew.
> 90% of orders arrive within 23 days, 99% within 46 days.

**So what:**
> The lead-time distribution is right-skewed: the bulk sits low (median 10 days)
> with a long tail stretching right. The gaps between percentiles widen toward
> the tail — median→Q75: 5 days, Q75→P90: 8, P90→P99: 23, P99→max: 163 —
> confirming a small group of very slow deliveries pulls the mean above the median.
> 90% of orders arrive within 23 days; only 1% exceed 46 days, up to 209.
> This long tail is where delivery risk likely concentrates — ***flagged for closer
> investigation at Q5 (stuck orders) and Q2 (late vs promise), rather than
> concluded as risk here.***

**Limits:**
> The tail beyond P90 is not yet explained: ~880 orders (0.91%) exceed 46 days,
> max 209. Cause unknown — could be genuinely stuck orders or timestamp
> artifacts. Revisit at Q5 (stuck) and Q2 (late vs promise); if neither
> accounts for it, treat as a data-quality issue.
> (lead_time < 0 already checked: 0 orders — purchase→delivered endpoint clean.)
---

## Q2 — Lateness: what share of delivered orders arrive later than promised, and where does it concentrate?

**Population:** delivered orders. Late rate = delivered late / all delivered.
**Slice:** by customer_state

**Query:**
```sql
--- Q2: Share of late delivered orders
WITH delivered_order AS
(SELECT
  order_id,
  customer_state,
  days_vs_promise
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  "Late delivery" AS Share_of_late_delivery
  , COUNTIF(days_vs_promise > 0) AS late_orders
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),2) AS share_pct 
  , COUNT(*) AS total_orders
FROM delivered_order;
--- Q2: Concentrate customer-sideWITH delivered_order AS
(SELECT
  order_id,
  customer_state,
  days_vs_promise
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  customer_state
  , COUNTIF(days_vs_promise > 0) AS late_orders
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),3) AS share_pct 
  , COUNT(*) AS total_orders
  , 0 AS Sort_flag
FROM delivered_order
GROUP BY customer_state
UNION ALL
SELECT
  'Total'
  , COUNTIF(days_vs_promise > 0)
  , ROUND(COUNTIF(days_vs_promise > 0) * 100/COUNT(*),3)
  , COUNT(*)
  , 1 AS Sort_flag
FROM delivered_order
ORDER BY Sort_flag, share_pct DESC;
```

**Numbers:**
> Late delivery orders
> |Share_of_late_delivery|late_orders|share_pct|total_orders|
> |---|---|---|---|
> |Late delivery|6535|6.77|96476|

> Late delivery orders on each customer_state
> |customer_state|late_orders|share_pct|total_orders|
> |---|---|---|---|
> |AL|85|21.411|397|
> |MA|125|17.434|717|
> |SE|51|15.224|335|
> |PI|66|13.866|476|
> |CE|176|13.761|1279|
> |RR|5|12.195|41|
> |BA|396|12.162|3256|
> |RJ|1495|12.102|12353|
> |PA|106|11.205|946|
> |ES|214|10.727|1995|
> |PB|54|10.445|517|
> |TO|27|9.854|274|
> |MS|68|9.7|701|
> |PE|153|9.605|1593|
> |RN|44|9.283|474|
> |SC|291|8.204|3547|
> |GO|128|6.541|1957|
> |RS|325|6.082|5344|
> |MT|53|5.982|886|
> |DF|118|5.673|2080|
> |MG|520|4.579|11355|
> |SP|1820|4.494|40495|
> |PR|199|4.042|4923|
> |AC|3|3.75|80|
> |AP|2|2.985|67|
> |RO|7|2.881|243|
> |AM|4|2.759|145|
> |Total|6535|6.774|96476|

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
