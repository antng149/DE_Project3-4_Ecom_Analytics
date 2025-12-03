import random
from datetime import date, timedelta

import psycopg2

# ---- connection parameters ----
CONN_PARAMS = {
    "host": "localhost",
    "port": "5433",
    "dbname": "dec",
    "user": "postgres",
    "password": "postgres",
}

# 👉 TUNE THESE
TOTAL_ORDERS = 3_000_000      # final goal: 2.5M–3M
BATCH_SIZE   = 50_000         # how many orders per batch/transaction

START_DATE = date(2025, 1, 1)
END_DATE   = date(2025, 12, 31)   # spread across a year


def random_date(start: date, end: date) -> date:
    """Pick a random date between start and end (inclusive)."""
    delta_days = (end - start).days
    offset = random.randint(0, delta_days)
    return start + timedelta(days=offset)


def load_products_by_seller(cur):
    """Load products into a dict: seller_id -> list[(product_id, discount_price)]."""
    cur.execute("""
        SELECT product_id, seller_id, discount_price
        FROM products
    """)
    rows = cur.fetchall()

    products_by_seller = {}
    for product_id, seller_id, discount_price in rows:
        products_by_seller.setdefault(seller_id, []).append(
            (product_id, float(discount_price))
        )

    # Optionally filter out sellers with no products
    return {sid: plist for sid, plist in products_by_seller.items() if plist}


def seed_batch(cur, products_by_seller, batch_size: int):
    """Insert a batch of orders + items inside one transaction."""
    # Get current max order_id so we know where we are
    cur.execute("SELECT COALESCE(MAX(order_id), 0) FROM orders;")
    start_order_id = cur.fetchone()[0]

    for i in range(1, batch_size + 1):
        # 1) pick a random seller that has products
        seller_id = random.choice(list(products_by_seller.keys()))

        # 2) random date and status
        order_date = random_date(START_DATE, END_DATE)
        status = random.choices(
            ["complete", "pending", "cancelled"],
            weights=[0.8, 0.1, 0.1],
            k=1
        )[0]

        # 3) Insert the order (temp total_amount = 0)
        cur.execute(
            """
            INSERT INTO orders (seller_id, order_date, status, total_amount)
            VALUES (%s, %s, %s, %s)
            RETURNING order_id, order_date;
            """,
            (seller_id, order_date, status, 0.0)
        )
        order_id, order_date_inserted = cur.fetchone()

        # 4) Choose 2–4 distinct products for this seller
        possible_products = products_by_seller[seller_id]
        num_items = random.randint(2, 4)
        num_items = min(num_items, len(possible_products))
        chosen_products = random.sample(possible_products, k=num_items)

        order_total = 0.0

        for product_id, discount_price in chosen_products:
            quantity = random.randint(1, 5)
            unit_price = discount_price
            subtotal = round(quantity * unit_price, 2)

            cur.execute(
                """
                INSERT INTO order_items (
                    order_id, order_date, product_id,
                    quantity, unit_price, subtotal
                )
                VALUES (%s, %s, %s, %s, %s, %s);
                """,
                (order_id, order_date_inserted, product_id,
                 quantity, unit_price, subtotal)
            )

            order_total += subtotal

        # 5) Update the order total
        order_total = round(order_total, 2)
        cur.execute(
            """
            UPDATE orders
            SET total_amount = %s
            WHERE order_id = %s AND order_date = %s;
            """,
            (order_total, order_id, order_date_inserted)
        )

        if i % 10_000 == 0:
            print(f"   Inserted {i} orders in this batch (up to order_id {order_id})")

    print(f"✅ Batch of {batch_size} orders inserted (order_id now > {start_order_id})")


def main():
    conn = psycopg2.connect(**CONN_PARAMS)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        products_by_seller = load_products_by_seller(cur)
        if not products_by_seller:
            raise RuntimeError("No products_by_seller found. Check products table.")

        num_full_batches = TOTAL_ORDERS // BATCH_SIZE
        remaining = TOTAL_ORDERS % BATCH_SIZE

        print(f"Seeding {TOTAL_ORDERS} orders in batches of {BATCH_SIZE}...")
        print(f"Full batches: {num_full_batches}, remaining: {remaining}")

        for b in range(1, num_full_batches + 1):
            print(f"\n🚚 Starting batch {b}/{num_full_batches}...")
            seed_batch(cur, products_by_seller, BATCH_SIZE)
            conn.commit()
            print(f"💾 Committed batch {b}/{num_full_batches}")

        if remaining > 0:
            print(f"\n🚚 Starting final partial batch of {remaining} orders...")
            seed_batch(cur, products_by_seller, remaining)
            conn.commit()
            print("💾 Committed final partial batch")

        print("\n🎉 Done seeding orders!")

    except Exception as e:
        conn.rollback()
        print("❌ Error while seeding orders:", e)

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
