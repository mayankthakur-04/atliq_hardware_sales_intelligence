# AtliQ Hardware Sales Intelligence Dashboard

A end-to-end business intelligence solution built in Power BI, connected to a MySQL database, that transforms raw sales transaction data into actionable insights for AtliQ Hardware — a computer hardware and peripherals manufacturer operating across India.

---

## The Problem

AtliQ Hardware's sales director was struggling to get a clear picture of the business. Regional managers across North, Central, and South India were giving verbal updates that were often optimistic and hard to verify. There was no single source of truth — no way to quickly answer questions like:

- Which markets are actually profitable, and which are dragging us down?
- Why did revenue drop so sharply in 2020?
- Who are our most valuable customers, and are we at risk of losing any of them?
- Is Bengaluru worth the investment given its -27.2% profit margin?

The goal of this project was to build a dashboard that answers these questions directly, without anyone having to dig through spreadsheets or wait for a weekly report.

---

## What I Built

A four-page Power BI dashboard connected live to a MySQL database, covering:

- **Executive Summary** — high-level KPIs and trends for quick decision-making
- **Key Insights** — market and customer contribution analysis with year and product type filters
- **Profit Analysis** — deep dive into which markets and customers are profitable vs loss-making
- **Performance Insights** — zone-level performance with YoY comparison and profit target tracking

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data Storage | MySQL 8.0 |
| Data Cleaning & Modeling | Power Query (M Language) |
| Data Transformation | SQL Views |
| Calculations & KPIs | DAX (Data Analysis Expressions) |
| Visualization | Power BI Desktop |
| Data Model | Star Schema |

---

## Project Architecture

```
MySQL Database (sales)
        │
        ├── Raw Tables
        │   ├── transactions
        │   ├── customers
        │   ├── markets
        │   ├── products
        │   └── date
        │
        └── SQL Views (Data Quality Layer)
            ├── v_india_transactions   ← Main fact source
            ├── v_monthly_revenue
            ├── v_customer_performance
            └── v_product_performance
                    │
                    ▼
            Power Query (ETL)
                    │
                    ▼
            Star Schema (Data Model)
            ┌───────────────────────────────┐
            │   Fact: sales v_india_trans   │
            │   Dim:  sales customers       │
            │   Dim:  sales markets         │
            │   Dim:  sales products        │
            │   Dim:  sales date            │
            └───────────────────────────────┘
                    │
                    ▼
            DAX Measures + Power BI Visuals
```

---

## Data Model

The project uses a **Star Schema** with one central fact table connected to four dimension tables.

**Fact Table:** `sales v_india_transactions`
- Contains all transaction records filtered to India (INR currency, valid zones only)
- Columns: customer_code, market_code, order_date, product_code, qty, sales_amount, profit_margin, profit_margin_percentage, cost_price

**Dimension Tables:**
- `sales customers` — customer name and type (Brick & Mortar / E-Commerce)
- `sales markets` — market name and zone (North / Central / South)
- `sales products` — product code and type (Own Brand / Distribution)
- `sales date` — full date hierarchy with month names and year

**Relationships:** All Many-to-One from fact to dimensions.

---

## SQL Views — Why They Exist

The raw database had a few data quality issues that needed to be handled before Power BI ever saw the data:

1. **Invalid market data** — Mark097 (New York) and Mark999 (Paris) existed in the markets table but AtliQ Hardware only operates in India. These were inflating revenue numbers.

2. **Currency mismatch** — Some transactions were recorded in USD. Comparing INR and USD values without conversion would produce meaningless aggregates.

3. **Duplicate joins** — Power BI was doing heavy JOIN operations on every refresh across 500K+ rows.

The SQL views solve all three problems at the database level, so Power BI always receives clean, pre-filtered data.

```sql
-- Primary view used as the fact table
CREATE VIEW v_india_transactions AS
SELECT 
    t.*,
    c.custmer_name,
    c.customer_type,
    m.markets_name,
    m.zone,
    p.product_type
FROM transactions t
JOIN customers c ON t.customer_code = c.customer_code
JOIN markets   m ON t.market_code   = m.markets_code
JOIN products  p ON t.product_code  = p.product_code
WHERE t.currency = 'INR'
AND m.zone != '';
```

Additional views created:
- `v_monthly_revenue` — pre-aggregated monthly revenue by market and zone
- `v_customer_performance` — customer-level revenue, profit, and avg daily revenue
- `v_product_performance` — product-level revenue and margin summary
- `v_yoy_comparison` — year-over-year revenue pivot by market

---

## Key DAX Measures

```dax
-- Core revenue metrics
Revenue = SUM('sales v_india_transactions'[sales_amount])

Revenue LY = 
CALCULATE([Revenue], SAMEPERIODLASTYEAR('sales date'[date]))

Revenue YoY % = 
DIVIDE([Revenue] - [Revenue LY], [Revenue LY], 0) * 100

-- Profitability
Profit Margin % = 
DIVIDE(
    SUM('sales v_india_transactions'[profit_margin]),
    [Revenue], 0
) * 100

Net Profit Margin = 
SUM('sales v_india_transactions'[profit_margin])

-- Market health
Loss Making Markets = 
CALCULATE(
    DISTINCTCOUNT('sales markets'[markets_name]),
    [Profit Margin %] < 0
)

-- Performance tracking
Profit Status = 
IF(
    [Profit Margin %] >= 'Profit Target'[Profit Target Value],
    "Target Met +" & 
    FORMAT([Profit Margin %] - 'Profit Target'[Profit Target Value], "0.0%"),
    "Below Target"
)
```

---

## Dashboard Pages

### Page 1 — Executive Summary

The landing page for senior leadership. Shows the overall health of the business at a glance.

**KPIs:** Total Revenue, Revenue LY, Sales Quantity, Revenue YoY%, Total Customers, Avg Order Value, Net Profit Margin

**Visuals:**
- Revenue by Month (area chart with trend line)
- Revenue by Zone (pie chart — North / Central / South split)
- Top 5 Customers by Revenue
- Top 5 Markets by Revenue
- Top 5 Products by Revenue

**Key finding visible here:** North zone dominates with 62.23% of revenue, almost entirely driven by Delhi NCR.

---

### Page 2 — Key Insights

Designed for sales managers who need to understand where volume and revenue is coming from, and how it has changed over time.

**Filters:** Year (2017–2020), Product Type (Distribution / Own Brand)

**Visuals:**
- Revenue Contribution % by Market (horizontal bar)
- Sales QTY by Market (horizontal bar)
- Sales QTY by Year (line chart — peak in 2018, sharp decline in 2020)
- Top 5 Customers by Revenue Contribution%
- Top 5 Products by Revenue Contribution%

**Key finding visible here:** Delhi NCR contributes 47% of revenue but Kochi leads in sales quantity — suggesting Kochi moves volume at lower price points.

---

### Page 3 — Profit Analysis

The most important page for business decisions. Shows which markets and customers are actually making money vs burning it.

**KPIs:** Revenue, Loss Making Markets count, Net Profit Margin

**Filters:** Year, Product Type

**Visuals:**
- Profit Margin % by Market (bar chart with negative values highlighted in red)
- Profit Contribution % by Market
- Revenue by Year with forecast band
- Customer profitability table (Revenue, Revenue Contribution%, Profit Margin Contribution%, Profit Margin%)

**Key findings:**
- **Bengaluru: -27.2% profit margin** — the company is losing money on every rupee of sales here
- **14 markets are loss-making** when the full dataset is considered
- Patna (5.4%) and Bhubaneshwar (4.0%) are the most profitable markets despite low revenue

---

### Page 4 — Performance Insights

Zone-level deep dive with the What-If profit target parameter. Useful for quarterly business reviews.

**KPIs:** Revenue, Sales QTY, Net Profit Margin, YoY%, QTY YoY%

**Filters:** Profit Target slider (What-If parameter), Year

**Visuals:**
- Profit Margin % by Zones (horizontal bar — color coded by target achievement)
- Revenue LY vs Revenue vs Profit Margin % by Year (combo chart)
- Full customer table with Revenue LY comparison column

**Key finding visible here:** Mumbai zone (4.2% margin) is consistently the most profitable zone. Central zone has mixed performance — Nagpur at 2.5% and Bhopal at 1.9% are both below the 3% target.

---

## Business Insights Summary

After building and analyzing this dashboard, here are the most important findings:

**Revenue Concentration Risk**
Delhi NCR alone accounts for 47% of total revenue. If AtliQ loses Electricalsara Stores (their single largest customer at 33.4% revenue contribution), the business takes a severe hit. This level of concentration is dangerous.

**Bengaluru is a Structural Problem**
A -27.2% profit margin is not a bad quarter — it is a broken market. Either the pricing strategy, the customer mix, or the cost structure in Bengaluru needs a fundamental rethink. Continuing operations there at this margin is destroying value.

**2020 Decline is Real and Steep**
Revenue peaked in 2018-2019 at around 213M and dropped to 77M in 2020 — a 64% decline. The Sales QTY chart confirms this is not just a pricing issue but a genuine volume decline. Understanding the cause (COVID-19 impact, competition, customer churn) is critical before making investment decisions.

**Own Brand vs Distribution**
The product type filter across all pages allows comparison between Own Brand and Distribution products. Distribution products contribute higher volume but Own Brand products typically carry better margins — a pattern worth exploring in depth.

**Most Profitable Markets are Being Underserved**
Patna (5.4%), Bhubaneshwar (4.0%), Mumbai (3.9%) and Bhopal (3.9%) have healthy margins but low revenue contribution. These markets may represent growth opportunities with better sales coverage.

---

## How to Run This Project

### Prerequisites
- MySQL 8.0 or higher
- Power BI Desktop (free)

### Setup Steps

**1. Set up the database**
```sql
-- Import the provided SQL dump
source db_AtliQ_Hardware.sql;
USE sales;
```

**2. Create the SQL views**
```sql
-- Run the views script
source views.sql;

-- Verify views were created
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
```

**3. Connect Power BI to MySQL**
```
Power BI Desktop
→ Home → Get Data → MySQL Database
→ Server: localhost
→ Database: sales
→ Select: v_india_transactions, customers, 
           markets, products, date
→ Load
```

**4. Verify the data model**
```
Model View → Check relationships:
v_india_transactions[customer_code] → customers[customer_code]  (Many-to-One)
v_india_transactions[market_code]   → markets[markets_code]     (Many-to-One)
v_india_transactions[product_code]  → products[product_code]    (Many-to-One)
v_india_transactions[order_date]    → date[date]                (Many-to-One)
```

**5. Open the .pbix file**
- Open `AtliQ_Hardware_Sales_Intelligence.pbix`
- Refresh data if prompted

---

## Project Structure

```
atliq-hardware-sales-intelligence/
│
├── AtliQ_Hardware_Sales_Intelligence.pbix   # Power BI file
├── db_dump_version_2.sql                    # MySQL database dump
├── views.sql                                # All SQL views
├── README.md                                # This file
│
└── screenshots/
    ├── executive_summary.png
    ├── key_insights.png
    ├── profit_analysis.png
    ├── performance_insights.png
    └── data_model.png
```

---

## What I Learned

This project was a good reminder that dashboards are not about making things look nice — they are about making decisions easier. The most valuable part of this build was not writing the DAX or designing the visuals. It was deciding which questions the business actually needs answered, and then making sure those questions have a clear, honest answer somewhere on the screen.

A few specific things this project reinforced:

- **Data quality at the source matters more than anything downstream.** The SQL views layer saved me from building an entire dashboard on numbers that included New York and Paris in the Indian market totals.
- **Negative numbers deserve their own visual treatment.** The red bars for loss-making markets in the Profit Analysis page are more informative than a neutral chart would be.
- **What-If parameters turn a report into a conversation.** The profit target slider means a sales director can actually use the dashboard to run scenarios, not just read static numbers.

---

## Author

**Mayank**
B.Tech CSE (Data Science) — Oriental College of Technology, Bhopal
Targeting Data Analyst and Data Science roles

---

## License

This project is built on a publicly available sample dataset for learning purposes.
