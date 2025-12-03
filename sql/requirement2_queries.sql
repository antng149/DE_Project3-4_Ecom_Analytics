--Total revenue per month--
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    date_trunc('month', o.order_date)::date AS month_start,
    ROUND(SUM(oi.subtotal), 2)              AS monthly_revenue
FROM orders o
JOIN order_items oi
  ON oi.order_id = o.order_id
 AND oi.order_date = o.order_date
GROUP BY date_trunc('month', o.order_date)
ORDER BY month_start;

--Orders filtered by seller and date--
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.seller_id,
    o.order_date,
    o.status,
    o.total_amount
FROM orders o
WHERE o.seller_id =  :seller_id        -- e.g. 10
  AND o.order_date BETWEEN :start_date  -- e.g. '2025-10-01'
                         AND :end_date  -- e.g. '2025-10-31'
ORDER BY o.order_date, o.order_id;

--Filter order_items by product_id
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    oi.order_id,
    oi.order_date,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.subtotal
FROM order_items oi
WHERE oi.product_id = :product_id       -- e.g. 123
ORDER BY oi.order_date, oi.order_id;

-- Find order with the highest total_amount
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.order_date,
    o.seller_id,
    o.status,
    o.total_amount
FROM orders o
ORDER BY o.total_amount DESC
LIMIT 1;

--List products with the highest quantity sold
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 20;   -- top 20, adjust as needed

--Orders by Seller in October (e.g. 2025-10)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.order_date,
    o.seller_id,
    s.seller_name,
    o.status,
    o.total_amount
FROM orders o
JOIN sellers s ON s.seller_id = o.seller_id
WHERE o.order_date >= DATE '2025-10-01'
  AND o.order_date <  DATE '2025-11-01'
ORDER BY o.seller_id, o.order_date, o.order_id;

--Revenue per Product per Month
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    date_trunc('month', oi.order_date)::date AS month_start,
    p.product_id,
    p.product_name,
    ROUND(SUM(oi.subtotal), 2)               AS product_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY month_start, p.product_id, p.product_name
ORDER BY month_start, product_revenue DESC;

-- Products sold per seller (by quantity)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    s.seller_id,
    s.seller_name,
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN orders o   ON o.order_id  = oi.order_id
               AND o.order_date = oi.order_date
JOIN products p ON p.product_id = oi.product_id
JOIN sellers s  ON s.seller_id  = o.seller_id
GROUP BY s.seller_id, s.seller_name, p.product_id, p.product_name
ORDER BY s.seller_id, total_quantity_sold DESC;