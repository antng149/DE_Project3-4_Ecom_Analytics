-- Report #1 Monthly Revenue Report
CREATE OR REPLACE FUNCTION monthly_revenue_report(
    start_date DATE,
    end_date   DATE
)
RETURNS TABLE (
    month DATE,
    total_orders BIGINT,
    total_quantity BIGINT,
    total_revenue NUMERIC(12,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        date_trunc('month', o.order_date)::date AS month,
        COUNT(DISTINCT o.order_id)              AS total_orders,
        SUM(oi.quantity)                        AS total_quantity,
        ROUND(SUM(oi.subtotal), 2)              AS total_revenue
    FROM orders o
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.order_date = o.order_date
    WHERE o.order_date BETWEEN start_date AND end_date
    GROUP BY month
    ORDER BY month;
END;
$$ LANGUAGE plpgsql STABLE;


SELECT * FROM monthly_revenue_report('2025-01-01', '2025-12-31');


--Report #2 — Daily Revenue Report (with product filter list)
CREATE OR REPLACE FUNCTION daily_revenue_report(
    start_date DATE,
    end_date   DATE,
    product_ids INT[] DEFAULT NULL     -- optional list
)
RETURNS TABLE (
    date DATE,
    total_orders BIGINT,
    total_quantity BIGINT,
    total_revenue NUMERIC(12,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.order_date AS date,
        COUNT(DISTINCT o.order_id),
        SUM(oi.quantity),
        ROUND(SUM(oi.subtotal), 2)
    FROM orders o
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.order_date = o.order_date
    WHERE o.order_date BETWEEN start_date AND end_date
      AND (product_ids IS NULL OR oi.product_id = ANY(product_ids))
    GROUP BY date
    ORDER BY date;
END;
$$ LANGUAGE plpgsql STABLE;


--Daily Revenue Report for January
SELECT * FROM daily_revenue_report('2025-01-01', '2025-01-31');
SELECT * FROM daily_revenue_report('2025-01-01', '2025-01-31', ARRAY[10, 11, 12]);


--- Seller Performance Report
CREATE OR REPLACE FUNCTION seller_performance_report(
    start_date DATE,
    end_date DATE,
    category_filter INT DEFAULT NULL,
    brand_filter INT DEFAULT NULL
)
RETURNS TABLE (
    seller_id INT,
    seller_name TEXT,
    total_orders BIGINT,
    total_quantity BIGINT,
    total_revenue NUMERIC(12,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.seller_id,
        s.seller_name::text,   -- 👈 explicit cast fixes the error
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity)        AS total_quantity,
        ROUND(SUM(oi.subtotal), 2) AS total_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id AND oi.order_date = o.order_date
    JOIN products p     ON p.product_id = oi.product_id
    JOIN sellers s      ON s.seller_id = o.seller_id
    WHERE o.order_date BETWEEN start_date AND end_date
      AND (category_filter IS NULL OR p.category_id = category_filter)
      AND (brand_filter    IS NULL OR p.brand_id    = brand_filter)
    GROUP BY s.seller_id, s.seller_name
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql STABLE;

----
SELECT * FROM seller_performance_report('2025-01-01', '2025-12-31');

SELECT * FROM seller_performance_report('2025-01-01', '2025-12-31', 3, NULL);



---Report #4 - Top Products per Brand
CREATE OR REPLACE FUNCTION top_products_per_brand(
    start_date DATE,
    end_date DATE,
    seller_filter INT[] DEFAULT NULL
)
RETURNS TABLE (
    brand_id INT,
    brand_name TEXT,
    product_id INT,
    product_name TEXT,
    total_quantity BIGINT,
    total_revenue NUMERIC(12,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.brand_id,
        b.brand_name::text,               -- 👈 cast to match return type
        p.product_id,
        p.product_name::text,            -- 👈 cast to match return type
        SUM(oi.quantity) AS total_quantity,
        ROUND(SUM(oi.subtotal), 2) AS total_revenue
    FROM order_items oi
    JOIN orders o     ON o.order_id = oi.order_id AND o.order_date = oi.order_date
    JOIN products p   ON p.product_id = oi.product_id
    JOIN brands b     ON b.brand_id = p.brand_id
    WHERE o.order_date BETWEEN start_date AND end_date
      AND (seller_filter IS NULL OR o.seller_id = ANY(seller_filter))
    GROUP BY b.brand_id, b.brand_name, p.product_id, p.product_name
    ORDER BY total_quantity DESC;
END;
$$ LANGUAGE plpgsql STABLE;

--Query for outputs --
SELECT * FROM top_products_per_brand('2025-01-01', '2025-12-31');
SELECT * FROM top_products_per_brand('2025-01-01', '2025-12-31', ARRAY[1, 4, 7]);


--- Report #5 Order Status Summary
CREATE OR REPLACE FUNCTION orders_status_summary(
    start_date DATE,
    end_date DATE,
    seller_filter INT[] DEFAULT NULL,
    category_filter INT[] DEFAULT NULL
)
RETURNS TABLE (
    status TEXT,
    total_orders BIGINT,
    total_revenue NUMERIC(12,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.status::text,                                  -- 👈 cast added
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.subtotal), 2) AS total_revenue
    FROM orders o
    JOIN order_items oi
      ON oi.order_id = o.order_id
     AND oi.order_date = o.order_date
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_date BETWEEN start_date AND end_date
      AND (seller_filter   IS NULL OR o.seller_id = ANY(seller_filter))
      AND (category_filter IS NULL OR p.category_id = ANY(category_filter))
    GROUP BY o.status
    ORDER BY total_orders DESC;
END;
$$ LANGUAGE plpgsql STABLE;


--- no filter--
SELECT * FROM orders_status_summary('2025-01-01', '2025-12-31');

---Seller filter
SELECT * FROM orders_status_summary('2025-01-01', '2025-12-31', ARRAY[7], NULL);


--- Category filter ---
SELECT * FROM orders_status_summary('2025-01-01', '2025-12-31', NULL, ARRAY[3]);

