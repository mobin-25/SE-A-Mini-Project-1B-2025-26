from app import app
from models import User

with app.app_context():
    users = User.query.all()
    print("\n--- USER DEVICE TOKEN CHECK ---")
    for u in users:
        status = "✅ HAS TOKEN" if u.device_token else "❌ NO TOKEN (Notifications will fail)"
        print(f"ID: {u.student_id} | Name: {u.name} | {status}")
    print("--------------------------------\n")