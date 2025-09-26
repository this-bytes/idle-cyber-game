# Cyberspace Tycoon - Backend API

Python/Flask REST API backend for the Cyberspace Tycoon idle cybersecurity game.

## Features

- **SQLite Database**: Simple file-based persistence
- **Player Management**: Create, retrieve, and update player game states
- **Admin Panel**: Administrative endpoints for managing players and global settings
- **Game Integration**: RESTful API designed for LÖVE 2D Lua client integration
- **Auto-initialization**: Database and default global state created automatically

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Run the Server

```bash
python app.py
```

The server will start on `http://localhost:5000` and automatically:
- Create the SQLite database (`database.db`)
- Initialize tables for players and global game state
- Set up default global multipliers

## API Endpoints

### Game Client Endpoints

These endpoints are designed for the LÖVE 2D game client:

#### Create Player
```http
POST /api/player/create
Content-Type: application/json

{
    "username": "player123",
    "current_currency": 1000,
    "prestige_level": 0,
    "reputation": 0,
    "xp": 0,
    "mission_tokens": 0
}
```

#### Get Player Data
```http
GET /api/player/player123
```

Returns player data with idle time calculation for offline earnings.

#### Save Player Data
```http
POST /api/player/save
Content-Type: application/json

{
    "username": "player123",
    "current_currency": 5000,
    "prestige_level": 1,
    "reputation": 150,
    "xp": 2500,
    "mission_tokens": 3
}
```

### Admin Panel Endpoints

Administrative endpoints for game management:

#### List All Players
```http
GET /admin/players
```

#### Edit Player Data
```http
PUT /admin/player/1
Content-Type: application/json

{
    "username": "newname",
    "current_currency": 10000,
    "prestige_level": 2
}
```

#### Get Global Game State
```http
GET /admin/global
```

#### Update Global Settings
```http
PUT /admin/global
Content-Type: application/json

{
    "base_production_rate": 1.5,
    "global_multiplier": 2.0,
    "max_players": 500,
    "maintenance_mode": false
}
```

### Health Check
```http
GET /health
```

## Database Schema

### Player Table
- `id` (Primary Key, Auto-increment)
- `username` (String, Unique)
- `current_currency` (Integer, Default: 0)
- `prestige_level` (Integer, Default: 0)
- `reputation` (Integer, Default: 0)
- `xp` (Integer, Default: 0)
- `mission_tokens` (Integer, Default: 0)
- `last_login` (DateTime)
- `created_at` (DateTime)

### Global Game State Table
- `id` (Primary Key, Fixed: 1)
- `base_production_rate` (Float, Default: 1.0)
- `global_multiplier` (Float, Default: 1.0)
- `max_players` (Integer, Default: 1000)
- `maintenance_mode` (Boolean, Default: false)
- `last_updated` (DateTime)

## Integration with LÖVE 2D Game

The API is designed to integrate with the existing Lua save system. You can modify the `SaveSystem` in your LÖVE 2D game to:

1. **Create Player**: Call `/api/player/create` when starting a new game
2. **Load Game**: Call `/api/player/<username>` to retrieve saved state
3. **Save Game**: Call `/api/player/save` periodically or on game exit
4. **Offline Earnings**: Use the `idle_time_seconds` from player data to calculate offline progress

### Example Lua Integration

```lua
-- In your save system, replace local file operations with HTTP calls
local http = require("socket.http")
local json = require("json")

function SaveSystem:saveToServer(username, gameData)
    local postData = json.encode({
        username = username,
        current_currency = gameData.resources.money,
        reputation = gameData.resources.reputation,
        xp = gameData.resources.xp,
        mission_tokens = gameData.resources.missionTokens,
        prestige_level = gameData.prestige or 0
    })
    
    local result = http.request{
        url = "http://localhost:5000/api/player/save",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(postData)
        },
        source = ltn12.source.string(postData)
    }
end
```

## Development

### Testing the API

You can test the API using curl:

```bash
# Create a player
curl -X POST http://localhost:5000/api/player/create \
  -H "Content-Type: application/json" \
  -d '{"username": "testplayer"}'

# Get player data
curl http://localhost:5000/api/player/testplayer

# Save player progress
curl -X POST http://localhost:5000/api/player/save \
  -H "Content-Type: application/json" \
  -d '{"username": "testplayer", "current_currency": 5000, "reputation": 100}'
```

### Database Management

The SQLite database file (`database.db`) will be created automatically. To inspect it:

```bash
sqlite3 database.db
.tables
.schema players
SELECT * FROM players;
```

## Security Notes

This is a basic implementation suitable for development and small-scale deployment. For production use, consider adding:

- Authentication/authorization
- Input sanitization and validation
- Rate limiting
- HTTPS/TLS encryption
- Database connection pooling
- Logging and monitoring