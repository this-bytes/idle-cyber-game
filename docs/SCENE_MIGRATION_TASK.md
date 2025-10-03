# Scene Migration Task for GitHub Coding Agent

## Overview

**Task**: Migrate remaining game scenes from SmartUIManager to pure LUIS (Love UI System) integration.

**Status**: Main menu fully migrated and tested. 5 scenes remaining.

**Reference Implementation**: `src/scenes/main_menu_luis.lua` (complete working example)

**Migration Guide**: `docs/LUIS_SCENE_MIGRATION_GUIDE.md` (comprehensive instructions)

---

## Current State

### ✅ Completed

- **main_menu_luis.lua** - Fully migrated, tested, and documented
- **LUIS Integration** - Direct integration in `soc_game.lua` (no wrapper)
- **Scene Transitions** - Working correctly with proper layer lifecycle
- **Documentation** - Complete migration guide created

### ⚠️ Scenes Requiring Migration

Priority order:

1. **soc_view.lua** - Main game view (HIGH PRIORITY)
2. **upgrade_shop.lua** - Equipment/upgrade shop
3. **game_over.lua** - Game over screen (SIMPLE)
4. **incident_response.lua** - Incident handling UI
5. **admin_mode.lua** - Admin/debug interface

---

## Migration Checklist (Per Scene)

Use this checklist for EACH scene migration:

### Phase 1: Constructor & Registration

- [ ] Update constructor: `function Scene.new(eventBus, luis)` 
- [ ] Store luis instance: `self.luis = luis`
- [ ] Add unique layer name: `self.layerName = "scene_name"`
- [ ] Update registration in `soc_game.lua`: Pass `self.luis` as second parameter
- [ ] Remove SmartUIManager references from constructor

### Phase 2: Layer Lifecycle

- [ ] Create layer in `load()`: `self.luis.newLayer(self.layerName)`
- [ ] Activate layer: `self.luis.setCurrentLayer(self.layerName)`
- [ ] Build UI: Call `self:buildUI()` from `load()`
- [ ] Disable layer in `exit()`: `self.luis.disableLayer(self.layerName)`
- [ ] Add debug logging to layer lifecycle methods

### Phase 3: UI Conversion

- [ ] Create `buildUI()` method
- [ ] Convert all UI elements to LUIS widgets:
  - [ ] Buttons → `luis.newButton()`
  - [ ] Labels/Text → `luis.newLabel()`
  - [ ] Input fields → `luis.newTextInput()`
  - [ ] Progress bars → `luis.newProgressBar()`
  - [ ] Other elements → See LUIS docs
- [ ] Use grid-based positioning (calculate centerRow/centerCol)
- [ ] Add widgets with `luis.insertElement(layerName, widget)`
- [ ] **IMPORTANT**: Do NOT use `createElement` with pre-created widgets!

### Phase 4: Cleanup

- [ ] Remove `update()` LUIS calls (handled globally)
- [ ] Remove `draw()` LUIS calls (handled globally)
- [ ] Remove input handlers (`mousepressed`, `keypressed`, etc.) unless scene-specific
- [ ] Remove all SmartUIManager references
- [ ] Keep scene-specific logic only

### Phase 5: Testing

- [ ] Test scene loads without errors
- [ ] Test all UI interactions work
- [ ] Test scene transitions (verify layer disables on exit)
- [ ] Test no visual overlap with other scenes
- [ ] Test with debug view (press TAB) to verify layer management
- [ ] Test returning to scene (if applicable)

---

## Key Implementation Patterns

### Constructor Pattern

```lua
function Scene.new(eventBus, luis)
    local self = setmetatable({}, Scene)
    self.eventBus = eventBus
    self.luis = luis  -- Direct LUIS instance, NO wrapper
    self.layerName = "unique_scene_name"
    return self
end
```

### Load Pattern

```lua
function Scene:load(data)
    print("📋 Scene: Loading")
    
    -- Create and activate layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Build UI
    self:buildUI()
end
```

### BuildUI Pattern

```lua
function Scene:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Calculate center position
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Create widgets
    local button = luis.newButton(
        "Button Text",
        20, 3,  -- width, height in grid units
        function() self:handleButtonClick() end,  -- onClick
        nil,  -- onRelease (optional)
        centerRow,  -- row
        centerCol - 10  -- col
    )
    
    -- Add to layer
    luis.insertElement(self.layerName, button)
    
    -- Create more widgets...
end
```

### Exit Pattern

```lua
function Scene:exit()
    print("📋 Scene: Exiting")
    
    -- CRITICAL: Disable layer!
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
        print("📋 Scene: Layer disabled")
    end
end
```

---

## Scene Registration (soc_game.lua)

Each scene needs to be updated in `soc_game.lua`:

### Before (❌ Wrong)
```lua
self.sceneManager:registerScene("scene_name", Scene.new(self.eventBus))
```

### After (✅ Correct)
```lua
self.sceneManager:registerScene("scene_name", Scene.new(self.eventBus, self.luis))
```

**Location**: `src/soc_game.lua`, around line 165-185

---

## LUIS Widget Reference

### Common Widgets

```lua
-- Button
local btn = luis.newButton(text, width, height, onClick, onRelease, row, col)

-- Label
local lbl = luis.newLabel(text, width, height, row, col)

-- Text Input
local input = luis.newTextInput(width, height, placeholder, onChange, row, col)

-- Slider
local slider = luis.newSlider(min, max, value, width, height, onChange, row, col)

-- Progress Bar
local bar = luis.newProgressBar(value, width, height, row, col)

-- Checkbox
local cb = luis.newCheckBox(value, size, onChange, row, col)

-- FlexContainer (for dynamic layouts)
local container = luis.newFlexContainer(width, height, row, col)
```

### Grid Positioning

```lua
-- Grid size (default 20px per grid unit)
local gridSize = luis.gridSize

-- Convert pixels to grid units
local gridCol = math.floor(pixelX / gridSize)
local gridRow = math.floor(pixelY / gridSize)

-- Center of screen in grid units
local centerCol = math.floor(love.graphics.getWidth() / gridSize / 2)
local centerRow = math.floor(love.graphics.getHeight() / gridSize / 2)

-- Widget dimensions in grid units
-- width=20 means 20*20=400 pixels wide
-- height=3 means 3*20=60 pixels tall
```

---

## Common Pitfalls (AVOID THESE!)

### ❌ Pitfall 1: Not Disabling Layer
```lua
function Scene:exit()
    -- Missing disableLayer!
    -- Layer will remain visible over next scene
end
```
**Fix**: Always call `self.luis.disableLayer(self.layerName)` in `exit()`

### ❌ Pitfall 2: Using createElement Wrong
```lua
local widget = luis.newButton(...)  -- Creates widget
luis.createElement(layerName, "Button", widget)  -- Creates ANOTHER widget!
```
**Fix**: Use `luis.insertElement(layerName, widget)` instead

### ❌ Pitfall 3: Manual LUIS Updates
```lua
function Scene:update(dt)
    self.luis.update(dt)  -- Wrong! SOCGame does this
end
```
**Fix**: Remove all LUIS update/draw/input calls from scenes

### ❌ Pitfall 4: Pixel Coordinates
```lua
local btn = luis.newButton("Text", 400, 60, onClick, nil, 300, 500)
-- 300 rows = 6000 pixels! Off screen!
```
**Fix**: Use grid units, not pixels

### ❌ Pitfall 5: Duplicate Layer Names
```lua
self.layerName = "main"  -- Conflicts with another scene!
```
**Fix**: Use unique layer names per scene (e.g., "soc_view", "upgrade_shop")

---

## Testing Strategy

### 1. Unit Test Each Scene
- Load scene
- Verify layer created and enabled
- Interact with UI elements
- Exit scene
- Verify layer disabled

### 2. Integration Test Transitions
- Main Menu → Scene → Back to Main Menu
- Verify no visual overlap
- Verify no duplicate elements
- Verify proper cleanup

### 3. Debug View Testing
- Press TAB to enable debug view
- Verify grid positioning
- Check layer names and states
- Verify element boundaries

---

## Scene-Specific Notes

### soc_view.lua (Main Game View)
- **Complexity**: HIGH - Many UI elements
- **Approach**: Break into logical sections (top bar, side panels, center area)
- **Considerations**: 
  - Resource display (money, generation rate)
  - Specialist list
  - Contract list
  - Incident notifications
- **Strategy**: Use FlexContainers for dynamic lists

### upgrade_shop.lua
- **Complexity**: MEDIUM - List-based UI
- **Approach**: Use FlexContainer for upgrade list
- **Considerations**:
  - Scrollable upgrade list
  - Purchase buttons
  - Resource display

### game_over.lua
- **Complexity**: LOW - Simple UI
- **Approach**: Good starting point for practice
- **Considerations**:
  - Score display
  - Restart button
  - Main menu button

### incident_response.lua
- **Complexity**: MEDIUM - Interactive UI
- **Approach**: Dynamic specialist assignment
- **Considerations**:
  - Incident details
  - Specialist selection
  - Action buttons

### admin_mode.lua
- **Complexity**: MEDIUM - Debug interface
- **Approach**: May use TextInput for commands
- **Considerations**:
  - Command input
  - State display
  - Debug actions

---

## Success Criteria

For each migrated scene:

1. ✅ Scene loads without errors
2. ✅ All UI elements visible and positioned correctly
3. ✅ All interactions work (buttons, inputs, etc.)
4. ✅ Scene transitions work smoothly
5. ✅ Layer properly disabled on exit (no overlap)
6. ✅ No SmartUIManager references remain
7. ✅ Debug view (TAB) shows correct layer state
8. ✅ Code follows main_menu_luis.lua pattern
9. ✅ Proper documentation/comments added

---

## Files to Modify

### Scene Files (Direct Migration)
1. `src/scenes/soc_view.lua`
2. `src/scenes/upgrade_shop.lua`
3. `src/scenes/game_over.lua`
4. `src/scenes/incident_response.lua`
5. `src/modes/admin_mode.lua`

### Registration File (Update Calls)
- `src/soc_game.lua` (lines ~165-185)

### Files to DELETE (After Migration Complete)
- `src/ui/smart_ui_manager.lua` (deprecated)
- Any scene-specific SmartUI helpers

---

## Documentation & References

### Essential Reading
1. **LUIS API Documentation**: https://github.com/SiENcE/luis/blob/main/luis-api-documentation.md
2. **Migration Guide**: `docs/LUIS_SCENE_MIGRATION_GUIDE.md`
3. **Reference Implementation**: `src/scenes/main_menu_luis.lua`

### Code References
- **LUIS Initialization**: `src/soc_game.lua` lines 75-90
- **Input Routing**: `src/soc_game.lua` lines 395-520
- **Scene Registration**: `src/soc_game.lua` lines 165-185

---

## Execution Plan

### Recommended Order

1. **game_over.lua** (SIMPLE - practice migration)
2. **upgrade_shop.lua** (MEDIUM - list-based UI)
3. **soc_view.lua** (COMPLEX - main game view, high priority)
4. **incident_response.lua** (MEDIUM - interactive UI)
5. **admin_mode.lua** (MEDIUM - debug interface)

### For Each Scene

1. Read the migration guide (`docs/LUIS_SCENE_MIGRATION_GUIDE.md`)
2. Review reference implementation (`src/scenes/main_menu_luis.lua`)
3. Follow the checklist above
4. Test thoroughly
5. Commit with clear message: "Migrate [scene_name] to pure LUIS"

---

## Questions or Blockers?

If you encounter issues:

1. **Check Common Pitfalls** section above
2. **Compare to main_menu_luis.lua** - working reference
3. **Enable debug view** (TAB key) - inspect layers
4. **Verify layer lifecycle** - create → enable → disable → remove
5. **Check console output** - Look for LUIS-related errors

---

## Final Notes

- **Take your time** - Each scene is unique
- **Test frequently** - After each major change
- **Keep it simple** - Follow the established patterns
- **Document changes** - Add comments for complex logic
- **Ask questions** - If stuck, refer to documentation

Good luck with the migration! 🚀

## Acceptance Criteria

When all scenes are migrated:

- [ ] All 5 scenes migrated and tested
- [ ] No SmartUIManager references remain
- [ ] All scene transitions work correctly
- [ ] No visual overlap between scenes
- [ ] Debug view (TAB) shows correct layer management
- [ ] All UI interactions functional
- [ ] Code follows established patterns
- [ ] Deprecated UI code removed (SmartUIManager files)
