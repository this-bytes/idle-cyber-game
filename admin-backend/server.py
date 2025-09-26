#!/usr/bin/env python3
"""
Admin Backend Server for Cyber Empire Command
Provides REST API for game asset management and balancing
"""

import json
import os
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/admin-backend.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for browser-based admin panels

# Configuration
CONFIG_DIR = "../data/config"
BACKUP_DIR = "backups"

# Ensure directories exist
os.makedirs("logs", exist_ok=True)
os.makedirs(BACKUP_DIR, exist_ok=True)

class ConfigFileHandler(FileSystemEventHandler):
    """Handles file system events for configuration files"""
    
    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith('.json'):
            logger.info(f"Configuration file modified: {event.src_path}")

# File watcher for configuration changes
observer = Observer()
if os.path.exists(CONFIG_DIR):
    observer.schedule(ConfigFileHandler(), CONFIG_DIR, recursive=True)
    observer.start()

def load_config_file(filename):
    """Load configuration file with error handling"""
    filepath = os.path.join(CONFIG_DIR, filename)
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {filepath}")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in {filepath}: {e}")
        return None

def save_config_file(filename, data):
    """Save configuration file with backup"""
    filepath = os.path.join(CONFIG_DIR, filename)
    
    # Create backup if file exists
    if os.path.exists(filepath):
        backup_filename = f"{filename}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        backup_path = os.path.join(BACKUP_DIR, backup_filename)
        
        try:
            with open(filepath, 'r') as original, open(backup_path, 'w') as backup:
                backup.write(original.read())
            logger.info(f"Created backup: {backup_path}")
        except Exception as e:
            logger.warning(f"Failed to create backup: {e}")
    
    # Save new configuration
    try:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        logger.info(f"Saved configuration: {filepath}")
        return True
    except Exception as e:
        logger.error(f"Failed to save {filepath}: {e}")
        return False

@app.route('/')
def admin_panel():
    """Serve the admin panel web interface"""
    return render_template('admin_panel.html')

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'Cyber Empire Command Admin Backend'
    })

@app.route('/api/upgrades', methods=['GET'])
def get_upgrades():
    """Get all upgrade configurations"""
    upgrades = load_config_file('upgrades.json')
    if upgrades is None:
        return jsonify({'error': 'Failed to load upgrades configuration'}), 500
    
    return jsonify({
        'upgrades': upgrades,
        'count': len(upgrades)
    })

@app.route('/api/upgrades/<upgrade_id>', methods=['GET'])
def get_upgrade(upgrade_id):
    """Get specific upgrade configuration"""
    upgrades = load_config_file('upgrades.json')
    if upgrades is None:
        return jsonify({'error': 'Failed to load upgrades configuration'}), 500
    
    if upgrade_id not in upgrades:
        return jsonify({'error': 'Upgrade not found'}), 404
    
    return jsonify({
        'upgrade': upgrades[upgrade_id],
        'id': upgrade_id
    })

@app.route('/api/upgrades/<upgrade_id>', methods=['PUT'])
def update_upgrade(upgrade_id):
    """Update specific upgrade configuration"""
    if not request.json:
        return jsonify({'error': 'Request body must be JSON'}), 400
    
    upgrades = load_config_file('upgrades.json')
    if upgrades is None:
        return jsonify({'error': 'Failed to load upgrades configuration'}), 500
    
    # Validate required fields
    required_fields = ['id', 'name', 'description', 'category', 'tier', 'maxCount', 'baseCost', 'costGrowth', 'effects']
    for field in required_fields:
        if field not in request.json:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    # Update upgrade
    upgrades[upgrade_id] = request.json
    
    # Save configuration
    if not save_config_file('upgrades.json', upgrades):
        return jsonify({'error': 'Failed to save configuration'}), 500
    
    logger.info(f"Updated upgrade configuration: {upgrade_id}")
    return jsonify({
        'message': 'Upgrade updated successfully',
        'upgrade': upgrades[upgrade_id]
    })

@app.route('/api/contracts', methods=['GET'])
def get_contracts():
    """Get all contract configurations"""
    contracts = load_config_file('contracts.json')
    if contracts is None:
        return jsonify({'error': 'Failed to load contracts configuration'}), 500
    
    return jsonify({
        'contracts': contracts,
        'count': len(contracts)
    })

@app.route('/api/contracts/<contract_id>', methods=['GET'])
def get_contract(contract_id):
    """Get specific contract configuration"""
    contracts = load_config_file('contracts.json')
    if contracts is None:
        return jsonify({'error': 'Failed to load contracts configuration'}), 500
    
    if contract_id not in contracts:
        return jsonify({'error': 'Contract not found'}), 404
    
    return jsonify({
        'contract': contracts[contract_id],
        'id': contract_id
    })

@app.route('/api/contracts/<contract_id>', methods=['PUT'])
def update_contract(contract_id):
    """Update specific contract configuration"""
    if not request.json:
        return jsonify({'error': 'Request body must be JSON'}), 400
    
    contracts = load_config_file('contracts.json')
    if contracts is None:
        return jsonify({'error': 'Failed to load contracts configuration'}), 500
    
    # Validate required fields
    required_fields = ['name', 'budgetRange', 'durationRange', 'reputationReward', 'riskLevel', 'description']
    for field in required_fields:
        if field not in request.json:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    # Update contract
    contracts[contract_id] = request.json
    
    # Save configuration
    if not save_config_file('contracts.json', contracts):
        return jsonify({'error': 'Failed to save configuration'}), 500
    
    logger.info(f"Updated contract configuration: {contract_id}")
    return jsonify({
        'message': 'Contract updated successfully',
        'contract': contracts[contract_id]
    })

@app.route('/api/crises', methods=['GET'])
def get_crises():
    """Get all crisis configurations"""
    crises = load_config_file('crises.json')
    if crises is None:
        return jsonify({'error': 'Failed to load crises configuration'}), 500
    
    return jsonify({
        'crises': crises,
        'count': len(crises)
    })

@app.route('/api/crises/<crisis_id>', methods=['PUT'])
def update_crisis(crisis_id):
    """Update specific crisis configuration"""
    if not request.json:
        return jsonify({'error': 'Request body must be JSON'}), 400
    
    crises = load_config_file('crises.json')
    if crises is None:
        return jsonify({'error': 'Failed to load crises configuration'}), 500
    
    # Update crisis
    crises[crisis_id] = request.json
    
    # Save configuration
    if not save_config_file('crises.json', crises):
        return jsonify({'error': 'Failed to save configuration'}), 500
    
    logger.info(f"Updated crisis configuration: {crisis_id}")
    return jsonify({
        'message': 'Crisis updated successfully',
        'crisis': crises[crisis_id]
    })

@app.route('/api/backups', methods=['GET'])
def list_backups():
    """List available backup files"""
    try:
        backups = []
        for filename in os.listdir(BACKUP_DIR):
            if '.backup.' in filename:  # Changed to match our backup naming
                filepath = os.path.join(BACKUP_DIR, filename)
                stat = os.stat(filepath)
                backups.append({
                    'filename': filename,
                    'size': stat.st_size,
                    'created': datetime.fromtimestamp(stat.st_ctime).isoformat()
                })
        
        return jsonify({
            'backups': sorted(backups, key=lambda x: x['created'], reverse=True),
            'count': len(backups)
        })
    except Exception as e:
        logger.error(f"Failed to list backups: {e}")
        return jsonify({'error': 'Failed to list backups'}), 500

if __name__ == '__main__':
    logger.info("Starting Cyber Empire Command Admin Backend Server")
    logger.info(f"Config directory: {os.path.abspath(CONFIG_DIR)}")
    logger.info(f"Backup directory: {os.path.abspath(BACKUP_DIR)}")
    
    try:
        app.run(host='127.0.0.1', port=5000, debug=True)
    except KeyboardInterrupt:
        logger.info("Server shutting down...")
    finally:
        observer.stop()
        observer.join()