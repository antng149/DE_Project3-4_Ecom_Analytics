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