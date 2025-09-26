# LÖVE 2D Client-Server API Integration Guide

This guide explains how to use the client-server bridge implementation for the Cyberspace Tycoon idle game.

## Overview

The integration provides a complete client-server bridge that allows the LÖVE 2D game to:
- Save and load player data to/from a Flask backend
- Handle both online and offline gameplay
- Synchronize game state across devices
- Apply offline earnings when returning to the game

## Architecture

```
LÖVE 2D Game Client ←→ api.lua ←→ Flask Backend ←→ SQLite Database
```

### Key Components

1. **api.lua** - HTTP communication module
2. **NetworkSaveSystem.lua** - Hybrid save system
3. **dkjson.lua** - JSON encoding/decoding library
4. **Flask Backend** - RESTful API server (already implemented)

## Quick Start

### 1. Prerequisites

- LÖVE 2D 11.3+ (12.0+ recommended for better HTTP support)
- Flask backend server running on localhost:5000
- Internet connection (optional - falls back to local saves)

### 2. Basic Usage

The integration is already built into the game. When you run the game:

1. **Automatic Setup**: The game creates a unique player ID and configures hybrid save mode
2. **Seamless Saving**: Game saves both locally and to server automatically
3. **Offline Support**: Game continues to work even when server is offline
4. **Automatic Sync**: When server comes back online, saves are synchronized

### 3. In-Game Controls

- **N** - Show network status and connection info
- **I** - Show business info including network status
- Standard game saves automatically use the network system

## API Module (api.lua)

### Core Functions

```lua
local api = require("api")

-- Test server connection
api.testConnection(callback, useAsync)

-- Create new player
api.createPlayer(username, callback, useAsync)

-- Load player data
api.loadPlayer(username, callback, useAsync)

-- Save player data
api.savePlayer(username, currency, prestige_level, additionalData, callback, useAsync)

-- Get global game state
api.getGlobalState(callback, useAsync)
```

### Synchronous vs Asynchronous

```lua
-- Synchronous (blocks game, use sparingly)
local success, result = api.testConnection(nil, false)

-- Asynchronous (recommended for gameplay)
api.testConnection(function(success, result)
    if success then
        print("Connected to server!")
    else
        print("Server offline: " .. result)
    end
end)
```

### Error Handling

The API module provides comprehensive error handling:

```lua
api.loadPlayer("player123", function(success, result)
    if success then
        -- Handle successful load
        local playerData = result.player
        print("Loaded player: " .. playerData.username)
    else
        -- Handle error
        print("Load failed: " .. result)
        -- Game falls back to local save automatically
    end
end)
```

## Network Save System

### Save Modes

1. **"local"** - Save only to local files
2. **"server"** - Save only to server (with emergency local backup)
3. **"hybrid"** - Save to both local and server (recommended)

```lua
-- Configure save mode
gameState.systems.save:setSaveMode("hybrid")

-- Set player username
gameState.systems.save:setUsername("my_unique_player")

-- Enable/disable offline mode
gameState.systems.save:setOfflineMode(true)
```

### Connection Status

```lua
local status = gameState.systems.save:getConnectionStatus()
print("Online: " .. (status.isOnline and "YES" or "NO"))
print("Save Mode: " .. status.saveMode)
print("Username: " .. status.username)
```

## Data Format

### Game Data Structure

```lua
local gameData = {
    resources = {
        money = 1000,
        reputation = 50,
        xp = 100,
        missionTokens = 5,
        prestige = 0
    },
    contracts = { ... },    -- Contract system state
    specialists = { ... },  -- Specialist system state
    upgrades = { ... },     -- Upgrade system state
    version = "1.0.0",
    timestamp = os.time()
}
```

### Server Response Format

```json
{
    "success": true,
    "player": {
        "id": 1,
        "username": "player123",
        "current_currency": 1000,
        "reputation": 50,
        "xp": 100,
        "mission_tokens": 5,
        "prestige_level": 0,
        "idle_time_seconds": 3600,
        "last_login": "2023-01-01T12:00:00",
        "created_at": "2023-01-01T10:00:00"
    }
}
```

## Advanced Features

### Offline Earnings

When a player returns after being offline, the system calculates earnings:

```lua
-- Automatic offline earnings calculation
if savedData.idleTimeSeconds and savedData.idleTimeSeconds > 0 then
    savedData = gameState.systems.save:applyOfflineEarnings(savedData, savedData.idleTimeSeconds)
    print("Offline earnings applied!")
end
```

### Custom Data Storage

Store additional game system data:

```lua
local additionalData = {
    reputation = resources.reputation,
    xp = resources.xp,
    mission_tokens = resources.missionTokens,
    -- Store complex data as JSON strings
    contracts_data = gameData.contracts,
    specialists_data = gameData.specialists
}

api.savePlayer(username, currency, prestige, additionalData, callback)
```

### Global Game State

Access server-wide multipliers and settings:

```lua
api.getGlobalState(function(success, result)
    if success and result.global_state then
        local multipliers = result.global_state
        -- Apply global multipliers to gameplay
        local productionRate = baseRate * multipliers.base_production_rate
        local globalBonus = multipliers.global_multiplier
    end
end)
```

## Testing

### Run API Tests

1. **Start Backend Server**:
   ```bash
   cd backend
   python app.py
   ```

2. **Run Test Script**:
   ```bash
   cd backend
   python test_api.py
   ```

3. **Test in LÖVE** (if available):
   ```bash
   love . --test-api
   ```

### Manual Testing

1. Start the game normally
2. Press **N** to check network status
3. Play the game - saves happen automatically
4. Close and restart the game to test loading
5. Try with server offline to test offline mode

## Troubleshooting

### Common Issues

1. **"Connection Failed"**
   - Ensure Flask server is running on localhost:5000
   - Check firewall settings
   - Game continues with local saves

2. **"JSON Decode Error"**
   - Server response format may be incorrect
   - Check backend logs for errors
   - Verify dkjson.lua is properly loaded

3. **"Player Not Found"**
   - Normal for first-time players
   - API automatically creates new player
   - Username may have changed

### Debug Mode

Enable debug information:

```lua
-- In game, press 'D' to toggle debug mode
-- Shows network status, FPS, and system information
```

### Network Status Indicators

- **Green "ONLINE"** - Connected to server, saves syncing
- **Red "OFFLINE"** - Server unavailable, using local saves only
- **Gray "DISABLED"** - Offline mode enabled, network disabled

## Production Deployment

### Security Considerations

For production deployment, consider:

1. **Authentication**: Add player tokens and authentication
2. **Rate Limiting**: Prevent API abuse
3. **HTTPS**: Use secure connections
4. **Input Validation**: Validate all client data
5. **Encryption**: Encrypt sensitive save data

### Server Configuration

```lua
-- Configure for production server
local BASE_URL = "https://your-game-server.com/api/player"
```

### Load Balancing

For multiple servers, implement:
- Player session stickiness
- Database clustering
- Redis for shared state
- CDN for static assets

## Example Integration

### Complete Save/Load Cycle

```lua
-- On game start
gameState.systems.save:load(function(success, data)
    if success then
        Game.loadGameState(data)
        
        -- Apply offline earnings
        if data.idleTimeSeconds > 0 then
            local bonusEarnings = calculateOfflineEarnings(data.idleTimeSeconds)
            resources.money = resources.money + bonusEarnings
            print("Welcome back! You earned $" .. bonusEarnings .. " while away!")
        end
    else
        Game.initializeDefaultState()
    end
end)

-- Periodic auto-save (every 60 seconds)
function Game.handleAutoSave(dt)
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= 60 then
        Game.save()
        autoSaveTimer = 0
    end
end

-- On game exit
function love.quit()
    Game.save()
end
```

This integration provides a robust, production-ready client-server bridge that enhances the idle game experience with persistent, synchronized saves and offline earnings.