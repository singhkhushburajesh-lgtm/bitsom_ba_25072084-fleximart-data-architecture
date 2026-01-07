# FlexiMart Data Warehouse - Star Schema Design

## Section 1: Schema Overview

### FACT TABLE: fact_sales

**Grain:** One row per product per order line item

**Business Process:** Sales transactions captured at the individual product level within each order

**Measures (Numeric Facts):**
- `quantity_sold`: Number of units of the product sold in this transaction
- `unit_price`: Price per unit at the time of sale (captures historical pricing)
- `discount_amount`: Total discount applied to this line item
- `total_amount`: Final revenue for this line item (quantity × unit_price - discount)

**Foreign Keys:**
- `date_key` → dim_date (When did the sale occur?)
- `product_key` → dim_product (What was sold?)
- `customer_key` → dim_customer (Who bought it?)

**Primary Key:**
- `sale_key`: Surrogate key for each fact record

---

### DIMENSION TABLE: dim_date

**Purpose:** Time dimension for temporal analysis of sales patterns

**Type:** Conformed dimension (can be shared across multiple fact tables)

**Attributes:**
- `date_key` (PK): Surrogate key in YYYYMMDD format (e.g., 20240115 for Jan 15, 2024)
- `full_date`: Actual calendar date
- `day_of_week`: Text name (Monday, Tuesday, etc.)
- `day_of_month`: Numeric day (1-31)
- `month`: Numeric month (1-12)
- `month_name`: Text month (January, February, etc.)
- `quarter`: Quarter designation (Q1, Q2, Q3, Q4)
- `year`: Four-digit year (2023, 2024, etc.)
- `is_weekend`: Boolean flag for Saturday/Sunday

**Why These Attributes?**
The date dimension is pre-calculated to avoid expensive date functions in queries. Having both numeric and text versions of time periods makes reporting flexible - we can sort by numeric values but display friendly text names.

---

### DIMENSION TABLE: dim_product

**Purpose:** Product master data for analyzing what's being sold

**Type:** Type 1 Slowly Changing Dimension (updates overwrite old values)

**Attributes:**
- `product_key` (PK): Surrogate key (auto-incrementing integer)
- `product_id`: Natural/business key from source system (e.g., "P001")
- `product_name`: Full product name
- `category`: High-level grouping (Electronics, Fashion, Groceries)
- `subcategory`: More specific classification (Smartphones, Laptops, etc.)
- `unit_price`: Current selling price (for reference)

**Design Note:**
We keep the natural product_id for traceability back to the source system, but use product_key for joins. The unit_price here is current price, while fact_sales.unit_price captures historical price at time of sale.

---

### DIMENSION TABLE: dim_customer

**Purpose:** Customer demographic and geographic information

**Type:** Type 1 SCD (current state only)

**Attributes:**
- `customer_key` (PK): Surrogate key (auto-incrementing integer)
- `customer_id`: Natural key from source system (e.g., "C001")
- `customer_name`: Full customer name
- `city`: Customer's city
- `state`: Customer's state/province
- `customer_segment`: Business classification (Premium, Regular, New)

**Segmentation Logic:**
The customer_segment is derived based on business rules - perhaps total lifetime value, purchase frequency, or registration tier. This makes it easy to analyze sales by customer type without complex calculations.

---

## Section 2: Design Decisions (150 words)

I chose **transaction line-item level granularity** because it gives us maximum flexibility. We can always roll up to order level or customer level, but we can't drill down if we start too high. This grain lets us analyze individual product performance within orders, which is crucial for understanding product mix and cross-selling patterns.

**Surrogate keys** are used instead of natural keys for several good reasons. First, natural keys can change (a product ID might get renumbered), but surrogate keys are stable. Second, integer surrogate keys are smaller and faster for joins compared to varchar natural keys. Third, they insulate the warehouse from source system changes - if the CRM changes customer ID formats, we don't have to rebuild our entire warehouse.

This design supports **drill-down and roll-up** through the date hierarchy. We can start with yearly totals, drill down to quarters, then months, then individual days. Similarly, we can roll up from product to subcategory to category for different levels of analysis.

---

## Section 3: Sample Data Flow

### Source Transaction Example

**From OLTP Database (fleximart):**
```
Order ID: ORD-101
Customer: Rahul Sharma (C001)
Order Date: 2024-01-15
Order Items:
  - Product: Samsung Galaxy S21 (P001)
  - Quantity: 2
  - Unit Price: ₹45,999
  - Discount: ₹1,000
```

---

### Transformation to Data Warehouse

**Step 1: Lookup/Create Dimension Keys**

Query dim_date for 2024-01-15:
- If exists: Get date_key = 20240115
- If not: Insert new date record with all attributes

Query dim_product for P001:
- If exists: Get product_key = 5
- If not: Insert product with details, get new product_key

Query dim_customer for C001:
- If exists: Get customer_key = 12
- If not: Insert customer with details, get new customer_key

**Step 2: Load Dimension Tables (if new records)**

```sql
-- dim_date record
{
  date_key: 20240115,
  full_date: '2024-01-15',
  day_of_week: 'Monday',
  day_of_month: 15,
  month: 1,
  month_name: 'January',
  quarter: 'Q1',
  year: 2024,
  is_weekend: false
}

-- dim_product record
{
  product_key: 5,
  product_id: 'P001',
  product_name: 'Samsung Galaxy S21',
  category: 'Electronics',
  subcategory: 'Smartphones',
  unit_price: 45999.00
}

-- dim_customer record
{
  customer_key: 12,
  customer_id: 'C001',
  customer_name: 'Rahul Sharma',
  city: 'Bangalore',
  state: 'Karnataka',
  customer_segment: 'Regular'
}
```

**Step 3: Load Fact Table**

```sql
-- fact_sales record
{
  sale_key: 1,
  date_key: 20240115,
  product_key: 5,
  customer_key: 12,
  quantity_sold: 2,
  unit_price: 45999.00,
  discount_amount: 1000.00,
  total_amount: 90998.00  -- (2 × 45999) - 1000
}
```

---

### Data Flow Summary

**Original OLTP:** Normalized tables with order header, order items, products, customers

**ETL Process:** 
1. Extract transactions from source
2. Transform: Lookup dimension keys, calculate measures
3. Load: Insert/update dimensions first, then fact records

**Result in Data Warehouse:** Denormalized star schema optimized for fast analytical queries. The fact table is kept lean with just numbers and foreign keys, while dimensions contain all descriptive attributes.

**Query Benefit:** To get "total sales by customer city", we just join fact_sales → dim_customer on customer_key and group by city. No complex joins through multiple normalized tables!