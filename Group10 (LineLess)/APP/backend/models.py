from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import bcrypt
 
db = SQLAlchemy()
 
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.String(8), unique=True, nullable=False)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(15), nullable=True)
    pin_hash = db.Column(db.String(60), nullable=False)
    role = db.Column(db.String(10), default='student')
    max_active_tokens = db.Column(db.Integer, default=3)
    device_token = db.Column(db.String(255), nullable=True)  # For push notifications
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    tokens = db.relationship('Token', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def set_pin(self, pin):
        """Hash and set PIN"""
        self.pin_hash = bcrypt.hashpw(pin.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    def check_pin(self, pin):
        """Verify PIN"""
        return bcrypt.checkpw(pin.encode('utf-8'), self.pin_hash.encode('utf-8'))
    
    def get_active_tokens_count(self):
        """Get count of active tokens for this user"""
        return Token.query.filter_by(user_id=self.id, status='ACTIVE').count()
    
    def can_create_token(self):
        """Check if user can create a new token"""
        return self.get_active_tokens_count() < self.max_active_tokens
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'student_id': self.student_id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'max_active_tokens': self.max_active_tokens,
            'active_tokens': self.get_active_tokens_count(),
            'created_at': self.created_at.isoformat()
        }
 
 
class Admin(db.Model):
    __tablename__ = 'admins'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(60), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    def check_password(self, password):
        """Verify password"""
        return bcrypt.checkpw(password.encode('utf-8'), self.password_hash.encode('utf-8'))
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'email': self.email,
            'name': self.name,
            'role': 'admin',
            'created_at': self.created_at.isoformat()
        }
 
 
class Service(db.Model):
    __tablename__ = 'services'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    icon = db.Column(db.String(50), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    tokens = db.relationship('Token', backref='service', lazy=True)
    
    def get_queue_count(self):
        """Get count of active tokens for this service"""
        return Token.query.filter_by(service_id=self.id, status='ACTIVE').count()
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'name': self.name,
            'desc': self.description,
            'icon': self.icon,
            'is_active': self.is_active,
            'queue_count': self.get_queue_count()
        }
 
 
class Token(db.Model):
    __tablename__ = 'tokens'
    
    id = db.Column(db.Integer, primary_key=True)
    token_id = db.Column(db.String(20), unique=True, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    status = db.Column(db.String(20), default='ACTIVE')  # ACTIVE, COMPLETED, CANCELLED
    queue_position = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime, nullable=True)
    cancelled_at = db.Column(db.DateTime, nullable=True)
    
    def to_dict(self):
        """Convert to dictionary"""
        # Calculate estimated wait time
        wait_mins = self.queue_position * 3
        
        return {
            'id': self.token_id,
            'student_id': self.user.student_id,
            'student_name': self.user.name,
            'service_name': self.service.name,
            'status': self.status,
            'queue_position': self.queue_position,
            'created_at': self.created_at.isoformat(),
            'display_time': self.created_at.strftime("%b %d, %Y • %I:%M %p"),
            'est_wait': f"{wait_mins}-{wait_mins+3} Mins",
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'cancelled_at': self.cancelled_at.isoformat() if self.cancelled_at else None
        }
 
 
class Notification(db.Model):
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)  # Null = broadcast
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.String(500), nullable=False)
    type = db.Column(db.String(30), nullable=False)  # queue_update, admin_message, system
    sent_at = db.Column(db.DateTime, default=datetime.utcnow)
    read = db.Column(db.Boolean, default=False)
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'message': self.message,
            'type': self.type,
            'sent_at': self.sent_at.isoformat(),
            'read': self.read
        }
 