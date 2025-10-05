# F3 Debug Overlay Fix

## Issue Description

The F3 debug overlay (stats_overlay_luis.lua) was not responding to F3 key presses. The overlay existed and was properly initialized, but could not be toggled on/off during gameplay.

## Root Cause

The `SOCGame:keypressed()` function in `src/soc_game.lua` was missing the F3 key handler. The function was only routing input to:
1. SceneManager
2. LUIS framework

But it never checked for the F3 key to toggle the debug overlay before passing control to other systems.

## Solution

Added F3 key handling as the **highest priority** in the input chain:

```lua
function SOCGame:keypressed(key, scancode, isrepeat)
    -- F3 toggles debug overlay (highest priority - works on any scene)
    if key == 'f3' and self.statsOverlay then
        self.statsOverlay:toggle()
        return
    end
    
    -- Route to overlayManager first (modal overlays block other input)
    if self.overlayManager and self.overlayManager:keypressed(key) then return end
    
    -- Then to scene manager
    if self.sceneManager and self.sceneManager:keypressed(key, scancode, isrepeat) then return end
    
    -- Finally to LUIS
    if self.luis and self.luis.keypressed(key, scancode, isrepeat) then return end
end
```

## Input Hierarchy (Priority Order)

1. **F3 Key** - Debug overlay toggle (game-wide, always available)
2. **OverlayManager** - Modal overlays (block input to lower layers)
3. **SceneManager** - Current scene input handling
4. **LUIS Framework** - UI widget input handling

## Testing

### Test Cases

1. **Basic Toggle**
   - [ ] Launch game
   - [ ] Press F3 → Debug overlay appears
   - [ ] Press F3 again → Debug overlay disappears

2. **Cross-Scene Functionality**
   - [ ] Open debug overlay on main menu (F3)
   - [ ] Navigate to SOC View → overlay persists
   - [ ] Navigate to Upgrade Shop → overlay persists
   - [ ] Press F3 → overlay closes on any scene

3. **ESC Key Close**
   - [ ] Open debug overlay (F3)
   - [ ] Press ESC → overlay closes
   - [ ] Press F3 again → overlay reopens

4. **Data Display**
   - [ ] Open debug overlay (F3)
   - [ ] Verify all 12 panels display data:
     - Column 1: Resources, Contracts, Threats, Events
     - Column 2: Specialists, Upgrades, Skills, RNG State
     - Column 3: Idle System, Progression, Achievements, Summary
   - [ ] Verify data updates in real-time (every 0.5s)

5. **Input Blocking**
   - [ ] Open debug overlay (F3)
   - [ ] Try clicking on scene elements → clicks blocked by overlay
   - [ ] Press ESC to close overlay
   - [ ] Try clicking on scene elements → clicks now work

## Technical Details

### Stats Overlay Components

**File**: `src/ui/stats_overlay_luis.lua`

**Key Features**:
- 12 information panels in 3x4 grid layout
- Updates every 0.5 seconds
- Modal overlay (blocks input to scenes when visible)
- ESC key closes overlay
- Semi-transparent dark background

**Data Sources**:
- ResourceManager: Money, reputation, XP, mission tokens
- ContractSystem: Active/available/completed contracts
- SpecialistSystem: Specialist counts and status
- ThreatSystem: Active threats and generation
- UpgradeSystem: Purchased upgrades
- SkillSystem: Unlocked skills
- IdleSystem: Offline earnings
- AchievementSystem: Unlocked achievements
- EventSystem: Active events

### Integration Points

1. **soc_game.lua** - Initializes overlay and handles F3 toggle
2. **overlay_manager.lua** - Manages overlay stack and input routing
3. **stats_overlay_luis.lua** - Overlay implementation using LUIS

## Benefits

1. **Debugging**: Comprehensive view of all game systems at a glance
2. **Balancing**: Real-time monitoring of economy multipliers and rates
3. **QA Testing**: Quick verification of system states
4. **Player Transparency**: Advanced players can inspect game mechanics

## Future Enhancements

- [ ] Add tabs for different information categories (Economy, Systems, Meta)
- [ ] Add search/filter functionality
- [ ] Add graph visualizations for rates over time
- [ ] Add export functionality (CSV, JSON)
- [ ] Add comparison mode (compare current vs target values)
- [ ] Add performance profiling panel (FPS, memory, draw calls)

## References

- [DEBUG_OVERLAY.md](DEBUG_OVERLAY.md) - Full documentation
- [LUIS API Documentation](../lib/luis/luis-api-documentation.md) - LUIS framework reference
- [SCENE_UI_ARCHITECTURE.md](SCENE_UI_ARCHITECTURE.md) - UI architecture overview
