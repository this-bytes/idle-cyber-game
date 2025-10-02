# Game State Engine Documentation

## Overview

The **GameStateEngine** is a comprehensive state management system that handles resource generation, persistence, offline earnings calculation, and automated state synchronization across all game systems.

## Features

- **Centralized State Management**: Single source of truth for all game state
- **Automatic Save/Load**: Persistent state across game sessions
- **Offline Earnings**: Calculates progress made while player is away
- **Auto-Save**: Periodic automatic saves (configurable interval)
- **State Validation**: Error recovery and version compatibility checks
- **Multi-System Support**: Manages state for all registered systems
- **Event-Driven**: Publishes events for UI updates and notifications

## Architecture

### Core Components

1. **GameStateEngine** (`src/systems/game_state_engine.lua`)
   - Main state management system
   - Handles save/load operations
   - Calculates offline earnings
   - Manages auto-save functionality

2. **System Registration**
   - Systems register with the engine
   - Engine collects state from registered systems
   - Supports both `getState()/loadState()` and `getSaveData()/loadSaveData()` patterns

3. **State Persistence**
   - Saves to `game_state.json` in LÖVE save directory
   - JSON format for human-readable saves
   - Version tracking for compatibility

## Usage

### Initialization

```lua
local GameStateEngine = require("src.systems.game_state_engine")

-- Create the engine
local gameStateEngine = GameStateEngine.new(eventBus)

-- Register systems for state management
gameStateEngine:registerSystem("resourceManager", resourceManager)
gameStateEngine:registerSystem("skillSystem", skillSystem)
gameStateEngine:registerSystem("upgradeSystem", upgradeSystem)
-- ... register other systems

-- Load saved state (if exists)
local saveLoaded = gameStateEngine:loadState()
if saveLoaded then
    print("Game state loaded from previous session")
else
    print("Starting new game")
end
```

### Update Loop

```lua
function game:update(dt)
    -- Update the engine (handles auto-save)
    if gameStateEngine then
        gameStateEngine:update(dt)
    end
    
    -- Update other systems...
end
```

### Calculating Offline Earnings

```lua
function game:startGame()
    -- Calculate offline progress
    local offlineProgress = gameStateEngine:calculateOfflineEarnings()
    
    if offlineProgress then
        print(string.format("Offline earnings: $%d", offlineProgress.netGain))
        print(string.format("Time away: %d seconds", offlineProgress.idleTime))
    end
end
```

### Shutdown

```lua
function game:shutdown()
    -- Save game state before exit
    if gameStateEngine then
        gameStateEngine:quickSave()
    end
end
```

## System Integration

For a system to be managed by the GameStateEngine, it must implement:

### Option 1: Standard Methods (Recommended)

```lua
-- Get current state for saving
function MySystem:getState()
    return {
        myValue = self.myValue,
        myCounter = self.myCounter
    }
end

-- Load state from saved data
function MySystem:loadState(state)
    if state.myValue then
        self.myValue = state.myValue
    end
    if state.myCounter then
        self.myCounter = state.myCounter
    end
end
```

### Option 2: Legacy Methods (Also Supported)

```lua
-- Get save data
function MySystem:getSaveData()
    return {
        myValue = self.myValue
    }
end

-- Load save data
function MySystem:loadSaveData(data)
    if data.myValue then
        self.myValue = data.myValue
    end
end
```

## API Reference

### GameStateEngine.new(eventBus)

Creates a new GameStateEngine instance.

**Parameters:**
- `eventBus` - Event bus for publishing state events

**Returns:** GameStateEngine instance

### gameStateEngine:registerSystem(name, system)

Registers a system for state management.

**Parameters:**
- `name` (string) - Unique name for the system
- `system` (table) - System instance with getState/loadState methods

**Returns:** boolean - Success status

### gameStateEngine:update(dt)

Updates the engine and handles auto-save.

**Parameters:**
- `dt` (number) - Delta time in seconds

### gameStateEngine:saveState()

Saves current game state to file.

**Returns:** boolean - Success status

### gameStateEngine:loadState()

Loads game state from file.

**Returns:** boolean - Success status (false if no save exists)

### gameStateEngine:calculateOfflineEarnings()

Calculates progress made while player was away.

**Returns:** table or nil
- `idleTime` - Seconds since last save
- `earnings` - Money earned
- `damage` - Damage taken from threats
- `netGain` - Net resource change
- `events` - List of events that occurred

### gameStateEngine:quickSave()

Performs immediate save (useful for manual saves or on exit).

**Returns:** boolean - Success status

### gameStateEngine:setAutoSave(enabled)

Enables or disables automatic saving.

**Parameters:**
- `enabled` (boolean) - Auto-save status

### gameStateEngine:setAutoSaveInterval(seconds)

Sets the auto-save interval.

**Parameters:**
- `seconds` (number) - Interval in seconds (minimum 10)

**Returns:** boolean - Success status

### gameStateEngine:getStateSummary()

Gets summary information about the current state.

**Returns:** table with state summary

### gameStateEngine:exportState()

Exports current state as JSON string.

**Returns:** string - JSON representation of state

### gameStateEngine:importState(jsonString)

Imports state from JSON string.

**Parameters:**
- `jsonString` (string) - JSON state data

**Returns:** boolean - Success status

### gameStateEngine:resetState()

Resets the game state (for new game).

### gameStateEngine:saveExists()

Checks if a save file exists.

**Returns:** boolean

### gameStateEngine:deleteSave()

Deletes the save file.

**Returns:** boolean - Success status

## Events Published

The GameStateEngine publishes the following events through the event bus:

### game_state_saved

Published when state is successfully saved.

**Data:**
```lua
{
    timestamp = os.time() -- Time of save
}
```

### game_state_loaded

Published when state is successfully loaded.

**Data:**
```lua
{
    totalPlayTime = number, -- Total play time
    timestamp = number      -- Load timestamp
}
```

### offline_earnings_calculated

Published when offline earnings are calculated.

**Data:**
```lua
{
    idleTime = number,     -- Seconds away
    earnings = number,     -- Money earned
    damage = number,       -- Damage taken
    netGain = number,      -- Net change
    events = table         -- List of events
}
```

### game_state_reset

Published when state is reset (new game).

**Data:** Empty table

## Configuration

### Default Settings

- **Auto-save interval**: 60 seconds
- **Auto-save enabled**: true
- **Save file**: `game_state.json`
- **Version**: "1.0.0"

### Customization

```lua
-- Change auto-save interval to 2 minutes
gameStateEngine:setAutoSaveInterval(120)

-- Disable auto-save
gameStateEngine:setAutoSave(false)
```

## Save File Format

The save file is stored as JSON with the following structure:

```json
{
    "version": "1.0.0",
    "timestamp": 1234567890,
    "lastSaveTime": 1234567890,
    "totalPlayTime": 3600.5,
    "systems": {
        "resourceManager": {
            "resources": {
                "money": 50000,
                "reputation": 100,
                "xp": 500
            },
            "generationRates": { ... },
            "multipliers": { ... }
        },
        "skillSystem": { ... },
        "upgradeSystem": { ... }
    }
}
```

## Offline Earnings Calculation

The offline earnings system uses the IdleSystem to calculate:

1. **Base Earnings**: Based on resource generation rates
2. **Threat Simulation**: Realistic cyber threats while away
3. **Damage Calculation**: Security infrastructure effectiveness
4. **Net Gain**: Earnings minus damage (with caps)

The calculation respects:
- Security rating and defenses
- Threat mitigation upgrades
- Damage caps (prevents complete loss)
- Time-based threat frequency

## Error Handling

The GameStateEngine includes comprehensive error handling:

- **Version Mismatch**: Attempts to load anyway with warning
- **Missing Systems**: Logs warning but continues
- **Save Failures**: Returns false and logs error
- **Load Failures**: Returns false and logs error
- **System Errors**: Catches exceptions during state operations

## Testing

### Unit Tests

Located in `tests/systems/test_game_state_engine.lua`

Run with:
```bash
lua5.3 tests/systems/test_game_state_engine.lua
```

Tests cover:
- Initialization
- System registration
- State collection and loading
- Save/load operations
- Auto-save functionality
- Export/import operations
- State reset

### Integration Tests

Located in `tests/integration/test_game_state_integration.lua`

Run with:
```bash
lua5.3 tests/integration/test_game_state_integration.lua
```

Tests cover:
- Full game state flow
- Offline earnings calculation
- Auto-save in game context
- State persistence across sessions
- Multiple system management

## Best Practices

1. **Register Early**: Register all systems during game initialization
2. **Update Regularly**: Call `update(dt)` every frame
3. **Save on Exit**: Always call `quickSave()` during shutdown
4. **Handle Load Failures**: Check return value of `loadState()`
5. **Version Management**: Update version string when save format changes
6. **Test State Methods**: Ensure all systems implement getState/loadState correctly

## Migration Guide

### From Legacy SaveSystem

If you're migrating from the old SaveSystem:

1. Replace SaveSystem with GameStateEngine
2. Register all systems with the engine
3. Add getState/loadState methods to systems (if using getSaveData/loadSaveData)
4. Update shutdown to use quickSave()
5. Update startup to calculate offline earnings

### Example Migration

**Before:**
```lua
-- Old code
local saveSystem = SaveSystem.new()
saveSystem:save(gameData)
```

**After:**
```lua
-- New code
local gameStateEngine = GameStateEngine.new(eventBus)
gameStateEngine:registerSystem("resourceManager", resourceManager)
gameStateEngine:saveState()
```

## Troubleshooting

### State Not Persisting

1. Check that system is registered: `gameStateEngine:registerSystem(name, system)`
2. Verify system has getState() method
3. Check console for error messages
4. Verify save file exists: `gameStateEngine:saveExists()`

### Offline Earnings Not Calculating

1. Ensure IdleSystem is registered: `gameStateEngine:registerSystem("idleSystem", idleSystem)`
2. Check lastSaveTime is set correctly
3. Verify player was away for > 60 seconds
4. Check console for calculation logs

### Auto-save Not Working

1. Verify auto-save is enabled: `gameStateEngine.autoSaveEnabled`
2. Check interval is not too long
3. Ensure update() is called regularly
4. Check console for save events

## Performance Considerations

- **Save Operations**: JSON encoding is CPU-intensive, keep auto-save interval reasonable
- **State Collection**: Systems should avoid expensive operations in getState()
- **Memory Usage**: Large state objects increase save file size
- **Disk I/O**: Auto-save writes to disk, don't set interval too low

## Security Considerations

- Save files are stored in LÖVE save directory (user-specific)
- JSON format is human-readable (users can edit saves)
- No encryption or validation beyond version check
- Consider adding checksums for competitive games

## Future Enhancements

Potential improvements for the GameStateEngine:

1. **Cloud Saves**: Backend integration for cross-device saves
2. **Compression**: Reduce save file size for large games
3. **Encryption**: Prevent save editing for competitive games
4. **Versioning**: Automatic migration between save format versions
5. **Backup System**: Keep multiple save slots or backups
6. **Delta Saves**: Only save changed state to reduce I/O
7. **Async Operations**: Non-blocking save/load for large states

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review test files for examples
3. Check console output for error messages
4. Review the source code comments

## License

MIT License - See LICENSE file for details
