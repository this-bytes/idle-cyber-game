"""
Flask REST API for Cyberspace Tycoon idle game backend.
Provides endpoints for game client and admin panel functionality.
"""

from flask import Flask, request, jsonify, send_from_directory
from datetime import datetime
import os

from game_data import db, Player, GlobalGameState, init_db
import json as pyjson
from flask import send_file
from functools import wraps
from pathlib import Path

# Initialize Flask app
static_dir = os.path.join(os.path.dirname(__file__), 'static')
app = Flask(__name__, static_folder=static_dir, static_url_path='/static')

# Configure SQLite database
basedir = os.path.abspath(os.path.dirname(__file__))
home_dir = os.path.expanduser("~")
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{os.path.join(home_dir, "database.db")}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# Engine options: increase timeout and allow multithreaded access when using sqlite file
# - timeout: wait up to 30 seconds for locks to clear
# - check_same_thread: False allows connections from different threads (Flask dev server)
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'connect_args': {
        'timeout': 30,
        'check_same_thread': False
    }
}

# Initialize database
init_db(app)


# ===== UTILITY FUNCTIONS =====

def validate_player_data(data, required_fields=None):
    """Validate player data from request."""
    if required_fields is None:
        required_fields = ['username']
    
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
    
    return True, None


# ===== GAME CLIENT ENDPOINTS =====

@app.route('/api/player/create', methods=['POST'])
def create_player():
    """Create a new player account."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        # Validate required fields
        is_valid, error_msg = validate_player_data(data, ['username'])
        if not is_valid:
            return jsonify({'error': error_msg}), 400
        
        username = data['username'].strip()
        if not username:
            return jsonify({'error': 'Username cannot be empty'}), 400
        
        # Check if player already exists
        existing_player = Player.query.filter_by(username=username).first()
        if existing_player:
            return jsonify({'error': 'Player with this username already exists'}), 409
        
        # Create new player
        player = Player(
            username=username,
            current_currency=data.get('current_currency', 1000),  # Starting money from Lua game
            prestige_level=data.get('prestige_level', 0),
            reputation=data.get('reputation', 0),
            xp=data.get('xp', 0),
            mission_tokens=data.get('mission_tokens', 0),
            last_login=datetime.utcnow()
        )
        
        db.session.add(player)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Player {username} created successfully',
            'player': player.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to create player: {str(e)}'}), 500


@app.route('/api/player/<username>', methods=['GET'])
def get_player(username):
    """Retrieve player data by username."""
    try:
        player = Player.query.filter_by(username=username).first()
        if not player:
            return jsonify({'error': 'Player not found'}), 404
        
        # Calculate idle time for potential offline earnings
        idle_time_seconds = 0
        if player.last_login:
            idle_time_seconds = (datetime.utcnow() - player.last_login).total_seconds()
        
        player_data = player.to_dict()
        player_data['idle_time_seconds'] = idle_time_seconds
        
        return jsonify({
            'success': True,
            'player': player_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to retrieve player: {str(e)}'}), 500


@app.route('/api/player/save', methods=['POST'])
def save_player():
    """Update player's game state."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        # Validate required fields
        is_valid, error_msg = validate_player_data(data, ['username'])
        if not is_valid:
            return jsonify({'error': error_msg}), 400
        
        username = data['username'].strip()
        player = Player.query.filter_by(username=username).first()
        if not player:
            return jsonify({'error': 'Player not found'}), 404
        
        # Update player data
        if 'current_currency' in data:
            player.current_currency = max(0, int(data['current_currency']))
        if 'prestige_level' in data:
            player.prestige_level = max(0, int(data['prestige_level']))
        if 'reputation' in data:
            player.reputation = max(0, int(data['reputation']))
        if 'xp' in data:
            player.xp = max(0, int(data['xp']))
        if 'mission_tokens' in data:
            player.mission_tokens = max(0, int(data['mission_tokens']))
        
        # Always update last login time
        player.last_login = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Player {username} data saved successfully',
            'player': player.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to save player: {str(e)}'}), 500


# ===== ADMIN PANEL ENDPOINTS =====

@app.route('/admin/players', methods=['GET'])
def list_players():
    """Get list of all players for admin panel."""
    try:
        players = Player.query.all()
        player_list = []
        
        for player in players:
            player_summary = {
                'id': player.id,
                'username': player.username,
                'current_currency': player.current_currency,
                'prestige_level': player.prestige_level,
                'reputation': player.reputation,
                'last_login': player.last_login.isoformat() if player.last_login else None
            }
            player_list.append(player_summary)
        
        return jsonify({
            'success': True,
            'players': player_list,
            'total_count': len(player_list)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to retrieve players: {str(e)}'}), 500


@app.route('/admin/player/<int:player_id>', methods=['PUT'])
def edit_player(player_id):
    """Edit player data via admin panel."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        player = Player.query.get(player_id)
        if not player:
            return jsonify({'error': 'Player not found'}), 404
        
        # Update allowed fields
        if 'username' in data:
            new_username = data['username'].strip()
            if new_username and new_username != player.username:
                # Check if new username is already taken
                existing = Player.query.filter_by(username=new_username).first()
                if existing:
                    return jsonify({'error': 'Username already taken'}), 409
                player.username = new_username
        
        if 'current_currency' in data:
            player.current_currency = max(0, int(data['current_currency']))
        if 'prestige_level' in data:
            player.prestige_level = max(0, int(data['prestige_level']))
        if 'reputation' in data:
            player.reputation = max(0, int(data['reputation']))
        if 'xp' in data:
            player.xp = max(0, int(data['xp']))
        if 'mission_tokens' in data:
            player.mission_tokens = max(0, int(data['mission_tokens']))
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Player {player.username} updated successfully',
            'player': player.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update player: {str(e)}'}), 500


@app.route('/admin/global', methods=['GET'])
def get_global_state():
    """Get global game state for admin panel."""
    try:
        global_state = GlobalGameState.query.get(1)
        if not global_state:
            return jsonify({'error': 'Global state not found'}), 404
        
        return jsonify({
            'success': True,
            'global_state': global_state.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to retrieve global state: {str(e)}'}), 500


@app.route('/admin/global', methods=['PUT'])
def update_global_state():
    """Update global game state via admin panel."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        global_state = GlobalGameState.query.get(1)
        if not global_state:
            return jsonify({'error': 'Global state not found'}), 404
        
        # Update allowed fields
        if 'base_production_rate' in data:
            global_state.base_production_rate = max(0.1, float(data['base_production_rate']))
        if 'global_multiplier' in data:
            global_state.global_multiplier = max(0.1, float(data['global_multiplier']))
        if 'max_players' in data:
            global_state.max_players = max(1, int(data['max_players']))
        if 'maintenance_mode' in data:
            global_state.maintenance_mode = bool(data['maintenance_mode'])
        
        global_state.last_updated = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Global state updated successfully',
            'global_state': global_state.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update global state: {str(e)}'}), 500


# ===== DATA FILE ENDPOINTS (for tuning) =====
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'src', 'data')
DATA_DIR = os.path.normpath(DATA_DIR)

def safe_join(base, *paths):
    p = os.path.normpath(os.path.join(base, *paths))
    if not p.startswith(base):
        raise ValueError("Invalid path")
    return p

def atomic_write(path, content):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        f.write(content)
    os.replace(tmp, path)

def validate_contracts_json(data):
    if not isinstance(data, list):
        return False, 'contracts must be a JSON array'
    for entry in data:
        if not isinstance(entry, dict) or 'id' not in entry:
            return False, 'each contract must be an object with an id field'
    return True, None

def validate_defs_json(data):
    if not isinstance(data, dict):
        return False, 'defs must be a JSON object'
    if 'Resources' not in data or 'Departments' not in data or 'GameModes' not in data:
        return False, 'defs must include Resources, Departments, and GameModes'
    return True, None


@app.route('/admin/data/contracts', methods=['GET'])
def get_contracts_data():
    try:
        path = safe_join(DATA_DIR, 'contracts.json')
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        return app.response_class(content, mimetype='application/json')
    except Exception as e:
        return jsonify({'error': f'Failed to read contracts.json: {str(e)}'}), 500


@app.route('/admin/data/contracts', methods=['PUT'])
def put_contracts_data():
    try:
        data = request.get_json()
        if data is None:
            return jsonify({'error': 'No JSON provided'}), 400
        ok, err = validate_contracts_json(data)
        if not ok:
            return jsonify({'error': err}), 400
        path = safe_join(DATA_DIR, 'contracts.json')
        atomic_write(path, pyjson.dumps(data, indent=2))
        return jsonify({'success': True}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to write contracts.json: {str(e)}'}), 500


@app.route('/admin/data/defs', methods=['GET'])
def get_defs_data():
    try:
        path = safe_join(DATA_DIR, 'defs.json')
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        return app.response_class(content, mimetype='application/json')
    except Exception as e:
        return jsonify({'error': f'Failed to read defs.json: {str(e)}'}), 500


@app.route('/admin/data/defs', methods=['PUT'])
def put_defs_data():
    try:
        data = request.get_json()
        if data is None:
            return jsonify({'error': 'No JSON provided'}), 400
        ok, err = validate_defs_json(data)
        if not ok:
            return jsonify({'error': err}), 400
        path = safe_join(DATA_DIR, 'defs.json')
        atomic_write(path, pyjson.dumps(data, indent=2))
        return jsonify({'success': True}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to write defs.json: {str(e)}'}), 500


# ===== HEALTH CHECK ENDPOINT =====

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'Cyberspace Tycoon API',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/admin')
def admin_ui():
    """Serve the admin UI HTML from the static folder."""
    try:
        return send_from_directory(static_dir, 'admin.html')
    except Exception:
        # Fallback: serve index file if present
        return send_from_directory(static_dir, 'admin.html')



# ===== ERROR HANDLERS =====

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({'error': 'Method not allowed'}), 405


@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    print("🚀 Starting Cyberspace Tycoon API server...")
    print("📊 Database: SQLite")
    print("🌐 Server: http://localhost:5001")
    print("📋 API endpoints available:")
    print("   Game Client:")
    print("     POST /api/player/create")
    print("     GET  /api/player/<username>")
    print("     POST /api/player/save")
    print("   Admin Panel:")
    print("     GET  /admin/players")
    print("     PUT  /admin/player/<id>")
    print("     GET  /admin/global")
    print("     PUT  /admin/global")
    print("   Health: GET /health")
    
    app.run(debug=True, host='0.0.0.0', port=5001)
