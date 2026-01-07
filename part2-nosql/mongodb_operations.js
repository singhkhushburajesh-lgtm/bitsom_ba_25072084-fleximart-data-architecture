// ============================================================================
// FlexiMart MongoDB Operations
// Task 2.2: MongoDB Implementation
// ============================================================================

// ============================================================================
// Operation 1: Load Data (1 mark)
// ============================================================================
// Import the products catalog JSON into MongoDB collection
// Run this from terminal/command line:
// mongoimport --db fleximart --collection products --file products_catalog.json --jsonArray

// Alternatively, if loading from within MongoDB shell or Node.js:
/*
use fleximart;

// Load the JSON array
var productsData = [
  // paste the entire products_catalog.json content here
];

// Insert all products at once
db.products.insertMany(productsData);

// Verify the import
print("Total products imported: " + db.products.countDocuments());
*/


// ============================================================================
// Operation 2: Basic Query (2 marks)
// ============================================================================
// Find all electronics products under Rs. 50,000
// Only show name, price, and stock - exclude the _id field

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

// Expected output: Products like headphones, monitors, OnePlus phones etc.
// Should NOT include MacBook Pro or Samsung TV (both over 50k)


// ============================================================================
// Operation 3: Review Analysis (2 marks)
// ============================================================================
// Find products with average rating of 4.0 or higher
// Need to calculate average from the reviews array

db.products.aggregate([
  {
    // First, unwind the reviews array so we can work with individual reviews
    $unwind: "$reviews"
  },
  {
    // Group back by product and calculate average rating
    $group: {
      _id: "$product_id",
      product_name: { $first: "$name" },
      category: { $first: "$category" },
      avg_rating: { $avg: "$reviews.rating" },
      review_count: { $sum: 1 }
    }
  },
  {
    // Filter for products with average rating >= 4.0
    $match: {
      avg_rating: { $gte: 4.0 }
    }
  },
  {
    // Sort by rating descending to see best products first
    $sort: { avg_rating: -1 }
  },
  {
    // Clean up the output format
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

// This should return most products since the sample data has good reviews
// Products with mix of ratings will show their actual average


// ============================================================================
// Operation 4: Update Operation (2 marks)
// ============================================================================
// Add a new review to Samsung Galaxy S21 Ultra (ELEC001)

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
        date: new Date().toISOString().split('T')[0]  // Today's date in YYYY-MM-DD format
      }
    }
  }
);

// Verify the update worked
db.products.find(
  { product_id: "ELEC001" },
  { name: 1, reviews: 1 }
);

// The new review should now appear at the end of the reviews array


// ============================================================================
// Operation 5: Complex Aggregation (3 marks)
// ============================================================================
// Calculate average price per category
// Show category name, average price, and count of products
// Sort by average price (highest first)

db.products.aggregate([
  {
    // Group all products by their category
    $group: {
      _id: "$category",
      avg_price: { $avg: "$price" },
      product_count: { $sum: 1 },
      min_price: { $min: "$price" },
      max_price: { $max: "$price" }
    }
  },
  {
    // Sort by average price descending (most expensive category first)
    $sort: { avg_price: -1 }
  },
  {
    // Format the output nicely
    $project: {
      _id: 0,
      category: "$_id",
      avg_price: { $round: ["$avg_price", 2] },
      product_count: 1,
      price_range: {
        $concat: [
          "Rs. ",
          { $toString: "$min_price" },
          " - Rs. ",
          { $toString: "$max_price" }
        ]
      }
    }
  }
]);

// Expected output:
// Electronics should have higher avg_price (lots of expensive items like MacBook, TV)
// Fashion should have lower avg_price (mostly clothing and shoes)
// This gives business insights into which categories are premium vs budget


// ============================================================================
// BONUS: Additional Useful Queries
// ============================================================================

// Find products low on stock (less than 50 units)
db.products.find(
  { stock: { $lt: 50 } },
  { name: 1, stock: 1, category: 1, _id: 0 }
).sort({ stock: 1 });


// Find all products with "smartphone" tag
db.products.find(
  { tags: "smartphone" },
  { name: 1, price: 1, "specifications.ram": 1, _id: 0 }
);


// Count products by subcategory
db.products.aggregate([
  {
    $group: {
      _id: "$subcategory",
      count: { $sum: 1 }
    }
  },
  { $sort: { count: -1 } }
]);


// ============================================================================
// Notes:
// ============================================================================
// 1. All queries use proper MongoDB operators ($lt, $gte, $avg, etc.)
// 2. Aggregation pipelines are broken down into clear stages
// 3. Projections exclude _id by default for cleaner output
// 4. Date handling uses ISO format for consistency
// 5. Comments explain the business logic, not just the syntax
// ============================================================================