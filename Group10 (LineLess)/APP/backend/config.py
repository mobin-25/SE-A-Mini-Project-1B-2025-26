import os
from dotenv import load_dotenv
 
load_dotenv()
 
class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Database Configuration
    # For SQLite (development)
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///lineless.db'
    
    # For PostgreSQL (production) - uncomment and update when deploying
    # SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
    #     'postgresql://username:password@localhost/lineless_db'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Firebase Configuration (for push notifications)
    FIREBASE_CREDENTIALS_PATH = os.environ.get('FIREBASE_CREDENTIALS_PATH') or 'firebase-credentials.json'
    
    # Token Configuration
    MAX_ACTIVE_TOKENS_PER_USER = 3
    TOKEN_PREFIX = 'LL'
    
    # Notification Configuration
    ENABLE_NOTIFICATIONS = os.environ.get('ENABLE_NOTIFICATIONS', 'True').lower() == 'true'
 
 
class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///lineless.db'
 
 
class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    # Override with production database URL
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
    
    # Ensure secret key is set in production
    if not os.environ.get('SECRET_KEY'):
        raise ValueError("SECRET_KEY environment variable must be set in production")
 
 
# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
 