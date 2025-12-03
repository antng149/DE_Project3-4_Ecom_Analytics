# Dự Án DEC – Phân Tích Thương Mại Điện Tử (PostgreSQL + Python)

```markdown
DE_UniGap_Project3/
│
├── README.md
├── README_ENG.md
├── README_VN.md
├── performance.md
├── requirement3_reports.md
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


## 1. Tổng Quan

Dự án này xây dựng một hệ thống cơ sở dữ liệu phân tích end-to-end cho mô hình thương mại điện tử, sử dụng PostgreSQL và Python.

Bao gồm các phần chính:

- Danh mục sản phẩm (brands, categories, sellers, products, promotions)
- Mô hình giao dịch (orders + order_items)
- Sinh dữ liệu mô phỏng quy mô lớn (~3 triệu đơn hàng)
- Tối ưu hiệu năng (partition theo tháng + index)
- Các hàm SQL động phục vụ phân tích dữ liệu kinh doanh

---

## 2. Công Nghệ Sử Dụng

- PostgreSQL 16 (Docker)
- Python 3.13
- psycopg2 / pandas (dùng để truy vấn & sinh dữ liệu)
- PL/pgSQL (dùng để viết hàm và báo cáo)
- PyCharm Pro làm IDE cho Python & SQL

---
## 3. Cách Chạy Dự Án

### 3.1 Khởi Động PostgreSQL Bằng Docker

Từ thư mục `docker/`:

```bash
cd docker
docker compose up -d
```

Lệnh này sẽ khởi động PostgreSQL trong container Docker, dựa trên cấu hình trong `docker-compose.yml` và file `.env`.

Sau khi container chạy, bạn có thể kiểm tra trạng thái bằng:

```bash
docker ps --filter name=dec_pg
```

Nếu trạng thái là **healthy**, bạn có thể tiếp tục sang bước tiếp theo.

---

### 3.2 Kết Nối Vào PostgreSQL

Sử dụng lệnh sau để kết nối vào database:

```bash
psql -h 127.0.0.1 -p 5433 -U postgres -d dec
```

---

### 3.3 Chạy File SQL Tạo Schema, Partition và Index

Trong cửa sổ psql:

```sql
\i sql/console.sql
```

File này bao gồm toàn bộ:

- Tạo bảng orders & order_items  
- Tạo partition theo tháng  
- Tạo index tối ưu  
- Tạo các hàm báo cáo động (Requirement 3)

---

### 3.4 Sinh Dữ Liệu (~3 triệu orders)

Dự án sử dụng các thư viện Python sau:
	•	sqlalchemy – tạo engine và quản lý kết nối cơ sở dữ liệu
	•	psycopg2-binary – driver PostgreSQL được SQLAlchemy sử dụng
	•	faker – sinh dữ liệu giả lập phục vụ tạo đơn hàng
	•	pandas – xử lý DataFrame và hỗ trợ ghi dữ liệu hàng loạt

Cài đặt các thư viện và chạy script sinh dữ liệu:

```bash
pip install psycopg2-binary sqlalchemy faker pandas
python src/seed_orders.py
```
Các thư viện chuẩn được Python cung cấp sẵn và không cần cài đặt thêm:

```bash
import random
import pandas as pd
from datetime import date, timedelta
from sqlalchemy import create_engine
pip install psycopg2 faker pandas
python src/seed_orders.py
```

Bạn có thể kiểm tra số lượng dữ liệu:

```sql
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
```

---

### 3.5 Chạy Các Báo Cáo (Dynamic Reports)

Các hàm báo cáo được định nghĩa trong file `sql/console.sql`. Sau khi schema và functions được load, bạn có thể chạy thử:

```sql
SELECT * FROM monthly_revenue_report('2025-01-01', '2025-12-31');
SELECT * FROM daily_revenue_report('2025-01-01', '2025-01-31');
SELECT * FROM seller_performance_report('2025-01-01', '2025-12-31');
```

Chi tiết xem thêm trong `reports.md`.

---
