# 📦 Real-Time Warehouse Management System (WMS)

## Project Overview

The objective of this project is to design and implement a high-concurrency, transaction-safe database backend for real-time warehouse inventory management using PostgreSQL and Python.

In a real-world e-commerce environment, a critical challenge is the **"Race Condition,"** where multiple users attempt to purchase the last remaining item simultaneously. Without proper concurrency control, this leads to **"Overselling"** (selling more items than physically available).

This project solves this problem by enforcing **ACID properties** and implementing **Pessimistic Locking**. It includes a full database schema, audit logging, and a multi-threaded Python stress-testing script to empirically prove the system's reliability.

---

## 1. Database Architecture & Design Principles

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
<img width="1312" height="739" alt="Screenshot 2025-11-29 at 22 49 47" src="https://github.com/user-attachments/assets/60890268-18b9-43a8-9d61-1ed33979c011" />

## 4. How to Run This Project

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
