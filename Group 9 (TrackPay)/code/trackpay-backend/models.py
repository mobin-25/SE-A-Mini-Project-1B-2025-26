from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime

from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    phone = Column(String, unique=True)

    pin = Column(String, nullable=False)

from sqlalchemy import Float, ForeignKey
from sqlalchemy.orm import relationship


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    name = Column(String, nullable=False)

    icon = Column(String, default="📁")

    total_budget = Column(Float, nullable=False)

    remaining_budget = Column(Float, nullable=False)

    # Relationship
    user = relationship("User")

from sqlalchemy import Boolean


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    # NEW: bank_id added
    bank_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=True)

    # category can be NULL for credit transactions
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)

    receiver_name = Column(String, nullable=False)

    amount = Column(Float, nullable=False)

    # NEW: CREDIT or DEBIT
    transaction_type = Column(String, default="DEBIT")

    override_used = Column(Boolean, default=False)

    timestamp = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    category = relationship("Category")
    

class BankAccount(Base):
    __tablename__ = "bank_accounts"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"))

    bank_name = Column(String, nullable=False)

    account_number = Column(String, unique=True, nullable=False)

    balance = Column(Float, default=0)

    user = relationship("User")
