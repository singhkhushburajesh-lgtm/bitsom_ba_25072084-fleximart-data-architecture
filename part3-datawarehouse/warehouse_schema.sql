-- ============================================================================
-- FlexiMart Data Warehouse - Schema Creation
-- Task 3.2: Star Schema Implementation
-- Database: fleximart_dw
-- ============================================================================

-- Drop database if exists and create fresh
DROP DATABASE IF EXISTS fleximart_dw;
CREATE DATABASE fleximart_dw;
USE fleximart_dw;

-- ============================================================================
-- DIMENSION TABLE: dim_date
-- Purpose: Time dimension for temporal analysis
-- ============================================================================

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week VARCHAR(10),
    day_of_month INT,
    month INT,
    month_name VARCHAR(10),
    quarter VARCHAR(2),
    year INT,
    is_weekend BOOLEAN
);

-- ============================================================================
-- DIMENSION TABLE: dim_product
-- Purpose: Product master data
-- ============================================================================

CREATE TABLE dim_product (
    product_key INT PRIMARY KEY AUTO_INCREMENT,
    product_id VARCHAR(20),
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    unit_price DECIMAL(10,2)
);

-- ============================================================================
-- DIMENSION TABLE: dim_customer
-- Purpose: Customer demographic and geographic information
-- ============================================================================

CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY AUTO_INCREMENT,
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    customer_segment VARCHAR(20)
);

-- ============================================================================
-- FACT TABLE: fact_sales
-- Purpose: Sales transactions at line-item level
-- Grain: One row per product per order
-- ============================================================================

CREATE TABLE fact_sales (
    sale_key INT PRIMARY KEY AUTO_INCREMENT,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    customer_key INT NOT NULL,
    quantity_sold INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
);

-- ============================================================================
-- Indexes for Query Performance
-- ============================================================================

-- Indexes on fact table foreign keys (automatically created by FK constraints)
-- Additional indexes for common query patterns

CREATE INDEX idx_fact_date ON fact_sales(date_key);
CREATE INDEX idx_fact_product ON fact_sales(product_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);

-- Composite index for common grouping queries
CREATE INDEX idx_fact_date_product ON fact_sales(date_key, product_key);
CREATE INDEX idx_fact_date_customer ON fact_sales(date_key, customer_key);

-- ============================================================================
-- Schema Verification
-- ============================================================================

-- Show all tables
SHOW TABLES;

-- Describe each table structure
DESCRIBE dim_date;
DESCRIBE dim_product;
DESCRIBE dim_customer;
DESCRIBE fact_sales;

-- ============================================================================
-- Notes:
-- ============================================================================
-- 1. Star schema with 1 fact table and 3 dimension tables
-- 2. Surrogate keys used for all dimensions
-- 3. Natural keys preserved for traceability (product_id, customer_id)
-- 4. Foreign key constraints ensure referential integrity
-- 5. Indexes created for optimal query performance
-- 6. date_key uses integer format (YYYYMMDD) for fast comparisons
-- ============================================================================