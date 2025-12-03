from faker import Faker
import random
import pandas as pd
from sqlalchemy import create_engine, text

# ---- config (update only if your port/db changed) ----
PG_URL = "postgresql+psycopg2://postgres:postgres@127.0.0.1:5433/dec"

# target volumes
N_BRANDS = 20
N_CATEGORIES = 10
N_SELLERS = 25
N_PRODUCTS = 200
N_PROMOTIONS = 10
N_PROMO_PRODUCTS = 100

fake = Faker()
Faker.seed(42)
random.seed(42)

engine = create_engine(PG_URL, future=True)

def bulk_insert(df: pd.DataFrame, table: str):
    df.to_sql(table, engine, if_exists="append", index=False)

def gen_brands(n=N_BRANDS):
    rows = []
    for _ in range(n):
        rows.append({
            "brand_name": fake.company(),
            "country": fake.country(),
            "created_at": fake.date_time_this_decade()
        })
    return pd.DataFrame(rows)

def gen_categories(n=N_CATEGORIES):
    # half level-1, half level-2 linked to a parent
    main_ct = max(1, n // 2)
    subs_ct = n - main_ct
    mains = [{"category_name": name, "parent_category_id": None, "level": 1,
              "created_at": fake.date_time_this_year()}
             for name in ["Electronics","Fashion","Home","Beauty","Sports","Toys","Automotive","Books","Grocery","Pets"][:main_ct]]
    return pd.DataFrame(mains), subs_ct

def attach_subcategories(inserted_main_df, subs_ct):
    parent_ids = inserted_main_df["category_id"].tolist()
    names = ["Mobile Phones","Laptops","Shoes","Bags","Furniture","Skincare","Fitness","Board Games","Car Care","Cat Food"]
    rows = []
    for i in range(subs_ct):
        rows.append({
            "category_name": names[i % len(names)],
            "parent_category_id": random.choice(parent_ids),
            "level": 2,
            "created_at": fake.date_time_this_year()
        })
    return pd.DataFrame(rows)

def gen_sellers(n=N_SELLERS):
    rows = []
    for _ in range(n):
        rows.append({
            "seller_name": fake.company(),
            "join_date": fake.date_between(start_date='-4y', end_date='today'),
            "seller_type": random.choice(["Official","Marketplace"]),
            "rating": round(random.uniform(3,5), 1),
            "country": "Vietnam"
        })
    return pd.DataFrame(rows)

def gen_products(n, categories_df, brands_df, sellers_df):
    cat_ids = categories_df["category_id"].tolist()
    brand_ids = brands_df["brand_id"].tolist()
    seller_ids = sellers_df["seller_id"].tolist()
    rows = []
    for _ in range(n):
        price = round(random.uniform(100_000, 50_000_000), 2)
        discount = round(price * random.uniform(0.7, 1.0), 2)
        rows.append({
            "product_name": fake.catch_phrase(),
            "category_id": random.choice(cat_ids),
            "brand_id": random.choice(brand_ids),
            "seller_id": random.choice(seller_ids),
            "price": price,
            "discount_price": discount,
            "stock_qty": random.randint(0, 500),
            "rating": round(random.uniform(3,5),1),
            "created_at": fake.date_time_between(start_date='-3y', end_date='now'),
            "is_active": random.choice([True, False, True])
        })
    return pd.DataFrame(rows)

def gen_promotions(n=N_PROMOTIONS):
    from datetime import timedelta
    rows = []
    for _ in range(n):
        start = fake.date_between(start_date='-180d', end_date='+30d')
        end = start + timedelta(days=random.randint(3, 45))
        rows.append({
            "promotion_name": f"{random.choice(['9.9','10.10','11.11','Year-End','Flash'])} {random.choice(['Mega Sale','Super Sale','Deals'])}",
            "promotion_type": random.choice(['product','category','seller','flash_sale']),
            "discount_type": random.choice(['percentage','fixed_amount']),
            "discount_value": round(random.uniform(5, 50), 2),
            "start_date": start,
            "end_date": end
        })
    return pd.DataFrame(rows)

def gen_promo_products(n, promotions_df, products_df):
    promo_ids = promotions_df["promotion_id"].tolist()
    prod_ids = products_df["product_id"].tolist()
    rows = []
    for _ in range(n):
        rows.append({
            "promotion_id": random.choice(promo_ids),
            "product_id": random.choice(prod_ids),
            "created_at": fake.date_time_this_year()
        })
    return pd.DataFrame(rows)

if __name__ == "__main__":
    with engine.begin() as conn:
        # brands
        brands = gen_brands()
        bulk_insert(brands, "brands")
        brands = pd.read_sql("SELECT * FROM brands ORDER BY brand_id", conn)

        # categories: insert parents first, then subs
        mains, subs_ct = gen_categories()
        bulk_insert(mains, "categories")
        mains = pd.read_sql("SELECT * FROM categories WHERE level=1 ORDER BY category_id", conn)
        subs = attach_subcategories(mains, subs_ct)
        bulk_insert(subs, "categories")
        categories = pd.read_sql("SELECT * FROM categories", conn)

        # sellers
        sellers = gen_sellers()
        bulk_insert(sellers, "sellers")
        sellers = pd.read_sql("SELECT * FROM sellers ORDER BY seller_id", conn)

        # products
        products = gen_products(N_PRODUCTS, categories, brands, sellers)
        bulk_insert(products, "products")
        products = pd.read_sql("SELECT product_id FROM products", conn)

        # promotions
        promotions = gen_promotions()
        bulk_insert(promotions, "promotions")
        promotions = pd.read_sql("SELECT promotion_id FROM promotions", conn)

        # promotion_products
        promo_products = gen_promo_products(N_PROMO_PRODUCTS, promotions, products)
        bulk_insert(promo_products, "promotion_products")

    print("✅ Seeding complete.")