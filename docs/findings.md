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
> Only 6,535 orders (6.77%) of delivered orders are late. SP and RJ have the highest count of late orders (1,820 and 1,495), but their rates are low — the high rates concentrate in a cluster of states: AL, MA, SE, PI, CE.

**So what:**
> Overall late rate is 6.77%, but it ranges widely by state — from 2.8% (AM) to 21.4% (AL). A broad pattern stands out: high-rate states are low-volume, low-rate states are high-volume — hinting that smaller / more remote markets get less reliable delivery. Three groups to read differently:
>
> - **SP and RJ** — highest count of late orders, but low rates (4.5% / 12.1%) on very large volumes (40,495 / 12,353). Worth monitoring for the number of customers affected, but not the risk hotspot: their late orders are a by-product of scale, not a reliability problem.
>
> - **High-rate cluster (AL, MA, SE, PI, CE, all >13%)** — this is where lateness actually concentrates. Within it, MA (17.4%, 717 orders) and CE (13.8%, 1,279) are the most trustworthy signals: high rate on a base large enough to not be noise. AL tops the table at 21.4% on a moderate base (397) — high enough to flag, not dismiss.
>
> - **Small-base states (SE, PI, RR, and the low-rate AC/AP/RO/AM)** — rates here sit on a few hundred orders or fewer, so treat as tentative; a handful of orders swings the percentage. Less focus for now until volume builds.

**Limit:**
> The analysis covers customer-state only, not seller-state. ***Seller-side lateness (where orders are *shipped* from) needs fct_order_items (item grain, seller_state not yet added) — see open thread. A full geographic view of delivery risk needs both sides.***
---

## Q3 — Delivery → satisfaction: does late delivery pull review scores down?

**Population:** all delivered orders (on-time orders are the control group — do NOT filter to late only).
**Measure:** relationship between days_vs_promise (X) and review_score (Y) — correlation and/or group means (late vs on-time).

**Query:**
```sql
WITH dataraw AS
(SELECT
  APPROX_QUANTILES(days_vs_promise,100) as pct
  ,COUNT(*) AS N
  ,AVG(days_vs_promise) AS AVG
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  'days_vs_promise' AS column
  ,d.pct[OFFSET(0)] AS min
  ,d.pct[OFFSET(25)] AS Q25
  ,d.pct[OFFSET(50)] AS median
  ,d.AVG AS mean
  ,d.pct[OFFSET(75)] AS Q75
  ,d.pct[OFFSET(100)] AS max
  ,d.pct[OFFSET(90)] AS P90
  ,d.pct[OFFSET(99)] AS P99
  ,d.N AS Total
FROM dataraw AS d;

---
WITH Q3_DB AS
(SELECT
  days_vs_promise
  , review_score
  , CASE
    WHEN days_vs_promise <0 THEN "1.Early"
    WHEN days_vs_promise = 0 THEN "2.On-time"
    WHEN days_vs_promise <= 5 THEN "3.Slightly Late"
    WHEN days_vs_promise <= 10 THEN "4.Late"
    ELSE "5.Severe Late"
  END AS Type
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL)
SELECT
  Type
  , COUNT(*) AS N
  , ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
  , ROUND(AVG(review_score),2) AS AVG
FROM Q3_DB
GROUP BY Type
UNION ALL
SELECT
  'Total'
  , COUNT(*) AS N
  , ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
  , ROUND(AVG(review_score),2) AS AVG
FROM Q3_DB
ORDER BY Type;
---
SELECT
  COUNTIF(review_score IS NOT NULL) AS with_review,
  COUNT(*) AS total_delivered,
  ROUND(COUNTIF(review_score IS NOT NULL) * 100 / COUNT(*), 2) AS pct_with_review
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE days_vs_promise IS NOT NULL;
```

**Numbers:**
> Distribution of days_vs_promise 
>|column|min|Q25|median|mean|Q75|max|P90|P99|Total|
>|---|---|---|---|---|---|---|---|---|---|
>|days_vs_promise|-146|-16|-11|-10.958010282349942|-6|188|-1|18|96476|

> Type and scores in average
>|Type|N|pct|AVG|
>|---|---|---|---|
>|1.Early|87187|90.37|4.3|
>|2.On-time|2754|2.85|4.1|
>|3.Slightly Late|2770|2.87|2.99|
>|4.Late|1672|1.73|1.77|
>|5.SevereLate|2093|2.17|1.71|
>|Total|96476|100.0|4.16|

> orders with review
>|with_review|total_delivered|pct_with_review|
>|---|---|---|
>|95830|96476|99.33|

**Reading:**
> Review score drops sharply as delivery slips past the promise: 4.3 (early) → 4.1 (on-time) → 2.99 (slightly late) → 1.77 (late) → 1.71 (severely late). The fall is not gradual — it is a cliff. On-time and early orders sit together near 4.2, then score collapses by ~1.1 points the moment an order is even 1–5 days late (4.1 → 2.99), and bottoms out around 1.7 for anything later. The late groups combined are only ~6,500 orders (6.7%) — a small minority, but hit hard.

**So what:**
> The decisive line for satisfaction is on-time vs late, not how late.
> - Delivering *early* buys almost nothing over delivering *on-time* (4.3 vs 4.1) — customers don't reward beating the promise, they just expect it kept.
> - The penalty lands the instant the promise is broken: a 1–5 day slip already costs ~1.1 score points. Beyond that, being 5 days late (2.99) vs 30+ days late (1.71) matters far less than crossing the line at all.
> - Operationally this reframes the target: the goal is not "deliver fast," it is "don't miss the promised date." Meeting the estimate — however padded — protects the score; breaching it is what customers punish.

**Limits:**
> - Correlation, not causation: late orders score lower, but this does not prove lateness *causes* the low score. Late orders may share other problems (defective goods, weak sellers) that also depress ratings.
> - Score reason unknown: review comment text is 58–88% null, so *why* a late order scores low is not answerable here — only that it does.
> - Coverage is near-complete: 95,830 of 96,476 delivered orders (99.33%) carry a review, so excluding review-less orders from avg_score has negligible effect.
> - ***Severe-late tail (>10 days) flagged for later cross-check with Q5 stuck orders.***

---

## Q4 — Category risk: which categories carry the most delivery risk?

**Population:** delivered order-lines (is_late in Late/Good; exclude Not_delivered from denominator).
**Measure:** per-category late rate = Late / (Late + Good), and/or avg days_vs_promise.
**Guardrail:** minimum-volume threshold per category before trusting a rate.
**Unit:** ORDER-LINES, not orders.

**Query:**
```sql
WITH delivered_lines AS (
  SELECT
    COALESCE(product_category_name_english, 'uncategorized') AS category,
    is_late
  FROM `myprojectolist.Olist_mart.fct_order_items`
  WHERE is_late != 'Not_delivered'   -- chỉ order-line đã giao (Late + Good)
)
SELECT
  category,
  COUNTIF(is_late = 'Late') AS late_lines,
  COUNT(*) AS total_lines,
  ROUND(COUNTIF(is_late = 'Late') * 100 / COUNT(*), 2) AS late_rate_pct
FROM delivered_lines
GROUP BY category
HAVING total_lines >=250
ORDER BY late_rate_pct DESC;
```
**Note on threshold:**
> Categories with fewer than 250 delivered order-lines are excluded. Below that, the late rate swings on a handful of orders (e.g. home_comfort_2: 30 lines, 13% = 4 late orders) — noise, not signal. 250 is a judgment cut, not a formula: it is the point where the rate stops jumping on small samples while still keeping categories with enough volume to trust (audio 362, home_confort 429). Q25 of total_lines was 83 — far too low to clear the noise, so not used.

**Numbers:**
>|category|late_lines|total_lines|late_rate_pct|
>|---|---|---|---|
>|audio|42|362|11.6|
>|home_confort|40|429|9.32|
>|books_technical|21|263|7.98|
>|office_furniture|133|1668|7.97|
>|baby|229|2982|7.68|
>|electronics|207|2729|7.59|
>|health_beauty|717|9467|7.57|
>|uncategorized|116|1559|7.44|
>|musical_instruments|48|651|7.37|
>|construction_tools_lights|22|301|7.31|
>|watches_gifts|422|5857|7.21|
>|furniture_living_room|35|495|7.07|
>|furniture_decor|574|8160|7.03|
>|auto|291|4139|7.03|
>|bed_bath_table|770|10953|7.03|
>|food|35|499|7.01|
>|telephony|308|4430|6.95|
>|stationery|167|2466|6.77|
>|garden_tools|280|4268|6.56|
>|perfumery|217|3342|6.49|
>|computers_accessories|496|7643|6.49|
>|industry_commerce_and_business|17|264|6.44|
>|toys|256|4030|6.35|
>|construction_tools_construction|58|916|6.33|
>|sports_leisure|532|8431|6.31|
>|books_general_interest|33|536|6.16|
>|consoles_games|64|1089|5.88|
>|home_construction|35|596|5.87|
>|cool_stuff|217|3718|5.84|
>|fashion_bags_accessories|105|1986|5.29|
>|housewares|340|6795|5.0|
>|pet_shop|95|1924|4.94|
>|small_appliances|30|658|4.56|
>|home_appliances|34|754|4.51|
>|drinks|16|361|4.43|
>|kitchen_dining_laundry_garden_furniture|12|274|4.38|
>|fashion_shoes|11|257|4.28|
>|luggage_accessories|45|1077|4.18|
>|food_drink|11|269|4.09|
>|fixed_telephony|10|255|3.92|
>|air_conditioning|11|289|3.81|
>|market_place|11|305|3.61|

**Reading:**
> - After filtering to categories with >= 250 order-lines, late rate runs from 3.6% to 11.6%.
> - Two categories stand out at the top: audio (11.6%, 362 lines) and home_confort (9.32%, 429 lines) — both high AND on enough volume to trust.
> - The third-highest (books_technical) is already down at 7.98%, so audio and home_confort are genuine outliers, not the top of a smooth range.
> - Most categories cluster tightly in the 6-8% band, sitting right around the overall late rate of 6.77% (Q2).

**So what:**
> - Delivery lateness is mostly flat across product categories. ~90% of categories sit in a narrow 5-8% band — the type of product barely moves the late rate.
> - Only audio and home_confort break out, and even they are worth a second look rather than a conclusion (why audio? bulky goods, or sellers concentrated in late-prone states? — to check in Q4b seller-side).
> - The bigger point comes from comparing spreads: by category, rate spans 3.6-11.6% but stays inside 5-8% for almost everything; by state (Q2) it spans 2.8-21.4%. Geography splits delivery risk far more sharply than product type does. If the goal is to cut lateness, the lever is the route / location, not the catalog.

**Limits:**
>

---

## Q5 — Stuck orders: how many never arrive, and where do they stall?

**Population:** never-delivered orders (delivered_customer_date IS NULL), excluding status = 'canceled'.
**Measure:** count by stall_stage, and by customer_state.

**Query:**
```sql
--- Q5: Part 1
SELECT
  COUNT(*) AS Total_never_arrive,
  COUNTIF(order_status = 'canceled') AS Those_canceled,
  COUNT(*) - COUNTIF(order_status = 'canceled') AS Those_stucked
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL;

--- Q5: Part 2
SELECT
  stall_stage,
  COUNT(*) AS N
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled'
GROUP BY stall_stage
UNION ALL
SELECT
  'Total',
  COUNT(*) AS N
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled';

SELECT
  customer_state
  ,stall_stage
  ,COUNT(*) AS N
  ,ROUND(COUNT(*) *100 / SUM(COUNT(*)) OVER(),2)AS pct
FROM `myprojectolist.Olist_mart.fct_order_delivery`
WHERE order_delivered_customer_date IS NULL AND order_status != 'canceled'
GROUP BY customer_state,stall_stage
ORDER BY customer_state ASC, stall_stage ASC;
```

**Numbers:**
> _(from mart validation: stall_stage non-'delivered' ≈ 2,965 orders; break down here)_
> |Total_never_arrive|Those_canceled|Those_stucked|
> |---|---|---|
> |2965|619|2346|

> And so,
> |stall_stage|N|
> |---|---|
> |stuck_at_carrier|1114|
> |stuck_after_approval|1227|
> |stuck_at_purchase|5|
> |Total|2346|

> And into customer_state over the whole risks.
> |customer_state|stall_stage|N|pct|
> |---|---|---|---|
> |SP|stuck_after_approval|589|25.11|
> |SP|stuck_at_carrier|335|14.28|
> |RJ|stuck_at_carrier|289|12.32|
> |MG|stuck_after_approval|146|6.22|
> |RJ|stuck_after_approval|126|5.37|
> |MG|stuck_at_carrier|71|3.03|
> |PR|stuck_after_approval|70|2.98|
> |BA|stuck_at_carrier|68|2.9|
> |RS|stuck_after_approval|59|2.51|
> |SC|stuck_after_approval|44|1.88|
> |BA|stuck_after_approval|40|1.71|
> |CE|stuck_at_carrier|38|1.62|
> |RS|stuck_at_carrier|37|1.58|
> |PE|stuck_at_carrier|35|1.49|
> |GO|stuck_at_carrier|31|1.32|
> |DF|stuck_at_carrier|30|1.28|
> |PR|stuck_at_carrier|29|1.24|
> |SC|stuck_at_carrier|28|1.19|
> |DF|stuck_after_approval|22|0.94|
> |GO|stuck_after_approval|19|0.81|
> |PA|stuck_at_carrier|19|0.81|
> |PE|stuck_after_approval|19|0.81|
> |ES|stuck_at_carrier|17|0.72|
> |MA|stuck_at_carrier|17|0.72|
> |MT|stuck_at_carrier|14|0.6|
> |CE|stuck_after_approval|12|0.51|
> |ES|stuck_after_approval|12|0.51|
> |PB|stuck_at_carrier|11|0.47|
> |AL|stuck_at_carrier|9|0.38|
> |MA|stuck_after_approval|9|0.38|
> |MS|stuck_after_approval|9|0.38|
> |SE|stuck_at_carrier|9|0.38|
> |PI|stuck_after_approval|8|0.34|
> |PI|stuck_at_carrier|7|0.3|
> |RN|stuck_at_carrier|7|0.3|
> |RO|stuck_after_approval|7|0.3|
> |AL|stuck_after_approval|6|0.26|
> |PA|stuck_after_approval|6|0.26|
> |PB|stuck_after_approval|6|0.26|
> |MT|stuck_after_approval|5|0.21|
> |SE|stuck_after_approval|5|0.21|
> |RN|stuck_after_approval|4|0.17|
> |RR|stuck_at_carrier|4|0.17|
> |MS|stuck_at_carrier|3|0.13|
> |TO|stuck_at_carrier|3|0.13|
> |AM|stuck_at_carrier|2|0.09|
> |TO|stuck_after_approval|2|0.09|
> |AC|stuck_at_carrier|1|0.04|
> |AM|stuck_after_approval|1|0.04|
> |AP|stuck_after_approval|1|0.04|
> |DF|stuck_at_purchase|1|0.04|
> |PR|stuck_at_purchase|1|0.04|
> |RJ|stuck_at_purchase|1|0.04|
> |RS|stuck_at_purchase|1|0.04|
> |SP|stuck_at_purchase|1|0.04|

**Reading:**
> Of 2,965 orders that never arrive, 619 are canceled and the remaining 2,346 (79%) are stuck — this is where the focus should be. Most are stuck at the carrier and approval stages. The most notable states are SP and RJ: SP contributes 924 stuck orders (589 approval + 335 carrier) and RJ 415 (126 approval + 289 carrier), together ~57% of all stuck orders.

**So what:**
> 79% of never-arrived orders are stuck, and SP + RJ alone account for over half of them (SP ~39%, RJ ~18%). Looking closer at the contribution split: RJ's stuck orders sit mostly at the carrier stage (transport), while SP is stuck more at approval than at carrier. The bottleneck concentrates at the carrier/approval stages — worth investigating why.

**Limits:**
> This analysis measures each state's *contribution* to total stuck risk, not its stuck *rate*. High-contribution states (SP, RJ) are also the highest-volume states, so their large stuck counts partly reflect scale. ***A per-state stuck rate is not computed yet. It should be added later as a geographic risk view — combining late-rate (Q2) and stuck-rate (Q5) by state, since both share the same volume caveat.***

---

## Synthesis (fill last)

One paragraph tying the five together: where does delivery risk live, and what
would an operations team act on first? This is the interview-facing summary.

## Note:
> Open thread — Q2×Q4 seller/customer geographic pairing: Q2 done customer-state (nơi nhận trễ). Q4b will add seller-state (nơi gửi trễ). At synthesis, pair them: which sending states ↔ which receiving states, to see if lateness is a route problem (specific seller-state → customer-state lanes) or a source problem (certain seller-states late everywhere). Also pair stuck-rate-by-state (Q5) into the same geographic view.
