SELECT 'brands' t, COUNT(*) FROM brands
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL SELECT 'promotion_products', COUNT(*) FROM promotion_products;


-- How many products per category? --
SELECT
  c.category_id,
  c.category_name,
  COUNT(p.product_id) AS product_count,
  ROUND(AVG(p.price)::numeric, 2) AS avg_price
FROM categories c
LEFT JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC, c.category_name;


-- Top-rated product in each category --
WITH ranked AS (
  SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.rating,
    ROW_NUMBER() OVER (
      PARTITION BY p.category_id
      ORDER BY p.rating DESC, p.product_id
    ) AS rn
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
)
SELECT product_id, product_name, category_name, rating
FROM ranked
WHERE rn = 1
ORDER BY category_name;

-- brand performance
SELECT
  b.brand_name,
  ROUND(AVG(p.rating)::numeric, 2) AS avg_rating,
  COUNT(*) AS product_count
FROM products p
JOIN brands b   ON b.brand_id   = p.brand_id
GROUP BY b.brand_name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC, product_count DESC
LIMIT 10;

-- seller performance
SELECT
  s.seller_name,
  ROUND(AVG(p.rating)::numeric, 2) AS avg_rating,
  COUNT(*) AS product_count
FROM products p
JOIN sellers s ON s.seller_id = p.seller_id
GROUP BY s.seller_name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC
LIMIT 10;

--Which promotions are active today? --
-- Active promotions today with how many products they cover
SELECT
  pr.promotion_id,
  pr.promotion_name,
  pr.start_date,
  pr.end_date,
  COUNT(pp.product_id) AS products_in_promo
FROM promotions pr
LEFT JOIN promotion_products pp ON pp.promotion_id = pr.promotion_id
WHERE CURRENT_DATE BETWEEN pr.start_date AND pr.end_date
GROUP BY pr.promotion_id, pr.promotion_name, pr.start_date, pr.end_date
ORDER BY products_in_promo DESC, pr.promotion_name;

-- sample products under one active promotion
SELECT
  pr.promotion_name,
  p.product_id,
  p.product_name,
  p.discount_price
FROM promotions pr
JOIN promotion_products pp ON pp.promotion_id = pr.promotion_id
JOIN products p           ON p.product_id     = pp.product_id
WHERE CURRENT_DATE BETWEEN pr.start_date AND pr.end_date
ORDER BY pr.promotion_name, p.product_id
LIMIT 20;

-- 6.1 discount should never exceed price
SELECT product_id, price, discount_price
FROM products
WHERE discount_price > price;

-- 6.2 rating must be in [0,5]
SELECT product_id, rating
FROM products
WHERE rating < 0 OR rating > 5;

-- 6.3 orphan checks (FKs should be valid) -- all should return 0 rows
SELECT COUNT(*) AS missing_brand_fk
FROM products p LEFT JOIN brands b ON p.brand_id = b.brand_id
WHERE b.brand_id IS NULL;

SELECT COUNT(*) AS missing_category_fk
FROM products p LEFT JOIN categories c ON p.category_id = c.category_id
WHERE c.category_id IS NULL;

SELECT COUNT(*) AS missing_seller_fk
FROM products p LEFT JOIN sellers s ON p.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- create orders table --
SELECT * FROM top_products_transformed LIMIT 10;

CREATE TABLE IF NOT EXISTS orders (
    order_id        BIGSERIAL PRIMARY KEY,     -- unique order identifier
    seller_id       INT NOT NULL,              -- FK: orders belong to one seller
    order_date      DATE NOT NULL,             -- date the order happened
    status          VARCHAR(20) NOT NULL,      -- e.g. complete, cancelled, pending
    total_amount    NUMERIC(10,2) NOT NULL,    -- sum of order_items.subtotal
    created_at      TIMESTAMP DEFAULT NOW(),   -- metadata timestamp

    CONSTRAINT fk_orders_seller
        FOREIGN KEY (seller_id)
        REFERENCES sellers(seller_id)
        ON DELETE RESTRICT
);

-- create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id   BIGSERIAL PRIMARY KEY,      -- each row inside the order
    order_id        BIGINT NOT NULL,            -- FK → orders.order_id
    product_id      INT NOT NULL,               -- FK → products.product_id
    order_date      DATE NOT NULL,              -- repeat for partitioning
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,
    subtotal        NUMERIC(10,2) NOT NULL,     -- quantity * unit_price
    created_at      TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
);

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';


SELECT seller_id, seller_name
FROM sellers
ORDER BY seller_id
LIMIT 10;

INSERT INTO orders (seller_id, order_date, status, total_amount)
VALUES
    (1, '2025-01-01', 'complete', 0),
    (2, '2025-01-02', 'complete', 0),
    (3, '2025-01-03', 'pending',  0),
    (4, '2025-01-04', 'cancelled', 0),
    (5, '2025-01-05', 'complete', 0);

SELECT * FROM orders ORDER BY order_id;

SELECT
  product_id,
  seller_id,
  product_name,
  discount_price
FROM products
WHERE seller_id IN (1,2,3,4,5)
ORDER BY seller_id, product_id
LIMIT 30;

SELECT * FROM orders WHERE order_id = 1;

SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    subtotal
FROM order_items
ORDER BY subtotal DESC
LIMIT 5;

UPDATE products p
SET
    price = vals.new_price,
    discount_price = vals.new_discount
FROM (
    SELECT
        product_id,
        new_price,
        -- discount between 50% and 100% of price
        ROUND(new_price * (0.5 + random() * 0.5)::numeric, 2) AS new_discount
    FROM (
        -- base random price between 5 and 10,000
        SELECT
            product_id,
            ROUND((5 + random() * 9995)::numeric, 2) AS new_price
        FROM products
    ) x
) vals
WHERE p.product_id = vals.product_id;

-- Insert 1–5 random items for each order
INSERT INTO order_items (order_id, product_id, order_date, quantity, unit_price, subtotal)
SELECT
    o.order_id,
    p.product_id,
    o.order_date,
    p.qty,
    p.discount_price AS unit_price,
    ROUND(p.qty * p.discount_price, 2) AS subtotal
FROM orders o
JOIN LATERAL (
    SELECT
        product_id,
        discount_price,
        (1 + floor(random() * 5))::int AS qty   -- quantity 1–5
    FROM products
    WHERE seller_id = o.seller_id
    ORDER BY random()
    LIMIT (2 + floor(random() * 3))::int        -- 1–5 products per order
) p ON TRUE;




-- Overall revenue and total discount across all orders
SELECT
    ROUND(SUM(oi.subtotal), 2) AS total_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS total_discount
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id;

SELECT
    o.order_id,
    o.total_amount,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS total_discount
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.order_id, o.total_amount
ORDER BY o.order_id;

-- Revenue per seller
SELECT
    s.seller_id,
    s.seller_name,
    ROUND(SUM(oi.subtotal), 2) AS seller_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS seller_total_discount
FROM order_items oi
JOIN orders o   ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN sellers s  ON s.seller_id  = o.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY seller_revenue DESC;


-- Revenue by category (joins + grouping)

SELECT
    c.category_id,
    c.category_name,
    ROUND(SUM(oi.subtotal), 2) AS category_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS category_discount
FROM order_items oi
JOIN products p   ON p.product_id   = oi.product_id
JOIN categories c ON c.category_id  = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY category_revenue DESC;

-- Daily revenue (starting time-series thinking)
SELECT
    o.order_date,
    ROUND(SUM(oi.subtotal), 2) AS daily_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS daily_discount
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY o.order_date
ORDER BY o.order_date;

-- update orders.total_amount
UPDATE orders o
SET total_amount = sub.order_total
FROM (
    SELECT
        order_id,
        ROUND(SUM(subtotal), 2) AS order_total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;

--Per-order totals & discounts
SELECT
    o.order_id,
    o.total_amount,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS total_discount
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.order_id, o.total_amount
ORDER BY o.order_id;

-- revenue per seller
SELECT
    s.seller_id,
    s.seller_name,
    ROUND(SUM(oi.subtotal), 2) AS seller_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS seller_total_discount
FROM order_items oi
JOIN orders o   ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN sellers s  ON s.seller_id  = o.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY seller_revenue DESC;

--revenue by category
SELECT
    c.category_id,
    c.category_name,
    ROUND(SUM(oi.subtotal), 2) AS category_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS category_discount
FROM order_items oi
JOIN products p   ON p.product_id   = oi.product_id
JOIN categories c ON c.category_id  = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY category_revenue DESC;


--daily revenue (time series)
SELECT
    o.order_date,
    ROUND(SUM(oi.subtotal), 2) AS daily_revenue,
    ROUND(SUM((p.price - p.discount_price) * oi.quantity), 2) AS daily_discount
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY o.order_date
ORDER BY o.order_date;

SELECT order_id, seller_id, total_amount
FROM orders
ORDER BY order_id;








