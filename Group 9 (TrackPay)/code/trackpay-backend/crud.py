from sqlalchemy.orm import Session
from models import User
from schemas import UserCreate
from schemas import CategoryCreate
from schemas import PaymentCreate
from models import BankAccount
from schemas import BankCreate
from schemas import BankDeposit
from models import Category

# Register New User
def create_user(db: Session, user: UserCreate):

    # Step 1: Create user
    new_user = User(
        name=user.name,
        phone=user.phone,
        pin=user.pin
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Step 2: Automatically create default "Other" category
    default_category = Category(
        user_id=new_user.id,
        name="Other",
        total_budget=999999,
        remaining_budget=999999
    )

    db.add(default_category)
    db.commit()

    return new_user


# Login User
def authenticate_user(db: Session, phone: str, pin: str):
    user = db.query(User).filter(User.phone == phone).first()

    if user is None:
        return None

    if user.pin != pin:
        return None

    return user


# Create Category
def create_category(db: Session, category: CategoryCreate):

    new_cat = Category(
        user_id=category.user_id,
        name=category.name,
        icon=category.icon,   # ✅ NEW
        total_budget=category.total_budget,
        remaining_budget=category.total_budget
    )

    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)

    return new_cat


# Get All Categories for Dashboard (with used_percent)
def get_categories_by_user(db: Session, user_id: int):

    categories = db.query(Category).filter(Category.user_id == user_id).all()

    result = []

    for cat in categories:
        spent = cat.total_budget - cat.remaining_budget

        if cat.total_budget > 0:
            used_percent = (spent / cat.total_budget) * 100
        else:
            used_percent = 0

        result.append({
            "id": cat.id,
            "name": cat.name,
            "icon": cat.icon,
            "total_budget": cat.total_budget,
            "remaining_budget": cat.remaining_budget,
            "used_percent": round(used_percent, 1)
        })

    return result


# Get Single Category Detail
def get_category_detail(db: Session, category_id: int):
    return db.query(Category).filter(Category.id == category_id).first()

from models import Transaction


# Payment Logic (Core TrackPay Feature)
def make_payment(db: Session, payment: PaymentCreate):

    # Step 0: Authenticate PIN
    user = db.query(User).filter(User.id == payment.user_id).first()

    if not user or user.pin != payment.pin:
        return {"error": "Invalid PIN"}

    # Step 1: Get Bank Account
    bank = db.query(BankAccount).filter(BankAccount.id == payment.bank_id).first()

    if not bank:
        return {"error": "Bank account not found"}

    # Step 2: Check Balance
    if payment.amount > bank.balance:
        return {
            "blocked": True,
            "message": "Insufficient bank balance!"
        }

    # Step 3: Get Category
    category = db.query(Category).filter(Category.id == payment.category_id).first()

    if not category:
        return {"error": "Category not found"}

    # Step 4: Budget Validation
    if payment.amount > category.remaining_budget:
        if not payment.override:
            return {
                "blocked": True,
                "message": "Budget exceeded! Override required."
            }

    # Step 5: Deduct balance + budget
    bank.balance -= payment.amount
    category.remaining_budget -= payment.amount

    # Step 6: Save transaction
    new_txn = Transaction(
    user_id=payment.user_id,
    bank_id=payment.bank_id,   # ✅ Added
    category_id=payment.category_id,
    receiver_name=payment.receiver_name,
    amount=payment.amount,
    transaction_type="DEBIT",  # ✅ Payment is DEBIT
    override_used=payment.override
)


    db.add(new_txn)
    db.commit()
    db.refresh(new_txn)

    return {
        "blocked": False,
        "transaction": new_txn,
        "remaining_budget": category.remaining_budget,
        "bank_balance": bank.balance
    }

# ✅ Global Transaction History (Like GPay)
def get_transactions_by_user(db: Session, user_id: int):

    txns = (
        db.query(Transaction)
        .filter(Transaction.user_id == user_id)
        .order_by(Transaction.timestamp.desc())
        .all()
    )

    result = []

    for txn in txns:
        bank = None
        category = None

        if txn.bank_id:
            bank_obj = db.query(BankAccount).filter(
                BankAccount.id == txn.bank_id
            ).first()
            bank = bank_obj.bank_name if bank_obj else None

        if txn.category_id:
            cat_obj = db.query(Category).filter(
                Category.id == txn.category_id
            ).first()
            category = cat_obj.name if cat_obj else None

        result.append({
            "id": txn.id,
            "receiver_name": txn.receiver_name,
            "amount": txn.amount,
            "transaction_type": txn.transaction_type,
            "timestamp": txn.timestamp,
            "bank_name": bank,
            "category_name": category
        })

    return result


# ✅ Category-wise Transaction History
def get_transactions_by_category(db: Session, category_id: int):

    txns = (
        db.query(Transaction)
        .filter(Transaction.category_id == category_id)
        .order_by(Transaction.timestamp.desc())
        .all()
    )

    result = []

    for txn in txns:

        # Bank Name
        bank_name = None
        if txn.bank_id:
            bank = db.query(BankAccount).filter(
                BankAccount.id == txn.bank_id
            ).first()
            bank_name = bank.bank_name if bank else None

        # Category Name
        category_name = None
        if txn.category_id:
            category = db.query(Category).filter(
                Category.id == txn.category_id
            ).first()
            category_name = category.name if category else None

        result.append({
            "id": txn.id,
            "receiver_name": txn.receiver_name,
            "amount": txn.amount,
            "transaction_type": txn.transaction_type,
            "timestamp": txn.timestamp,
            "bank_name": bank_name,
            "category_name": category_name
        })

    return result


# ✅ Spending Summary (Dashboard Analytics)
def get_summary(db: Session, user_id: int):

    categories = get_categories_by_user(db, user_id)

    summary = []

    for cat in categories:
        spent = cat.total_budget - cat.remaining_budget

        summary.append({
            "category": cat.name,
            "total_budget": cat.total_budget,
            "spent": spent,
            "remaining": cat.remaining_budget
        })

    return summary

# ✅ Create Bank Account
def create_bank(db: Session, bank: BankCreate):

    new_bank = BankAccount(
        user_id=bank.user_id,
        bank_name=bank.bank_name,
        account_number=bank.account_number,
        balance=bank.balance
    )

    db.add(new_bank)
    db.commit()
    db.refresh(new_bank)

    return new_bank

# ✅ List Banks for User
def get_banks_by_user(db: Session, user_id: int):
    return db.query(BankAccount).filter(BankAccount.user_id == user_id).all()

def update_category_budget(db: Session, category_id: int, new_budget: float):

    category = db.query(Category).filter(Category.id == category_id).first()

    if not category:
        return None

    # Calculate already spent
    spent = category.total_budget - category.remaining_budget

    # Update total budget
    category.total_budget = new_budget

    # Recalculate remaining correctly
    category.remaining_budget = new_budget - spent

    db.commit()
    db.refresh(category)

    return category

# reset budget
def reset_monthly_budgets(db: Session, user_id: int):

    categories = db.query(Category).filter(Category.user_id == user_id).all()

    for cat in categories:
        cat.remaining_budget = cat.total_budget

    db.commit()

    return categories

def deposit_money(db: Session, data: BankDeposit):

    # Step 1: Find bank account
    bank = db.query(BankAccount).filter(BankAccount.id == data.bank_id).first()

    if not bank:
        return None

    # Step 2: Add money
    bank.balance += data.amount

    # Step 3: Save CREDIT transaction
    txn = Transaction(
        user_id=data.user_id,
        bank_id=data.bank_id,
        category_id=None,
        receiver_name="Bank Deposit",
        amount=data.amount,
        transaction_type="CREDIT",
        override_used=False
    )

    db.add(txn)
    db.commit()
    db.refresh(txn)

    return txn

def delete_category(db: Session, category_id: int):

    # Step 1: Find category
    category = db.query(Category).filter(Category.id == category_id).first()

    if not category:
        return None

    # Step 2: Keep transactions, just remove category link
    transactions = db.query(Transaction).filter(
        Transaction.category_id == category_id
    ).all()

    for txn in transactions:
        txn.category_id = None

    # Step 3: Delete category folder
    db.delete(category)
    db.commit()

    return True

def delete_bank_account(db: Session, bank_id: int):

    # Step 1: Find bank account
    bank = db.query(BankAccount).filter(BankAccount.id == bank_id).first()

    if not bank:
        return None

    # Step 2: Keep transactions, remove bank link
    transactions = db.query(Transaction).filter(
        Transaction.bank_id == bank_id
    ).all()

    for txn in transactions:
        txn.bank_id = None

    # Step 3: Delete bank account
    db.delete(bank)
    db.commit()

    return True

from datetime import datetime, timedelta


def get_dashboard_insights(db: Session, user_id: int):

    insights = {
        "warnings": [],
        "trend": "",
        "savings_message": ""
    }

    # -----------------------------
    # 1. Budget Usage Warnings
    # -----------------------------
    categories = db.query(Category).filter(Category.user_id == user_id).all()

    for cat in categories:
        spent = cat.total_budget - cat.remaining_budget

        if cat.total_budget > 0:
            used_percent = (spent / cat.total_budget) * 100

            if used_percent >= 40:
                insights["warnings"].append(
                    f"{cat.name} budget used {used_percent:.0f}%"
                )

    # -----------------------------
    # 2. Spending Trend (Month Compare)
    # -----------------------------
    now = datetime.utcnow()
    last_30_days = now - timedelta(days=30)
    prev_30_days = now - timedelta(days=60)

    # Current month spending
    current_txns = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.transaction_type == "DEBIT",
        Transaction.timestamp >= last_30_days
    ).all()

    current_spent = sum(t.amount for t in current_txns)

    # Previous month spending
    previous_txns = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.transaction_type == "DEBIT",
        Transaction.timestamp >= prev_30_days,
        Transaction.timestamp < last_30_days
    ).all()

    previous_spent = sum(t.amount for t in previous_txns)

    if previous_spent > 0:
        change = ((current_spent - previous_spent) / previous_spent) * 100

        if change > 0:
            insights["trend"] = f"Spending increased by {change:.0f}% compared to last month"
        else:
            insights["trend"] = f"Spending decreased by {abs(change):.0f}% compared to last month"
    else:
        insights["trend"] = "Not enough previous month data"

    # -----------------------------
    # 3. Savings Message
    # -----------------------------
    total_budget = sum(c.total_budget for c in categories)
    total_remaining = sum(c.remaining_budget for c in categories)

    total_spent = total_budget - total_remaining

    if total_spent < total_budget:
        insights["savings_message"] = "Great! You are under budget this month 🎉"
    else:
        insights["savings_message"] = "You have exceeded your total budget ⚠️"

    return insights

def update_category_emoji(db: Session, category_id: int, new_icon: str):
    category = db.query(Category).filter(Category.id == category_id).first()

    if not category:
        return None

    category.icon = new_icon
    db.commit()
    db.refresh(category)

    return category

from sqlalchemy import func
from datetime import datetime

def get_category_spending(db, user_id: int):
    try:
        current_month = datetime.now().month
        current_year = datetime.now().year

        results = (
            db.query(
                Category.name,
                func.sum(Transaction.amount).label("total")
            )
            .join(
                Transaction,
                (Transaction.category_id == Category.id)
            )
            .filter(
                Category.user_id == user_id,
                Transaction.transaction_type == "DEBIT",
                Transaction.category_id != None,
                Transaction.amount != None
            )
            .group_by(Category.name)
            .all()
        )

        return [
            {"name": name or "Other", "amount": float(total or 0)}
            for name, total in results
        ]

    except Exception as e:
        print("ERROR in get_category_spending:", e)
        return []
    
from sqlalchemy import func
from datetime import datetime

# =========================
# 📈 Spending Trend
# =========================
def get_spending_trend(db, user_id: int):
    try:
        current_month = datetime.now().month

        total = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.transaction_type == "DEBIT"
        ).scalar() or 0

        return f"You spent ₹{int(total)} this month"

    except Exception as e:
        print("Trend Error:", e)
        return ""


# =========================
# 💰 Savings Message
# =========================
def get_savings_message(db, user_id: int):
    try:
        total_budget = db.query(func.sum(Category.total_budget)).filter(
            Category.user_id == user_id
        ).scalar() or 0

        total_spent = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.transaction_type == "DEBIT"
        ).scalar() or 0

        if total_budget == 0:
            return "No budget set"

        if total_spent < total_budget:
            return f"You saved ₹{int(total_budget - total_spent)} 🎉"
        else:
            return "Budget exceeded ⚠️"

    except Exception as e:
        print("Savings Error:", e)
        return ""
    
def get_budget_warnings(db, user_id: int):
    try:
        categories = db.query(Category).filter(
            Category.user_id == user_id
        ).all()

        warnings = []

        for cat in categories:
            if cat.total_budget and cat.total_budget > 0:
                spent = cat.total_budget - (cat.remaining_budget or 0)

                percent = (spent / cat.total_budget) * 100

                if percent >= 40:
                    warnings.append(
                        f"{cat.name} budget used {int(percent)}%"
                    )

        return warnings

    except Exception as e:
        print("Warning Error:", e)
        return []