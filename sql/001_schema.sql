-- E-commerce OLTP core tables (PostgreSQL)

CREATE TABLE brands (
  brand_id SERIAL PRIMARY KEY,
  brand_name VARCHAR(100) NOT NULL,
  country VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE categories (
  category_id SERIAL PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL,
  parent_category_id INT NULL,
  level SMALLINT NOT NULL CHECK (level IN (1,2)),
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id)
    REFERENCES categories(category_id)
);

CREATE TABLE sellers (
  seller_id SERIAL PRIMARY KEY,
  seller_name VARCHAR(150) NOT NULL,
  join_date DATE NOT NULL,
  seller_type VARCHAR(50) NOT NULL CHECK (seller_type IN ('Official','Marketplace')),
  rating DECIMAL(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
  country VARCHAR(50) NOT NULL
);

CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  product_name VARCHAR(200) NOT NULL,
  category_id INT NOT NULL REFERENCES categories(category_id),
  brand_id INT NOT NULL REFERENCES brands(brand_id),
  seller_id INT NOT NULL REFERENCES sellers(seller_id),
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  discount_price DECIMAL(12,2) NOT NULL CHECK (discount_price >= 0 AND discount_price <= price),
  stock_qty INT NOT NULL CHECK (stock_qty >= 0),
  rating FLOAT NOT NULL CHECK (rating >= 0 AND rating <= 5),
  created_at TIMESTAMP NOT NULL,
  is_active BOOLEAN NOT NULL
);

CREATE TABLE promotions (
  promotion_id SERIAL PRIMARY KEY,
  promotion_name VARCHAR(100) NOT NULL,
  promotion_type VARCHAR(50) NOT NULL,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage','fixed_amount')),
  discount_value NUMERIC(10,2) NOT NULL CHECK (discount_value >= 0),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL CHECK (end_date >= start_date)
);

CREATE TABLE promotion_products (
  promo_product_id SERIAL PRIMARY KEY,
  promotion_id INT NOT NULL REFERENCES promotions(promotion_id),
  product_id INT NOT NULL REFERENCES products(product_id),
  created_at TIMESTAMP NOT NULL
);
