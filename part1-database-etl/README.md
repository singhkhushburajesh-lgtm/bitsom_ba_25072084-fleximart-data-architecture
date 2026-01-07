# Part 1: Database Design & ETL Pipeline

**Project:** FlexiMart Data Architecture  
**Component:** Relational Database & ETL  
**Marks:** 35 / 100

---

## Overview

This module implements a complete ETL (Extract, Transform, Load) pipeline for FlexiMart's operational database. It processes raw CSV files containing customer, product, and sales data with various quality issues, cleans the data, and loads it into a normalized MySQL database following 3NF principles.

---

## Objectives

1. **Extract** data from three CSV files with intentional quality issues
2. **Transform** data by handling duplicates, missing values, and format inconsistencies
3. **Load** cleaned data into a properly normalized MySQL database
4. **Document** the database schema with ER descriptions and normalization justification
5. **Query** the database to answer specific business questions

---

## Files in This Directory

```
part1-database-etl/
├── README.md                    # This file
├── etl_pipeline.py              # Main ETL script
├── schema_documentation.md      # Database design documentation
├── business_queries.sql         # SQL queries for business analysis
├── data_quality_report.txt      # Generated report (after ETL run)
├── etl_pipeline.log            # Execution logs (after ETL run)
└── requirements.txt            # Python dependencies
```

---

## Input Data Files

Located in `../data/` directory:

### 1. customers_raw.csv (26 records)
**Data Quality Issues:**
- 1 duplicate record (C001 appears twice)
- 5 missing emails (C003, C007, C012, C018, C023)
- Inconsistent phone formats (+91-, 0 prefix, dashes)
- Inconsistent date formats (YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY)
- Mixed case city names

### 2. products_raw.csv (20 records)
**Data Quality Issues:**
- 3 missing prices (P003, P010, P017)
- 1 missing stock quantity (P006)
- Inconsistent category naming (electronics vs Electronics vs ELECTRONICS)
- Extra whitespace in product names

### 3. sales_raw.csv (40 records)
**Data Quality Issues:**
- 1 duplicate transaction (T001 appears twice)
- 3 missing customer_ids (T004, T016, T030)
- 2 missing product_ids (T008, T025)
- Inconsistent date formats (3 different formats)

---

## Database Schema

### Entity-Relationship Model

The database follows a normalized star-like structure with 4 tables:

```
customers (1) ----< orders (M) ----< order_items (M) >---- (M) products (1)
```

### Tables

#### 1. **customers**
- **Purpose:** Store customer registration and contact information
- **Primary Key:** customer_id (auto-increment)
- **Unique Constraint:** email
- **Attributes:** first_name, last_name, email, phone, city, registration_date

#### 2. **products**
- **Purpose:** Maintain product catalog with pricing and inventory
- **Primary Key:** product_id (auto-increment)
- **Attributes:** product_name, category, price, stock_quantity

#### 3. **orders**
- **Purpose:** Track order headers with customer and status
- **Primary Key:** order_id (auto-increment)
- **Foreign Key:** customer_id → customers(customer_id)
- **Attributes:** order_date, total_amount, status

#### 4. **order_items**
- **Purpose:** Store line-item details for each order
- **Primary Key:** order_item_id (auto-increment)
- **Foreign Keys:** 
  - order_id → orders(order_id)
  - product_id → products(product_id)
- **Attributes:** quantity, unit_price, subtotal

---

## Setup Instructions

### Prerequisites

1. **MySQL Server 8.0+** or **PostgreSQL 14+**
2. **Python 3.8+**
3. **pip** package manager

### Step 1: Install Python Dependencies

```bash
cd part1-database-etl
pip install -r requirements.txt
```

**Dependencies:**
- `pandas` - Data manipulation
- `mysql-connector-python` - MySQL connectivity
- `python-dateutil` - Date parsing

### Step 2: Create Database and Tables

```bash
mysql -u root -p
```

```sql
-- Create database
CREATE DATABASE fleximart;
USE fleximart;

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    city VARCHAR(50),
    registration_date DATE
);

-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT DEFAULT 0
);

-- Create orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create order_items table
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

### Step 3: Configure Database Credentials

Edit `etl_pipeline.py` and update the database configuration at the bottom:

```python
db_config = {
    'host': 'localhost',
    'database': 'fleximart',
    'user': 'your_username',      # CHANGE THIS
    'password': 'your_password'    # CHANGE THIS
}
```

### Step 4: Run ETL Pipeline

```bash
python etl_pipeline.py
```

**Expected Console Output:**
```
2026-01-07 10:30:45 - INFO - ======================================================================
2026-01-07 10:30:45 - INFO - STARTING FLEXIMART ETL PIPELINE
2026-01-07 10:30:45 - INFO - ======================================================================
2026-01-07 10:30:45 - INFO - Successfully connected to database

2026-01-07 10:30:45 - INFO - --- EXTRACT PHASE ---
2026-01-07 10:30:45 - INFO - Extracted 26 customer records
2026-01-07 10:30:45 - INFO - Extracted 20 product records
2026-01-07 10:30:45 - INFO - Extracted 40 sales records

2026-01-07 10:30:46 - INFO - --- TRANSFORM PHASE ---
2026-01-07 10:30:46 - INFO - Removed 1 duplicate customer records
2026-01-07 10:30:46 - INFO - Customer transformation complete: 20 clean records
2026-01-07 10:30:46 - INFO - Product transformation complete: 17 clean records
2026-01-07 10:30:46 - INFO - Removed 1 duplicate sales records
2026-01-07 10:30:46 - INFO - Sales transformation complete: 34 clean records

2026-01-07 10:30:47 - INFO - --- LOAD PHASE ---
2026-01-07 10:30:47 - INFO - Loaded 20 customers into database
2026-01-07 10:30:47 - INFO - Loaded 17 products into database
2026-01-07 10:30:47 - INFO - Loaded 34 order items into database

2026-01-07 10:30:47 - INFO - --- GENERATING REPORT ---
2026-01-07 10:30:47 - INFO - Data quality report generated: data_quality_report.txt
2026-01-07 10:30:47 - INFO - ETL PIPELINE COMPLETED SUCCESSFULLY
```

---

## ETL Pipeline Details

### Extract Phase

**Function:** `extract_customers()`, `extract_products()`, `extract_sales()`

- Reads CSV files using pandas
- Tracks raw record counts
- Handles file not found errors

### Transform Phase

#### Customer Transformations
```python
# Remove duplicates based on customer_id
df.drop_duplicates(subset=['customer_id'], keep='first')

# Drop records with missing emails (required field)
df.dropna(subset=['email'])

# Standardize phone: +91-9876543210
phone = re.sub(r'\D', '', str(phone))  # Remove non-digits
phone = f"+91-{phone[-10:]}"            # Format

# Standardize dates: YYYY-MM-DD
datetime.strptime(date_str, format).strftime('%Y-%m-%d')

# Standardize city names: Title Case
df['city'] = df['city'].str.strip().str.title()
```

#### Product Transformations
```python
# Drop records with missing prices (required)
df.dropna(subset=['price'])

# Fill missing stock with 0
df['stock_quantity'].fillna(0)

# Standardize categories: Title Case
df['category'] = df['category'].str.strip().str.title()
```

#### Sales Transformations
```python
# Remove duplicate transactions
df.drop_duplicates(subset=['transaction_id'], keep='first')

# Drop records with missing customer_id or product_id
df.dropna(subset=['customer_id', 'product_id'])

# Calculate subtotal
df['subtotal'] = df['quantity'] * df['unit_price']
```

### Load Phase

**Key Features:**
- Uses auto-increment primary keys for all tables
- Creates mapping dictionaries (old_id → new_id)
- Groups sales by customer+date to create orders
- Inserts order items referencing new order_id
- Uses transactions with commit/rollback

---

## Data Quality Report

After running the ETL, check `data_quality_report.txt`:

```
======================================================================
FLEXIMART ETL PIPELINE - DATA QUALITY REPORT
======================================================================

CUSTOMERS DATASET
----------------------------------------------------------------------
Records in raw file:              26
Duplicate records removed:        1
Missing values handled:           5
Records loaded successfully:      20
Data quality score:               76.92%

PRODUCTS DATASET
----------------------------------------------------------------------
Records in raw file:              20
Duplicate records removed:        0
Missing values handled:           4
Records loaded successfully:      17
Data quality score:               85.00%

SALES DATASET
----------------------------------------------------------------------
Records in raw file:              40
Duplicate records removed:        1
Missing values handled:           5
Records loaded successfully:      34
Data quality score:               85.00%

OVERALL SUMMARY
----------------------------------------------------------------------
Total records processed:          86
Total records loaded:             71
Overall success rate:             82.56%
```

---

## Business Queries

After loading data, run the business analysis queries:

```bash
mysql -u root -p fleximart < business_queries.sql
```

### Query 1: Customer Purchase History
**Business Question:** Which customers are our most valuable? Show customers with 2+ orders and >₹5,000 spent.

**Output Columns:** customer_name, email, total_orders, total_spent

**Sample Result:**
```
+----------------+---------------------------+--------------+-------------+
| customer_name  | email                     | total_orders | total_spent |
+----------------+---------------------------+--------------+-------------+
| Rahul Sharma   | rahul.sharma@gmail.com    |            3 |   152997.00 |
| Priya Patel    | priya.patel@yahoo.com     |            2 |    52997.00 |
+----------------+---------------------------+--------------+-------------+
```

### Query 2: Product Sales Analysis
**Business Question:** Which product categories generate the most revenue? Show categories with >₹10,000 revenue.

**Output Columns:** category, num_products, total_quantity_sold, total_revenue

**Sample Result:**
```
+-------------+--------------+---------------------+---------------+
| category    | num_products | total_quantity_sold | total_revenue |
+-------------+--------------+---------------------+---------------+
| Electronics |            6 |                  45 |     523950.00 |
| Fashion     |            5 |                  28 |      98760.00 |
+-------------+--------------+---------------------+---------------+
```

### Query 3: Monthly Sales Trend
**Business Question:** What are our monthly sales patterns? Show monthly revenue with cumulative totals for 2024.

**Output Columns:** month_name, total_orders, monthly_revenue, cumulative_revenue

**Sample Result:**
```
+------------+--------------+-----------------+--------------------+
| month_name | total_orders | monthly_revenue | cumulative_revenue |
+------------+--------------+-----------------+--------------------+
| January    |           15 |       324500.00 |          324500.00 |
| February   |           12 |       298210.00 |          622710.00 |
+------------+--------------+-----------------+--------------------+
```

---

## Normalization Analysis

### Third Normal Form (3NF) Compliance

**1st Normal Form (1NF):**
✅ All attributes contain atomic values
✅ No repeating groups
✅ Each record is unique with a primary key

**2nd Normal Form (2NF):**
✅ All non-key attributes fully depend on primary key
✅ No partial dependencies

**3rd Normal Form (3NF):**
✅ No transitive dependencies
✅ Non-key attributes depend only on primary key

**Example:**
- Customer city is in `customers` table, not in `orders`
- Product price is in `products` table, not in `order_items` (historical price stored separately)
- This eliminates redundancy and prevents update anomalies

### Anomaly Prevention

**Update Anomalies:** Customer email change requires updating only 1 row in `customers`, not multiple rows in `orders`

**Insert Anomalies:** Can add products without orders, and customers without purchases

**Delete Anomalies:** Deleting an order doesn't delete customer information

---

## Testing & Validation

### Verify Data Load

```sql
-- Check record counts
SELECT 'customers' AS table_name, COUNT(*) AS count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;
```

**Expected Counts:**
- customers: 20
- products: 17
- orders: ~25-30 (grouped from sales)
- order_items: 34

### Verify Data Integrity

```sql
-- Check for orphaned order_items
SELECT COUNT(*) 
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Should return 0

-- Check for orders without customers
SELECT COUNT(*) 
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- Should return 0
```

---

## Troubleshooting

### Issue 1: Database Connection Failed
**Error:** `mysql.connector.errors.DatabaseError: 2003: Can't connect to MySQL server`

**Solution:**
- Check MySQL service is running: `sudo systemctl status mysql`
- Verify credentials in `db_config`
- Test connection: `mysql -u root -p`

### Issue 2: Foreign Key Constraint Fails
**Error:** `Cannot add or update a child row: a foreign key constraint fails`

**Solution:**
- This shouldn't happen with the ETL pipeline as it handles ID mapping
- If manual inserts fail, ensure referenced records exist first
- Load order: customers → products → orders → order_items

### Issue 3: CSV File Not Found
**Error:** `FileNotFoundError: [Errno 2] No such file or directory`

**Solution:**
- Ensure CSV files are in the correct location
- Check file names match exactly: `customers_raw.csv`, `products_raw.csv`, `sales_raw.csv`
- Run ETL from the correct directory

### Issue 4: Duplicate Email Error
**Error:** `Duplicate entry 'email@example.com' for key 'customers.email'`

**Solution:**
- The ETL should handle this by dropping duplicates first
- If inserting manually, ensure emails are unique
- Check the `transform_customers()` logic

---

## Performance Considerations

### ETL Optimization
- **Batch Inserts:** Uses single `execute()` calls rather than executemany() for better error handling
- **Index Usage:** Primary keys and foreign keys are automatically indexed
- **Transaction Management:** Commits after successful batch, rolls back on error

### Query Optimization
- **JOIN Performance:** Foreign key indexes speed up joins
- **Aggregation:** Uses efficient `GROUP BY` with proper indexing
- **Window Functions:** Uses `SUM() OVER()` for running totals (MySQL 8.0+)

---

## Key Learnings

### Data Quality Challenges
1. **Multiple Date Formats:** Real-world data rarely comes in consistent formats
2. **Missing Critical Data:** Had to make business decisions on what to drop vs fill
3. **ID Mapping:** Maintaining referential integrity during ETL requires careful tracking

### Best Practices Applied
1. **Logging:** Comprehensive logging helps debug issues and audit the process
2. **Error Handling:** Try-catch blocks prevent pipeline crashes
3. **Data Validation:** Verify foreign keys exist before inserting dependent records
4. **Idempotency:** Can re-run ETL safely (though current version doesn't truncate first)

---

## Future Enhancements

### Short-term
- [ ] Add incremental load capability (only new/changed records)
- [ ] Implement data validation rules (e.g., price > 0)
- [ ] Add email notification on ETL completion/failure
- [ ] Create data lineage tracking

### Long-term
- [ ] Migrate to Apache Airflow for scheduling
- [ ] Add data quality dashboard with metrics over time
- [ ] Implement Change Data Capture (CDC) for real-time updates
- [ ] Add machine learning for anomaly detection in data

---

## Documentation

For detailed schema documentation including ER descriptions, functional dependencies, and normalization justification, see:

📄 **[schema_documentation.md](./schema_documentation.md)**

---

## Contact

For questions about this component:

**Email:** singhkhushburajesh@gmail.com  
**Project:** FlexiMart Data Architecture  
**Component:** Part 1 - Database & ETL

---

**Last Updated:** January 2026  
**Status:** ✅ Complete and Tested