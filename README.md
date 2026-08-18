# Project_Olist
# Olist Delivery Risk Analysis

**Delivery risk lives in the tail, not the average.**
An end-to-end SQL analysis of 100K+ Brazilian e-commerce orders (Olist), framed through a supply-chain/operational-risk lens: not "how fast does Olist deliver on average," but "where does delivery reliability break, who does it hurt, and what should operations fix first".


[Image]


**Key findings:**
- Delivery risk lives in the tail, not the average (median at 10 days, the tail reaches 209 days)
- Lateness concentrates in specific states - MA is the worst on both the receiving (customer, 17.4%) and sending (seller, 19.4%) sides.
- Satisfaction score drops significantly when late delivery happens (4.1 to 3.0)
- Stalling is concentrated by funnel stage (carrier/approval), not by region.
- Geography drives delivery risk more than product type does.

**Business questions:**
Scope is deliberately operational - the flow of an order from purchase to delivery -
not financial/payment analysis. Presented in analytical order: Q1 -> Q2 -> Q3 -> Q5 -> Q4.
- Question 1 (Lead time): How long do orders take to deliver end-to-end?
- Question 2 (Lateness): What share of delivered orders arrive later than promised, 
and where does latness concentrate?
- Question 3 (Delivery & Satisfaction): Does late delivery pull review score down?
- Question 4 (Category vs Seller risk): Which product categories (Q4a) and seller state (Q4b)
carry the most delivery risk?
- Question 5 (Stuck orders): How many orders never arrive, and where do they stall?

**Data & architecture:**
Dataset(raw data): Olist from Kaggle with around 100k rows and 9 tables.
Olist_stg : from raw data, raw tables are cleaned, typed, and standardized.
Olist_mart: from the Olist_stg, the data is transferred into 2 fact tables.
- fct_order_delivery: with grain of orders, 99441 rows
- fct_order_items: with grain of order-lines, 112650 rows.

**Approach/ methodology:**
- Grain discipline: fct_order_delivery (99441 rows) and fct_order_items (112650 rows) are constants in row numbers. If there is a mismatch during the analysis or joining, it is a signal of fan-out, and it will be investigated.
- Question-driven modeling: Every mart column traces to a specific analytical question; nothing built speculatively.
- Population precision: Each rate states its denominator explicitly (e.g. late rate = late/all delivered), and rate is separated from raw count to avoid volume bias.
- Data-quality logging: Anomalies logged with a reasoned decision (DQ-001..007), not silently dropped.
- Null-as-boundary/validation: NULL treated as a population boundary, not missing data - the same null defines exclusion in one question and the target set in another.

**Key technical decisions:**
- 2 mart tables are defined to analyze specific grains (orders and order-lines)
- Q4 late-rate charts apply minimum-volme cut-offs (greater than and equal to 250 lines for category,
greater than and equal to 150 for seller-state). Some states/categories
show extreme rates on tiny samples - noise, not signal. The two thresholds differ
because the distributions differ: seller-state has a natrual gap around 150,
while category is smoother, so 250 is chosen. 
- dim_state bridge for slicer cross_filter is done to filter risk by state, which is more important than categories in this analysis..

**Tech stack:**
- SQL: BigQuery
- Data visualization & modeling: Power BI (dim_state bridge table, DAX measures)
- Version control: Git/GitHub

**Repository structure:**
sql/          → 01_profiling, 02_staging, 03_mart, 04_analysis
docs/         → mart_design.md, data_quality_log.md, findings.md, dashboard.png
README.md

**Link to full analysis:**
- Link to [findings.md](https://github.com/LeonTran29/Project_Olist/blob/main/docs%2Ffindings.md)