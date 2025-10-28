# 📦 Real-Time Warehouse Management System (WMS)

🎯 Project Objective

The goal of this project is to design and implement a concurrency-safe database system for real-time warehouse inventory management.
The system must satisfy three critical guarantees:

✅ No Overselling: Stock quantities must never become negative.

✅ Data Consistency: When 100 users attempt to purchase the last 10 items, only 10 orders should succeed, while the other 90 must receive a “Stock Unavailable” message.

✅ Full Traceability: Every inventory change (inbound or outbound) must have a detailed and auditable transaction record.

🏗️ Phase 1: Database Design (Foundation)

The database design follows the normalization principles outlined in Doc 9: Database Design Basics.
It consists of six core tables:

1️⃣ Products

Stores product metadata such as a unique product ID, SKU code, and product name.

2️⃣ Warehouses

Contains warehouse information, including warehouse ID and location name (e.g., “Bishkek Central Warehouse”).

3️⃣ Inventory – Core Table 1

Tracks the current quantity of each product in each warehouse.
It uses a composite primary key (product_id, warehouse_id) to ensure that each product–warehouse combination appears only once.
A non-negative constraint enforces that inventory quantities can never drop below zero.
This table represents the current state of inventory.

4️⃣ Customer Orders

Stores the main order information, including order ID, customer name, order status, and creation time.
Order status values include: Pending, Fulfilled, and Cancelled.

5️⃣ Order Items

Lists the details of each product within an order, including the product ID and the quantity requested by the customer.
Each item must request a strictly positive quantity.

6️⃣ Stock Movements – Core Table 2

Serves as the ledger that records every stock movement event.
Each record contains the affected product and warehouse, the quantity change (positive for inbound, negative for outbound), the reason for the change (e.g., “Purchase Order” or “Customer Order”), and the timestamp of the movement.

The Inventory table shows the “current snapshot,” while Stock Movements provides the “historical truth.”
At any point, the total of all stock movements should match the quantity in the inventory table, ensuring full data integrity and auditability.

🧱 Phase 2: Inbound Logic (The Easy Part)

Inbound operations are relatively simple because they rarely face concurrency conflicts.
However, they must be handled transactionally to ensure ACID atomicity.

In an inbound scenario, when new goods arrive at the warehouse, both the Inventory and Stock Movements tables must be updated together within a single transaction.

If either update fails (for example, a system or disk error occurs), the entire transaction must roll back, ensuring that no “phantom stock” appears without a matching movement record.
This guarantees strong data consistency.

⚔️ Phase 3: Outbound Logic (The Concurrency Challenge)
Problem: Race Condition

When two or more users try to purchase the same product simultaneously, they may all read the same available quantity before any of their updates commit.
This can result in overselling, where multiple successful orders are created for stock that does not exist.

Correct Approach: Pessimistic Locking

To ensure concurrency safety, the system must use row-level locks when reading and modifying inventory.
A locking query such as “SELECT … FOR UPDATE” in PostgreSQL prevents other concurrent transactions from modifying or locking the same row until the current transaction finishes.

This ensures that only one transaction can reduce the stock of a specific product in a specific warehouse at any given time.

If sufficient inventory is available, the system safely updates the quantity, records a stock movement, and fulfills the order.
If the inventory is insufficient, the transaction is rolled back, and the customer receives a “Stock Unavailable” message.

This locking mechanism guarantees true concurrency safety.

📊 Phase 4: Advanced Querying (Analytical Insights)

Once the database is populated with transactional data, it can support advanced business analytics.

1️⃣ Available-to-Sell (ATS)

“Available stock” is not always equal to “quantity on hand.”
If certain quantities are already allocated to pending orders, the true sellable stock should subtract those allocations.

A Common Table Expression (CTE) can be used to calculate all pending allocations and then determine the available-to-sell quantity for each product.

2️⃣ 30-Day Rolling Average Sales

Using window functions, the system can compute the rolling 30-day average of daily sales per product.
This helps forecast replenishment needs and supports automated restocking strategies.

Such analytical queries transform the operational database into a decision-support tool for inventory optimization.

⚡ Phase 5: Concurrency Stress Testing (Proof of Correctness)

This final phase empirically proves the concurrency safety of the system.

Test Setup

Insert a test product into the inventory table with an initial quantity of 100.

Write a test script (in Python, Node.js, or Go) that spawns 200 concurrent threads or processes, each attempting to purchase one unit of the test product.

Each thread follows the full transaction logic defined in the concurrency-safe outbound process.

Validation Criteria

After running the test, the following conditions must all be true:

The final inventory quantity equals 0.

Exactly 100 orders have the status Fulfilled.

The total of all stock movement records equals –100.

No inventory record has a negative quantity.

If all these results hold, the system is physically concurrency-safe.

⚙️ Performance Optimization (Indexing Strategy)

While primary and foreign keys automatically generate indexes, additional indexes can significantly improve query performance—particularly during Phase 4’s analytical queries.

A composite index on (product_id, movement_time) in the Stock Movements table accelerates time-based aggregation and rolling average calculations.

An index on product_id in the Order Items table speeds up the computation of pending allocations during the Available-to-Sell (ATS) query.

These optimizations ensure that analytical performance scales efficiently even as data volume grows.

✅ Conclusion

This project demonstrates a complete design and implementation of a real-time, concurrency-safe Warehouse Management System (WMS) with:

Transactional integrity and ACID compliance

Strict data constraints preventing negative stock

Comprehensive auditability through movement logs

Concurrency-safe outbound processing using pessimistic locking

High-performance analytical querying with indexing optimization

Passing the final stress test validates the system’s physical concurrency safety, proving that your database design and implementation achieve both theoretical correctness and real-world reliability.
