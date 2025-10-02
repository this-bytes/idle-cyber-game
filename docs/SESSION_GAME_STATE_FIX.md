# Game State Management & Offline Earnings - Implementation Summary

## Issues Fixed

### 1. **Main Menu Not Starting Game**
**Problem:** Game systems (contracts, threats) were running even on the main menu, causing incidents to fire before player started.

**Solution:** 
- Added `isGameStarted` flag to `SOCGame`
- Modified `update()` to only run game systems when `isGameStarted == true`
- Subscribe to `scene_request` event to detect when player starts game from main menu
- Main menu remains interactive while game systems stay idle

### 2. **Missing handleThreatDetected Method**
**Problem:** `src/scenes/soc_view.lua:71: attempt to call method 'handleThreatDetected' (a nil value)`

**Solution:**
- Added `handleThreatDetected(threat)` method to SOCView
- Creates incident from threat and adds to active incidents
- Displays notification when threat is detected
- Added `handleIncidentResolved(data)` method for proper incident cleanup

### 3. **Offline Earnings Not Tracked**
**Problem:** No way to calculate earnings while player was away from game.

**Solution:**
- Added `lastExitTime` tracking to SOCGame
- Implemented `saveExitTime()` to save timestamp when game exits
- Implemented `loadExitTime()` to load timestamp on game start
- Added `startGame()` method that calculates offline progress using IdleSystem
- Displays offline earnings notification showing time away, earnings, damage, and net gain
- Integrates with existing `IdleSystem.calculateOfflineProgress()`

## Technical Implementation

### SOCGame Changes (`src/soc_game.lua`)

```lua
-- New properties
self.isGameStarted = false
self.lastExitTime = nil

-- Game state management
function SOCGame:startGame()
    self.isGameStarted = true
    -- Calculate offline earnings if player was away
    if self.lastExitTime and self.systems.idleSystem then
        local idleTimeSeconds = os.time() - self.lastExitTime
        if idleTimeSeconds > 60 then
            local offlineProgress = self.systems.idleSystem:calculateOfflineProgress(idleTimeSeconds)
            -- Apply earnings and show notification
        end
    end
end

-- Modified update to only run systems when game started
function SOCGame:update(dt)
    self.sceneManager:update(dt) -- Always update (for menus)
    
    if not self.isGameStarted then
        return -- Don't update game systems until started
    end
    
    -- Update all game systems...
end

-- Save/load exit time
function SOCGame:saveExitTime()
    love.filesystem.write("last_exit.dat", string.format("%d", os.time()))
end

function SOCGame:loadExitTime()
    if love.filesystem.getInfo("last_exit.dat") then
        local data = love.filesystem.read("last_exit.dat")
        self.lastExitTime = tonumber(data)
    end
end
```

### SOCView Changes (`src/scenes/soc_view.lua`)

```lua
-- Added missing threat handler
function SOCView:handleThreatDetected(threat)
    local incident = {
        id = threat.id,
        name = threat.name,
        description = threat.description,
        severity = threat.severity,
        timeRemaining = threat.duration or 30,
        threat = threat
    }
    table.insert(self.socStatus.activeIncidents, incident)
    self.notificationPanel:addNotification("Threat Detected: " .. incident.name, incident.severity)
end

-- Added incident resolution handler
function SOCView:handleIncidentResolved(data)
    -- Remove incident from active list
    -- Show success notification
end

-- Added offline earnings display
function SOCView:showOfflineEarnings(data)
    local message = string.format(
        "Welcome back! Away for %s\\nEarned: $%d | Damage: $%d | Net: $%d",
        data.timeAway, data.earnings, data.damage, data.netGain
    )
    self.notificationPanel:addNotification(message, "INFO")
end
```

## Game Flow

### Before Fix
1. Game starts → All systems active immediately
2. Threats generate on main menu (bad!)
3. No offline earnings tracking
4. Error when threat detected

### After Fix
1. Game starts → Only menu systems active
2. Player sees main menu (idle state)
3. Player clicks "Start SOC Operations"
4. `scene_request` event → `startGame()` called
5. Load last exit time → Calculate offline progress
6. Show offline earnings notification
7. Game systems now active
8. Threats generate normally (good!)
9. On exit → Save current time

## Event Flow

```
Main Menu
    ↓
  [Player clicks "Start SOC Operations"]
    ↓
  scene_request(scene="soc_view") published
    ↓
  SOCGame:startGame() triggered
    ↓
  ┌─────────────────────────────────┐
  │ 1. Set isGameStarted = true     │
  │ 2. Load lastExitTime            │
  │ 3. Calculate offline earnings   │
  │ 4. Apply earnings to resources  │
  │ 5. Publish notification event   │
  └─────────────────────────────────┘
    ↓
  Game systems start updating
    ↓
  SOCView shows offline earnings
```

## Offline Earnings Calculation

Handled by existing `IdleSystem:calculateOfflineProgress()`:

1. **Base Earnings**: Resource generation rate × time away
2. **Idle Bonus**: Early-game boost (200-700/sec based on security)
3. **Threat Simulation**: Realistic threat events during idle time
4. **Damage Calculation**: Security rating reduces threat damage
5. **Net Gain**: Total earnings - total damage

## Files Modified

1. `src/soc_game.lua`
   - Added game state management
   - Added offline earnings tracking
   - Modified update loop to respect game state

2. `src/scenes/soc_view.lua`
   - Added handleThreatDetected method
   - Added handleIncidentResolved method
   - Added showOfflineEarnings method
   - Added offline_earnings_calculated event subscription

3. `src/systems/contract_system.lua`
   - Added missing `return ContractSystem` statement (module loading fix)

## Testing Verification

✅ Game starts on main menu without running systems
✅ Main menu is interactive and responsive
✅ "Start SOC Operations" triggers game start
✅ Offline earnings calculated on game start
✅ Exit time saved when game closes
✅ No errors when threats are detected
✅ Incidents properly created and displayed
✅ Notifications show offline earnings summary

## Persistence

Exit time stored in: `<love-save-directory>/last_exit.dat`
- Format: Plain text Unix timestamp
- Example: `1759384113`
- Automatically created/updated on game exit
- Loaded on game initialization

## Benefits

1. **Better Idle Experience**: Players feel rewarded for being away
2. **Clean Separation**: Main menu is truly idle, no background processing
3. **Transparent Progress**: Clear display of what happened while away
4. **Fault Tolerant**: Gracefully handles missing files and errors
5. **Performance**: No wasted CPU cycles running systems on menu
6. **Security Themed**: Damage from threats even while offline adds realism

## Future Enhancements

- Visual popup for offline earnings (not just notification)
- Detailed log of what happened while away
- Option to disable offline threats for casual players
- Achievements for offline milestones
- Push notifications (mobile) for long idle periods
- Offline earnings cap to prevent exploitation
