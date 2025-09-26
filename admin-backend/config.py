# Admin Backend Configuration - Cyber Empire Command

import os
from pathlib import Path

class Config:
    # Flask configuration
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'cyber-empire-admin-key-dev'
    DEBUG = os.environ.get('FLASK_ENV') != 'production'
    
    # Server configuration
    HOST = '127.0.0.1'  # Local only for security
    PORT = int(os.environ.get('PORT', 5000))
    
    # Game integration
    GAME_SAVE_PATH = os.environ.get('GAME_SAVE_PATH') or '../saves'
    GAME_LOG_PATH = os.environ.get('GAME_LOG_PATH') or '../logs'
    
    # Refresh intervals (seconds)
    GAME_STATE_REFRESH = 2.0
    ANALYTICS_REFRESH = 10.0
    SAVE_BACKUP_INTERVAL = 300.0  # 5 minutes
    
    # Admin authentication
    ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD') or 'admin123'
    
    # CORS settings
    CORS_ORIGINS = ['http://localhost:8080', 'http://127.0.0.1:8080']
    
    # Logging
    LOG_LEVEL = 'INFO'
    LOG_FILE = 'logs/admin-backend.log'
    
    # Feature flags
    ENABLE_WEBSOCKETS = True
    ENABLE_GAME_CONTROL = True
    ENABLE_ANALYTICS = True
    
    @staticmethod
    def init_app(app):
        # Create necessary directories
        os.makedirs('logs', exist_ok=True)
        os.makedirs(Config.GAME_SAVE_PATH, exist_ok=True)
        os.makedirs(Config.GAME_LOG_PATH, exist_ok=True)

class DevelopmentConfig(Config):
    DEBUG = True
    
class ProductionConfig(Config):
    DEBUG = False
    
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}