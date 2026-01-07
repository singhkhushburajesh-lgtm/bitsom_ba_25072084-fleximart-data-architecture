# NoSQL Analysis for FlexiMart Product Catalog

## Section A: Limitations of RDBMS (150 words)

The current relational database setup has some real headaches when dealing with diverse products. First off, different products need different attributes - a laptop needs RAM and processor fields, while shoes need size and color. In MySQL, we'd either end up with a massive table full of NULL values (wasteful) or create separate tables for each product type (maintenance nightmare).

Second issue is schema changes. Every time marketing wants to add a new product category, we're looking at ALTER TABLE statements, potential downtime, and careful migration planning. Not exactly agile.

Third, storing customer reviews is messy. We can't directly nest reviews inside product records, so we need a separate reviews table with foreign keys. Fetching a product with all its reviews means JOINs, which get expensive with thousands of reviews. Plus, if each review has different fields (some have photos, some don't), we're back to the NULL problem again.

## Section B: NoSQL Benefits (150 words)

MongoDB handles these issues pretty elegantly. The flexible schema is a game-changer - each product document can have whatever fields it needs. Laptops get their specs, shoes get their sizing info, and there's no wasted space with NULLs everywhere. Adding a new product type? Just insert it with its unique attributes. No schema migration required.

Embedding reviews directly in the product document is super convenient. One query gets you the product and all its reviews together - no joins needed. It's faster and the data structure actually matches how we think about it: a product *has* reviews.

Horizontal scalability is another win. As the catalog grows to millions of products, we can shard across multiple servers based on category or product ID. MySQL can scale vertically (bigger server) but horizontal scaling with proper ACID guarantees is much harder.

## Section C: Trade-offs (100 words)

However, MongoDB isn't perfect for everything. First, there's no strong referential integrity enforcement. If we delete a customer, their reviews in various product documents stick around unless we manually clean them up. MySQL's foreign key constraints handle this automatically.

Second, transactions across multiple documents used to be problematic (though MongoDB 4.0+ improved this). For our orders system where we need to update inventory, create orders, and update customer balances atomically, MySQL's ACID transactions are more reliable and have been battle-tested for decades. NoSQL databases typically favor availability over consistency in distributed scenarios.