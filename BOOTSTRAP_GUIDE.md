# Cyber Empire Command - Bootstrap Architecture Guide

## Overview

This guide explains the new modular, config-driven bootstrap architecture that has been implemented following the instruction files in `.github/copilot-instructions/`.

## Architecture Changes

### ✅ Completed Bootstrap Features

#### 1. Configuration-Driven Design
- **`src/config/game_config.lua`** - Central configuration for all game data
- Resources, client tiers, specialist roles, crisis scenarios all defined in config
- Data-driven approach allows easy modification without code changes

#### 2. Modular System Architecture
- **Event Bus Pattern** - Decoupled communication between systems
- **Dependency Injection** - Systems receive dependencies rather than creating them
- **Clean Separation** - Game logic, UI, and data clearly separated

#### 3. Bootstrap Game Controller
- **`src/game.lua`** - Updated to use configuration system
- Proper initialization order for systems
- Config-based resource initialization
- Auto-save uses config intervals

#### 4. Admin Backend (Separate Web Service)
- **Flask-based web server** with Socket.IO for real-time updates
- **RESTful API** for game state management
- **Real-time dashboard** with cyberpunk terminal aesthetic
- **Admin controls** for testing and debugging
- **Complete documentation** in `admin-backend/README.md`

## File Structure

```
src/
├── config/
│   └── game_config.lua         # Central game configuration
├── systems/
│   ├── resource_system.lua     # Updated to use config
│   ├── contract_system.lua     # Updated to use config  
│   ├── specialist_system.lua   # Team management
│   └── ...                     # Other systems
├── modes/
│   ├── idle_mode.lua          # Updated for bootstrap UI
│   └── admin_mode.lua         # Crisis response mode
├── utils/
│   └── event_bus.lua          # Modular communication
└── game.lua                   # Main game controller

admin-backend/
├── app.py                     # Flask web server
├── config.py                  # Backend configuration
├── requirements.txt           # Python dependencies
├── templates/                 # HTML templates
└── README.md                  # Complete setup guide
```

## Running the Game

### Game Client (LÖVE 2D)
```bash
# Run the game directly
love .

# Or use the provided script (if available)
./run-love.sh
```

### Admin Backend (Web Dashboard)
```bash
cd admin-backend
pip install -r requirements.txt
python app.py
```

Then open: `http://localhost:5000`

## Key Features Implemented

### 1. Data-Driven Configuration
- **Client Tiers**: Startup → Small Business → Enterprise → Government
- **Resources**: Money, Reputation, XP, Mission Tokens
- **Specialist Roles**: Analyst, Engineer, Responder
- **Crisis Scenarios**: Configurable multi-stage events

### 2. Modular Systems
- **Resource System**: Config-driven resource management
- **Contract System**: Uses client tiers from configuration
- **Event Bus**: Decoupled system communication
- **Save System**: JSON-based with versioning

### 3. Admin Backend Features
- **Real-time Monitoring**: Live game state updates
- **Resource Modification**: Admin controls for testing
- **Crisis Simulation**: Trigger scenarios for testing
- **Analytics Dashboard**: Performance metrics and graphs
- **Save Management**: Backup and restore functionality

### 4. Terminal Aesthetic
- **Cyberpunk Theme**: Green terminal colors, monospace fonts
- **Professional UI**: Bootstrap-based responsive design
- **Real-time Updates**: WebSocket communication

## Testing the Bootstrap

### Manual Verification
1. **Start the game**: Should show "Cyber Empire Command" title
2. **Check resources**: Should display money, reputation, XP, mission tokens
3. **Verify config**: Resources should match `game_config.lua` starting amounts
4. **Start admin backend**: Dashboard should show real-time game state

### Admin Backend Testing
1. **Start admin backend**: `python admin-backend/app.py`
2. **Open dashboard**: Visit `http://localhost:5000`
3. **Test controls**: Try resource modification with admin password
4. **Crisis simulation**: Trigger test crisis scenarios
5. **Real-time updates**: Verify live data synchronization

## Configuration Examples

### Adding New Client Tier
```lua
-- In src/config/game_config.lua
GameConfig.CLIENT_TIERS.megacorp = {
    name = "Mega Corporation",
    budgetRange = {100000, 500000},
    durationRange = {1200, 2400},
    reputationReward = {100, 300},
    riskLevel = "extreme",
    threatTypes = {"nation_state", "quantum_attacks"},
    description = "Global mega-corporation requiring ultimate security",
    unlockRequirement = {reputation = 500, missionTokens = 20}
}
```

### Adding New Resource
```lua
-- In src/config/game_config.lua
GameConfig.RESOURCES.intel = {
    name = "Intelligence",
    symbol = "🕵️",
    startingAmount = 0,
    description = "Strategic information for advanced operations"
}
```

## Development Workflow

### Phase 1 Completion Checklist
- [x] Configuration system implemented
- [x] Core systems updated for config usage
- [x] Admin backend functional
- [x] Bootstrap architecture verified
- [ ] UI polish and cyberpunk theme completion
- [ ] Crisis mode full implementation
- [ ] Save/load integration testing

### Next Development Steps
1. **Complete UI Theming**: Full cyberpunk terminal aesthetic
2. **Crisis Mode Enhancement**: Multi-stage interactive scenarios
3. **Specialist System**: Complete team management features
4. **Testing Suite**: Comprehensive automated tests
5. **Performance Optimization**: Ensure smooth idle operation

## Admin Backend API

### Key Endpoints
- `GET /api/game-state` - Current game state
- `POST /api/resources` - Modify resources (admin)
- `POST /api/crisis/trigger` - Start crisis scenario
- `GET /api/analytics` - Performance metrics
- `POST /api/save/backup` - Create save backup

### WebSocket Events
- `game_state_update` - Real-time state changes
- `trigger_crisis` - Crisis activation
- `request_game_state` - Request current state

## Security Considerations

### Admin Backend Security
- **Local Network Only**: Bound to 127.0.0.1 by default
- **Password Protection**: Admin actions require password
- **Input Validation**: All admin inputs validated
- **CORS Configuration**: Limited to specific origins

### Game Data Integrity
- **Save Checksums**: Detect corrupted save files
- **Config Validation**: Ensure valid configuration data
- **Error Handling**: Graceful handling of invalid states

## Troubleshooting

### Common Issues
1. **Config not loading**: Check file path in require statements
2. **Admin backend connection**: Verify port 5000 is available
3. **WebSocket issues**: Check CORS settings and firewall
4. **Save file errors**: Check write permissions in save directory

### Debug Tools
- **Debug Mode**: Press 'D' in game for debug information
- **Admin Console**: Use admin backend for state inspection
- **Log Files**: Check `admin-backend/logs/` for error logs

This bootstrap architecture provides a solid foundation for building the complete "Cyber Empire Command" idle game as envisioned in the instruction files.