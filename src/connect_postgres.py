import psycopg2

# Connection details - must match your docker/.env
conn_params = {
    "host": "localhost",      # or 127.0.0.1
    "port": "5433",           # your docker port mapping
    "dbname": "dec",
    "user": "postgres",
    "password": "postgres"
}

try:
    # Establish connection
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()

    # Simple test query
    cur.execute("SELECT COUNT(*) FROM products;")
    result = cur.fetchone()
    print(f"✅ Connection successful! Products count: {result[0]}")

    # Close everything cleanly
    cur.close()
    conn.close()

except Exception as e:
    print("❌ Connection failed:", e)