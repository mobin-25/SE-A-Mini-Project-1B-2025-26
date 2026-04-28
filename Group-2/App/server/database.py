import asyncpg
import os

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "uniaccess")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "admin123")

pool = None

CREATE_TABLES = """
CREATE TABLE IF NOT EXISTS users (
    username   TEXT PRIMARY KEY,
    password   TEXT NOT NULL,
    is_admin   BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS clients (
    username   TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,
    ip         TEXT DEFAULT '',
    files_sent INT DEFAULT 0,
    packets    BIGINT DEFAULT 0,
    ping       INT DEFAULT 0,
    is_blocked BOOLEAN DEFAULT FALSE,
    is_flooder BOOLEAN DEFAULT FALSE,
    last_seen  TIMESTAMP DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS logs (
    id         SERIAL PRIMARY KEY,
    time       TIMESTAMP DEFAULT NOW(),
    source_ip  TEXT DEFAULT '',
    dest_ip    TEXT DEFAULT 'SERVER',
    protocol   TEXT DEFAULT '',
    length     INT DEFAULT 0,
    info       TEXT DEFAULT '',
    username   TEXT DEFAULT ''
);
"""

async def init_db():
    global pool
    pool = await asyncpg.create_pool(
        host=DB_HOST, port=int(DB_PORT),
        database=DB_NAME, user=DB_USER, password=DB_PASS,
        min_size=2, max_size=10)
    async with pool.acquire() as conn:
        await conn.execute(CREATE_TABLES)
    print("✅ Database connected and tables ready")

async def close_db():
    if pool:
        await pool.close()

async def get_user(username: str):
    async with pool.acquire() as conn:
        return await conn.fetchrow("SELECT * FROM users WHERE username=$1", username)

async def create_user(username: str, password: str, is_admin: bool = False):
    async with pool.acquire() as conn:
        try:
            await conn.execute(
                "INSERT INTO users(username,password,is_admin) VALUES($1,$2,$3)",
                username, password, is_admin)
            return True
        except asyncpg.UniqueViolationError:
            return False

async def upsert_client(username: str, ip: str = "", is_flooder: bool = False):
    async with pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO clients(username,ip,is_flooder)
            VALUES($1,$2,$3)
            ON CONFLICT(username) DO UPDATE
            SET ip=EXCLUDED.ip, is_flooder=EXCLUDED.is_flooder, last_seen=NOW()
        """, username, ip, is_flooder)

async def get_all_clients():
    async with pool.acquire() as conn:
        return await conn.fetch("SELECT * FROM clients ORDER BY username")

async def get_client(username: str):
    async with pool.acquire() as conn:
        return await conn.fetchrow("SELECT * FROM clients WHERE username=$1", username)

async def set_client_blocked(username: str, blocked: bool):
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE clients SET is_blocked=$2 WHERE username=$1", username, blocked)

async def update_flooder_flag(username: str, flag: bool):
    async with pool.acquire() as conn:
        await conn.execute(
            "UPDATE clients SET is_flooder=$2 WHERE username=$1", username, flag)

async def update_client_full(username: str, files: int, packets: int, ping: int):
    async with pool.acquire() as conn:
        await conn.execute("""
            UPDATE clients SET files_sent=$2, packets=$3, ping=$4, last_seen=NOW()
            WHERE username=$1
        """, username, files, packets, ping)

async def insert_log(source_ip: str, protocol: str, length: int,
                     info: str, username: str = ""):
    async with pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO logs(source_ip,protocol,length,info,username)
            VALUES($1,$2,$3,$4,$5)
        """, source_ip, protocol, length, info, username)

async def get_recent_logs(limit: int = 100):
    async with pool.acquire() as conn:
        return await conn.fetch(
            "SELECT * FROM logs ORDER BY id DESC LIMIT $1", limit)

async def get_all_logs():
    async with pool.acquire() as conn:
        return await conn.fetch("SELECT * FROM logs ORDER BY id ASC")