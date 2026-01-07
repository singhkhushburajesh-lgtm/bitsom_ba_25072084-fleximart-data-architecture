# FlexiMart Data Architecture Project

**Student Name:** Khushbu Singh  
**Student ID:** bitsom_ba_25072084  
**Email:** singhkhushburajesh@gmail.com  
**Date:** January 2026

## Project Overview

This project demonstrates a complete data architecture solution for FlexiMart, an e-commerce company. The implementation includes building an ETL pipeline to clean and load transactional data into a relational database, evaluating NoSQL databases for flexible product catalogs, and designing a data warehouse with star schema for analytical reporting. The project showcases skills in database design, data quality management, SQL optimization, and dimensional modeling.

## Repository Structure

```
fleximart-data-architecture/
├── data/
│   ├── customers_raw.csv
│   ├── products_raw.csv
│   └── sales_raw.csv
├── part1-database-etl/
│   ├── etl_pipeline.py
│   ├── schema_documentation.md
│   ├── business_queries.sql
│   ├── data_quality_report.txt
│   └── requirements.txt
├── part2-nosql/
│   ├── nosql_analysis.md
│   ├── mongodb_operations.js
│   └── products_catalog.json
├── part3-datawarehouse/
│   ├── star_schema_design.md
│   ├── warehouse_schema.sql
│   ├── warehouse_data.sql
│   └── analytics_queries.sql
├── .gitignore
└── README.md
```

## Technologies Used

- **Python 3.10+** - ETL pipeline implementation
- **pandas 2.0+** - Data transformation and cleaning
- **mysql-connector-python** - Database connectivity
- **MySQL 8.0** - Relational database (OLTP and Data Warehouse)
- **MongoDB 6.0+** - NoSQL document database
- **SQL** - Query language for analytics

## Setup Instructions

### Prerequisites

Ensure you have the following installed:
- Python 3.10 or higher
- MySQL 8.0 or higher
- MongoDB 6.0 or higher
- Git for version control

### Database Setup

**Step 1: Create MySQL Databases**

```bash
# Open MySQL command line
mysql -u root -p

# Create databases
CREATE DATABASE fleximart;
CREATE DATABASE fleximart_dw;
exit;
```

**Step 2: Install Python Dependencies**

```bash
cd part1-database-etl
pip install -r requirements.txt
```

### Part 1: Database & ETL Pipeline

**Run the ETL Pipeline:**

```bash
# Navigate to part1 directory
cd part1-database-etl

# Execute ETL script (will create tables and load cleaned data)
python etl_pipeline.py
```

This will:
- Read the three raw CSV files from the `data/` directory
- Clean and transform the data (handle duplicates, missing values, format standardization)
- Load data into MySQL `fleximart` database
- Generate `data_quality_report.txt`

**Run Business Queries:**

```bash
# Execute analytical queries
mysql -u root -p fleximart < business_queries.sql
```

### Part 2: NoSQL MongoDB

**Setup MongoDB:**

```bash
# Start MongoDB service (Windows)
net start MongoDB

# Import product catalog
cd part2-nosql
mongoimport --db fleximart --collection products --file products_catalog.json --jsonArray

# Run MongoDB operations
mongosh < mongodb_operations.js
```

### Part 3: Data Warehouse

**Create Star Schema:**

```bash
cd part3-datawarehouse

# Step 1: Create warehouse schema
mysql -u root -p fleximart_dw < warehouse_schema.sql

# Step 2: Load dimension and fact data
mysql -u root -p fleximart_dw < warehouse_data.sql

# Step 3: Run analytics queries
mysql -u root -p fleximart_dw < analytics_queries.sql
```

## Key Features

### Part 1: ETL & Relational Database
- Automated data quality checks and cleaning
- Normalization to 3NF to eliminate redundancy
- Complex SQL queries with JOINs, aggregations, and window functions
- Handles 24 customers, 20 products, and 39 sales transactions

### Part 2: NoSQL Analysis
- Flexible schema design for diverse product attributes
- Embedded documents for nested review data
- Aggregation pipelines for complex analytics
- 12 products with detailed specifications and reviews

### Part 3: Data Warehouse
- Star schema with 1 fact table and 3 dimension tables
- 40 sales transactions across 30 dates
- OLAP queries supporting drill-down and roll-up operations
- Customer segmentation and product performance analysis

## Key Learnings

Throughout this project, I gained hands-on experience in designing complete data architectures from scratch. I learned how to balance trade-offs between normalized relational databases for transactional integrity versus denormalized star schemas for analytical performance. Working with both SQL and NoSQL databases deepened my understanding of when to use each approach - relational for structured data with strong consistency needs, and document databases for flexible schemas with nested data. The ETL process taught me the importance of data quality checks and how much effort real-world data cleaning requires before it's analysis-ready.

## Challenges Faced

1. **Handling Inconsistent Date Formats**: The source data had three different date formats (YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY). Solved this by implementing a flexible date parser using pandas that tries multiple formats and standardizes to YYYY-MM-DD.

2. **Missing Foreign Keys in Transactions**: Some sales records had missing customer_id or product_id values. Decided to drop these incomplete records rather than impute them, as fabricating transaction relationships would compromise data integrity.

3. **MongoDB Aggregation Pipeline Complexity**: Calculating average ratings from nested review arrays required unwinding the array, grouping, and re-projecting. Used MongoDB's $unwind and $group stages to properly aggregate nested document data.

4. **Window Functions for Running Totals**: Implementing cumulative revenue calculations required understanding SQL window functions with proper ordering. Provided both window function and subquery solutions for compatibility with different MySQL versions.

## Query Performance Insights

- ETL Pipeline processes ~80 records in under 2 seconds
- Business queries execute in <100ms on indexed tables
- OLAP queries on star schema are 3-5x faster than equivalent queries on normalized OLTP schema
- MongoDB aggregation on 12 products with embedded reviews completes in <50ms

## Future Enhancements

- Implement Type 2 Slowly Changing Dimensions to track product price history
- Add incremental ETL for daily data loads instead of full refresh
- Create data quality dashboards using Python visualization libraries
- Implement MongoDB sharding strategy for scaling to millions of products
- Add data lineage tracking to trace transformations from source to warehouse

## Contact

For any questions or clarifications about this project:
- Email: singhkhushburajesh@gmail.com
- GitHub: https://github.com/singhkhushburajesh-lgtm

---

**License:** This project is for educational purposes as part of database coursework.

**Acknowledgments:** Dataset and Problem statement provided by the Database Systems course instructor.