-- WMS Advanced Analysis & Optimization Queries

-- 1. Indexing Demonstration
-- Create indexes to optimize query performance for history logs and order status.
CREATE INDEX idx_movements_time ON stock_movements(movement_time);
CREATE INDEX idx_orders_status ON customer_orders(order_status);

-- 2. Advanced Query: Common Table Expressions (CTE)
-- Calculate "Available-to-Sell" inventory by subtracting pending allocations from physical stock.
WITH PendingAllocations AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity_requested) AS reserved_qty
    FROM order_items oi
    JOIN customer_orders co ON oi.order_id = co.order_id
    WHERE co.order_status = 'Pending'
    GROUP BY oi.product_id
)
SELECT 
    p.name AS product_name,
    w.location_name AS warehouse,
    i.quantity_on_hand AS physical_stock,
    COALESCE(pa.reserved_qty, 0) AS reserved_stock,
    (i.quantity_on_hand - COALESCE(pa.reserved_qty, 0)) AS available_to_sell
FROM inventory i
JOIN products p ON i.product_id = p.product_id
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
LEFT JOIN PendingAllocations pa ON i.product_id = pa.product_id;

-- 3. Advanced Query: Window Functions
-- Calculate the cumulative running total of sales (outbound movements) over time.
SELECT 
    m.movement_time,
    p.name AS product_name,
    ABS(m.quantity_change) AS quantity_sold,
    SUM(ABS(m.quantity_change)) OVER (
        PARTITION BY m.product_id 
        ORDER BY m.movement_time
    ) as cumulative_sales_total
FROM stock_movements m
JOIN products p ON m.product_id = p.product_id
WHERE m.quantity_change < 0
ORDER BY m.movement_time DESC;

-- 4. Basic Query: Multi-Table Joins
-- Retrieve full details for a specific order, including customer and product info.
SELECT 
    co.order_id,
    co.customer_name,
    co.order_status,
    p.name AS product_name,
    oi.quantity_requested
FROM customer_orders co
JOIN order_items oi ON co.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE co.order_id = 4;
