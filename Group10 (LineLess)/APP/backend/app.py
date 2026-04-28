from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
from config import config
from models import db, User, Admin, Service, Token, Notification
from notifications import init_notification_service, get_notification_service
import os

# Initialize Flask app
app = Flask(__name__)

# Load configuration
env = os.environ.get('FLASK_ENV', 'development')
app.config.from_object(config[env])

# Initialize extensions
CORS(app)
db.init_app(app)

# Initialize notification service

# Token counter (for generating unique token IDs)
# --- TOKEN COUNTER FIX ---
token_counter = 88290

def sync_token_counter():
    """Initializes the global token_counter based on the highest ID in the database"""
    global token_counter
    # Pulls 'LL' from your config.py
    prefix = app.config.get('TOKEN_PREFIX', 'LL')
    try:
        # Get the latest token issued
        latest_token = Token.query.order_by(Token.id.desc()).first()
        if latest_token and latest_token.token_id:
            # Splits "LL-88291" into ["LL", "88291"]
            parts = latest_token.token_id.split('-')
            if len(parts) > 1 and parts[1].isdigit():
                db_value = int(parts[1])
                # Set counter to the higher value (DB or Default)
                token_counter = max(token_counter, db_value)
                print(f"[*] Token counter synced from DB to: {token_counter}")
    except Exception as e:
        print(f"[!] Warning: Could not sync token counter: {e}")


def update_queue_positions(service_id):
    """Update queue positions for all active tokens of a service"""
    try:
        active_tokens = Token.query.filter_by(
            service_id=service_id,
            status='ACTIVE'
        ).order_by(Token.created_at).all()

        notification_service = get_notification_service()

        for idx, token in enumerate(active_tokens):
            old_position = token.queue_position
            new_position = idx + 1
            token.queue_position = new_position

            # Send notification only if service is available and position changed
            try:
                if (notification_service and
                        old_position != new_position and
                        token.user and
                        token.user.device_token):
                    notification_service.send_queue_update(
                        token.user.device_token,
                        token.service.name,
                        new_position
                    )
            except Exception as notif_err:
                print(f"[WARN] Notification failed for token {token.token_id}: {notif_err}")

        db.session.commit()
    except Exception as e:
        print(f"[ERROR] update_queue_positions failed: {e}")
        db.session.rollback()


# ==================== INITIALIZATION ====================

# Tables are created at startup (see __main__ block below)
# Initialize notification service and sync counter on startup
with app.app_context():
    db.create_all() # Keep your existing lines
    init_notification_service(app.config.get('FIREBASE_CREDENTIALS_PATH')) # Keep your existing lines
    sync_token_counter() # <--- ADD THIS LINE HERE

@app.cli.command('init-db')
def init_db():
    """Initialize database with default data"""
    db.create_all()
    
    # Create default services
    services_data = [
        {"name": "Scholarships", "description": "Apply for merit & need-based grants", "icon": "school"},
        {"name": "Train Concessions", "description": "Monthly railway pass verification", "icon": "train"},
        {"name": "Visa Letters", "description": "Request official bonafide docs", "icon": "description"},
        {"name": "Fee Waiver", "description": "Financial aid documentation", "icon": "payments"},
    ]
    
    for service_data in services_data:
        if not Service.query.filter_by(name=service_data['name']).first():
            service = Service(**service_data)
            db.session.add(service)
    
    # Create default admin
    if not Admin.query.filter_by(email='admin@apsit.edu.in').first():
        admin = Admin(
            email='admin@apsit.edu.in',
            name='Admin User'
        )
        admin.set_password('admin123')
        db.session.add(admin)
    
    # Create demo student users (optional - for testing)
    demo_users = [
        {"student_id": "24107095", "name": "Nikhil Sharma", "email": "nikhil@student.edu", "pin": "123456"},
        {"student_id": "24107096", "name": "Priya Patel", "email": "priya@student.edu", "pin": "654321"},
    ]
    
    for user_data in demo_users:
        if not User.query.filter_by(student_id=user_data['student_id']).first():
            user = User(
                student_id=user_data['student_id'],
                name=user_data['name'],
                email=user_data['email']
            )
            user.set_pin(user_data['pin'])
            db.session.add(user)
    
    db.session.commit()
    print("Database initialized successfully!")


# ==================== AUTHENTICATION ====================

@app.route('/register', methods=['POST'])
def register():
    """Register a new student user"""
    data = request.json
    
    # Validate required fields
    required_fields = ['student_id', 'name', 'email', 'pin']
    for field in required_fields:
        if not data.get(field):
            return jsonify({"success": False, "message": f"Missing field: {field}"}), 400
    
    # Check if student_id already exists
    if User.query.filter_by(student_id=data['student_id']).first():
        return jsonify({"success": False, "message": "Student ID already registered"}), 400
    
    # Check if email already exists
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"success": False, "message": "Email already registered"}), 400
    
    # Validate student ID format (8 digits)
    if len(data['student_id']) != 8 or not data['student_id'].isdigit():
        return jsonify({"success": False, "message": "Student ID must be 8 digits"}), 400
    
    # Validate PIN (6 digits)
    if len(data['pin']) != 6 or not data['pin'].isdigit():
        return jsonify({"success": False, "message": "PIN must be 6 digits"}), 400
    
    # Create new user
    user = User(
        student_id=data['student_id'],
        name=data['name'],
        email=data['email'],
        phone=data.get('phone'),
        role='student'
    )
    user.set_pin(data['pin'])
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify({
        "success": True,
        "message": "Registration successful",
        "user": user.to_dict()
    }), 201


@app.route('/login', methods=['POST'])
def login():
    """Student login"""
    data = request.json
    student_id = data.get('student_id')
    pin = data.get('pin')
    
    if not student_id or not pin:
        return jsonify({"success": False, "message": "Missing credentials"}), 400
    
    user = User.query.filter_by(student_id=student_id).first()
    
    if user and user.check_pin(pin):
        # Update device token if provided
        if data.get('device_token'):
            user.device_token = data['device_token']
            db.session.commit()
        
        # Return student_id as 'id' for Flutter compatibility
        return jsonify({
            "success": True,
            "user": {
                "id": user.student_id,  # Return student_id, not database id
                "name": user.name,
                "role": "student"
            }
        })
    
    return jsonify({"success": False, "message": "Invalid Student ID or PIN"}), 401


@app.route('/admin/login', methods=['POST'])
def admin_login():
    """Admin login"""
    data = request.json
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({"success": False, "message": "Missing credentials"}), 400
    
    admin = Admin.query.filter_by(email=email).first()
    
    if admin and admin.check_password(password):
        return jsonify({
            "success": True,
            "user": admin.to_dict()
        })
    
    return jsonify({"success": False, "message": "Invalid admin credentials"}), 401


# ==================== USER PROFILE ====================

@app.route('/profile/<int:user_id>', methods=['GET'])
def get_profile(user_id):
    """Get user profile"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404
    
    return jsonify({
        "success": True,
        "user": user.to_dict()
    })


@app.route('/profile/<int:user_id>', methods=['PUT'])
def update_profile(user_id):
    """Update user profile"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404
    
    data = request.json
    
    # Update allowed fields
    if 'name' in data:
        user.name = data['name']
    if 'email' in data:
        # Check if email is already taken by another user
        existing = User.query.filter_by(email=data['email']).first()
        if existing and existing.id != user_id:
            return jsonify({"success": False, "message": "Email already in use"}), 400
        user.email = data['email']
    if 'phone' in data:
        user.phone = data['phone']
    if 'device_token' in data:
        user.device_token = data['device_token']
    
    db.session.commit()
    
    return jsonify({
        "success": True,
        "message": "Profile updated successfully",
        "user": user.to_dict()
    })


@app.route('/profile/<int:user_id>/change-pin', methods=['POST'])
def change_pin(user_id):
    """Change user PIN"""
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404
    
    data = request.json
    old_pin = data.get('old_pin')
    new_pin = data.get('new_pin')
    
    if not old_pin or not new_pin:
        return jsonify({"success": False, "message": "Missing PIN data"}), 400
    
    # Verify old PIN
    if not user.check_pin(old_pin):
        return jsonify({"success": False, "message": "Incorrect current PIN"}), 401
    
    # Validate new PIN
    if len(new_pin) != 6 or not new_pin.isdigit():
        return jsonify({"success": False, "message": "New PIN must be 6 digits"}), 400
    
    # Set new PIN
    user.set_pin(new_pin)
    db.session.commit()
    
    return jsonify({
        "success": True,
        "message": "PIN changed successfully"
    })


# ==================== SERVICES ====================

@app.route('/services', methods=['GET'])
def get_services():
    """Get all active services with queue counts"""
    services = Service.query.filter_by(is_active=True).all()
    return jsonify({
        "services": [service.to_dict() for service in services]
    })


# ==================== TOKENS ====================

@app.route('/tokens', methods=['GET'])
def get_tokens():
    """Get tokens for a specific user"""
    student_id = request.args.get('student_id')
    
    if not student_id:
        return jsonify({"success": False, "message": "Missing student_id"}), 400
    
    user = User.query.filter_by(student_id=student_id).first()
    
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404
    
    tokens = Token.query.filter_by(user_id=user.id).order_by(Token.created_at.desc()).all()
    
    return jsonify({
        "tokens": [token.to_dict() for token in tokens]
    })


@app.route('/admin/tokens', methods=['GET'])
def get_all_tokens():
    """Get all tokens (admin only)"""
    tokens = Token.query.order_by(Token.created_at.desc()).all()
    
    return jsonify({
        "tokens": [token.to_dict() for token in tokens]
    })


@app.route('/admin/tokens/by-service', methods=['GET'])
def get_tokens_by_service():
    """Get all tokens grouped by service (admin only)"""
    services = Service.query.filter_by(is_active=True).all()
    
    result = []
    for service in services:
        service_tokens = Token.query.filter_by(service_id=service.id).order_by(Token.created_at.desc()).all()
        
        result.append({
            "service_name": service.name,
            "service_id": service.id,
            "total_tokens": len(service_tokens),
            "active_tokens": len([t for t in service_tokens if t.status == 'ACTIVE']),
            "tokens": [token.to_dict() for token in service_tokens]
        })
    
    return jsonify({
        "services": result
    })


@app.route('/tokens/<token_id>/remove', methods=['POST'])
def remove_token(token_id):
    """Remove/cancel token (admin can use this too)"""
    token = Token.query.filter_by(token_id=token_id).first()
    
    if not token:
        return jsonify({"success": False, "message": "Token not found"}), 404
    
    if token.status != 'ACTIVE':
        return jsonify({"success": False, "message": "Token is not active"}), 400
    
    token.status = 'CANCELLED'
    token.cancelled_at = datetime.utcnow()
    
    db.session.commit()
    
    # Update queue positions for this service
    update_queue_positions(token.service_id)
    
    return jsonify({"success": True, "message": "Token removed successfully"})


@app.route('/tokens', methods=['POST'])
def create_token():
    """Create a new token"""
    global token_counter
    
    data = request.json
    student_id = data.get('student_id')
    service_name = data.get('service_name')
    
    if not student_id or not service_name:
        return jsonify({"success": False, "message": "Missing required fields"}), 400
    
    # Get user
    user = User.query.filter_by(student_id=student_id).first()
    if not user:
        return jsonify({"success": False, "message": "User not found"}), 404
    
    # Get service
    service = Service.query.filter_by(name=service_name, is_active=True).first()
    if not service:
        return jsonify({"success": False, "message": "Service not found"}), 404
    
    # Check if user already has a token for this service
    existing_token = Token.query.filter_by(
        user_id=user.id,
        service_id=service.id,
        status='ACTIVE'
    ).first()
    
    if existing_token:
        return jsonify({
            "success": False,
            "message": f"You already have an active token for {service_name}. Please wait for it to be completed or cancel it first.",
            "error_type": "duplicate_service"
        }), 400
    
    # Check overall token limit (max 3 active tokens total)
    if not user.can_create_token():
        active_count = user.get_active_tokens_count()
        return jsonify({
            "success": False,
            "message": f"Token limit reached! You have {active_count} active tokens. Maximum allowed: {user.max_active_tokens}",
            "active_tokens": active_count,
            "max_tokens": user.max_active_tokens,
            "error_type": "limit_reached"
        }), 400
    
    # Calculate queue position
    queue_position = service.get_queue_count() + 1
    
    # Generate unique token ID
    token_counter += 1
    prefix = app.config.get('TOKEN_PREFIX', 'LL') # <--- Add this line
    token_id = f"{prefix}-{token_counter}"        # <--- Update this line
    
    # Create token
    token = Token(
        token_id=token_id,
        user_id=user.id,
        service_id=service.id,
        queue_position=queue_position,
        status='ACTIVE'
    )
    
    db.session.add(token)
    db.session.commit()
    
    # Update queue positions
    update_queue_positions(service.id)
    
    return jsonify({
        "success": True,
        "message": "Token generated successfully!",
        "token": token.to_dict()
    }), 201


@app.route('/tokens/<token_id>/complete', methods=['POST'])
def complete_token(token_id):
    """Mark token as completed (admin only)"""
    token = Token.query.filter_by(token_id=token_id).first()
    
    if not token:
        return jsonify({"success": False, "message": "Token not found"}), 404
    
    if token.status != 'ACTIVE':
        return jsonify({"success": False, "message": "Token is not active"}), 400
    
    token.status = 'COMPLETED'
    token.completed_at = datetime.utcnow()
    
    db.session.commit()

    # Send notification to user (guarded - Firebase may not be configured)
    try:
        notification_service = get_notification_service()
        if notification_service and token.user and token.user.device_token:
            notification_service.send_token_completed(
                token.user.device_token,
                token.service.name
            )
    except Exception as notif_err:
        print(f"[WARN] Completion notification failed: {notif_err}")
    
    # Update queue positions for this service
    update_queue_positions(token.service_id)
    
    # Log notification
    notification = Notification(
        user_id=token.user_id,
        title="Token Completed",
        message=f"Your token for {token.service.name} has been completed!",
        type="token_completed"
    )
    db.session.add(notification)
    db.session.commit()
    
    return jsonify({"success": True})


@app.route('/tokens/<token_id>/cancel', methods=['POST'])
def cancel_token(token_id):
    """Cancel a token (student only)"""
    token = Token.query.filter_by(token_id=token_id).first()
    
    if not token:
        return jsonify({"success": False, "message": "Token not found"}), 404
    
    if token.status != 'ACTIVE':
        return jsonify({"success": False, "message": "Token is not active"}), 400
    
    token.status = 'CANCELLED'
    token.cancelled_at = datetime.utcnow()
    
    db.session.commit()
    
    # Update queue positions for this service
    update_queue_positions(token.service_id)
    
    return jsonify({"success": True})


# ==================== NOTIFICATIONS ====================

@app.route('/admin/send-notification', methods=['POST'])
def send_admin_notification():
    """Send custom notification from admin"""
    data = request.json
    message = data.get('message')
    target = data.get('target', 'all')  # 'all', 'service', or specific user_id
    service_name = data.get('service_name')
    user_id = data.get('user_id')
    
    if not message:
        return jsonify({"success": False, "message": "Message is required"}), 400
    
    notification_service = get_notification_service()
    device_tokens = []
    user_ids = []
    
    # Determine recipients
    if target == 'all':
        # Send to all users with device tokens
        users = User.query.filter(User.device_token.isnot(None)).all()
        device_tokens = [user.device_token for user in users]
        user_ids = [user.id for user in users]
        
    elif target == 'service' and service_name:
        # Send to all users with active tokens for this service
        service = Service.query.filter_by(name=service_name).first()
        if service:
            tokens = Token.query.filter_by(service_id=service.id, status='ACTIVE').all()
            unique_users = {token.user for token in tokens if token.user.device_token}
            device_tokens = [user.device_token for user in unique_users]
            user_ids = [user.id for user in unique_users]
    
    elif user_id:
        # Send to specific user
        user = User.query.get(user_id)
        if user and user.device_token:
            device_tokens = [user.device_token]
            user_ids = [user.id]
    
    if not device_tokens:
        return jsonify({"success": False, "message": "No recipients found"}), 400
    
    # Send notifications
    result = notification_service.send_admin_message(device_tokens, message)
    
    # Log notifications in database
    for uid in user_ids:
        notification = Notification(
            user_id=uid,
            title="Admin Notification",
            message=message,
            type="admin_message"
        )
        db.session.add(notification)
    
    db.session.commit()
    
    return jsonify({
        "success": True,
        "message": "Notifications sent",
        "sent": result['success'],
        "failed": result['failure']
    })


@app.route('/notifications/<int:user_id>', methods=['GET'])
def get_notifications(user_id):
    """Get notifications for a user"""
    notifications = Notification.query.filter_by(user_id=user_id).order_by(Notification.sent_at.desc()).all()
    
    # Also get broadcast notifications (user_id = None)
    broadcast_notifications = Notification.query.filter_by(user_id=None).order_by(Notification.sent_at.desc()).limit(10).all()
    
    all_notifications = notifications + broadcast_notifications
    all_notifications.sort(key=lambda x: x.sent_at, reverse=True)
    
    return jsonify({
        "notifications": [notif.to_dict() for notif in all_notifications]
    })


@app.route('/notifications/<int:notification_id>/read', methods=['POST'])
def mark_notification_read(notification_id):
    """Mark notification as read"""
    notification = Notification.query.get(notification_id)
    
    if not notification:
        return jsonify({"success": False, "message": "Notification not found"}), 404
    
    notification.read = True
    db.session.commit()
    
    return jsonify({"success": True})


# ==================== QUEUE INFO ====================

@app.route('/queue/<service_name>', methods=['GET'])
def get_queue_info(service_name):
    """Get queue information for a specific service"""
    service = Service.query.filter_by(name=service_name).first()
    
    if not service:
        return jsonify({"success": False, "message": "Service not found"}), 404
    
    active_tokens = Token.query.filter_by(
        service_id=service.id,
        status='ACTIVE'
    ).order_by(Token.queue_position).all()
    
    return jsonify({
        "service_name": service.name,
        "total_in_queue": len(active_tokens),
        "tokens": [token.to_dict() for token in active_tokens]
    })


# ==================== HEALTH CHECK ====================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "database": "connected",
        "timestamp": datetime.utcnow().isoformat()
    })


# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    return jsonify({"success": False, "message": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({"success": False, "message": "Internal server error"}), 500


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("Database tables created")
        print("Run 'flask init-db' to initialize with default data")
    
    app.run(host='0.0.0.0', port=5000, debug=True)