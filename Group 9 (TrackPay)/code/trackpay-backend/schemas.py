from pydantic import BaseModel


# User Registration Input
class UserCreate(BaseModel):
    name: str
    phone: str
    pin: str


# User Login Input
class UserLogin(BaseModel):
    phone: str
    pin: str


# User Response Output
class UserResponse(BaseModel):
    id: int
    name: str
    phone: str

    class Config:
        from_attributes = True

# Category Create Input
class CategoryCreate(BaseModel):
    user_id: int
    name: str
    icon: str | None = "📁"   # ✅ NEW
    total_budget: float


# Basic Category Response (for create/edit/detail)
class CategoryResponse(BaseModel):
    id: int
    name: str
    icon: str
    total_budget: float
    remaining_budget: float


# Dashboard Category Response (includes used_percent)
class CategoryDashboardResponse(CategoryResponse):
    used_percent: float


# Payment Input
class PaymentCreate(BaseModel):
    user_id: int
    bank_id: int
    category_id: int
    receiver_name: str
    amount: float
    pin: str
    override: bool = False

# Payment Response
class PaymentResponse(BaseModel):
    message: str
    transaction_id: int
    remaining_budget: float

from datetime import datetime


# Transaction Output Schema
class TransactionResponse(BaseModel):
    id: int
    receiver_name: str
    amount: float
    transaction_type: str
    timestamp: datetime

    bank_name: str | None
    category_name: str | None

    class Config:
        from_attributes = True

# Bank Account Input
class BankCreate(BaseModel):
    user_id: int
    bank_name: str
    account_number: str
    balance: float


# Bank Account Output
class BankResponse(BaseModel):
    id: int
    user_id: int
    bank_name: str
    account_number: str
    balance: float

    class Config:
        from_attributes = True

# Update Category Budget Input
class BudgetUpdate(BaseModel):
    new_total_budget: float

# Bank Deposit Input
class BankDeposit(BaseModel):
    user_id: int
    bank_id: int
    amount: float

from pydantic import BaseModel

class CategoryEmojiUpdate(BaseModel):
    icon: str