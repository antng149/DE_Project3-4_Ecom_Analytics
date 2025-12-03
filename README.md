---
# DEC Project – E-Commerce Analytics (PostgreSQL + Python)

## 1. Overview

This project implements an end‑to‑end analytical database system for an e‑commerce platform using PostgreSQL and Python.

It includes:

- A product catalog (brands, categories, sellers, products, promotions)
- A transactional data model (`orders` and `order_items`)
- Large‑scale synthetic data generation (~3 million orders)
- Performance optimization using **monthly partitioning** and **indexes**
- Dynamic SQL reporting functions to support business analytics

---

## 2. Tech Stack

- **PostgreSQL 16** (Docker)
- **Python 3.13**
- **psycopg2 / pandas** for querying and data generation
- **PL/pgSQL** for stored procedures and reporting functions
- **PyCharm Professional** as the IDE for SQL and Python

---

## 3. How to Run the Project

### 3.1 Start PostgreSQL via Docker

From the `docker/` directory:

```bash
cd docker
docker compose up -d
```

This command starts PostgreSQL inside a Docker container, using the configuration defined in `docker-compose.yml` and `.env`.

Check the container status:

```bash
docker ps --filter name=dec_pg
```

If the status shows **healthy**, proceed to the next steps.

---

### 3.2 Connect to PostgreSQL

Use:

```bash
psql -h 127.0.0.1 -p 5433 -U postgres -d dec
```

---

### 3.3 Run SQL File to Create Schema, Partitions, Indexes, and Reporting Functions

Inside the PostgreSQL console:

```sql
\i sql/console.sql
```

This SQL file includes:

- Creation of `orders` and `order_items` tables  
- Monthly partitioning setup  
- Indexes for performance optimization  
- Dynamic report functions (Requirement 3)

---

### 3.4 Generate Synthetic Data (~3 million orders)

This project uses the following Python libraries:

- `sqlalchemy` – database engine and connection management
- `psycopg2-binary` – PostgreSQL driver used by SQLAlchemy
- `faker` – synthetic data generation
- `pandas` – DataFrame handling and bulk inserts

Install dependencies and run the data generator:

```bash
pip install psycopg2 faker pandas
import random
import pandas as pd
from datetime import date, timedelta
from sqlalchemy import create_engine
python src/seed_orders.py
```

Verify that the data has been generated:

```sql
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
```

---

### 3.5 Run Dynamic Reports

All report functions are defined in `sql/console.sql`.

Example queries:

```sql
SELECT * FROM monthly_revenue_report('2025-01-01', '2025-12-31');

SELECT * FROM daily_revenue_report('2025-01-01', '2025-01-31');

SELECT * FROM seller_performance_report('2025-01-01', '2025-12-31');
```

More sample outputs are included in **reports.md**.

---

## 4. Project Requirements

### Requirement 1 – Data Model & Generation
- Build product and transaction tables
- Create synthetic data: ~3M orders, each with 2–4 items
- Ensure foreign keys and constraints are valid

### Requirement 2 – Performance Optimization
- Add monthly partitions for `orders` and `order_items`
- Create important indexes (`product_id`, `seller_id`, `order_date`)
- Capture before/after performance using `EXPLAIN (ANALYZE, BUFFERS)`
- Compare execution time and query plans

### Requirement 3 – Dynamic Reporting
Five PL/pgSQL report functions:

1. `monthly_revenue_report(start_date, end_date)`
2. `daily_revenue_report(start_date, end_date, product_ids)`
3. `seller_performance_report(start_date, end_date, category_filter, brand_filter)`
4. `top_products_per_brand(start_date, end_date, seller_ids)`
5. `orders_status_summary(start_date, end_date, seller_ids, category_ids)`

---

## 5. Deliverables

- **README.md** (this file)
- **sql/console.sql** – full schema, partitions, indexes, and PL/pgSQL reports  
- **src/seed_orders.py** – script generating ~3M synthetic orders  
- **performance.md** – performance comparison (before vs after index)  
- **reports.md** – output samples of all dynamic reports  
- **images/** – execution plan screenshots  

---

## 6. Project Structure

```
DE_UniGap_Project3/
│
├── README.md
├── performance.md
├── reports.md
│
├── docker/
│   ├── docker-compose.yml
│   └── .env
│
├── sql/
│   └── console.sql
│
├── src/
│   ├── seed.py
│   ├── seed_orders.py
│   ├── query_products.py
│   └── connect_postgres.py
│
├── images/              # Execution plan screenshots
└── samples/             # Optional CSV outputs
```

---

## 7. Summary

This project successfully delivers:

- A complete e‑commerce analytical schema  
- Massive synthetic dataset (~3M orders)  
- Partitioning + indexing for performance  
- Before/after benchmark analysis  
- Comprehensive dynamic PL/pgSQL reporting suite  

The system is optimized for analytical workloads and scalable for large datasets.