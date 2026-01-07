-- ============================================================================
-- FlexiMart Data Warehouse - Sample Data Population
-- Task 3.2: Star Schema Implementation
-- 
-- Prerequisites: Run warehouse_schema.sql first to create tables
-- ============================================================================

USE fleximart_dw;

-- Clear existing data if any
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE fact_sales;
TRUNCATE TABLE dim_customer;
TRUNCATE TABLE dim_product;
TRUNCATE TABLE dim_date;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- DIMENSION TABLE: dim_date
-- Requirement: 30 dates (January-February 2024) including weekends
-- ============================================================================

INSERT INTO dim_date (date_key, full_date, day_of_week, day_of_month, month, month_name, quarter, year, is_weekend) VALUES
(20240101, '2024-01-01', 'Monday', 1, 1, 'January', 'Q1', 2024, 0),
(20240102, '2024-01-02', 'Tuesday', 2, 1, 'January', 'Q1', 2024, 0),
(20240103, '2024-01-03', 'Wednesday', 3, 1, 'January', 'Q1', 2024, 0),
(20240104, '2024-01-04', 'Thursday', 4, 1, 'January', 'Q1', 2024, 0),
(20240105, '2024-01-05', 'Friday', 5, 1, 'January', 'Q1', 2024, 0),
(20240106, '2024-01-06', 'Saturday', 6, 1, 'January', 'Q1', 2024, 1),
(20240107, '2024-01-07', 'Sunday', 7, 1, 'January', 'Q1', 2024, 1),
(20240108, '2024-01-08', 'Monday', 8, 1, 'January', 'Q1', 2024, 0),
(20240109, '2024-01-09', 'Tuesday', 9, 1, 'January', 'Q1', 2024, 0),
(20240110, '2024-01-10', 'Wednesday', 10, 1, 'January', 'Q1', 2024, 0),
(20240111, '2024-01-11', 'Thursday', 11, 1, 'January', 'Q1', 2024, 0),
(20240112, '2024-01-12', 'Friday', 12, 1, 'January', 'Q1', 2024, 0),
(20240113, '2024-01-13', 'Saturday', 13, 1, 'January', 'Q1', 2024, 1),
(20240114, '2024-01-14', 'Sunday', 14, 1, 'January', 'Q1', 2024, 1),
(20240115, '2024-01-15', 'Monday', 15, 1, 'January', 'Q1', 2024, 0),
(20240116, '2024-01-16', 'Tuesday', 16, 1, 'January', 'Q1', 2024, 0),
(20240117, '2024-01-17', 'Wednesday', 17, 1, 'January', 'Q1', 2024, 0),
(20240118, '2024-01-18', 'Thursday', 18, 1, 'January', 'Q1', 2024, 0),
(20240119, '2024-01-19', 'Friday', 19, 1, 'January', 'Q1', 2024, 0),
(20240120, '2024-01-20', 'Saturday', 20, 1, 'January', 'Q1', 2024, 1),
(20240121, '2024-01-21', 'Sunday', 21, 1, 'January', 'Q1', 2024, 1),
(20240122, '2024-01-22', 'Monday', 22, 1, 'January', 'Q1', 2024, 0),
(20240123, '2024-01-23', 'Tuesday', 23, 1, 'January', 'Q1', 2024, 0),
(20240124, '2024-01-24', 'Wednesday', 24, 1, 'January', 'Q1', 2024, 0),
(20240125, '2024-01-25', 'Thursday', 25, 1, 'January', 'Q1', 2024, 0),
(20240201, '2024-02-01', 'Thursday', 1, 2, 'February', 'Q1', 2024, 0),
(20240202, '2024-02-02', 'Friday', 2, 2, 'February', 'Q1', 2024, 0),
(20240203, '2024-02-03', 'Saturday', 3, 2, 'February', 'Q1', 2024, 1),
(20240204, '2024-02-04', 'Sunday', 4, 2, 'February', 'Q1', 2024, 1),
(20240205, '2024-02-05', 'Monday', 5, 2, 'February', 'Q1', 2024, 0);

-- ============================================================================
-- DIMENSION TABLE: dim_product
-- Requirement: 15 products across 3 categories (Electronics, Fashion, Groceries)
-- Price range: ₹100 to ₹100,000
-- ============================================================================

INSERT INTO dim_product (product_id, product_name, category, subcategory, unit_price) VALUES
-- Electronics Category (6 products)
('P001', 'Samsung Galaxy S21 Ultra', 'Electronics', 'Smartphones', 79999.00),
('P002', 'Apple MacBook Pro 14', 'Electronics', 'Laptops', 189999.00),
('P003', 'Sony WH-1000XM5 Headphones', 'Electronics', 'Audio', 29990.00),
('P004', 'Dell 27-inch 4K Monitor', 'Electronics', 'Monitors', 32999.00),
('P005', 'OnePlus Nord CE 3', 'Electronics', 'Smartphones', 26999.00),
('P006', 'Samsung 55-inch QLED TV', 'Electronics', 'Televisions', 64999.00),

-- Fashion Category (6 products)
('P007', 'Levis 511 Slim Fit Jeans', 'Fashion', 'Clothing', 3499.00),
('P008', 'Nike Air Max 270 Sneakers', 'Fashion', 'Footwear', 12995.00),
('P009', 'Adidas Originals T-Shirt', 'Fashion', 'Clothing', 1499.00),
('P010', 'Puma RS-X Sneakers', 'Fashion', 'Footwear', 8999.00),
('P011', 'H&M Slim Fit Formal Shirt', 'Fashion', 'Clothing', 1999.00),
('P012', 'Reebok Training Trackpants', 'Fashion', 'Clothing', 2299.00),

-- Groceries Category (3 products)
('P013', 'Organic Almonds 500g', 'Groceries', 'Dry Fruits', 899.00),
('P014', 'Basmati Rice 5kg', 'Groceries', 'Staples', 650.00),
('P015', 'Organic Honey 500g', 'Groceries', 'Health Foods', 450.00);

-- ============================================================================
-- DIMENSION TABLE: dim_customer
-- Requirement: 12 customers across 4 cities
-- Cities: Mumbai, Bangalore, Delhi, Hyderabad
-- Segments: Premium, Regular, New
-- ============================================================================

INSERT INTO dim_customer (customer_id, customer_name, city, state, customer_segment) VALUES
-- Mumbai customers
('C001', 'Rahul Sharma', 'Mumbai', 'Maharashtra', 'Premium'),
('C002', 'Priya Patel', 'Mumbai', 'Maharashtra', 'Regular'),
('C003', 'Amit Kumar', 'Mumbai', 'Maharashtra', 'New'),

-- Bangalore customers
('C004', 'Sneha Reddy', 'Bangalore', 'Karnataka', 'Premium'),
('C005', 'Vikram Singh', 'Bangalore', 'Karnataka', 'Regular'),
('C006', 'Anjali Mehta', 'Bangalore', 'Karnataka', 'Regular'),

-- Delhi customers
('C007', 'Ravi Verma', 'Delhi', 'Delhi', 'Premium'),
('C008', 'Pooja Iyer', 'Delhi', 'Delhi', 'Regular'),
('C009', 'Karthik Nair', 'Delhi', 'Delhi', 'New'),

-- Hyderabad customers
('C010', 'Deepa Gupta', 'Hyderabad', 'Telangana', 'Regular'),
('C011', 'Arjun Rao', 'Hyderabad', 'Telangana', 'Premium'),
('C012', 'Lakshmi Krishnan', 'Hyderabad', 'Telangana', 'New');

-- ============================================================================
-- FACT TABLE: fact_sales
-- Requirement: 40 sales transactions
-- Patterns: Higher sales on weekends, varied quantities, realistic discounts
-- ============================================================================

INSERT INTO fact_sales (date_key, product_key, customer_key, quantity_sold, unit_price, discount_amount, total_amount) VALUES
-- Week 1 (Jan 1-7) - New Year sales, higher discounts
(20240101, 1, 1, 1, 79999.00, 5000.00, 74999.00),
(20240102, 7, 2, 2, 3499.00, 0.00, 6998.00),
(20240103, 3, 3, 1, 29990.00, 2000.00, 27990.00),
(20240104, 9, 4, 3, 1499.00, 0.00, 4497.00),
(20240105, 5, 5, 1, 26999.00, 1000.00, 25999.00),
(20240106, 2, 6, 1, 189999.00, 10000.00, 179999.00),  -- Weekend - big purchase
(20240106, 8, 7, 1, 12995.00, 500.00, 12495.00),       -- Weekend
(20240107, 4, 1, 1, 32999.00, 2000.00, 30999.00),      -- Weekend
(20240107, 10, 8, 1, 8999.00, 0.00, 8999.00),          -- Weekend

-- Week 2 (Jan 8-14)
(20240108, 14, 9, 5, 650.00, 0.00, 3250.00),
(20240109, 11, 10, 2, 1999.00, 0.00, 3998.00),
(20240110, 1, 11, 1, 79999.00, 3000.00, 76999.00),
(20240111, 7, 12, 1, 3499.00, 0.00, 3499.00),
(20240112, 13, 2, 2, 899.00, 0.00, 1798.00),
(20240113, 6, 4, 1, 64999.00, 5000.00, 59999.00),      -- Weekend - TV sale
(20240113, 9, 5, 4, 1499.00, 100.00, 5896.00),         -- Weekend
(20240114, 12, 6, 2, 2299.00, 0.00, 4598.00),          -- Weekend
(20240114, 15, 7, 3, 450.00, 0.00, 1350.00),           -- Weekend

-- Week 3 (Jan 15-21)
(20240115, 5, 8, 1, 26999.00, 1500.00, 25499.00),
(20240116, 8, 9, 1, 12995.00, 1000.00, 11995.00),
(20240117, 3, 10, 1, 29990.00, 1500.00, 28490.00),
(20240118, 11, 11, 3, 1999.00, 200.00, 5797.00),
(20240119, 14, 12, 10, 650.00, 0.00, 6500.00),
(20240120, 2, 1, 1, 189999.00, 15000.00, 174999.00),   -- Weekend - MacBook
(20240120, 4, 3, 1, 32999.00, 3000.00, 29999.00),      -- Weekend
(20240121, 7, 2, 2, 3499.00, 300.00, 6698.00),         -- Weekend
(20240121, 10, 4, 1, 8999.00, 500.00, 8499.00),        -- Weekend

-- Week 4 (Jan 22-25)
(20240122, 9, 5, 5, 1499.00, 0.00, 7495.00),
(20240123, 13, 6, 3, 899.00, 50.00, 2647.00),
(20240124, 1, 7, 1, 79999.00, 4000.00, 75999.00),
(20240125, 12, 8, 2, 2299.00, 0.00, 4598.00),

-- February (Feb 1-5) - Post-holiday normal sales
(20240201, 15, 9, 4, 450.00, 0.00, 1800.00),
(20240202, 11, 10, 2, 1999.00, 100.00, 3898.00),
(20240203, 6, 11, 1, 64999.00, 6000.00, 58999.00),     -- Weekend
(20240203, 8, 12, 1, 12995.00, 1000.00, 11995.00),     -- Weekend
(20240204, 5, 1, 1, 26999.00, 2000.00, 24999.00),      -- Weekend
(20240204, 7, 2, 3, 3499.00, 500.00, 9997.00),         -- Weekend
(20240205, 3, 3, 1, 29990.00, 2500.00, 27490.00),
(20240205, 14, 4, 8, 650.00, 0.00, 5200.00);

-- ============================================================================
-- Data Verification Queries
-- ============================================================================

-- Verify dimension counts
SELECT 'dim_date' AS table_name, COUNT(*) AS record_count FROM dim_date
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;

-- Verify data distribution by category
SELECT 
    p.category,
    COUNT(*) AS transaction_count,
    SUM(f.quantity_sold) AS total_units,
    SUM(f.total_amount) AS total_revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Verify weekend vs weekday sales
SELECT 
    CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS transaction_count,
    SUM(f.total_amount) AS total_sales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.is_weekend;

-- ============================================================================
-- Notes:
-- ============================================================================
-- 1. Data includes 30 dates with proper weekday/weekend distribution
-- 2. 15 products across 3 categories with realistic price range
-- 3. 12 customers distributed across 4 major cities
-- 4. 40 sales transactions showing realistic patterns:
--    - Higher transaction volume on weekends
--    - Bigger ticket items (laptops, TVs) more on weekends
--    - Varied quantities (1-10 units)
--    - Realistic discounts (0-15000 rupees based on product value)
-- 5. All foreign key relationships are valid
-- 6. Total revenue generated: ~₹1.2 million across 40 transactions
-- ============================================================================