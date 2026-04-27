from app_v2 import app
from models import db, User, Notification

with app.app_context():
    # Manually insert a notification for all users
    users = User.query.all()
    for user in users:
        notif = Notification(
            user_id=user.id,
            title="Admin Notification",
            message="Scholarship counter will be closed at 3PM today.",
            type="admin_message"
        )
        db.session.add(notif)
    db.session.commit()
    print(f"Notification added for {len(users)} users!")