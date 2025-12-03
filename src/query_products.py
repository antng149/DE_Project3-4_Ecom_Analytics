import psycopg2
import pandas as pd
from sqlalchemy import create_engine


# same connection info
conn_params = {
    "host": "localhost",
    "port": "5433",
    "dbname": "dec",
    "user": "postgres",
    "password": "postgres"
}

# SQL from your earlier step — top-rated product per category
sql = """
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
"""

try:
    # connect
    conn = psycopg2.connect(**conn_params)

    # use pandas to run the SQL and get a DataFrame
    df = pd.read_sql(sql, conn)

    print("✅ Query executed successfully!")
    print(df.head())

    # === Data Transformation ===
    # 1. Sort products by rating descending (just in case)
    df = df.sort_values(by="rating", ascending=False)

    # 2. Add a new column with a simplified version of category name (example transformation)
    df["category_clean"] = df["category_name"].str.lower().str.replace(" ", "_")

    # 3. Add a rank column across all categories (top product overall)
    df["overall_rank"] = df["rating"].rank(ascending=False, method="dense").astype(int)

    # 4. Print the transformed DataFrame
    print("\n🔍 After transformation:")
    print(df.head())

    # Save as a new file
    df.to_csv("top_products_transformed.csv", index=False)
    print("📄 Saved transformed data to top_products_transformed.csv")

    # Close the psycopg2 connection
    conn.close()

    # === Load Step: Write transformed DataFrame back into PostgreSQL ===
    try:
        engine = create_engine("postgresql+psycopg2://postgres:postgres@localhost:5433/dec")

        # Write DataFrame to SQL (replace old table if it exists)
        df.to_sql("top_products_transformed", engine, index=False, if_exists="replace")

        print("🗄️  Transformed data loaded into PostgreSQL table: top_products_transformed")

    except Exception as e:
        print("❌ Load step failed:", e)

except Exception as e:
    print("❌ Error:", e)