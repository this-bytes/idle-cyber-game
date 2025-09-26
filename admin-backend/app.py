#!/usr/bin/env python3
"""
Cyber Empire Command - Admin Backend
Real-time monitoring and management dashboard for the game
"""

import os
import json
import logging
from datetime import datetime
from pathlib import Path

from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import psutil

from config import config

# Initialize Flask app
app = Flask(__name__)
config_name = os.getenv('FLASK_CONFIG', 'default')
app.config.from_object(config[config_name])
config[config_name].init_app(app)

# Initialize extensions
socketio = SocketIO(app, cors_allowed_origins=app.config['CORS_ORIGINS'])
CORS(app, origins=app.config['CORS_ORIGINS'])

# Setup logging
logging.basicConfig(
    level=getattr(logging, app.config['LOG_LEVEL']),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(app.config['LOG_FILE']),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global state
game_state = {
    'connected': False,
    'last_update': None,
    'resources': {},
    'contracts': {'active': [], 'available': []},
    'specialists': [],
    'performance': {},
    'mode': 'idle'
}

analytics_data = {
    'resource_history': [],
    'contract_history': [],
    'crisis_history': [],
    'uptime': datetime.now()
}

@app.route('/')
def index():
    """Main dashboard view"""
    return render_template('dashboard.html', 
                         game_state=game_state,
                         analytics=analytics_data)

@app.route('/analytics')
def analytics():
    """Analytics dashboard view"""
    return render_template('analytics.html',
                         analytics=analytics_data,
                         game_state=game_state)

@app.route('/crisis')
def crisis():
    """Crisis management view"""
    return render_template('crisis.html',
                         game_state=game_state)

# API Routes
@app.route('/api/game-state')
def api_game_state():
    """Get current game state"""
    return jsonify({
        'status': 'success',
        'data': game_state,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/resources', methods=['GET', 'POST'])
def api_resources():
    """Get or modify game resources"""
    if request.method == 'GET':
        return jsonify({
            'status': 'success',
            'resources': game_state.get('resources', {})
        })
    
    elif request.method == 'POST':
        # Admin resource modification
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'No data provided'}), 400
        
        # Validate admin password
        if data.get('admin_password') != app.config['ADMIN_PASSWORD']:
            return jsonify({'status': 'error', 'message': 'Unauthorized'}), 401
        
        # Update resources
        resources = data.get('resources', {})
        for resource, value in resources.items():
            if isinstance(value, (int, float)) and value >= 0:
                game_state['resources'][resource] = value
                logger.info(f"Admin updated {resource} to {value}")
        
        # Broadcast update to connected clients
        socketio.emit('game_state_update', game_state)
        
        return jsonify({
            'status': 'success',
            'message': 'Resources updated',
            'resources': game_state['resources']
        })

@app.route('/api/contracts')
def api_contracts():
    """Get contract information"""
    return jsonify({
        'status': 'success',
        'contracts': game_state.get('contracts', {'active': [], 'available': []})
    })

@app.route('/api/specialists')
def api_specialists():
    """Get specialist information"""
    return jsonify({
        'status': 'success',
        'specialists': game_state.get('specialists', [])
    })

@app.route('/api/crisis/trigger', methods=['POST'])
def api_trigger_crisis():
    """Trigger a crisis scenario for testing"""
    data = request.get_json()
    if not data:
        return jsonify({'status': 'error', 'message': 'No data provided'}), 400
    
    # Validate admin password
    if data.get('admin_password') != app.config['ADMIN_PASSWORD']:
        return jsonify({'status': 'error', 'message': 'Unauthorized'}), 401
    
    crisis_type = data.get('crisis_type', 'phishing_campaign')
    
    # Log crisis trigger
    crisis_event = {
        'type': crisis_type,
        'triggered_by': 'admin',
        'timestamp': datetime.now().isoformat(),
        'status': 'triggered'
    }
    
    analytics_data['crisis_history'].append(crisis_event)
    logger.info(f"Admin triggered crisis: {crisis_type}")
    
    # Broadcast crisis to game (if connected)
    socketio.emit('trigger_crisis', {'crisis_type': crisis_type})
    
    return jsonify({
        'status': 'success',
        'message': f'Crisis "{crisis_type}" triggered',
        'crisis': crisis_event
    })

@app.route('/api/analytics')
def api_analytics():
    """Get analytics data"""
    return jsonify({
        'status': 'success',
        'analytics': analytics_data,
        'system_info': {
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent,
            'uptime': (datetime.now() - analytics_data['uptime']).total_seconds()
        }
    })

@app.route('/api/save/backup', methods=['POST'])
def api_save_backup():
    """Create a save backup"""
    try:
        save_path = Path(app.config['GAME_SAVE_PATH'])
        backup_path = save_path / 'backups'
        backup_path.mkdir(exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_file = backup_path / f'save_backup_{timestamp}.json'
        
        # Create backup of current game state
        with open(backup_file, 'w') as f:
            json.dump(game_state, f, indent=2)
        
        logger.info(f"Created save backup: {backup_file}")
        
        return jsonify({
            'status': 'success',
            'message': 'Backup created successfully',
            'backup_file': str(backup_file)
        })
    
    except Exception as e:
        logger.error(f"Failed to create backup: {e}")
        return jsonify({
            'status': 'error',
            'message': f'Backup failed: {str(e)}'
        }), 500

# WebSocket Events
@socketio.on('connect')
def on_connect():
    """Handle client connection"""
    logger.info(f"Client connected: {request.sid}")
    emit('game_state_update', game_state)

@socketio.on('disconnect')
def on_disconnect():
    """Handle client disconnection"""
    logger.info(f"Client disconnected: {request.sid}")

@socketio.on('game_update')
def on_game_update(data):
    """Handle game state updates from the game client"""
    global game_state
    
    # Update game state
    game_state.update(data)
    game_state['last_update'] = datetime.now().isoformat()
    game_state['connected'] = True
    
    # Add to analytics history
    if 'resources' in data:
        analytics_data['resource_history'].append({
            'timestamp': datetime.now().isoformat(),
            'resources': data['resources'].copy()
        })
        
        # Keep only last 1000 entries
        if len(analytics_data['resource_history']) > 1000:
            analytics_data['resource_history'] = analytics_data['resource_history'][-1000:]
    
    # Broadcast to all connected clients
    emit('game_state_update', game_state, broadcast=True)
    logger.debug("Game state updated and broadcasted")

@socketio.on('request_game_state')
def on_request_game_state():
    """Handle requests for current game state"""
    emit('game_state_update', game_state)

if __name__ == '__main__':
    logger.info("Starting Cyber Empire Command Admin Backend")
    logger.info(f"Dashboard will be available at: http://{app.config['HOST']}:{app.config['PORT']}")
    
    socketio.run(app, 
                host=app.config['HOST'], 
                port=app.config['PORT'],
                debug=app.config['DEBUG'])