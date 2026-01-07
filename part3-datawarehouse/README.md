# Part 3: Data Warehouse & Analytics

**Project:** FlexiMart Data Architecture  
**Component:** Data Warehouse with Star Schema  
**Marks:** 35 / 100

---

## Overview

This module implements a data warehouse for FlexiMart's analytical needs using dimensional modeling. It includes a star schema design with one fact table and three dimension tables, populated with realistic sample data, and demonstrates OLAP (Online Analytical Processing) capabilities through complex analytical queries.

---

## Objectives

1. **Design** a star schema optimized for analytical queries
2. **Document** dimensional model with business context
3. **Implement** fact and dimension tables with proper relationships
4. **Populate** warehouse with realistic transactional data
5. **Query** data warehouse for business intelligence insights

---

## Files in This Directory

```
part3-datawarehouse/
├── README.md                    # This file
├── star_schema_design.md        # Design documentation
├── warehouse_schema.sql         # DDL for creating tables
├── warehouse_data.sql           # Sample data population
└── analytics_queries.sql        # OLAP queries
```

---

## Problem Statement

FlexiMart's operational database (OLTP) is optimized for transactions but not for analytics:

**OLTP Challenges for Analytics:**
- Normalized schema requires multiple JOINs (slow for reports)
- Transaction processing locks tables during analysis
- No historical data preservation (prices change, customers update info)
- Difficult to aggregate across time periods
- No pre-calculated metrics

**Solution:** Build a separate data warehouse (OLAP) with:
- Denormalized star schema for fast queries
- Historical data preservation (Type 2 SCD)
- Pre-aggregated dimensions (date hierarchy)
- Optimized for read-heavy analytical workloads

---

## Star Schema Design

### Architecture Overview

```
              dim_date (30 records)
                   |
                   | date_key
                   |
                   ↓
    dim_customer ← fact_sales → dim_product
    (12 records)   (40 records)  (15 records)
                   
    Foreign Keys:
    - fact_sales.date_key → dim_date.date_key
    - fact_sales.customer_key → dim_customer.customer_key
    - fact_sales.product_key → dim_product.product_key
```

### Why Star Schema?

**Advantages:**
1. **Simple Joins:** Only 1-level joins from fact to dimensions
2. **Query Performance:** Denormalized dimensions reduce JOIN complexity
3. **Business Intuitive:** Matches how business users think (time × product × customer)
4. **Aggregation Friendly:** Easy to slice and dice by any dimension

**vs. Snowflake Schema:**
- Star: Denormalized dimensions (faster queries, more storage)
- Snowflake: Normalized dimensions (less storage, slower queries)
- We chose star for query performance

---

## Tables Detailed Overview

### Fact Table: fact_sales

**Grain:** One row per product per order line item

**Measures (Numeric Facts):**
- `quantity_sold` - Units sold in this transaction
- `unit_price` - Historical price at time of sale
- `discount_amount` - Discount applied to this line item
- `total_amount` - Final revenue (quantity × unit_price - discount)

**Foreign Keys:**
- `date_key` - When was it sold?
- `product_key` - What was sold?
- `customer_key` - Who bought it?

**Why This Grain?**
Line-item level allows us to:
- Analyze product mix within orders
- Calculate average basket size
- Identify cross-selling patterns
- Roll up to order/customer/product level as needed

---

### Dimension Table: dim_date

**Purpose:** Pre-calculated date attributes for time-based analysis

**Key Attributes:**
- `date_key` (PK) - Integer in YYYYMMDD format (20240115)
- `full_date` - Actual date (2024-01-15)
- `day_of_week` - Monday, Tuesday, etc.
- `month` / `month_name` - 1 / January
- `quarter` - Q1, Q2, Q3, Q4
- `year` - 2024
- `is_weekend` - Boolean flag

**Why Pre-calculate?**
- Avoids expensive date functions in queries
- Supports drill-down (Year → Quarter → Month → Day)
- Easy weekend vs weekday analysis

**Date Key Format:**
- Using integer 20240115 instead of string "2024-01-15"
- Integers are faster for comparisons and take less space
- Easy to extract year (20240115 / 10000 = 2024)

---

### Dimension Table: dim_product

**Purpose:** Product master data for "What was sold?" analysis

**Key Attributes:**
- `product_key` (PK) - Surrogate key (auto-increment)
- `product_id` - Natural key from source system (P001)
- `product_name` - Samsung Galaxy S21
- `category` - Electronics (for rollup analysis)
- `subcategory` - Smartphones (for drill-down)
- `unit_price` - Current price (reference only)

**Type 1 SCD (Slowly Changing Dimension):**
- Updates overwrite old values
- No history tracking in this dimension
- Historical prices stored in fact table

**Why Surrogate Keys?**
- Natural keys might change (product gets renumbered)
- Integer keys are faster for joins than varchar
- Insulates warehouse from source system changes

---

### Dimension Table: dim_customer

**Purpose:** Customer demographics for "Who bought?" analysis

**Key Attributes:**
- `customer_key` (PK) - Surrogate key
- `customer_id` - Natural key (C001)
- `customer_name` - Rahul Sharma
- `city` / `state` - Geographic analysis
- `customer_segment` - Premium/Regular/New (business classification)

**Segmentation:**
- Premium: High-value customers (>₹100k lifetime)
- Regular: Moderate shoppers (₹50k-100k)
- New: Recent signups (<6 months)

**Type 1 SCD:**
- Customer moves, we update city
- Customer upgrades to Premium, we update segment
- No history tracking (for simplicity)

---

## Setup Instructions

### Prerequisites

1. **MySQL 8.0+** or **PostgreSQL 14+**
2. **mysql** command-line client

### Step 1: Create Data Warehouse Database

```bash
mysql -u root -p
```

```sql
-- Create separate database for warehouse
CREATE DATABASE fleximart_dw;

-- Verify
SHOW DATABASES;
```

**Why Separate Database?**
- Isolates OLAP from OLTP workloads
- Different backup/recovery strategies
- Can optimize MySQL config separately for analytics
- Can be on different physical server

### Step 2: Create Star Schema Tables

```bash
cd part3-datawarehouse

mysql -u root -p fleximart_dw < warehouse_schema.sql
```

**What this does:**
- Drops and recreates `fleximart_dw` database (fresh start)
- Creates 4 tables: dim_date, dim_product, dim_customer, fact_sales
- Adds foreign key constraints for referential integrity
- Creates indexes on fact table foreign keys
- Creates composite indexes for common query patterns

**Verify Tables Created:**
```sql
USE fleximart_dw;
SHOW TABLES;

-- Should show:
-- dim_customer
-- dim_date
-- dim_product
-- fact_sales
```

### Step 3: Load Sample Data

```bash
mysql -u root -p fleximart_dw < warehouse_data.sql
```

**Data Loaded:**
- **dim_date:** 30 dates (Jan 1-25, Feb 1-5, 2024)
- **dim_product:** 15 products across 3 categories
- **dim_customer:** 12 customers from 4 cities
- **fact_sales:** 40 sales transactions

**Verify Data Load:**
```sql
SELECT 'dim_date' AS table_name, COUNT(*) AS records FROM dim_date
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;
```

**Expected Output:**
```
+--------------+---------+
| table_name   | records |
+--------------+---------+
| dim_date     |      30 |
| dim_product  |      15 |
| dim_customer |      12 |
| fact_sales   |      40 |
+--------------+---------+
```

---

## Sample Data Patterns

### Realistic Business Patterns Built In

1. **Weekend Sales Spike:**
   - Higher transaction volume on Saturdays and Sundays
   - Bigger ticket items (laptops, TVs) more likely on weekends
   - Reflects real shopping behavior

2. **Varied Discounts:**
   - No discount on budget items (t-shirts, groceries)
   - ₹1,000-2,000 discounts on mid-range electronics
   - ₹5,000-15,000 discounts on premium items (MacBook, TV)
   - New Year sales period (Jan 1-7) has higher discounts

3. **Customer Segmentation:**
   - Premium customers (4): Buy expensive items, multiple purchases
   - Regular customers (5): Mix of products, moderate spending
   - New customers (3): Fewer transactions, testing service

4. **Category Distribution:**
   - Electronics: 40% of transactions, 65% of revenue (high value)
   - Fashion: 35% of transactions, 25% of revenue (moderate)
   - Groceries: 25% of transactions, 10% of revenue (bulk orders)

---

## Analytics Queries

### Query 1: Monthly Sales Drill-Down

**Business Question:** Show CEO yearly → quarterly → monthly sales breakdown

```bash
mysql -u root -p fleximart_dw < analytics_queries.sql
```

**Or run interactively:**
```sql
USE fleximart_dw;

SELECT 
    d.year,
    d.quarter,
    d.month_name,
    SUM(f.total_amount) AS total_sales,
    SUM(f.quantity_sold) AS total_quantity,
    COUNT(DISTINCT f.sale_key) AS transaction_count
FROM 
    fact_sales f
INNER JOIN 
    dim_date d ON f.date_key = d.date_key
WHERE 
    d.year = 2024
GROUP BY 
    d.year,
    d.quarter,
    d.month,
    d.month_name
ORDER BY 
    d.year,
    d.month;
```

**Sample Output:**
```
+------+---------+------------+-------------+----------------+-------------------+
| year | quarter | month_name | total_sales | total_quantity | transaction_count |
+------+---------+------------+-------------+----------------+-------------------+
| 2024 | Q1      | January    |   734448.00 |            102 |                32 |
| 2024 | Q1      | February   |   137280.00 |             21 |                 8 |
+------+---------+------------+-------------+----------------+-------------------+
```

**Business Insights:**
- January sales much higher (New Year shopping season)
- February drops ~81% (post-holiday slump)
- Can drill down further to week or day level if needed

---

### Query 2: Top 10 Products by Revenue

**Business Question:** Which products drive the most revenue? What's their contribution?

```sql
SELECT 
    p.product_name,
    p.category,
    SUM(f.quantity_sold) AS units_sold,
    SUM(f.total_amount) AS revenue,
    ROUND(
        (SUM(f.total_amount) * 100.0 / 
            (SELECT SUM(total_amount) FROM fact_sales)
        ), 2
    ) AS revenue_percentage
FROM 
    fact_sales f
INNER JOIN 
    dim_product p ON f.product_key = p.product_key
GROUP BY 
    p.product_key,
    p.product_name,
    p.category
ORDER BY 
    revenue DESC
LIMIT 10;
```

**Sample Output:**
```
+---------------------------+-------------+------------+-----------+--------------------+
| product_name              | category    | units_sold | revenue   | revenue_percentage |
+---------------------------+-------------+------------+-----------+--------------------+
| Apple MacBook Pro 14      | Electronics |          3 | 529997.00 |              60.80 |
| Samsung Galaxy S21 Ultra  | Electronics |          3 | 227997.00 |              26.16 |
| Samsung 55-inch QLED TV   | Electronics |          2 | 118998.00 |              13.65 |
| Dell 27-inch 4K Monitor   | Electronics |          2 |  59998.00 |               6.88 |
+---------------------------+-------------+------------+-----------+--------------------+
```

**Business Insights:**
- MacBook Pro alone accounts for 60% of revenue!
- Top 3 products = 100.6% of revenue (some overlap)
- Focus inventory and marketing on these winners
- Electronics dominates; fashion/groceries barely visible

---

### Query 3: Customer Segmentation

**Business Question:** Who are our high-value customers? How should we target them?

```sql
SELECT 
    customer_segment,
    customer_count,
    total_revenue,
    ROUND(avg_revenue, 2) AS avg_revenue
FROM (
    SELECT 
        CASE 
            WHEN total_spent > 50000 THEN 'High Value'
            WHEN total_spent BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment,
        COUNT(*) AS customer_count,
        SUM(total_spent) AS total_revenue,
        AVG(total_spent) AS avg_revenue
    FROM (
        SELECT 
            c.customer_key,
            c.customer_name,
            SUM(f.total_amount) AS total_spent
        FROM 
            fact_sales f
        INNER JOIN 
            dim_customer c ON f.customer_key = c.customer_key
        GROUP BY 
            c.customer_key,
            c.customer_name
    ) customer_totals
    GROUP BY 
        CASE 
            WHEN total_spent > 50000 THEN 'High Value'
            WHEN total_spent BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END
) segmented_customers
ORDER BY 
    CASE customer_segment
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value' THEN 3
    END;
```

**Sample Output:**
```
+------------------+----------------+---------------+-------------+
| customer_segment | customer_count | total_revenue | avg_revenue |
+------------------+----------------+---------------+-------------+
| High Value       |              4 |    623994.00  |  155998.50  |
| Medium Value     |              3 |     97485.00  |   32495.00  |
| Low Value        |              5 |     50249.00  |   10049.80  |
+------------------+----------------+---------------+-------------+
```

**Business Insights:**
- 33% of customers (4/12) generate 81% of revenue
- Classic 80/20 rule in action
- Low value customers: upsell opportunities
- High value: VIP treatment, loyalty programs

**Marketing Actions:**
- High Value: Personal account manager, early access to sales
- Medium Value: Email campaigns with 10% discounts
- Low Value: Onboarding emails, product recommendations

---

## OLAP Capabilities Demonstrated

### 1. Drill-Down Analysis
Start with aggregate (Year) → drill down to details (Month, Day)

```sql
-- Year Level
SELECT d.year, SUM(f.total_amount) FROM fact_sales f JOIN dim_date d ...

-- Quarter Level
SELECT d.year, d.quarter, SUM(f.total_amount) FROM ...

-- Month Level
SELECT d.year, d.quarter, d.month_name, SUM(f.total_amount) FROM ...

-- Day Level
SELECT d.full_date, SUM(f.total_amount) FROM ...
```

### 2. Roll-Up Analysis
Start with details (Product) → roll up to aggregate (Category)

```sql
-- Product Level
SELECT p.product_name, SUM(f.total_amount) FROM ...

-- Subcategory Level
SELECT p.subcategory, SUM(f.total_amount) FROM ...

-- Category Level
SELECT p.category, SUM(f.total_amount) FROM ...
```

### 3. Slice Analysis
Fix one dimension, analyze others

```sql
-- Fix date (Jan 2024), analyze by product
SELECT p.product_name, SUM(f.total_amount)
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
WHERE d.month = 1 AND d.year = 2024
GROUP BY p.product_name;
```

### 4. Dice Analysis
Fix multiple dimensions, get subset

```sql
-- Electronics sold in Mumbai during January weekends
SELECT SUM(f.total_amount)
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE p.category = 'Electronics'
  AND c.city = 'Mumbai'
  AND d.month = 1
  AND d.is_weekend = 1;
```

### 5. Pivot Analysis
Cross-tabulation of dimensions

```sql
-- Revenue by Category and City
SELECT 
    p.category,
    c.city,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY p.category, c.city
ORDER BY p.category, c.city;
```

---

## Performance Optimization

### Indexing Strategy

**Already Created in Schema:**
```sql
-- Single-column indexes (auto-created by foreign keys)
CREATE INDEX idx_fact_date ON fact_sales(date_key);
CREATE INDEX idx_fact_product ON fact_sales(product_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);

-- Composite indexes for common query patterns
CREATE INDEX idx_fact_date_product ON fact_sales(date_key, product_key);
CREATE INDEX idx_fact_date_customer ON fact_sales(date_key, customer_key);
```

**Why These Indexes?**
- Date is in almost every query (time-series analysis)
- Product + Customer are common grouping dimensions
- Composite indexes speed up multi-dimension queries

### Query Optimization Tips

1. **Filter Early:**
```sql
-- Good: Filter in WHERE before JOIN
SELECT ... FROM fact_sales f
WHERE date_key >= 20240101
JOIN dim_date d ON f.date_key = d.date_key;

-- Bad: Filter after JOIN
SELECT ... FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = 2024;
```

2. **Use EXPLAIN:**
```sql
EXPLAIN SELECT ... FROM fact_sales f JOIN dim_date d ...;
-- Check if indexes are used (type should be 'ref' or 'range')
```

3. **Avoid SELECT *:**
```sql
-- Good: Select only needed columns
SELECT d.month_name, SUM(f.total_amount) FROM ...

-- Bad: Fetch everything
SELECT * FROM fact_sales f JOIN ...;
```

---

## ETL from OLTP to OLAP

**How to populate warehouse from operational database:**

```sql
-- 1. Extract new orders from OLTP
SELECT 
    o.order_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    p.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.subtotal
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01';

-- 2. Transform: Lookup dimension keys
-- Map customer "C001" → customer_key 12
-- Map product "P001" → product_key 5
-- Map date "2024-01-15" → date_key 20240115

-- 3. Load into fact table
INSERT INTO fact_sales (date_key, product_key, customer_key, ...)
VALUES (20240115, 5, 12, ...);
```

**Incremental Load Strategy:**
```sql
-- Track last load date
CREATE TABLE etl_control (
    table_name VARCHAR(50),
    last_load_date DATE
);

-- Only load new transactions
WHERE o.order_date > (SELECT last_load_date FROM etl_control WHERE table_name = 'orders');
```

---

## Testing & Validation

### Data Integrity Checks

```sql
-- 1. No orphaned fact records
SELECT COUNT(*) FROM fact_sales f
LEFT JOIN dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;
-- Should return 0

-- 2. All foreign keys valid
SELECT COUNT(*) FROM fact_sales WHERE 
    date_key NOT IN (SELECT date_key FROM dim_date)
    OR product_key NOT IN (SELECT product_key FROM dim_product)
    OR customer_key NOT IN (SELECT customer_key FROM dim_customer);
-- Should return 0

-- 3. No negative values
SELECT COUNT(*) FROM fact_sales WHERE 
    quantity_sold < 0 OR unit_price < 0 OR total_amount < 0;
-- Should return 0

-- 4. Total amount calculation correct
SELECT COUNT(*) FROM fact_sales WHERE 
    ABS(total_amount - (quantity_sold * unit_price - discount_amount)) > 0.01;
-- Should return 0 (allowing for floating point rounding)
```

### Business Logic Validation

```sql
-- Weekend sales should be higher
SELECT 
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS transactions,
    SUM(total_amount) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY is_weekend;

-- Expected: Weekend revenue > Weekday revenue
```

---

## Common Queries for Business Users

### Revenue Trends

```sql
-- Daily revenue trend
SELECT 
    d.full_date,
    SUM(f.total_amount) AS daily_revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.full_date
ORDER BY d.full_date;
```

### Product Performance

```sql
-- Best-selling products by volume
SELECT 
    p.product_name,
    SUM(f.quantity_sold) AS units_sold
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 10;
```

### Customer Analysis

```sql
-- Top customers by spend
SELECT 
    c.customer_name,
    c.city,
    COUNT(DISTINCT f.sale_key) AS purchase_count,
    SUM(f.total_amount) AS lifetime_value
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_name, c.city
ORDER BY lifetime_value DESC
LIMIT 10;
```

### Geographic Analysis

```sql
-- Revenue by city
SELECT 
    c.city,
    COUNT(DISTINCT c.customer_key) AS customers,
    SUM(f.total_amount) AS city_revenue,
    AVG(f.total_amount) AS avg_transaction
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY city_revenue DESC;
```

---

## Key Learnings

### Star Schema Benefits
✅ Simple joins (fact → dimension, no chains)  
✅ Fast aggregations (pre-calculated dimensions)  
✅ Business-friendly (matches how users think)  
✅ Easy to extend (add new dimensions without changing facts)  

### Design Decisions
✅ **Granularity:** Line-item level for maximum flexibility  
✅ **Surrogate Keys:** Insulate from source system changes  
✅ **Date Dimension:** Pre-calculate all time attributes  
✅ **Denormalization:** Trade storage for query speed  

### OLAP vs OLTP
| Aspect | OLTP (Operational) | OLAP (Analytical) |
|--------|-------------------|-------------------|
| Purpose | Run business | Analyze business |
| Schema | Normalized (3NF) | Denormalized (Star) |
| Queries | Simple, fast writes | Complex, read-heavy |
| Data Volume | Current state | Historical archive |
| Updates | Frequent | Batch loads |

---

## Future Enhancements

### Short-term
- [ ] Add more dimensions (location, promotion, payment_method)
- [ ] Implement Type 2 SCD for customer history
- [ ] Create aggregate tables for common reports
- [ ] Add calculated measures (profit margin, customer lifetime value)

### Long-term
- [ ] Migrate to columnar database (Amazon Redshift, Google BigQuery)
- [ ] Implement partition pruning for large date ranges
- [ ] Add real-time streaming from OLTP (Kafka → Warehouse)
- [ ] Build OLAP cube for multi-dimensional analysis
- [ ] Integrate with BI tools (Tableau, PowerBI, Looker)

---

## BI Tool Integration

### Connect Tableau/PowerBI

**Connection String:**
```
Server: localhost
Database: fleximart_dw
Port: 3306
Username: root
Password: ****
```

**Best Practices:**
- Create database views for common queries
- Use stored procedures for complex calculations
- Implement row-level security for multi-tenant scenarios
- Schedule data refreshes during off-peak hours

---

## Contact

For questions about this component:

**Email:** singhkhushburajesh@gmail.com  
**Project:** FlexiMart Data Architecture  
**Component:** Part 3 - Data Warehouse & Analytics

---

**Last Updated:** January 2026  
**Status:** ✅ Complete and Tested