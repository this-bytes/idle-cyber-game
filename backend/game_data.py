"""
Database models for the Cyberspace Tycoon idle game backend.
Handles player data and global game state persistence.
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import time
from sqlalchemy.exc import OperationalError
import json

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


class Skill(db.Model):
    """Skill model representing game skills from skills.lua"""
    
    __tablename__ = 'skills'
    
    # Primary key
    id = db.Column(db.String(50), primary_key=True)  # skill_id like "basic_analysis"
    
    # Basic info
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(50), nullable=False)
    
    # Progression
    max_level = db.Column(db.Integer, default=10, nullable=False)
    base_xp_cost = db.Column(db.Integer, default=100, nullable=False)
    xp_growth = db.Column(db.Float, default=1.2, nullable=False)
    
    # Requirements (stored as JSON)
    prerequisites = db.Column(db.Text)  # JSON array of prerequisite skill IDs
    unlock_requirements = db.Column(db.Text)  # JSON object with unlock conditions
    
    # Effects (stored as JSON)
    effects = db.Column(db.Text)  # JSON object with effect multipliers
    
    # Metadata
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert skill data to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'category': self.category,
            'maxLevel': self.max_level,
            'baseXpCost': self.base_xp_cost,
            'xpGrowth': self.xp_growth,
            'prerequisites': json.loads(self.prerequisites) if self.prerequisites else [],
            'unlockRequirements': json.loads(self.unlock_requirements) if self.unlock_requirements else {},
            'effects': json.loads(self.effects) if self.effects else {},
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'updatedAt': self.updated_at.isoformat() if self.updated_at else None
        }


class Specialist(db.Model):
    """Specialist model representing team members who enhance gameplay"""
    
    __tablename__ = 'specialists'
    
    # Primary key
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    
    # Identification
    specialist_type = db.Column(db.String(50), nullable=False)  # e.g., "junior_analyst"
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    
    # Stats
    efficiency = db.Column(db.Float, default=1.0, nullable=False)
    speed = db.Column(db.Float, default=1.0, nullable=False)
    trace = db.Column(db.Float, default=1.0, nullable=False)
    defense = db.Column(db.Float, default=1.0, nullable=False)
    
    # Cost (stored as JSON)
    cost = db.Column(db.Text)  # JSON object with cost requirements
    
    # Abilities (stored as JSON)
    abilities = db.Column(db.Text)  # JSON array of ability names
    
    # Availability
    available = db.Column(db.Boolean, default=True, nullable=False)
    tier = db.Column(db.Integer, default=1, nullable=False)
    
    # Metadata
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert specialist data to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'specialistType': self.specialist_type,
            'name': self.name,
            'description': self.description,
            'efficiency': self.efficiency,
            'speed': self.speed,
            'trace': self.trace,
            'defense': self.defense,
            'cost': json.loads(self.cost) if self.cost else {},
            'abilities': json.loads(self.abilities) if self.abilities else [],
            'available': self.available,
            'tier': self.tier,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'updatedAt': self.updated_at.isoformat() if self.updated_at else None
        }


class Achievement(db.Model):
    """Achievement model representing player achievements and progress tracking"""
    
    __tablename__ = 'achievements'
    
    # Primary key
    id = db.Column(db.String(50), primary_key=True)  # achievement_id like "firstClick"
    
    # Basic info
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    
    # Requirements (stored as JSON)
    requirement = db.Column(db.Text)  # JSON object with requirement type and value
    
    # Rewards (stored as JSON)
    reward = db.Column(db.Text)  # JSON object with reward type and value
    
    # Status
    unlocked = db.Column(db.Boolean, default=False, nullable=False)
    hidden = db.Column(db.Boolean, default=False, nullable=False)  # Hidden until unlocked
    
    # Metadata
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert achievement data to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'requirement': json.loads(self.requirement) if self.requirement else {},
            'reward': json.loads(self.reward) if self.reward else {},
            'unlocked': self.unlocked,
            'hidden': self.hidden,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'updatedAt': self.updated_at.isoformat() if self.updated_at else None
        }


class Item(db.Model):
    """Item model representing game items, equipment, and consumables"""
    
    __tablename__ = 'items'
    
    # Primary key
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    
    # Identification
    item_id = db.Column(db.String(50), unique=True, nullable=False)  # Unique identifier
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    
    # Classification
    category = db.Column(db.String(50), nullable=False)  # e.g., "equipment", "consumable", "upgrade"
    rarity = db.Column(db.String(20), default="common", nullable=False)  # common, uncommon, rare, epic, legendary
    
    # Economy
    cost = db.Column(db.Text)  # JSON object with cost requirements
    sell_value = db.Column(db.Integer, default=0, nullable=False)
    
    # Effects (stored as JSON)
    effects = db.Column(db.Text)  # JSON object with stat bonuses and abilities
    
    # Usage
    stackable = db.Column(db.Boolean, default=False, nullable=False)
    consumable = db.Column(db.Boolean, default=False, nullable=False)
    max_stack = db.Column(db.Integer, default=1, nullable=False)
    
    # Availability
    available = db.Column(db.Boolean, default=True, nullable=False)
    
    # Metadata
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convert item data to dictionary for JSON serialization."""
        return {
            'id': self.id,
            'itemId': self.item_id,
            'name': self.name,
            'description': self.description,
            'category': self.category,
            'rarity': self.rarity,
            'cost': json.loads(self.cost) if self.cost else {},
            'sellValue': self.sell_value,
            'effects': json.loads(self.effects) if self.effects else {},
            'stackable': self.stackable,
            'consumable': self.consumable,
            'maxStack': self.max_stack,
            'available': self.available,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'updatedAt': self.updated_at.isoformat() if self.updated_at else None
        }


def init_db(app):
    """Initialize database with app context and create default global state."""
    db.init_app(app)
    
    with app.app_context():
        # Create all tables with retry logic to handle brief SQLITE locks
        max_retries = 5
        backoff = 0.5
        for attempt in range(1, max_retries + 1):
            try:
                db.create_all()
                break
            except OperationalError as e:
                # sqlite 'database is locked' can occur if another process/thread
                # briefly holds the file lock. Retry a few times with backoff.
                if 'database is locked' in str(e).lower() and attempt < max_retries:
                    print(f"⚠️  Database locked, retrying init (attempt {attempt}/{max_retries})...")
                    time.sleep(backoff)
                    backoff *= 2
                    continue
                else:
                    raise

        # Create default global game state if it doesn't exist
        try:
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
        finally:
            # Ensure the session is removed to free connections
            try:
                db.session.close()
            except Exception:
                pass