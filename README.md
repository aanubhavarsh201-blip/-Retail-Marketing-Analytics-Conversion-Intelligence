# -Retail-Marketing-Analytics-Conversion-Intelligence
An end-to-end data analytics pipeline investigating reduced customer engagement and conversion rates for an online retail business — from raw data ingestion to interactive Power BI dashboards and NLP-driven sentiment analysis.

![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=flat&logo=python&logoColor=white)
![pandas](https://img.shields.io/badge/pandas-Data%20Wrangling-150458?style=flat&logo=pandas&logoColor=white)
![NLTK](https://img.shields.io/badge/NLTK-VADER%20NLP-85C1E9?style=flat)
![SQL](https://img.shields.io/badge/SQL-Analytical%20Queries-336791?style=flat&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboards-F2C811?style=flat&logo=powerbi&logoColor=black)

---

## 📌 Problem Statement

An online retail business launched multiple digital marketing campaigns across social media, blogs, newsletters, and video channels. Despite achieving strong reach — **12M views** and a **19.57% CTR** — the business is experiencing a measurable decline in **conversion rates** and **customer engagement**. The root causes were unclear.

**This project was built to surface them through data.**

### Core Business Questions

| # | Question |
|---|----------|
| 1 | Where exactly are customers dropping off in the purchase funnel, and which products and geographies are most affected? |
| 2 | Which content types and products are driving the highest click-through and engagement? |
| 3 | What are customers saying in their reviews, and does sentiment vary by product? |
| 4 | Who are the customers — by age, gender, and geography — and are campaigns targeting the right segments? |

---

## 🗂️ Project Structure

```
retail-marketing-analytics/
│
├── data/
│   ├── customers.csv           # Raw customer records
│   ├── reviews.csv             # Customer reviews & ratings
│   ├── engagement.csv          # Social/content engagement logs
│   ├── products.csv            # Product catalog
│   ├── geography.csv           # Country/city reference
│   └── journey.csv             # Customer purchase journey events
│
├── notebooks/
│   └── Marketing Campaign Analysis.ipynb   # Full Python pipeline
│
├── sql/
│   └── Marketing Analysis Query.sql     # 9 analytical queries 
│
├── outputs/
│   ├── customers_geo.csv
│   ├── engagement.csv
│   ├── journey.csv
│   ├── products.csv
│   └── reviews.csv     # Includes sentiment scores & categories
│
├── dashboard/
│   └── Marketing Analysis Dashboard.pbix"  # Power BI report file
│
└── README.md
```

---

## ⚙️ Project Pipeline

```
Raw CSVs  ──►  Python (Clean + Feature Engineering + NLP)
                          │
                          ▼
               Cleaned CSVs / SQL Database
                          │
                          ▼
               SQL (9 Analytical Queries → KPIs)
                          │
                          ▼
               Power BI (4 Dashboard Pages → Insights)
```

---

## 🐍 Step 1 — Python: Data Cleaning, Preprocessing & Feature Engineering

### Datasets Loaded

| Dataset | Shape | Key Issues Resolved |
|---------|-------|---------------------|
| Customers | 100 × 6 | Merged with Geography on `Geography_ID` |
| Engagement | 4,623 × 8 | Split `ViewsClicksCombined`, fixed dtypes, normalized casing |
| Journey | 4,011 × 7 | Converted `VisitDate`, removed 71 duplicates; 613 intentional nulls retained |
| Products | 20 × 4 | Clean; `Price_Category` feature engineered |
| Reviews | 1,363 × 6 | Converted `Review_Date`, normalized whitespace in `ReviewText` |
| Geography | Reference | Joined to Customers |

### Key Transformations

**Feature Engineering**
- `Age_Group` — customers binned into 5 bands: `18-25`, `26-35`, `36-50`, `51-65`, `65+`
- `Price_Category` — products segmented into `Low`, `Medium`, `High` based on price thresholds

**Engagement Cleaning**
- `ViewsClicksCombined` split into separate `Views` and `Clicks` columns
- Datetime conversion for `EngagementDate`
- `ContentType` standardized to title case; `"Socialmedia"` corrected to `"Social Media"`
- Null values in `Views` and `Clicks` filled with `0`

**Journey Cleaning**
- `VisitDate` converted to datetime
- 71 duplicate rows removed
- 613 nulls in `Duration` retained intentionally — all correspond to `Drop-Off` actions where no duration exists by definition

### Sentiment Analysis 

- Imported the nltk library and downloaded the VADER (Valence Aware Dictionary and sEntiment Reasoner) lexicon — a pre-trained, rule-based sentiment tool designed for short informal texts like customer reviews that requires no model training — then initialized a SentimentIntensityAnalyzer instance as the core scoring engine for the pipeline.
- Defined a sentiment score function to extract the compound score from each review text — a normalized value ranging from -1.0 (most negative) to +1.0 (most positive) — selected because it consolidates positive, negative, and neutral signals into a single rankable metric suitable for aggregation and comparison across all 1,363 reviews.
- Defined a sentiment categorization function using a dual-signal approach — combining the VADER text score with the customer's numeric star rating — to produce five output labels: Positive, Mixed Positive, Neutral, Mixed Negative, and Negative, accounting for cases where review language and star ratings contradict each other.
- Defined a sentiment bucketing function to assign each review to a labeled compound score range (e.g., "Highly Positive: 0.5 to 1.0") independent of the star rating, enabling distribution-level analysis of raw sentiment strength across the full review corpus.
- Applied all three functions sequentially across the Reviews DataFrame to populate three new columns — Sentiment_Score, Sentiment_Category, and Sentiment_Bucket — then previewed the enriched output to verify correct computation before exporting the final dataset for SQL aggregation and Power BI reporting.
---

## 🗄️ Step 2 — SQL: Analytical Queries

| # | Query | Tables Used | Purpose |
|---|-------|-------------|---------|
| 1 | Overall Conversion Rate | `journey` | Purchase vs view rate across all customer-product pairs |
| 2 | Funnel by Product ID | `journey` | 4-stage breakdown: homepage → product page → checkout → purchase |
| 3 | Funnel by Country & City | `journey`, `customers`, `products` | Geographic conversion segmentation |
| 4 | Checkout Drop-off by Product | `journey`, `products` | Identify which products leak most at final stage |
| 5 | Engagement & CTR by Content Type | `engagement` | Blog vs Video vs Social Media vs Newsletter performance |
| 6 | Engagement & CTR by Product | `engagement`, `products` | Per-product views, clicks, likes, CTR |
| 7 | Sentiment Summary by Product | `reviews_sentiment`, `products` | Avg rating + sentiment category counts per product |
| 8 | Sentiment Summary by Country | `reviews_sentiment`, `customers` | Geographic sentiment distribution |
| 9 | Sentiment Summary by Age Group | `reviews_sentiment`, `customers` | Demographic sentiment distribution |

### Query Patterns Used

- **CTEs** (`WITH`) for staged funnel logic
- **Conditional aggregation** (`COUNT(DISTINCT CASE WHEN ... END)`) for funnel stage counts
- **CASE WHEN with division guards** (`CASE WHEN x > 0 THEN ...`) to prevent divide-by-zero
- **Multi-table JOINs** across journey, customers, products, and reviews
- **LIKE pattern matching** on `SentimentCategory` for flexible sentiment grouping

---

## 📊 Step 3 — Power BI: Interactive Dashboards

Four dashboard pages, each filterable by **Year**, **Month**, and **Product**.

### Page 1 — Customer Demography
- **100** total customers across **10** European countries
- Age group histogram (36–50 dominant at ~33%)
- Gender split: 54% Female / 46% Male
- Customers by country bar chart (Spain leads)

### Page 2 — Conversion
- **14.62%** overall conversion rate
- **19.00%** checkout drop-off rate
- 4-stage funnel: Homepage → Product Page → Checkout → **81%** Purchase
- Conversion rate by price tier: Medium (~15%) > High (~16%) > Low (~12%)
- Year-over-year trend lines (2023–2025)

### Page 3 — Social Media Engagement
- **12M** Views · **2M** Clicks · **529K** Likes · **4,623** Posts
- **19.57%** overall CTR
- CTR by content type (Video 19.85% leads marginally)
- Monthly clicks breakdown by channel

### Page 4 — Sentiment & Reviews
- **3.69/5.0** average rating across **1,363** reviews
- Sentiment volume: Positive dominates (~800+), ~300 Negative
- Monthly sentiment trend by category
- Review table with full text, product, category, and rating

---

## 🔍 Key Findings

### 1. Checkout Is the Critical Leak
The funnel shows near-perfect progression from homepage to checkout (100% → 100%), but **19% of checkout starters abandon** before purchasing. This is the single highest-leverage fix available.

### 2. Campaigns Work — The On-Site Experience Doesn't
All four content channels achieve a consistent ~19.5% CTR, confirming campaigns successfully drive intent. The gap between CTR (19.57%) and conversion (14.62%) points to a **post-click, on-site problem** — not a campaign problem.

### 3. Price Tier Paradox
Medium and High priced products convert better than Low-priced ones, suggesting low-price items suffer from a **perceived value gap** rather than a cost barrier.

### 4. Sentiment Is Mostly Positive, But Fragile
An average rating of 3.69 sits just below the 4.0 trust threshold. The ~300 negative reviews concentrate around delivery and customer support — both **operational, fixable issues**.

---

## 🛠️ Tech Stack

| Layer | Tools |
|-------|-------|
| Data Cleaning & EDA | Python 3.x, pandas, numpy |
| NLP / Sentiment | nltk, VADER SentimentIntensityAnalyzer |
| Analytics / KPIs | SQL (MySQL / PostgreSQL), CTEs, Window Functions |
| Visualization | Microsoft Power BI, DAX |
| Environment | Jupyter Notebook |

---
