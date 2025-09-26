# Cyber Empire Command - Admin Backend

Backend server for game asset management and balance control system.

## Overview

This backend system allows real-time modification of game assets including upgrades, contracts, and crisis scenarios through a REST API and web-based admin panel. All changes are automatically written back to the core game configuration files and include automatic backup functionality.

## Features

- **REST API** for full CRUD operations on game assets
- **Web-based Admin Panel** with terminal-style cyberpunk interface  
- **Automatic Backup System** creates timestamped backups before any changes
- **File Watching** detects external changes to configuration files
- **Hot-Reload Support** game systems can detect and reload configuration changes
- **Validation** ensures configuration data integrity
- **Logging** comprehensive audit trail of all changes

## Quick Start

### Prerequisites

- Python 3.6+
- pip

### Installation

```bash
cd admin-backend
pip install -r requirements.txt
```

### Running the Server

```bash
python server.py
```

The server will start on `http://127.0.0.1:5000`

### Accessing the Admin Panel

Open your browser to `http://127.0.0.1:5000` to access the web-based admin panel.

## API Endpoints

### Health Check
- `GET /api/health` - Server status

### Upgrades
- `GET /api/upgrades` - List all upgrade configurations
- `GET /api/upgrades/{id}` - Get specific upgrade
- `PUT /api/upgrades/{id}` - Update upgrade configuration

### Contracts  
- `GET /api/contracts` - List all contract configurations
- `GET /api/contracts/{id}` - Get specific contract
- `PUT /api/contracts/{id}` - Update contract configuration

### Crises
- `GET /api/crises` - List all crisis scenarios
- `PUT /api/crises/{id}` - Update crisis configuration

### Backups
- `GET /api/backups` - List available backup files

## Configuration Files

The system manages the following JSON configuration files in `../data/config/`:

- `upgrades.json` - Game upgrade definitions
- `contracts.json` - Contract type definitions  
- `crises.json` - Crisis scenario definitions

## Game Integration

The Lua game systems include hot-reload functionality:

1. **ConfigLoader** utility monitors file changes
2. **Systems** (UpgradeSystem, ContractSystem, AdminMode) check for updates each frame
3. **Automatic Reload** applies changes without losing player progress
4. **Event System** notifies other systems of configuration updates

## Backup System

- Automatic backups created before any modification
- Timestamped backup files in `backups/` directory
- Web interface shows backup history
- Manual restoration possible by copying backup files

## Development

### Project Structure

```
admin-backend/
├── server.py              # Main Flask application
├── requirements.txt       # Python dependencies
├── templates/
│   └── admin_panel.html   # Web admin interface
├── backups/               # Automatic backup storage
└── logs/
    └── admin-backend.log  # Server logs
```

### Adding New Asset Types

1. Create JSON configuration file in `../data/config/`
2. Add API endpoints in `server.py`
3. Create Lua configuration loader in game system
4. Update admin panel interface

## Security Notes

- Development server only - use production WSGI server for production
- No authentication implemented - add as needed
- File system access limited to configuration directory
- CORS enabled for browser access

## Troubleshooting

### Common Issues

- **Port 5000 already in use**: Change port in `server.py`
- **Permission errors**: Check file system permissions
- **JSON parsing errors**: Validate JSON syntax before saving
- **Game not reloading**: Check file modification timestamps

### Logs

Server logs are written to `logs/admin-backend.log` with detailed information about:
- Configuration changes
- API requests
- File system operations
- Error conditions