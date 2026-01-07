# FlexiMart Database Schema Documentation

## 1. Entity-Relationship Description

### ENTITY: customers
**Purpose:** Stores customer information for all registered users of FlexiMart

**Attributes:**
- `customer_id` (INT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for each customer
- `first_name` (VARCHAR(50), NOT NULL): Customer's first name
- `last_name` (VARCHAR(50), NOT NULL): Customer's last name
- `email` (VARCHAR(100), UNIQUE, NOT NULL): Customer's email address for communication and login
- `phone` (VARCHAR(20)): Customer's contact phone number in standardized format (+91-XXXXXXXXXX)
- `city` (VARCHAR(50)): City where customer resides
- `registration_date` (DATE): Date when customer registered with FlexiMart

**Relationships:**
- One customer can place MANY orders (1:M relationship with orders table)
- Referenced by: orders.customer_id (Foreign Key)

---

### ENTITY: products
**Purpose:** Stores product catalog information including inventory details

**Attributes:**
- `product_id` (INT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for each product
- `product_name` (VARCHAR(100), NOT NULL): Name/description of the product
- `category` (VARCHAR(50), NOT NULL): Product category (Electronics, Fashion, Groceries)
- `price` (DECIMAL(10,2), NOT NULL): Current selling price of the product in rupees
- `stock_quantity` (INT, DEFAULT 0): Available quantity in inventory

**Relationships:**
- One product can appear in MANY order items (1:M relationship with order_items table)
- Referenced by: order_items.product_id (Foreign Key)

---

### ENTITY: orders
**Purpose:** Stores order header information tracking customer purchases

**Attributes:**
- `order_id` (INT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for each order
- `customer_id` (INT, NOT NULL, FOREIGN KEY): References the customer who placed the order
- `order_date` (DATE, NOT NULL): Date when the order was placed
- `total_amount` (DECIMAL(10,2), NOT NULL): Total value of the entire order
- `status` (VARCHAR(20), DEFAULT 'Pending'): Current status of order (Pending, Completed, Cancelled)

**Relationships:**
- MANY orders belong to ONE customer (M:1 relationship with customers table)
- One order can have MANY order items (1:M relationship with order_items table)
- References: customers.customer_id (Foreign Key)
- Referenced by: order_items.order_id (Foreign Key)

---

### ENTITY: order_items
**Purpose:** Stores line-item details for products included in each order

**Attributes:**
- `order_item_id` (INT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for each order line item
- `order_id` (INT, NOT NULL, FOREIGN KEY): References the parent order
- `product_id` (INT, NOT NULL, FOREIGN KEY): References the product being purchased
- `quantity` (INT, NOT NULL): Number of units of this product ordered
- `unit_price` (DECIMAL(10,2), NOT NULL): Price per unit at the time of purchase
- `subtotal` (DECIMAL(10,2), NOT NULL): Calculated total for this line item (quantity × unit_price)

**Relationships:**
- MANY order items belong to ONE order (M:1 relationship with orders table)
- MANY order items reference ONE product (M:1 relationship with products table)
- References: orders.order_id (Foreign Key)
- References: products.product_id (Foreign Key)

---

## 2. Normalization Explanation

### Third Normal Form (3NF) Justification

The FlexiMart database schema is designed to comply with Third Normal Form (3NF), which ensures data integrity, eliminates redundancy, and prevents anomalies. To be in 3NF, a database must satisfy three conditions: First Normal Form (1NF), Second Normal Form (2NF), and Third Normal Form (3NF) requirements.

**First Normal Form (1NF) Compliance:**
All tables contain only atomic values with no repeating groups. Each column contains a single value, and each record is unique, identified by a primary key. For example, customer names are split into first_name and last_name rather than a single combined field, and there are no multi-valued attributes like storing multiple phone numbers in one field.

**Second Normal Form (2NF) Compliance:**
All non-key attributes are fully functionally dependent on the entire primary key. In the order_items table, attributes like quantity, unit_price, and subtotal depend on the complete composite context (order_item_id), not just part of a key. This eliminates partial dependencies.

**Third Normal Form (3NF) Compliance:**
There are no transitive dependencies—non-key attributes depend only on the primary key, not on other non-key attributes. For instance, the total_amount in the orders table is derived from order_items but stored for performance; however, it doesn't create transitive dependency as it's a calculated aggregate. Customer information like city is stored in the customers table, not redundantly in orders, preventing transitive dependencies.

### Functional Dependencies

**customers table:**
- customer_id → first_name, last_name, email, phone, city, registration_date
- email → customer_id (email is unique)

**products table:**
- product_id → product_name, category, price, stock_quantity

**orders table:**
- order_id → customer_id, order_date, total_amount, status
- customer_id ↛ order_id (one customer can have many orders)

**order_items table:**
- order_item_id → order_id, product_id, quantity, unit_price, subtotal
- (order_id, product_id) → order_item_id (composite candidate key scenario)

### Anomaly Prevention

**Update Anomalies Prevented:**
Customer information is stored only in the customers table. If a customer changes their email or phone number, we update just one record in the customers table, not multiple order records. Similarly, product prices are maintained in the products table, while order_items stores the historical unit_price at purchase time, preserving transaction history.

**Insert Anomalies Prevented:**
We can add new products to the catalog without requiring an order to exist. Similarly, customers can register without placing orders immediately. The separation of entities allows independent data entry without enforcing unnecessary relationships.

**Delete Anomalies Prevented:**
Deleting an order doesn't remove customer information, as it's stored separately. If we remove a product from the catalog, historical order_items still retain the product_id and unit_price, preserving transaction records. The foreign key constraints with proper cascading rules ensure referential integrity while preventing orphaned records.

---

## 3. Sample Data Representation

### Sample Data: customers Table

| customer_id | first_name | last_name | email | phone | city | registration_date |
|-------------|------------|-----------|-------|-------|------|-------------------|
| 1 | Rahul | Sharma | rahul.sharma@gmail.com | +91-9876543210 | Bangalore | 2023-01-15 |
| 2 | Priya | Patel | priya.patel@yahoo.com | +91-9988776655 | Mumbai | 2023-02-20 |
| 3 | Vikram | Singh | vikram.singh@outlook.com | +91-9988112233 | Chennai | 2023-05-22 |

---

### Sample Data: products Table

| product_id | product_name | category | price | stock_quantity |
|------------|--------------|----------|-------|----------------|
| 1 | Samsung Galaxy S21 | Electronics | 45999.00 | 150 |
| 2 | Nike Running Shoes | Fashion | 3499.00 | 80 |
| 3 | HP Laptop | Electronics | 52999.00 | 60 |

---

### Sample Data: orders Table

| order_id | customer_id | order_date | total_amount | status |
|----------|-------------|------------|--------------|--------|
| 1 | 1 | 2024-01-15 | 45999.00 | Completed |
| 2 | 2 | 2024-01-16 | 5998.00 | Completed |
| 3 | 3 | 2024-01-20 | 1950.00 | Completed |

---

### Sample Data: order_items Table

| order_item_id | order_id | product_id | quantity | unit_price | subtotal |
|---------------|----------|------------|----------|------------|----------|
| 1 | 1 | 1 | 1 | 45999.00 | 45999.00 |
| 2 | 2 | 2 | 2 | 2999.00 | 5998.00 |
| 3 | 3 | 3 | 3 | 650.00 | 1950.00 |

---

## 4. Relationship Diagram (Text Format)

```
customers (1) ----< orders (M)
    |
    | 1:M relationship
    |
    customer_id (PK) references customer_id (FK) in orders


orders (1) ----< order_items (M)
    |
    | 1:M relationship
    |
    order_id (PK) references order_id (FK) in order_items


products (1) ----< order_items (M)
    |
    | 1:M relationship
    |
    product_id (PK) references product_id (FK) in order_items
```

**Cardinality Summary:**
- One customer → Many orders (1:M)
- One order → Many order items (1:M)
- One product → Many order items (1:M)
- Many orders → One customer (M:1)
- Many order items → One order (M:1)
- Many order items → One product (M:1)

---

## 5. Key Design Decisions

### 1. Separation of Orders and Order Items
The design uses two tables (orders and order_items) instead of a single table to follow normalization principles. This prevents data redundancy when an order contains multiple products and allows atomic operations on order headers versus line items.

### 2. Historical Price Preservation
The order_items table stores unit_price at the time of purchase rather than referencing the current product price. This design decision preserves transaction history accurately, even if product prices change later.

### 3. Auto-Increment Primary Keys
All tables use surrogate keys (auto-increment integers) rather than natural keys. This provides better performance, simplifies foreign key relationships, and allows natural attributes to change without affecting referential integrity.

### 4. Status Tracking
The orders table includes a status field with a default value of 'Pending', enabling order lifecycle management (Pending → Completed/Cancelled) and supporting business reporting on order fulfillment.

### 5. Data Integrity Constraints
- NOT NULL constraints on critical fields ensure data completeness
- UNIQUE constraint on customer email prevents duplicate accounts
- Foreign key constraints maintain referential integrity across tables
- DEFAULT values provide sensible fallbacks (e.g., stock_quantity = 0)

---

## 6. Schema Advantages

1. **Scalability:** The normalized structure allows the database to grow efficiently without redundancy
2. **Data Integrity:** Foreign key constraints and normalization prevent inconsistencies
3. **Flexibility:** Easy to add new features like product reviews, shipping addresses, or payment methods
4. **Query Performance:** Proper indexing on primary and foreign keys enables fast joins
5. **Maintenance:** Changes to customer or product data require updates in only one location
6. **Historical Accuracy:** Transaction records preserve pricing and relationships at the time of purchase

---

## 7. Potential Extensions

Future schema enhancements could include:
- **categories table:** Separate table for product categories with hierarchical structure
- **addresses table:** Multiple shipping/billing addresses per customer
- **payments table:** Track payment methods and transaction details
- **reviews table:** Customer product reviews and ratings
- **inventory_logs table:** Track stock movements and adjustments
- **promotions table:** Discount codes and promotional campaigns

---

*End of Schema Documentation*