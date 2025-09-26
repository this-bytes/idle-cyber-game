"""
Database models for the Cyberspace Tycoon idle game backend.
Handles player data and global game state persistence.
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

# Initialize SQLAlchemy
db = SQLAlchemy()


class Player(db.Model):
    """Player model storing individual player game state."""
    
    __tablename__ = 'players'
    
    # Primary key
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    
    # Player identification
    username = db.Column(db.String(50), unique=True, nullable=False)
    
    # Core game resources
    current_currency = db.Column(db.Integer, default=0, nullable=False)
    prestige_level = db.Column(db.Integer, default=0, nullable=False)
    
    # Additional game resources from the Lua game system
    reputation = db.Column(db.Integer, default=0, nullable=False)
    xp = db.Column(db.Integer, default=0, nullable=False)
    mission_tokens = db.Column(db.Integer, default=0, nullable=False)
    
    # Timestamps
    last_login = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert player data to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'username': self.username,
            'current_currency': self.current_currency,
            'prestige_level': self.prestige_level,
            'reputation': self.reputation,
            'xp': self.xp,
            'mission_tokens': self.mission_tokens,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class GlobalGameState(db.Model):
    """Global game state model for server-wide settings and multipliers."""
    
    __tablename__ = 'global_game_state'
    
    # Fixed primary key (always 1 for singleton pattern)
    id = db.Column(db.Integer, primary_key=True, default=1)
    
    # Global game multipliers
    base_production_rate = db.Column(db.Float, default=1.0, nullable=False)
    global_multiplier = db.Column(db.Float, default=1.0, nullable=False)
    
    # Additional global settings
    max_players = db.Column(db.Integer, default=1000, nullable=False)
    maintenance_mode = db.Column(db.Boolean, default=False, nullable=False)
    
    # Timestamps
    last_updated = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert global state to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'base_production_rate': self.base_production_rate,
            'global_multiplier': self.global_multiplier,
            'max_players': self.max_players,
            'maintenance_mode': self.maintenance_mode,
            'last_updated': self.last_updated.isoformat() if self.last_updated else None
        }


def init_db(app):
    """Initialize database with app context and create default global state."""
    db.init_app(app)
    
    with app.app_context():
        # Create all tables
        db.create_all()
        
        # Create default global game state if it doesn't exist
        global_state = GlobalGameState.query.get(1)
        if not global_state:
            global_state = GlobalGameState(
                id=1,
                base_production_rate=1.0,
                global_multiplier=1.0,
                max_players=1000,
                maintenance_mode=False
            )
            db.session.add(global_state)
            db.session.commit()
            print("🌍 Created default global game state")