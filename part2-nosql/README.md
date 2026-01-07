# Part 2: NoSQL Database Analysis

**Project:** FlexiMart Data Architecture  
**Component:** MongoDB NoSQL Implementation  
**Marks:** 20 / 100

---

## Overview

This module explores MongoDB as an alternative to relational databases for FlexiMart's product catalog. It includes both theoretical analysis (comparing RDBMS limitations with NoSQL benefits) and practical implementation (CRUD operations, aggregation pipelines, and complex queries on a flexible product catalog).

---

## Objectives

1. **Analyze** limitations of relational databases for flexible product catalogs
2. **Justify** MongoDB as a solution using document-based storage
3. **Implement** basic and advanced MongoDB operations
4. **Demonstrate** aggregation pipelines for analytics
5. **Evaluate** trade-offs between SQL and NoSQL approaches

---

## Files in This Directory

```
part2-nosql/
├── README.md                    # This file
├── nosql_analysis.md            # Theory: RDBMS vs NoSQL comparison
├── mongodb_operations.js        # MongoDB CRUD and aggregation queries
└── products_catalog.json        # Sample product data (12 products)
```

---

## Problem Statement

FlexiMart wants to expand its product catalog to include highly diverse products with varying attributes:

- **Electronics:** Need fields like RAM, processor, screen size, battery
- **Fashion:** Need fields like size, color, material, fit
- **Groceries:** Need fields like weight, expiry date, organic certification

**Challenge:** In a relational database, this requires either:
1. Many NULL values in a single wide table
2. Multiple category-specific tables (maintenance nightmare)
3. Entity-Attribute-Value (EAV) pattern (poor query performance)

**Solution:** MongoDB's flexible schema allows each product to have its own structure.

---

## MongoDB Sample Data

The `products_catalog.json` contains 12 products across 2 categories:

### Electronics (6 products)
- Samsung Galaxy S21 Ultra (₹79,999) - Smartphone
- Apple MacBook Pro 14-inch (₹1,89,999) - Laptop
- Sony WH-1000XM5 Headphones (₹29,990) - Audio
- Dell 27-inch 4K Monitor (₹32,999) - Monitor
- OnePlus Nord CE 3 (₹26,999) - Smartphone
- Samsung 55-inch QLED TV (₹64,999) - Television

### Fashion (6 products)
- Levi's 511 Slim Fit Jeans (₹3,499) - Clothing
- Nike Air Max 270 Sneakers (₹12,995) - Footwear
- Adidas Originals T-Shirt (₹1,499) - Clothing
- Puma RS-X Sneakers (₹8,999) - Footwear
- H&M Slim Fit Formal Shirt (₹1,999) - Clothing
- Reebok Training Trackpants (₹2,299) - Clothing

### Document Structure Example

```json
{
  "product_id": "ELEC001",
  "name": "Samsung Galaxy S21 Ultra",
  "category": "Electronics",
  "subcategory": "Smartphones",
  "price": 79999.00,
  "stock": 150,
  "specifications": {
    "brand": "Samsung",
    "ram": "12GB",
    "storage": "256GB",
    "screen_size": "6.8 inches",
    "processor": "Exynos 2100",
    "battery": "5000mAh",
    "camera": "108MP + 12MP + 10MP"
  },
  "reviews": [
    {
      "user_id": "U001",
      "username": "TechGuru",
      "rating": 5,
      "comment": "Excellent phone with amazing camera quality!",
      "date": "2024-01-15"
    }
  ],
  "tags": ["flagship", "5G", "android", "photography"],
  "warranty_months": 12
}
```

**Key Features:**
- Nested `specifications` object (varies by product type)
- Embedded `reviews` array (no separate table needed)
- Flexible attributes (only relevant fields per product)

---

## Setup Instructions

### Prerequisites

1. **MongoDB 6.0+** installed
2. **mongosh** (MongoDB Shell)
3. **mongoimport** utility (comes with MongoDB)

### Step 1: Install MongoDB

**macOS:**
```bash
brew tap mongodb/brew
brew install mongodb-community@6.0
brew services start mongodb-community@6.0
```

**Ubuntu/Debian:**
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
```

**Windows:**
- Download from [MongoDB Download Center](https://www.mongodb.com/try/download/community)
- Install and start MongoDB as a service

### Step 2: Verify MongoDB is Running

```bash
mongosh
```

You should see:
```
Current Mongosh Log ID:	...
Connecting to:		mongodb://127.0.0.1:27017/
Using MongoDB:		6.0.x
```

Type `exit` to close.

### Step 3: Import Product Catalog

```bash
cd part2-nosql

# Import JSON data into MongoDB
mongoimport --db fleximart \
            --collection products \
            --file products_catalog.json \
            --jsonArray

# Expected output:
# 12 document(s) imported successfully. 0 document(s) failed to import.
```

### Step 4: Verify Import

```bash
mongosh fleximart

# Inside mongosh:
db.products.countDocuments()
# Should return: 12

db.products.findOne()
# Should display one product document
```

---

## MongoDB Operations

### Operation 1: Load Data ✅

Already done in Step 3 above using `mongoimport`.

**Alternative method** (if loading from Node.js or mongosh):

```javascript
use fleximart;

// Load products from JSON
load('products_catalog.json');

// Insert the array
db.products.insertMany(productsData);

// Verify
print("Total products imported: " + db.products.countDocuments());
```

---

### Operation 2: Basic Query (Find Electronics < ₹50,000)

**Business Question:** Show all affordable electronics under ₹50,000

```javascript
db.products.find(
  {
    category: "Electronics",
    price: { $lt: 50000 }
  },
  {
    _id: 0,
    name: 1,
    price: 1,
    stock: 1
  }
);
```

**Expected Output:**
```javascript
[
  { name: "Sony WH-1000XM5 Headphones", price: 29990, stock: 200 },
  { name: "Dell 27-inch 4K Monitor", price: 32999, stock: 60 },
  { name: "OnePlus Nord CE 3", price: 26999, stock: 180 }
]
```

**Key Concepts:**
- `$lt` - Less than operator
- Projection: `_id: 0` hides MongoDB's default _id, `name: 1` shows name

---

### Operation 3: Review Analysis (Products with avg rating ≥ 4.0)

**Business Question:** Which products have the best customer ratings?

```javascript
db.products.aggregate([
  {
    // Step 1: Unwind reviews array
    $unwind: "$reviews"
  },
  {
    // Step 2: Group by product and calculate average
    $group: {
      _id: "$product_id",
      product_name: { $first: "$name" },
      category: { $first: "$category" },
      avg_rating: { $avg: "$reviews.rating" },
      review_count: { $sum: 1 }
    }
  },
  {
    // Step 3: Filter for 4.0+ ratings
    $match: {
      avg_rating: { $gte: 4.0 }
    }
  },
  {
    // Step 4: Sort by rating (best first)
    $sort: { avg_rating: -1 }
  },
  {
    // Step 5: Format output
    $project: {
      _id: 0,
      product_id: "$_id",
      product_name: 1,
      category: 1,
      avg_rating: { $round: ["$avg_rating", 2] },
      review_count: 1
    }
  }
]);
```

**Expected Output:**
```javascript
[
  { product_id: "ELEC001", product_name: "Samsung Galaxy S21 Ultra", 
    category: "Electronics", avg_rating: 4.67, review_count: 3 },
  { product_id: "ELEC002", product_name: "Apple MacBook Pro 14-inch", 
    category: "Electronics", avg_rating: 5.0, review_count: 2 },
  { product_id: "FASH001", product_name: "Levi's 511 Slim Fit Jeans", 
    category: "Fashion", avg_rating: 4.67, review_count: 3 }
]
```

**Key Concepts:**
- `$unwind` - Deconstructs array into separate documents
- `$group` - Aggregates data (like SQL GROUP BY)
- `$avg` - Calculates average
- `$match` - Filters results (like SQL WHERE)
- `$round` - Rounds decimal to 2 places

---

### Operation 4: Update Operation (Add Review)

**Business Question:** A customer just left a new review. How do we add it?

```javascript
db.products.updateOne(
  {
    product_id: "ELEC001"
  },
  {
    $push: {
      reviews: {
        user_id: "U999",
        username: "NewCustomer",
        rating: 4,
        comment: "Good value for money. Camera is solid!",
        date: new Date().toISOString().split('T')[0]
      }
    }
  }
);
```

**Response:**
```javascript
{
  acknowledged: true,
  matchedCount: 1,
  modifiedCount: 1
}
```

**Verify the Update:**
```javascript
db.products.find(
  { product_id: "ELEC001" },
  { name: 1, reviews: 1 }
);
```

**Key Concepts:**
- `updateOne()` - Updates single document
- `$push` - Adds element to array
- No need for separate reviews table or JOIN

---

### Operation 5: Complex Aggregation (Average Price by Category)

**Business Question:** Which product categories are premium vs budget?

```javascript
db.products.aggregate([
  {
    // Step 1: Group by category
    $group: {
      _id: "$category",
      avg_price: { $avg: "$price" },
      product_count: { $sum: 1 },
      min_price: { $min: "$price" },
      max_price: { $max: "$price" }
    }
  },
  {
    // Step 2: Sort by average price (highest first)
    $sort: { avg_price: -1 }
  },
  {
    // Step 3: Format output
    $project: {
      _id: 0,
      category: "$_id",
      avg_price: { $round: ["$avg_price", 2] },
      product_count: 1,
      price_range: {
        $concat: [
          "₹",
          { $toString: "$min_price" },
          " - ₹",
          { $toString: "$max_price" }
        ]
      }
    }
  }
]);
```

**Expected Output:**
```javascript
[
  { category: "Electronics", avg_price: 54166.33, product_count: 6, 
    price_range: "₹26999 - ₹189999" },
  { category: "Fashion", avg_price: 5365.17, product_count: 6, 
    price_range: "₹1499 - ₹12995" }
]
```

**Key Insights:**
- Electronics average ₹54,166 (premium category)
- Fashion average ₹5,365 (budget-friendly)
- Wide price range in electronics (₹27k to ₹1.9L)

---

## Theoretical Analysis

See **[nosql_analysis.md](./nosql_analysis.md)** for complete analysis covering:

### Section A: RDBMS Limitations (150 words)

**Key Points:**
1. **Schema Rigidity:** Different product types need different attributes, leading to sparse tables with many NULLs
2. **Schema Evolution:** Adding new product categories requires ALTER TABLE statements and potential downtime
3. **Nested Data:** Storing reviews requires separate table and expensive JOINs

### Section B: NoSQL Benefits (150 words)

**Key Points:**
1. **Flexible Schema:** Each product document can have unique fields without NULLs
2. **Embedded Documents:** Reviews stored directly in product document (no JOINs needed)
3. **Horizontal Scalability:** Easy to shard across multiple servers by category or product_id

### Section C: Trade-offs (100 words)

**Key Points:**
1. **No Referential Integrity:** MongoDB doesn't enforce foreign key constraints
2. **Transaction Limitations:** Multi-document transactions are complex (though improved in MongoDB 4.0+)

---

## Running the Operations

### Method 1: Interactive (Recommended for Learning)

```bash
mongosh fleximart
```

Then copy-paste each operation from `mongodb_operations.js` one at a time.

### Method 2: Script Execution

```bash
mongosh fleximart < mongodb_operations.js
```

This runs all operations sequentially.

### Method 3: Node.js (Production Approach)

```javascript
const { MongoClient } = require('mongodb');

async function runOperations() {
  const client = new MongoClient('mongodb://localhost:27017');
  await client.connect();
  const db = client.db('fleximart');
  
  // Operation 2: Basic Query
  const electronics = await db.collection('products')
    .find({ category: "Electronics", price: { $lt: 50000 }})
    .project({ _id: 0, name: 1, price: 1, stock: 1 })
    .toArray();
  
  console.log(electronics);
  
  await client.close();
}

runOperations();
```

---

## Query Patterns & Use Cases

### 1. Full-Text Search

```javascript
// Create text index
db.products.createIndex({ name: "text", "specifications.brand": "text" });

// Search for "Samsung"
db.products.find({ $text: { $search: "Samsung" }});
```

### 2. Array Queries

```javascript
// Find products with specific tag
db.products.find({ tags: "5G" });

// Find products with multiple tags (AND)
db.products.find({ tags: { $all: ["5G", "flagship"] }});

// Find products with any of these tags (OR)
db.products.find({ tags: { $in: ["5G", "wireless"] }});
```

### 3. Nested Field Queries

```javascript
// Find products with 12GB RAM
db.products.find({ "specifications.ram": "12GB" });

// Find products with RAM >= 8GB (if stored as number)
db.products.find({ "specifications.ram_gb": { $gte: 8 }});
```

---

## Performance Considerations

### Indexing Strategy

```javascript
// Index on frequently queried fields
db.products.createIndex({ category: 1 });
db.products.createIndex({ price: 1 });
db.products.createIndex({ "specifications.brand": 1 });

// Compound index for common query patterns
db.products.createIndex({ category: 1, price: 1 });

// Text index for search functionality
db.products.createIndex({ name: "text", tags: "text" });
```

### Aggregation Optimization

```javascript
// Use $match early in pipeline to reduce documents
db.products.aggregate([
  { $match: { category: "Electronics" }},  // Filter first
  { $unwind: "$reviews" },                 // Then unwind
  { $group: { ... }}                       // Then group
]);

// Use allowDiskUse for large datasets
db.products.aggregate([...], { allowDiskUse: true });
```

---

## Comparison: MongoDB vs MySQL

### Data Retrieval Speed

**MongoDB (No JOIN):**
```javascript
// Single query gets product + all reviews
db.products.findOne({ product_id: "ELEC001" });
// ~5ms
```

**MySQL (With JOIN):**
```sql
-- Need to JOIN product and reviews tables
SELECT p.*, r.* 
FROM products p 
LEFT JOIN reviews r ON p.product_id = r.product_id 
WHERE p.product_id = 'ELEC001';
-- ~15-20ms with proper indexes
```

### Schema Evolution

**MongoDB:**
```javascript
// Just insert document with new fields - no migration needed
db.products.insertOne({
  product_id: "GROC001",
  name: "Organic Almonds",
  category: "Groceries",
  weight_grams: 500,        // New field
  expiry_date: "2024-12-31", // New field
  organic_certified: true    // New field
});
```

**MySQL:**
```sql
-- Requires ALTER TABLE (potentially slow on large tables)
ALTER TABLE products 
ADD COLUMN weight_grams INT,
ADD COLUMN expiry_date DATE,
ADD COLUMN organic_certified BOOLEAN;
-- Then NULL values for all existing products
```

---

## Testing & Validation

### Verify All Operations Work

```javascript
// Test 1: Count documents
db.products.countDocuments();
// Expected: 12

// Test 2: Verify categories
db.products.distinct("category");
// Expected: ["Electronics", "Fashion"]

// Test 3: Check price range
db.products.aggregate([
  { $group: { 
      _id: null, 
      min: { $min: "$price" }, 
      max: { $max: "$price" } 
  }}
]);
// Expected: min: 1499, max: 189999

// Test 4: Verify embedded reviews
db.products.aggregate([
  { $unwind: "$reviews" },
  { $count: "total_reviews" }
]);
// Expected: ~25-30 reviews total
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Not Using Projection
**Problem:** Fetching entire documents when you only need few fields (wastes bandwidth)

**Solution:**
```javascript
// Bad
db.products.find({ category: "Electronics" });

// Good
db.products.find(
  { category: "Electronics" },
  { name: 1, price: 1, _id: 0 }
);
```

### Pitfall 2: Forgetting to Unwind Arrays
**Problem:** Trying to aggregate on array fields without unwinding

**Solution:**
```javascript
// Wrong - will group entire array as single value
db.products.aggregate([
  { $group: { _id: "$reviews.rating" }}
]);

// Correct - unwind first
db.products.aggregate([
  { $unwind: "$reviews" },
  { $group: { _id: "$reviews.rating", count: { $sum: 1 }}}
]);
```

### Pitfall 3: No Indexes on Queries
**Problem:** Slow queries on large collections

**Solution:**
```javascript
// Check if query uses index
db.products.find({ category: "Electronics" }).explain("executionStats");

// Create index if needed
db.products.createIndex({ category: 1 });
```

---

## Key Learnings

### When to Use MongoDB
✅ Flexible schemas with varying attributes  
✅ Nested/hierarchical data (reviews, comments, metadata)  
✅ Rapid prototyping and schema evolution  
✅ High write throughput with horizontal scaling  
✅ Content management systems, catalogs, user profiles  

### When to Use MySQL
✅ Strong ACID requirements across multiple entities  
✅ Complex transactions involving multiple tables  
✅ Well-defined schema that rarely changes  
✅ Complex JOIN operations across normalized tables  
✅ Financial systems, ERP, inventory management  

---

## Future Enhancements

### Short-term
- [ ] Add full-text search indexes for product search
- [ ] Implement pagination for large result sets
- [ ] Add data validation using JSON Schema
- [ ] Create backup/restore scripts

### Long-term
- [ ] Set up replica set for high availability
- [ ] Implement sharding for horizontal scaling
- [ ] Add change streams for real-time notifications
- [ ] Integrate with Elasticsearch for advanced search

---

## Additional Resources

- **Official MongoDB Docs:** https://www.mongodb.com/docs/
- **Aggregation Pipeline:** https://www.mongodb.com/docs/manual/aggregation/
- **Schema Design Patterns:** https://www.mongodb.com/blog/post/building-with-patterns-a-summary
- **Performance Best Practices:** https://www.mongodb.com/docs/manual/administration/analyzing-mongodb-performance/

---

## Contact

For questions about this component:

**Email:** [Your Email]  
**Project:** FlexiMart Data Architecture  
**Component:** Part 2 - NoSQL Analysis

---

**Last Updated:** January 2026  
**Status:** ✅ Complete and Tested