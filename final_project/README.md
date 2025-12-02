# 📦 Real-Time Warehouse Management System (WMS)

## Project Overview

The objective of this project is to design and implement a high-concurrency, transaction-safe database backend for real-time warehouse inventory management using PostgreSQL and Python.

In a real-world e-commerce environment, a critical challenge is the **"Race Condition,"** where multiple users attempt to purchase the last remaining item simultaneously. Without proper concurrency control, this leads to **"Overselling"** (selling more items than physically available).

This project solves this problem by enforcing **ACID properties** and implementing **Pessimistic Locking**. It includes a full database schema, audit logging, and a multi-threaded Python stress-testing script to empirically prove the system's reliability.

---

## 1. Database Architecture & Design Principles
<img width="933" height="718" alt="Screenshot 2025-11-30 at 21 02 40" src="https://github.com/user-attachments/assets/cbe1971f-c07d-4cd0-b88c-2d3301a639cf" />

The database schema adheres to normalization principles and consists of six core tables. The design focuses on data integrity, constraints, and auditability.

### Core Tables and Design Rationale

#### A. Static Data: `products` & `warehouses`
These tables store metadata.
* **Key Data in Project:** We utilize Product ID `5` (iPhone 15 Pro 256GB) and Warehouse ID `1` (Bishkek Central) for all testing scenarios.

#### B. State Management: `inventory`
* **Function:** Tracks the *current* snapshot of stock.
* **Design Choice:** Uses a composite primary key `(product_id, warehouse_id)`.
* **Critical Constraint:** We applied a database-level constraint `CHECK (quantity_on_hand >= 0)`.
    * *Why?* This serves as the final line of defense. Even if the application logic fails, the database kernel will physically reject any transaction that attempts to make stock negative.

#### C. Business Logic: `customer_orders` & `order_items`
* **Function:** Records the business intent (Who bought what).
* **Design Choice:** Separating headers and items allows for complex orders. The `order_status` field ('Pending', 'Fulfilled') allows us to track transaction success during stress testing.

#### D. The Ledger: `stock_movements`
* **Function:** Records the *history* of every stock change (Immutable Ledger).
* **Design Choice:** Every `INSERT` into this table must happen in the same transaction as the `inventory` update.
* **Role in Verification:** This table is crucial for the "Logic Loop." In our final test, we verify correctness by summing up these records. If Inventory drops by 5, the sum of movements must be exactly -5.
<img width="441" height="481" alt="sql_design_and_relationship drawio" src="https://github.com/user-attachments/assets/575d3c67-9310-4bee-8f16-e226d1821661" />

---

## 2. Solving the Concurrency Challenge (Phase 3)

The core technical challenge is handling outbound logic when traffic spikes.

### The Problem: Race Condition
If User A and User B both read `quantity_on_hand = 1` at the same time, both logic checks pass (`1 >= 1`), and both issue an `UPDATE`. The stock becomes `-1` (or the second write overwrites the first).

### The Solution: Pessimistic Locking
We utilize PostgreSQL's `SELECT ... FOR UPDATE` mechanism. This logic is implemented in the Python application layer.

**Implementation Logic:**
1.  **Begin Transaction.**
2.  **Lock the Row:** Query the inventory for Product `5` in Warehouse `1` using `FOR UPDATE`.
    * *Effect:* The database locks this specific row. Any other thread attempting to read this row must wait until the current transaction Commits or Rollbacks.
3.  **Check Logic:** Calculate `current_stock - requested_qty`.
4.  **Commit or Rollback:**
    * If sufficient: `UPDATE` inventory, `INSERT` movement, `COMMIT`.
    * If insufficient: `ROLLBACK`.

---

## 3. Stress Testing & Verification (Phase 5)

To prove the system design works, we developed a Python script (`wms_test.py`) to simulate a high-concurrency "Flash Sale" scenario.

### Test Scenario
* **Initial State:** Inventory for "iPhone 15 Pro" is reset to **5 units**.
* **Load:** **20 concurrent users** (threads) are spawned instantly via Python's `threading` library.
* **Action:** Each user attempts to purchase **1 unit**.

### Python Implementation Details
The script uses `psycopg2` to manage database connections. Below is the critical locking logic extracted from `wms_test.py`:

```python
# Snippet from wms_test.py
cur.execute("""
    SELECT quantity_on_hand 
    FROM inventory 
    WHERE product_id = %s AND warehouse_id = %s 
    FOR UPDATE;
""", (PRODUCT_ID, WAREHOUSE_ID))
```
### Empirical Results
After running the script, the system produced the following results, closing the logic loop:

1.  **Inventory Check:**
    * *Expectation:* Stock should drop from 5 to 0, not -15.
    * *Result:* `SELECT quantity_on_hand FROM inventory WHERE product_id=5` returned **0**.
    
2.  **Order Success Rate:**
    * *Expectation:* Exactly 5 users should receive success messages.
    * *Result:* The Python log showed 5 "Success" messages and 15 "Stock Unavailable" messages.
    * *Database Proof:* `SELECT COUNT(*) FROM customer_orders WHERE order_status='Fulfilled'` returned **5**.

3.  **Audit Trail Verification:**
    * *Expectation:* The ledger must reflect the exact outflow.
    * *Database Proof:* `SELECT COUNT(*) FROM stock_movements` returned **5 records**, each with a change of `-1`.

---
### Empirical Test Results (Log Evidence)

The following database logs demonstrate the successful handling of the concurrency test.

**1. Verification of Order Success:**
We queried for a specific user (User-19) who was lucky enough to grab an item.
```sql
wms_project=# SELECT * FROM customer_orders WHERE customer_name = 'User-19';
 order_id | customer_name | order_status |         created_at         
----------+---------------+--------------+----------------------------
        4 | User-19       | Fulfilled    | 2025-11-29 22:13:44.693254
(1 row)
```

**2. Verification of Inventory Integrity:**
After the stress test (20 users fighting for 5 items), the inventory correctly dropped to exactly 0.
```sql
wms_project=# SELECT * FROM inventory WHERE product_id = 5;
 product_id | warehouse_id | quantity_on_hand 
------------+--------------+------------------
          5 |            1 |                0
(1 row)
```

**3. Audit Trail Verification:**
The `stock_movements` table captured exactly 5 transactions. Note the timestamps are nearly identical, proving high concurrency.
```sql
wms_project=# SELECT * FROM stock_movements ORDER BY movement_id DESC LIMIT 5;
 movement_id | product_id | warehouse_id | quantity_change |      reason       |       movement_time        
-------------+------------+--------------+-----------------+-------------------+----------------------------
           7 |          5 |            1 |              -1 | Order 3 Fulfilled | 2025-11-29 22:13:44.691311
           6 |          5 |            1 |              -1 | Order 8 Fulfilled | 2025-11-29 22:13:44.717809
           5 |          5 |            1 |              -1 | Order 6 Fulfilled | 2025-11-29 22:13:44.703467
           4 |          5 |            1 |              -1 | Order 7 Fulfilled | 2025-11-29 22:13:44.707031
           3 |          5 |            1 |              -1 | Order 4 Fulfilled | 2025-11-29 22:13:44.693254
(5 rows)
```
---
## 4. Advanced Analytics & Optimization

Beyond transaction processing, the project includes advanced SQL capabilities for business intelligence (See `analysis_queries.sql` in the repository).

* **Indexing:** Created custom indexes on `stock_movements(movement_time)` to optimize historical query performance.
* **Common Table Expressions (CTEs):** Used to calculate "Available-to-Sell" inventory by subtracting pending allocations from physical stock.
* **Window Functions:** Implemented rolling average calculations to analyze sales trends over time.

---
## 5. Backup & Recovery Strategy

To ensure data persistence and disaster recovery, the project employs the following strategy:

**1. Logical Backups (pg_dump):**
Full database snapshots are taken using PostgreSQL's standard `pg_dump` utility. This exports the schema and data into a portable SQL file (Plain Text format), allowing for version control and migration between different servers.
* **Command:** `pg_dump -U <username> wms_project > backup.sql`

**2. Recovery Strategy:**
In case of system failure or data corruption, the database can be restored to the latest snapshot using the `psql` utility.
* **Command:** `psql -U <username> -d wms_project -f backup.sql`

---


## 6. How to Run This Project

### Prerequisites
* PostgreSQL (Local or Remote)
* Python 3.x
* Library: `psycopg2-binary`

### Steps
1.  **Initialize Database:**
    Import the provided SQL dump to create the schema and initial data.
    ```bash
    psql -U <username> -d wms_project -f wms_database_dump.sql
    ```

2.  **Configure Connection:**
    Open `wms_test.py` and update the `DB_PARAMS` dictionary with your local database credentials.

3.  **Run the Stress Test:**
    ```bash
    python3 wms_test.py
    ```

4.  **Verify Data:**
    Check the terminal output for the verification report, or inspect the tables manually using pgAdmin/psql to see the resulting transaction logs.

## I pledge to meet all deadlines and will accept disciplinary action for failing to do so.
