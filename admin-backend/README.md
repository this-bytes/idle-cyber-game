# Cyber Empire Command - Admin Backend

## Overview

This is the separate admin backend for Cyber Empire Command, providing real-time monitoring, analytics, and administrative control over the game. Built with a modern web framework to provide a professional dashboard interface.

## Technology Stack

### Flask (Python) - Recommended Service
We're using Flask as our web framework for the admin backend due to its:
- **Simplicity**: Easy to set up and configure
- **Flexibility**: Can handle REST APIs and web UI
- **Real-time Support**: WebSocket integration via Flask-SocketIO
- **Rich Ecosystem**: Extensive plugin support
- **Development Speed**: Rapid prototyping and iteration

### Alternative Options Considered
- **FastAPI**: Great for APIs but overkill for this use case
- **Django**: Too heavyweight for a game admin panel
- **Node.js/Express**: Would require JavaScript, keeping it Python for consistency

## Features

### Core Functionality
- **Real-time Game State Monitoring**: Live view of resources, contracts, specialists
- **Analytics Dashboard**: Performance metrics, player progression, business KPIs
- **Admin Controls**: Game state modification, testing tools, debug controls
- **Crisis Simulation**: Trigger crisis scenarios for testing
- **Save Management**: Backup, restore, and migrate save files

### API Endpoints
- `GET /api/game-state` - Current game resources and status
- `POST /api/resources` - Modify game resources (admin only)
- `GET /api/contracts` - List active and available contracts
- `POST /api/crisis/trigger` - Start crisis scenario for testing
- `GET /api/analytics` - Game analytics and statistics
- `POST /api/save/backup` - Create save backup
- `POST /api/save/restore` - Restore from backup

### Dashboard Views
- **Overview**: Real-time resource counters, active contracts, system status
- **Analytics**: Graphs showing resource generation, contract completion rates
- **Crisis Management**: Crisis history, response times, success rates
- **Specialist Management**: Team roster, performance metrics, deployment status
- **Debug Tools**: Console for game commands, state inspection, testing utilities

## Setup Instructions

### Prerequisites
```bash
python3 -p venv admin-venv
source admin-venv/bin/activate  # Linux/Mac
# admin-venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

### Installation
```bash
cd admin-backend
pip install flask flask-socketio flask-cors requests
```

### Running the Server
```bash
python app.py
```

The admin dashboard will be available at: `http://localhost:5000`

### Configuration
Edit `config.py` to configure:
- Game save file location
- Refresh intervals
- Authentication settings
- Debugging options

## Integration with Game

### Communication Protocol
The admin backend communicates with the game through:
1. **Save File Monitoring**: Watches game save files for changes
2. **REST API**: Game can POST updates to admin backend
3. **WebSocket**: Real-time bidirectional communication
4. **File System**: Shared data directory for logs and backups

### Security Considerations
- **Local Network Only**: Admin backend should only be accessible on local network
- **Authentication**: Basic auth for production deployments
- **CORS**: Configured to allow game client connections
- **Input Validation**: All admin inputs are validated before applying to game

## Development Workflow

### Adding New Features
1. Define API endpoint in `api/routes.py`
2. Create dashboard view in `templates/`
3. Add JavaScript frontend logic in `static/js/`
4. Update game integration if needed
5. Test with real game instance

### Monitoring Integration
The backend automatically:
- Tracks resource generation rates
- Monitors contract success/failure rates
- Logs crisis response times
- Analyzes player decision patterns
- Generates performance reports

## Production Deployment

### Recommended Hosting
- **Local Development**: Run directly with `python app.py`
- **Production**: Deploy with Gunicorn + Nginx
- **Docker**: Containerized deployment available
- **Cloud**: Can be deployed to Heroku, AWS, or similar

### Environment Variables
```bash
FLASK_ENV=production
GAME_SAVE_PATH=/path/to/game/saves
ADMIN_PASSWORD=secure_password
PORT=5000
```

## Troubleshooting

### Common Issues
- **Port conflicts**: Change port in config.py
- **Game connection**: Ensure game save path is correct
- **WebSocket issues**: Check CORS and firewall settings
- **Performance**: Monitor memory usage with large datasets

### Logs and Debugging
- Admin backend logs: `logs/admin.log`
- Game integration logs: `logs/game-integration.log`
- Error logs: `logs/errors.log`

## Future Enhancements

### Planned Features
- **Multi-player Support**: Monitor multiple game instances
- **Advanced Analytics**: Machine learning insights
- **Mobile Dashboard**: Responsive design for mobile devices
- **API Documentation**: Swagger/OpenAPI integration
- **Performance Profiling**: Detailed game performance analysis

This admin backend ensures the game can be monitored, analyzed, and debugged effectively while maintaining a clean separation between game logic and administrative tools.