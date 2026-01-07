-- ============================================================================
-- FlexiMart Data Warehouse - OLAP Analytics Queries
-- Task 3.3: OLAP Analytics Queries
-- ============================================================================

-- ============================================================================
-- Query 1: Monthly Sales Drill-Down Analysis (5 marks)
-- ============================================================================
-- Business Scenario: "The CEO wants to see sales performance broken down by 
-- time periods. Start with yearly total, then quarterly, then monthly sales 
-- for 2024."
--
-- Demonstrates: Drill-down from Year → Quarter → Month
-- ============================================================================

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

-- Alternative query showing just quarter-level rollup
/*
SELECT 
    d.year,
    d.quarter,
    SUM(f.total_amount) AS total_sales,
    SUM(f.quantity_sold) AS total_quantity
FROM 
    fact_sales f
INNER JOIN 
    dim_date d ON f.date_key = d.date_key
WHERE 
    d.year = 2024
GROUP BY 
    d.year,
    d.quarter
ORDER BY 
    d.year,
    d.quarter;
*/


-- ============================================================================
-- Query 2: Product Performance Analysis (5 marks)
-- ============================================================================
-- Business Scenario: "The product manager needs to identify top-performing 
-- products. Show the top 10 products by revenue, along with their category, 
-- total units sold, and revenue contribution percentage."
--
-- Includes: Revenue percentage calculation using window function
-- ============================================================================

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

-- Alternative solution using window function (MySQL 8.0+)
/*
WITH product_revenue AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.quantity_sold) AS units_sold,
        SUM(f.total_amount) AS revenue
    FROM 
        fact_sales f
    INNER JOIN 
        dim_product p ON f.product_key = p.product_key
    GROUP BY 
        p.product_key,
        p.product_name,
        p.category
)
SELECT 
    product_name,
    category,
    units_sold,
    revenue,
    ROUND(
        (revenue * 100.0 / SUM(revenue) OVER ()), 2
    ) AS revenue_percentage
FROM 
    product_revenue
ORDER BY 
    revenue DESC
LIMIT 10;
*/


-- ============================================================================
-- Query 3: Customer Segmentation Analysis (5 marks)
-- ============================================================================
-- Business Scenario: "Marketing wants to target high-value customers. Segment 
-- customers into 'High Value' (>₹50,000 spent), 'Medium Value' 
-- (₹20,000-₹50,000), and 'Low Value' (<₹20,000). Show count of customers and 
-- total revenue in each segment."
--
-- Segments: High/Medium/Low value customers using CASE statement
-- ============================================================================

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

-- Alternative cleaner version using CTE (Common Table Expression)
/*
WITH customer_spending AS (
    SELECT 
        c.customer_key,
        c.customer_name,
        c.city,
        SUM(f.total_amount) AS total_spent
    FROM 
        fact_sales f
    INNER JOIN 
        dim_customer c ON f.customer_key = c.customer_key
    GROUP BY 
        c.customer_key,
        c.customer_name,
        c.city
),
customer_segments AS (
    SELECT 
        customer_key,
        customer_name,
        city,
        total_spent,
        CASE 
            WHEN total_spent > 50000 THEN 'High Value'
            WHEN total_spent >= 20000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS segment
    FROM 
        customer_spending
)
SELECT 
    segment AS customer_segment,
    COUNT(*) AS customer_count,
    SUM(total_spent) AS total_revenue,
    ROUND(AVG(total_spent), 2) AS avg_revenue
FROM 
    customer_segments
GROUP BY 
    segment
ORDER BY 
    CASE segment
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value' THEN 3
    END;
*/


-- ============================================================================
-- BONUS: Additional Analytical Queries for Business Insights
-- ============================================================================

-- Query 4: City-wise Sales Performance
-- Shows which cities generate most revenue
SELECT 
    c.city,
    c.state,
    COUNT(DISTINCT c.customer_key) AS customer_count,
    COUNT(f.sale_key) AS transaction_count,
    SUM(f.total_amount) AS total_revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_transaction_value
FROM 
    fact_sales f
INNER JOIN 
    dim_customer c ON f.customer_key = c.customer_key
GROUP BY 
    c.city,
    c.state
ORDER BY 
    total_revenue DESC;


-- Query 5: Category Performance by Customer Segment
-- Cross-tab analysis: Which customer segments buy which categories?
SELECT 
    c.customer_segment,
    p.category,
    COUNT(f.sale_key) AS purchase_count,
    SUM(f.total_amount) AS category_revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_purchase_value
FROM 
    fact_sales f
INNER JOIN 
    dim_customer c ON f.customer_key = c.customer_key
INNER JOIN 
    dim_product p ON f.product_key = p.product_key
GROUP BY 
    c.customer_segment,
    p.category
ORDER BY 
    c.customer_segment,
    category_revenue DESC;


-- Query 6: Weekend vs Weekday Sales Comparison
-- Business insight: Should we run weekend promotions?
SELECT 
    CASE 
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(DISTINCT f.date_key) AS days_count,
    COUNT(f.sale_key) AS transaction_count,
    SUM(f.total_amount) AS total_sales,
    ROUND(AVG(f.total_amount), 2) AS avg_transaction_value,
    ROUND(SUM(f.total_amount) / COUNT(DISTINCT f.date_key), 2) AS avg_daily_sales
FROM 
    fact_sales f
INNER JOIN 
    dim_date d ON f.date_key = d.date_key
GROUP BY 
    d.is_weekend
ORDER BY 
    day_type;


-- Query 7: Product Affinity Analysis
-- Which products are frequently bought by same customers?
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(DISTINCT f1.customer_key) AS customers_who_bought_both
FROM 
    fact_sales f1
INNER JOIN 
    fact_sales f2 ON f1.customer_key = f2.customer_key 
                  AND f1.product_key < f2.product_key
INNER JOIN 
    dim_product p1 ON f1.product_key = p1.product_key
INNER JOIN 
    dim_product p2 ON f2.product_key = p2.product_key
GROUP BY 
    p1.product_name,
    p2.product_name
HAVING 
    COUNT(DISTINCT f1.customer_key) >= 2
ORDER BY 
    customers_who_bought_both DESC;


-- ============================================================================
-- Query Execution Summary
-- ============================================================================
/*
Expected Results Summary:

Query 1 - Monthly Drill-Down:
- Should show Q1 2024 broken down by January and February
- January likely has higher sales due to New Year discounts
- Can easily roll up to quarter or year level

Query 2 - Top 10 Products:
- Apple MacBook Pro and Samsung phones likely at top
- Electronics category dominates revenue
- Percentage column shows concentration of sales

Query 3 - Customer Segmentation:
- High Value: Customers spending >50k (likely 3-4 customers)
- Medium Value: 20-50k range (likely 4-5 customers)
- Low Value: Under 20k (remaining customers)
- Useful for targeted marketing campaigns

These queries demonstrate:
✓ Dimensional modeling benefits (fast joins)
✓ Aggregation at different levels (drill-down/roll-up)
✓ Business-focused metrics (not just technical queries)
✓ Real decision-making support for FlexiMart management
*/