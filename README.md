# Project_Olist
# Olist Delivery Risk Analysis

**Delivery risk lives in the tail, not the average.**
And end-to-end SQL analysis of 100K+ Brazillian e-commerce order (Olist), framed through a supply-chain/operational-risk lens: not "how fast does Olist deliver on average," but "where does delivery reliability break, who does it hurt, and what should operation fix first".


[Image]


**Key findings:**
- Delivery risk lives in the tail, not the average (median at 10 days, the tail reaches 209 days)
- Late rate focus on some site - MA is the worst place for both customer & seller (17.4% & 19.4%)
- Satisfaction score drops significantly as the late delivery happens (4.1 to 3.0)
- Stuck happens in stall (carrier/approval), not site.
- Site is more remarkable to consider than category in risk delivery.

**Business questions:**
Scope is deliberately operational - the flow of an order from purchase to delivery -
not financial/payment analysis. Presented in analytical order: Q1 -> Q2 -> Q3 -> Q5 -> Q4.
- Quétion 1 (Lead time): How long do orders take to deliver end-to-end?
- Quétion 2 (Lateness): What share of delivered orders arrive later than promised, 
and where does latness concentrate?
- Question 3 (Delivery & Satisfaction): Does late delivery pull review score down?
0 Question 4 (Category vs Seller risk): Which product categories (Q4a) and seller state (Q4b)
carry the most delivery risk?
- Question 5 (Stuck orders): How many orders never arrive, and where do they stall?

**Data & architecture:**
Dateset(raw data): Olist from Kaggle with around 100k rows and 9 tables.
Olist_stg : from raw data, the noise data and wrong data types are fixed.
Olist_mart: from the Olist_stage, the data is transferred into 2 fact tables.
- fct_order_delivery: with grain of orders, 99441 rows
- fct_order_items: with grain of order-lines, 112650 rows.

**Approach/ methodology:**
- Grain discipline: fct_order_delivery (99441 rows) and fct_order_items (112650 rows) are constants in row numbers. If there is a mismatch during the analysis or joining, it is a signal of fan-out, and it will be investigated.
- Question-driven modeling: Every mart column traces to a specific analytical question; nothing built speculatively.
- Population precision: Each rate states its denominator explicity (e.g. late rate = late/all delivered), and rate is separtated from raw count to avoid volume bias.
- Data-quality logging: Anomalities logged with a reasoned decision (DQ-001..007), not silently dropped.
- Null-as-boundary/validation: NULL treated as a population boundary, not missing data - the same null defines exclusion in one question and the target set in another.

**Key technical decisions:**
- 2 mart tables are defined to analyze specific grain (orders and order-lines)
- In filtering the Item Late Rate in question 4: there are a cut-off boundaries of lower 250 and 150. There are various site with exclusive Late Rate but the count is so small to mark it as a risk. 
- dim_state bridge for slicer cross_filter is done to filter risk situation in each site, which is more important than categories.

**Tech stack:**
- SQL: BigQuery
- Data visualization: Power BI
- Storage and demonstration: Git.

**Repository structure:**
- sql/
- docs/
- README.md

** Link to full analysis:**
- link to findings.md