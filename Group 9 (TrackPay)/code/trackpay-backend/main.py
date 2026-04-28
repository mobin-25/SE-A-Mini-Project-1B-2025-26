from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session

from database import engine, get_db
from models import Base
from schemas import UserCreate, UserLogin, UserResponse
import crud
from schemas import CategoryCreate, CategoryResponse
from models import Category
from schemas import PaymentCreate, PaymentResponse
from schemas import TransactionResponse
from schemas import BankCreate, BankResponse
from schemas import BudgetUpdate
from schemas import BankDeposit
from schemas import CategoryDashboardResponse

app = FastAPI(title="TrackPay Backend")

# Create tables
Base.metadata.create_all(bind=engine)


@app.get("/")
def root():
    return {"message": "TrackPay backend running with APIs"}


# ✅ Register API
@app.post("/register", response_model=UserResponse)
def register_user(user: UserCreate, db: Session = Depends(get_db)):

    # Check if phone already exists
    from models import User
    existing = db.query(User).filter(User.phone == user.phone).first()

    if existing:
        raise HTTPException(status_code=400, detail="Phone already registered")

    return crud.create_user(db, user)


# ✅ Login API
@app.post("/login")
def login_user(login: UserLogin, db: Session = Depends(get_db)):

    user = crud.authenticate_user(db, login.phone, login.pin)

    if not user:
        raise HTTPException(status_code=401, detail="Invalid phone or PIN")

    return {"message": "Login successful", "user_id": user.id}

# ✅ Category API
@app.post("/categories", response_model=CategoryResponse)
def create_category(category: CategoryCreate, db: Session = Depends(get_db)):
    return crud.create_category(db, category)

# ✅ List Categories (Dashboard)
@app.get("/categories/{user_id}", response_model=list[CategoryDashboardResponse])
def list_categories(user_id: int, db: Session = Depends(get_db)):
    return crud.get_categories_by_user(db, user_id)

# ✅ Category Detail Screen API
@app.get("/category/{category_id}", response_model=CategoryResponse)
def category_detail(category_id: int, db: Session = Depends(get_db)):

    category = crud.get_category_detail(db, category_id)

    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    return category

# ✅ Edit Budget API
@app.put("/category/{category_id}/budget", response_model=CategoryResponse)
def edit_budget(
    category_id: int,
    budget: BudgetUpdate,
    db: Session = Depends(get_db)
):
    updated = crud.update_category_budget(db, category_id, budget.new_total_budget)

    if not updated:
        raise HTTPException(status_code=404, detail="Category not found")

    return updated

# ✅ Payment API
@app.post("/pay")
def pay(payment: PaymentCreate, db: Session = Depends(get_db)):

    result = crud.make_payment(db, payment)

    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    if result["blocked"]:
        raise HTTPException(status_code=400, detail=result["message"])

    txn = result["transaction"]

    return {
        "message": "Payment successful",
        "transaction_id": txn.id,
        "remaining_budget": result["remaining_budget"],
        "bank_balance": result["bank_balance"]
    }

# ✅ API 1: Full Transaction History (GPay Style)
@app.get("/transactions/{user_id}", response_model=list[TransactionResponse])
def transaction_history(user_id: int, db: Session = Depends(get_db)):
    return crud.get_transactions_by_user(db, user_id)

# ✅ API 2: Category Folder History
@app.get("/transactions/category/{category_id}", response_model=list[TransactionResponse])
def category_transactions(category_id: int, db: Session = Depends(get_db)):
    return crud.get_transactions_by_category(db, category_id)

# ✅ API 3: Category Budget Summary
@app.get("/summary/{user_id}")
def user_summary(user_id: int, db: Session = Depends(get_db)):
    return {
        "user_id": user_id,
        "category_summary": crud.get_summary(db, user_id)
    }

# ✅ Add Bank Account
@app.post("/banks", response_model=BankResponse)
def add_bank(bank: BankCreate, db: Session = Depends(get_db)):
    return crud.create_bank(db, bank)

# ✅ List Banks (Dashboard Bank Section)
@app.get("/banks/{user_id}", response_model=list[BankResponse])
def list_banks(user_id: int, db: Session = Depends(get_db)):
    return crud.get_banks_by_user(db, user_id)

# ✅ budget reset
@app.post("/reset-budgets/{user_id}")
def reset_budgets(user_id: int, db: Session = Depends(get_db)):

    categories = crud.reset_monthly_budgets(db, user_id)

    return {
        "message": "Monthly budgets reset successfully",
        "categories_reset": len(categories)
    }

@app.post("/bank/deposit")
def deposit_money(data: BankDeposit, db: Session = Depends(get_db)):

    txn = crud.deposit_money(db, data)

    if not txn:
        raise HTTPException(status_code=404, detail="Bank account not found")

    return {
        "message": "Money added successfully",
        "transaction_id": txn.id,
        "amount_added": txn.amount
    }

@app.delete("/category/{category_id}")
def remove_category(category_id: int, db: Session = Depends(get_db)):

    result = crud.delete_category(db, category_id)

    if not result:
        raise HTTPException(status_code=404, detail="Category not found")

    return {"message": "Category deleted successfully (transactions kept)"}

@app.delete("/bank/{bank_id}")
def remove_bank(bank_id: int, db: Session = Depends(get_db)):

    result = crud.delete_bank_account(db, bank_id)

    if not result:
        raise HTTPException(status_code=404, detail="Bank account not found")

    return {"message": "Bank account deleted successfully (transactions kept)"}

@app.get("/insights/{user_id}")
def get_insights(user_id: int, db: Session = Depends(get_db)):

    warnings = crud.get_budget_warnings(db, user_id)
    trend = crud.get_spending_trend(db, user_id)
    savings = crud.get_savings_message(db, user_id)
    category_spending = crud.get_category_spending(db, user_id)

    return {
        "warnings": warnings,
        "trend": trend,
        "savings_message": savings,
        "category_spending": category_spending
    }

from schemas import CategoryEmojiUpdate

@app.put("/category/{category_id}/emoji")
def update_category_emoji_api(
    category_id: int,
    emoji_data: CategoryEmojiUpdate,
    db: Session = Depends(get_db)
):
    updated = crud.update_category_emoji(
        db,
        category_id,
        emoji_data.icon
    )

    if not updated:
        raise HTTPException(status_code=404, detail="Category not found")

    return {"message": "Emoji updated successfully"}