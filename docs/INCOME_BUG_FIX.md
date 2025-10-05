# Income Generation Bug Fix - RESOLVED ✅

## Problem Summary
**User Report**: "One contract generated, i accepted but nothing seemed to happen. income is 0 and doesnt increase"

**Impact**: CRITICAL - Core idle game loop completely broken. No income generation means no progression.

## Root Cause Analysis

### The Bugs (Plural!)
This issue had **TWO critical bugs** that both needed to be fixed:

#### Bug #1: Dictionary Length Check
Located in `src/systems/contract_system.lua` at line 112:

```lua
function ContractSystem:generateIncome()
    local totalIncome = 0
    
    if #self.activeContracts == 0 then  -- ❌ BUG HERE
        return
    end
    // ... rest of income calculation
end
```

**Problem**: Using the **length operator (`#`)** on a **dictionary (hash table)**.
- `self.activeContracts` is a dictionary indexed by contract IDs: `{["basic_small_business"] = contract, ...}`
- The `#` operator in Lua **only works on arrays** (numeric sequential indices)
- For dictionaries, `#` always returns `0`, regardless of contents
- Result: Function returned early every time, never calculating income

#### Bug #2: Game Never Started
Located in `src/soc_game.lua`:

**Problem**: `isGameStarted` was never set to `true`, so systems never received update calls.

The game flow was:
1. Main menu shows
2. Player clicks "Start Game" or "Continue" 
3. Scene changes to "soc_view"
4. **But gameplay systems were never activated** because `isGameStarted` remained `false`

In `SOCGame:update(dt)`:
```lua
if not self.isGameStarted then
    if self._pendingStart then
        self._pendingStart = nil
        self:startGame()
    end
    return  -- ❌ Systems never get updated!
end

-- This code was never reached:
if self.systems.contractSystem then self.systems.contractSystem:update(dt) end
```

### Architecture Context

The event-driven income system works as follows:

1. **ContractSystem** calculates income every 0.1 seconds via `generateIncome()`
2. **Publishes event**: `eventBus:publish("resource_add", {money = totalIncome})`
3. **ResourceManager** subscribes to `"resource_add"` events
4. **Processes event**: Adds money to player's resources
5. **Updates UI**: Publishes `"resource_changed"` event for UI refresh

Bug #1 prevented the income calculation from ever producing non-zero income.
Bug #2 prevented ContractSystem:update() from ever being called in the first place.

## The Fixes

### Fix #1: Replace Broken Dictionary Check
Replaced the broken length check with proper dictionary iteration:

```lua
function ContractSystem:generateIncome()
    local totalIncome = 0
    
    -- ✅ FIXED: Proper dictionary check
    local hasActiveContracts = false
    for _ in pairs(self.activeContracts) do
        hasActiveContracts = true
        break
    end
    
    if not hasActiveContracts then
        return
    end
    
    -- ... rest of income calculation
end
```

**How It Works**:
- Iterate through the dictionary using `pairs()`
- Break immediately on first entry (only checking existence)
- Efficient: O(1) check for empty vs non-empty

### Fix #2: Start Game When Entering Main Gameplay
Added event subscription to start the game when transitioning to `soc_view`:

```lua
-- In SOCGame:load()
self.eventBus:subscribe("request_scene_change", function(data)
    if data and data.scene == "soc_view" and not self.isGameStarted then
        print("🎮 Starting game systems (entering soc_view)...")
        self._pendingStart = true
    end
end)
```

**How It Works**:
- Listen for scene change events
- When player enters "soc_view" (main gameplay screen), set `_pendingStart` flag
- On next update cycle, `startGame()` is called
- `isGameStarted` is set to `true`
- Systems begin receiving update() calls

### Fix #3: Remove Invalid IdleSystem Update
Removed erroneous call to `idleSystem:update()` which doesn't exist:

```lua
-- ❌ REMOVED THIS LINE:
if self.systems.idleSystem then self.systems.idleSystem:update(dt) end
```

IdleSystem is a state management system, not an active update system.

## Testing Verification

### Expected Behavior After Fix
1. Launch game → See welcome message
2. Navigate to Contracts Board
3. Accept a contract (e.g., "Basic WiFi Security")
4. **Money counter increases** visibly in real-time
5. Progress bar on contract advances
6. Contract completes after duration expires

### Actual Results (Verified Working)
Console output from successful test:

```
✅ Contract accepted: Food Delivery Network ($3200, 40s, $80.00/sec)
✅ Contract accepted: National Telecom ($16000, 140s, $114.29/sec)
[Multiple income events showing $237.09/sec and $459.80/sec being added]
```

Player report: Money is now increasing correctly! ✅

### Income Calculation
For "Basic WiFi Security" contract:
- **Base Budget**: $300
- **Base Duration**: 20 seconds
- **Income Rate**: $300 / 20 = $15/sec
- **Update Interval**: Every 0.1 seconds
- **Per-tick Income**: $15 * 0.1 = $1.50 per update

## Impact

### Before Fixes
- ❌ No income generated from contracts
- ❌ Idle loop completely broken
- ❌ Game unplayable - no progression possible
- ❌ Player couldn't hire specialists, buy upgrades, or advance

### After Fixes
- ✅ Income generates every 0.1 seconds from active contracts
- ✅ Idle loop functions correctly
- ✅ Money visibly increases in real-time
- ✅ Player can progress through gameplay loop
- ✅ Core idle tycoon mechanics restored

## Lessons Learned

### Lua Data Structure Gotchas
1. **Arrays vs Dictionaries**: Lua tables can be both, but operators behave differently
2. **Length operator (`#`)**: Only works on sequential numeric indices
3. **Dictionary checking**: Always use `pairs()` iterator or `next()` function
4. **Silent failures**: Wrong operator doesn't error - just returns wrong value

### Game State Management
1. **Explicit initialization required**: `isGameStarted` must be set when gameplay begins
2. **Scene transitions need hooks**: Main gameplay scene should trigger system activation
3. **Update loops must be verified**: Systems won't run unless explicitly updated

### Event-Driven Architecture Benefits
- Bug was isolated to single function (once systems were running)
- Event system continued working correctly
- No cascading failures
- Easy to add debug logging at event boundaries

### Testing Gaps
- Unit tests didn't catch dictionary issue (likely used array-style contracts)
- Integration tests needed for real gameplay scenarios
- Need test cases specifically for dictionary operations
- Need tests that verify systems are actually being updated

## Files Modified

### Primary Fixes
- `src/systems/contract_system.lua` - Fixed `generateIncome()` dictionary check
- `src/soc_game.lua` - Added game start trigger on scene change
- `src/soc_game.lua` - Removed invalid `idleSystem:update()` call

### Dependencies
- `src/systems/resource_manager.lua` - Receives income events (no changes needed)
- `src/core/event_bus.lua` - Event pub/sub system (no changes needed)
- `src/scenes/scene_manager.lua` - Handles scene transitions (no changes needed)

### Data Files
- `src/data/contracts.json` - Contract definitions with `baseBudget` and `baseDuration`

## Future Improvements

1. **Add Unit Tests**: 
   - Test `generateIncome()` with dictionary-based activeContracts
   - Test game state initialization flow
   - Test system update calls
   
2. **Type Safety**: Consider using type annotations or runtime checks

3. **Performance**: Cache contract count instead of recalculating

4. **Error Handling**: Add validation that contracts have reward/duration fields

5. **Architecture**: 
   - Make game start more explicit (remove reliance on scene change events)
   - Consider a proper game state machine

## Commit Message

```
fix(core): Critical bugs - income generation and game loop not starting

PROBLEMS:
1. Contracts accepted but income stayed at $0
2. Game systems never received update() calls
3. Core idle game loop non-functional
4. Game completely unplayable

ROOT CAUSES:
1. Used length operator (#) on dictionary (hash table)
   - # only works on arrays, returns 0 for dictionaries
   - generateIncome() returned early every time
   
2. isGameStarted never set to true
   - Systems update() only called when game started
   - No hook to start game when entering gameplay scene
   
3. Invalid call to idleSystem:update() method
   - IdleSystem doesn't have update method
   - Caused crash when systems did start running

FIXES:
1. Replace # check with proper pairs() iteration
2. Add event subscription to start game on soc_view entry  
3. Remove idleSystem:update() call
4. Check dictionary is non-empty before processing

IMPACT:
- Income now generates every 0.1s from active contracts
- Money increases visibly in real-time
- Idle game loop restored to working state
- Players can progress through game normally
- Game is now playable!

FILES:
- src/systems/contract_system.lua (fixed generateIncome)
- src/soc_game.lua (added game start trigger, removed bad update)
```

---

**Status**: ✅ RESOLVED - Fully tested and working
**Priority**: CRITICAL - Showstopper bugs fixed
**Date**: 2025
**Testing**: Verified in-game with multiple contracts generating income correctly
