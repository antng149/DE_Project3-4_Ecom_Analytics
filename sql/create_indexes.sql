-- For date-based queries (time series, daily/monthly revenue)
CREATE INDEX IF NOT EXISTS idx_orders_order_date
  ON orders(order_date);

-- For joining/filtering by seller
CREATE INDEX IF NOT EXISTS idx_orders_seller_id
  ON orders(seller_id);

-- For fast join: orders ↔ order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
  ON order_items(order_id);

-- For fast join: order_items ↔ products
CREATE INDEX IF NOT EXISTS idx_order_items_product_id
  ON order_items(product_id);