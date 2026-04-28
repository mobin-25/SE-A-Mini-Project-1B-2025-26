import asyncio
import asyncpg
import hashlib
import os

async def main():
    conn = await asyncpg.connect(
        host="localhost", port=5432,
        database="uniaccess", user="postgres",
        password=os.getenv("DB_PASS", "admin123"))
    pw = hashlib.sha256("admin123".encode()).hexdigest()
    try:
        await conn.execute(
            "INSERT INTO users(username,password,is_admin) VALUES($1,$2,$3)",
            "admin", pw, True)
        print("✅ Admin created — username: admin  password: admin123")
    except asyncpg.UniqueViolationError:
        print("ℹ️  Admin already exists — username: admin  password: admin123")
    await conn.close()

asyncio.run(main())