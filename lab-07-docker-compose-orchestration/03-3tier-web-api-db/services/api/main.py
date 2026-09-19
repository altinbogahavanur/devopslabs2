import os
import json
import time
from fastapi import FastAPI, HTTPException
import redis
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(title="Microservice Product Catalog")

# 12-Factor: Konfigürasyon tamamen ortam değişkenlerinden okunur
DB_HOST = os.getenv("POSTGRES_HOST", "db")
DB_USER = os.getenv("POSTGRES_USER", "appuser")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "BilgincIT454")
DB_NAME = os.getenv("POSTGRES_DB", "productdb")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")

REDIS_HOST = os.getenv("REDIS_HOST", "cache")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        dbname=DB_NAME,
        port=DB_PORT
    )

def get_redis_client():
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True)

@app.on_event("startup")
def startup_db():
    retries = 10
    while retries > 0:
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR(100) NOT NULL,
                    price NUMERIC(10, 2) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            conn.commit()
            cur.close()
            conn.close()
            print("PostgreSQL veritabanı tablosu hazır.")
            break
        except Exception as e:
            print(f"Veritabanı henüz hazır değil, bekleniyor: {e}")
            retries -= 1
            time.sleep(2)

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "Product Catalog API (Compose Stack)",
        "architecture": "Nginx Proxy -> FastAPI -> Redis Cache -> PostgreSQL DB"
    }

@app.get("/health")
@app.get("/healthz")
@app.get("/api/health")
def healthz():
    return {"status": "healthy"}

@app.get("/products")
@app.get("/api/v1/products")
def list_products():
    r = get_redis_client()
    cached = r.get("all_products")
    if cached:
        return {"source": "redis_cache", "data": json.loads(cached)}

    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT id, title, price, created_at FROM products;")
    products = cur.fetchall()
    cur.close()
    conn.close()

    # Redis'e 30 saniyelik cache ekle
    # datetime nesnelerini str formatına çevir
    serialized = []
    for p in products:
        item = dict(p)
        item["created_at"] = str(item["created_at"])
        item["price"] = float(item["price"])
        serialized.append(item)

    r.setex("all_products", 30, json.dumps(serialized))
    return {"source": "postgresql_database", "data": serialized}

@app.post("/products")
@app.post("/api/v1/products")
def create_product(title: str, price: float):
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("INSERT INTO products (title, price) VALUES (%s, %s) RETURNING id, title, price;", (title, price))
    new_product = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    # Cache'i geçersiz kıl
    r = get_redis_client()
    r.delete("all_products")

    item = dict(new_product)
    item["price"] = float(item["price"])
    return {"message": "Ürün eklendi", "product": item}
