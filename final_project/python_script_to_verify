import psycopg2
import threading
import time

DB_PARAMS = {
    "dbname": "wms_project",
    "user": "Dan",
    "password": "a2296957743A",
    "host": "localhost",
    "port": "5432"
}

PRODUCT_ID = 5
WAREHOUSE_ID = 1
BUY_QTY = 1
CONCURRENT_USERS = 20

def purchase_attempt(user_id):
    conn = None
    try:
        conn = psycopg2.connect(**DB_PARAMS)
        cur = conn.cursor()

        cur.execute("BEGIN;")

        cur.execute("""
            INSERT INTO customer_orders (customer_name, order_status) 
            VALUES (%s, 'Pending') RETURNING order_id;
        """, (f'User-{user_id}',))
        order_id = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO order_items (order_id, product_id, quantity_requested)
            VALUES (%s, %s, %s);
        """, (order_id, PRODUCT_ID, BUY_QTY))


        cur.execute("""
            SELECT quantity_on_hand 
            FROM inventory 
            WHERE product_id = %s AND warehouse_id = %s 
            FOR UPDATE;
        """, (PRODUCT_ID, WAREHOUSE_ID))

        row = cur.fetchone()
        current_stock = row[0] if row else 0

        if current_stock >= BUY_QTY:
            cur.execute("""
                UPDATE inventory 
                SET quantity_on_hand = quantity_on_hand - %s 
                WHERE product_id = %s AND warehouse_id = %s;
            """, (BUY_QTY, PRODUCT_ID, WAREHOUSE_ID))

            cur.execute("""
                INSERT INTO stock_movements (product_id, warehouse_id, quantity_change, reason)
                VALUES (%s, %s, %s, %s);
            """, (PRODUCT_ID, WAREHOUSE_ID, -BUY_QTY, f'Order {order_id} Fulfilled'))

            cur.execute("""
                UPDATE customer_orders 
                SET order_status = 'Fulfilled' 
                WHERE order_id = %s;
            """, (order_id,))

            conn.commit()
            print(f"User {user_id:02d} Purchase successful. (Remaining Stock: {current_stock - BUY_QTY})")
            return True

        else:
            conn.rollback()
            print(f"User {user_id:02d} Purchase failed: Insufficient stock. (Current Stock: {current_stock})")
            return False

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"User {user_id:02d} System error occurred: {e}")
        return False
    finally:
        if conn:
            conn.close()


def verify_result():
    print("\n" + "=" * 30)
    print("Verifying final database state...")
    try:
        conn = psycopg2.connect(**DB_PARAMS)
        cur = conn.cursor()

        cur.execute("SELECT quantity_on_hand FROM inventory WHERE product_id = %s", (PRODUCT_ID,))
        final_stock = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM customer_orders WHERE order_status = 'Fulfilled'")
        fulfilled_orders = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM stock_movements WHERE quantity_change < 0 AND reason LIKE 'Order %'")
        movements = cur.fetchone()[0]

        print(f"1. Final Inventory: {final_stock} \t(Expected: 0)")
        print(f"2. Fulfilled Orders: {fulfilled_orders} \t(Expected: 5)")
        print(f"3. Stock Movements: {movements} \t(Expected: 5)")

        print("=" * 30)
        if final_stock == 0 and fulfilled_orders == 5 and movements == 5:
            print("Test Passed: System maintained data integrity under concurrency (No overselling).")
        else:
            print("Test Failed: Data inconsistency detected.")

        conn.close()
    except Exception as e:
        print(f"Error during verification: {e}")


def run_concurrent_test():
    print(f"--- Starting High Concurrency Test: {CONCURRENT_USERS} users attempting purchase ---")
    start_time = time.time()

    threads = []

    for i in range(CONCURRENT_USERS):
        t = threading.Thread(target=purchase_attempt, args=(i + 1,))
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    end_time = time.time()
    print(f"\n--- All requests processed. Time elapsed: {end_time - start_time:.2f} seconds ---")

    verify_result()


if __name__ == "__main__":
    run_concurrent_test()
