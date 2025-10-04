# LUIS Scene Migration - Remaining Tasks

## Overview

This document tracks the remaining scene migrations to LUIS (Love UI System). The F3 overlay and simple scenes have been migrated. Complex scenes remain.

## Completed Migrations ✅

### 1. Main Menu (main_menu_luis.lua)
- **Status**: ✅ Complete
- **Lines**: 200 lines
- **Complexity**: LOW
- **Widgets**: 5 (1 label, 4 buttons)
- **Pattern**: Simple centered menu with buttons

### 2. F3 Debug Overlay (stats_overlay_luis.lua)  
- **Status**: ✅ Complete
- **Lines**: 545 lines
- **Complexity**: MEDIUM
- **Widgets**: 60+ labels (12 panels × 5-7 lines each)
- **Pattern**: Grid-based data display, modal overlay, auto-refresh

### 3. Game Over Scene (game_over_luis.lua)
- **Status**: ✅ Complete
- **Lines**: 147 lines
- **Complexity**: LOW
- **Widgets**: 6 (2 labels, 3 buttons, 1 info label)
- **Pattern**: Simple dialog with actions

---

## Remaining Scenes

### Priority 1: Core Game Scenes (Required for MVP)

#### 1. SOC View (soc_view.lua → soc_view_luis.lua)
- **Status**: ⏳ TODO
- **Lines**: 1,298 lines (LARGEST)
- **Complexity**: HIGH ⚠️
- **Current Tech**: SmartUIManager + NotificationPanel
- **Dependencies**: All game systems (resources, contracts, specialists, threats, etc.)
- **Key Features**:
  - Main operational dashboard
  - Multi-panel navigation (threats, incidents, resources, upgrades, contracts, specialists, skills)
  - Real-time status updates
  - Notification system
  - Event display system
  - Resource counters
  - Threat monitor
  - Incident response interface
- **Migration Strategy**:
  1. Create LUIS layer for main view
  2. Convert SmartUIManager panels to LUIS FlexContainers
  3. Migrate tab/panel system to LUIS buttons
  4. Convert notification panel to LUIS labels
  5. Update all data displays to LUIS labels
  6. Test extensively - this is the main game interface!

#### 2. Upgrade Shop (upgrade_shop.lua → upgrade_shop_luis.lua)
- **Status**: ⏳ TODO
- **Lines**: 477 lines
- **Complexity**: MEDIUM
- **Current Tech**: Manual love.graphics drawing
- **Key Features**:
  - Category sidebar (4 categories)
  - Upgrade list (scrollable)
  - Upgrade details panel
  - Resource status display
  - Purchase button
  - Category switching (TAB key)
- **Migration Strategy**:
  1. Create LUIS layer
  2. Left panel: Category buttons (4 buttons)
  3. Center panel: Upgrade list (FlexContainer with buttons)
  4. Right panel: Details (multiple labels)
  5. Bottom: Resource display + Purchase button
  6. Implement category switching logic

---

### Priority 2: Interactive Scenes

#### 3. Incident Response (incident_response.lua → incident_response_luis.lua)
- **Status**: ⏳ TODO
- **Lines**: 328 lines
- **Complexity**: MEDIUM
- **Current Tech**: Manual love.graphics drawing
- **Key Features**:
  - Incident details display
  - Specialist assignment interface
  - Action selection (Analyze, Contain, Eradicate, etc.)
  - Progress tracking
  - Severity indicators
- **Migration Strategy**:
  1. Create LUIS layer
  2. Top: Incident info panel (labels)
  3. Middle: Available specialists (buttons)
  4. Bottom: Action buttons (4-6 buttons)
  5. Status display (labels)

#### 4. Admin Mode (admin_mode.lua → admin_mode_luis.lua)
- **Status**: ⏳ TODO
- **Lines**: 254 lines
- **Complexity**: LOW
- **Current Tech**: Manual love.graphics drawing
- **Key Features**:
  - Debug controls
  - System toggles
  - Resource manipulation
  - State inspection
- **Migration Strategy**:
  1. Create LUIS layer
  2. Simple button grid for debug actions
  3. Labels for state display
  4. Similar pattern to stats_overlay

---

## Migration Patterns & Best Practices

### 1. Scene Structure Template

```lua
local SceneLuis = {}
SceneLuis.__index = SceneLuis

function SceneLuis.new(eventBus, luis)
    local self = setmetatable({}, SceneLuis)
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "scene_name"
    return self
end

function SceneLuis:load(data)
    -- Store data
    -- Create layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    -- Build UI
    self:buildUI()
end

function SceneLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Calculate positions
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Create widgets
    local widget = luis.newButton(text, w, h, onClick, nil, row, col)
    luis.insertElement(self.layerName, widget)
end

function SceneLuis:exit()
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
    end
end

function SceneLuis:update(dt)
    -- Update logic
end
```

### 2. Common Widget Patterns

**Label (Text Display):**
```lua
local label = luis.newLabel(text, width_units, height_units, row, col)
luis.insertElement(layerName, label)
```

**Button (Interactive Element):**
```lua
local button = luis.newButton(
    text,           -- Button text
    width_units,    -- Width in grid units
    height_units,   -- Height in grid units
    function()      -- onClick handler
        -- Action code
    end,
    nil,            -- onRelease (usually nil)
    row,            -- Grid row position
    col             -- Grid column position
)
luis.insertElement(layerName, button)
```

**FlexContainer (Group of Widgets):**
```lua
local container = luis.newFlexContainer(
    width_units,
    height_units,
    row,
    col,
    customTheme,    -- Optional theme
    containerName   -- Optional name
)
luis.insertElement(layerName, container)
```

### 3. Grid Positioning

LUIS uses a grid-based layout system:
- Screen divided by `gridSize` (default 20)
- Positions specified in grid units, not pixels
- Example: 1024px wide / 20 = ~51 grid columns

```lua
local gridSize = luis.gridSize
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

local gridCols = math.floor(screenWidth / gridSize)
local gridRows = math.floor(screenHeight / gridSize)

local centerCol = math.floor(gridCols / 2)
local centerRow = math.floor(gridRows / 2)
```

### 4. Layer Lifecycle

**Critical for Scene Transitions:**
```lua
-- In load():
self.luis.newLayer(layerName)
self.luis.setCurrentLayer(layerName)  -- Enables and activates

-- In exit():
if self.luis.isLayerEnabled(layerName) then
    self.luis.disableLayer(layerName)  -- Hides but preserves
end

-- Optional complete cleanup:
self.luis.removeLayer(layerName)  -- Deletes entirely
```

### 5. Dynamic Content Updates

**For scenes that need to refresh UI:**
```lua
function Scene:update(dt)
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer >= self.updateInterval then
        self:rebuildUI()
        self.updateTimer = 0
    end
end

function Scene:rebuildUI()
    -- Clear and rebuild
    self.luis.disableLayer(self.layerName)
    self.luis.removeLayer(self.layerName)
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    self:buildUI()
end
```

---

## Testing Checklist

For each migrated scene:

- [ ] Scene loads without errors
- [ ] All widgets render correctly
- [ ] Button clicks work (event handlers fire)
- [ ] Keyboard shortcuts still work
- [ ] Scene transition (exit) properly disables layer
- [ ] No visual overlap with other scenes
- [ ] Data displays update correctly
- [ ] Layout adapts to window resize (if applicable)
- [ ] Performance is acceptable (no lag)

---

## Common Pitfalls

### ❌ Pitfall 1: Using createElement with existing widget
```lua
-- WRONG:
local button = luis.newButton(...)
luis.createElement(layer, "Button", button)  -- Creates ANOTHER button!

-- CORRECT:
local button = luis.newButton(...)
luis.insertElement(layer, button)  -- Adds existing button
```

### ❌ Pitfall 2: Forgetting to disable layer on exit
```lua
-- WRONG:
function Scene:exit()
    -- Layer stays visible, overlaps next scene!
end

-- CORRECT:
function Scene:exit()
    self.luis.disableLayer(self.layerName)
end
```

### ❌ Pitfall 3: Wrong parameter order
```lua
-- WRONG:
luis.newButton(text, width, height, col, row, onClick)  -- col/row swapped!

-- CORRECT:
luis.newButton(text, width, height, onClick, onRelease, row, col)
```

### ❌ Pitfall 4: Not accounting for grid system
```lua
-- WRONG:
local x = 500  -- Pixel position
local y = 300
local button = luis.newButton(text, w, h, onClick, nil, x, y)  -- Treats as pixels!

-- CORRECT:
local gridSize = luis.gridSize
local col = math.floor(500 / gridSize)
local row = math.floor(300 / gridSize)
local button = luis.newButton(text, w, h, onClick, nil, row, col)
```

---

## Estimated Effort

| Scene | Lines | Complexity | Est. Time | Priority |
|-------|-------|------------|-----------|----------|
| soc_view | 1,298 | HIGH | 4-6 hours | P1 |
| upgrade_shop | 477 | MEDIUM | 2-3 hours | P1 |
| incident_response | 328 | MEDIUM | 1-2 hours | P2 |
| admin_mode | 254 | LOW | 1 hour | P2 |
| **TOTAL** | **2,357** | - | **8-12 hours** | - |

---

## Success Criteria

✅ All registered scenes migrated to LUIS  
✅ No SmartUIManager dependencies remain  
✅ All scenes tested and working  
✅ Scene transitions smooth (no visual artifacts)  
✅ All existing functionality preserved  
✅ Documentation updated with examples  

---

## Notes

- **soc_view.lua** is the most critical scene - main game interface
- Consider creating reusable LUIS components if patterns emerge
- Test on different screen sizes to verify grid layout
- Profile performance after migration (LUIS may be faster than manual drawing)
- Keep original files as reference until fully tested

---

## Questions for Review

1. Should we create a base SceneLuis class for shared functionality?
2. Do we need custom LUIS themes for different scene types?
3. Should we add animation support (LUIS supports flux animations)?
4. How should we handle complex layouts (e.g., scrollable lists)?
5. Should we migrate admin_mode or leave as low-priority debug tool?
