from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Step 1: PostgreSQL connection URL
DATABASE_URL = "postgresql://postgres:jannat13@localhost:5432/trackpay_db"

# Step 2: Create engine (connect FastAPI to PostgreSQL)
engine = create_engine(DATABASE_URL)

# Step 3: Session maker (used to run queries)
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Step 4: Base class for all models/tables
Base = declarative_base()
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
