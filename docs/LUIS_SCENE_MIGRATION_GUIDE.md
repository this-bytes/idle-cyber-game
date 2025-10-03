# LUIS Scene Migration Guide

This guide explains how to migrate existing scenes from SmartUIManager to pure LUIS (Love UI System) integration.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Step-by-Step Migration](#step-by-step-migration)
4. [LUIS Layer Lifecycle](#luis-layer-lifecycle)
5. [Widget Creation Patterns](#widget-creation-patterns)
6. [Input Handling](#input-handling)
7. [Common Pitfalls](#common-pitfalls)
8. [Complete Example](#complete-example)

---

## Overview

**Goal**: Remove all SmartUIManager dependencies and use LUIS directly for UI rendering.

**Key Changes**:
- ❌ No more `SmartUIManager` wrapper
- ✅ Direct LUIS instance passed to scenes
- ✅ LUIS handles ALL input/update/draw globally in `SOCGame`
- ✅ Scenes manage their own LUIS layers

---

## Architecture

### Before (SmartUIManager)
```
SOCGame → SmartUIManager → Custom UI Code
         ↓
      Scene → Manual drawing with love.graphics
```

### After (Pure LUIS)
```
SOCGame → LUIS (direct) → Scenes
         ↓
      LUIS Layers → LUIS Widgets
```

### File Structure
```
src/
├── soc_game.lua           # Initializes LUIS, passes to scenes
├── scenes/
│   ├── main_menu_luis.lua # ✅ EXAMPLE - Fully migrated
│   ├── soc_view.lua       # ⚠️  TODO - Needs migration
│   ├── upgrade_shop.lua   # ⚠️  TODO - Needs migration
│   └── ...
└── ui/
    ├── luis_manager.lua   # ❌ DELETED - No longer needed
    └── smart_ui_manager.lua # ❌ DEPRECATED - Remove after migration
```

---

## Step-by-Step Migration

### Step 1: Update Scene Constructor

**Before:**
```lua
function MyScene.new(eventBus)
    local self = setmetatable({}, MyScene)
    self.eventBus = eventBus
    self.uiManager = SmartUIManager.new() -- ❌ Remove this
    return self
end
```

**After:**
```lua
function MyScene.new(eventBus, luis)
    local self = setmetatable({}, MyScene)
    self.eventBus = eventBus
    self.luis = luis  -- ✅ Store LUIS instance directly
    self.layerName = "my_scene"  -- ✅ Unique layer name for this scene
    return self
end
```

### Step 2: Update Scene Registration in `soc_game.lua`

**Before:**
```lua
self.sceneManager:registerScene("my_scene", MyScene.new(self.eventBus))
```

**After:**
```lua
self.sceneManager:registerScene("my_scene", MyScene.new(self.eventBus, self.luis))
```

### Step 3: Create LUIS Layer in `load()`

**Before:**
```lua
function MyScene:load(data)
    -- Manual UI setup with SmartUIManager
    self.uiManager:clear()
    self.uiManager:addButton(...)
end
```

**After:**
```lua
function MyScene:load(data)
    print("📋 MyScene: Loading scene")
    
    -- Create dedicated LUIS layer for this scene
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)  -- Activates and enables layer
    
    -- Build UI using LUIS widgets
    self:buildUI()
end
```

### Step 4: Build UI with LUIS Widgets

```lua
function MyScene:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate grid-based positioning
    -- LUIS uses grid units (default gridSize = 20)
    local gridSize = luis.gridSize
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Create widgets using luis.newXXX functions
    -- Pattern: newWidget(params..., row, col, [theme])
    local button = luis.newButton(
        "Click Me",      -- text
        20,              -- width in grid units
        3,               -- height in grid units
        function()       -- onClick callback
            print("Button clicked!")
        end,
        nil,             -- onRelease callback (optional)
        centerRow,       -- row position (grid coordinates)
        centerCol - 10   -- col position (grid coordinates)
    )
    
    -- Add to layer using insertElement
    -- IMPORTANT: Use insertElement, NOT createElement!
    luis.insertElement(self.layerName, button)
    
    -- Create more widgets...
    local label = luis.newLabel("Hello World", 15, 2, centerRow - 5, centerCol - 7)
    luis.insertElement(self.layerName, label)
end
```

### Step 5: Disable Layer in `exit()`

**CRITICAL**: Must disable layer when exiting scene!

```lua
function MyScene:exit()
    print("📋 MyScene: Exiting scene")
    
    -- CRITICAL: Disable the LUIS layer to hide it
    -- Just clearing elements is NOT enough - layer remains visible!
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
        print("📋 MyScene: Layer '" .. self.layerName .. "' disabled")
    end
    
    -- Optional: Remove layer entirely if you won't return
    -- self.luis.removeLayer(self.layerName)
end
```

### Step 6: Remove Update/Draw Logic

**Before:**
```lua
function MyScene:update(dt)
    self.uiManager:update(dt) -- ❌ Remove
end

function MyScene:draw()
    self.uiManager:draw() -- ❌ Remove
end
```

**After:**
```lua
function MyScene:update(dt)
    -- Scene-specific updates only
    -- LUIS is updated globally in SOCGame
end

function MyScene:draw()
    -- Optional: Scene-specific background/effects
    love.graphics.clear(0.1, 0.1, 0.15, 1.0)
    
    -- LUIS is drawn globally in SOCGame
end
```

### Step 7: Remove Input Handlers

**Before:**
```lua
function MyScene:mousepressed(x, y, button)
    self.uiManager:mousepressed(x, y, button) -- ❌ Remove
end
```

**After:**
```lua
-- No mouse/keyboard handlers needed!
-- LUIS handles input globally in SOCGame
-- Only add handlers if you need custom scene-specific behavior
```

---

## LUIS Layer Lifecycle

### Layer States

1. **Created** - `luis.newLayer(name)` - Layer exists but is disabled
2. **Enabled** - `luis.enableLayer(name)` or `luis.setCurrentLayer(name)` - Layer is visible and receives input
3. **Disabled** - `luis.disableLayer(name)` - Layer is hidden but elements preserved
4. **Removed** - `luis.removeLayer(name)` - Layer is deleted entirely

### Scene Lifecycle Mapping

```
Scene Lifecycle         LUIS Layer Action
----------------       ------------------
load()          →      newLayer() + setCurrentLayer()
                       (Creates and enables layer)

[Scene Active]  →      Layer remains enabled
                       (Renders and receives input)

exit()          →      disableLayer()
                       (Hides layer but keeps elements)

[Optional]      →      removeLayer()
                       (Complete cleanup if never returning)
```

### Layer Management Functions

```lua
-- Create layer
luis.newLayer("my_layer")

-- Activate and enable layer
luis.setCurrentLayer("my_layer")  -- Also enables it

-- Enable/disable layer
luis.enableLayer("my_layer")      -- Show layer
luis.disableLayer("my_layer")     -- Hide layer
luis.toggleLayer("my_layer")      -- Toggle visibility

-- Check layer state
local enabled = luis.isLayerEnabled("my_layer")

-- Remove layer completely
luis.removeLayer("my_layer")
```

---

## Widget Creation Patterns

### Available Widgets

All widgets use grid-based positioning (row, col) starting at (1,1):

```lua
-- Button
luis.newButton(text, width, height, onClick, onRelease, row, col, customTheme)

-- Label
luis.newLabel(text, width, height, row, col, align, customTheme)

-- Slider
luis.newSlider(min, max, value, width, height, onChange, row, col, customTheme)

-- TextInput
luis.newTextInput(width, height, placeholder, onChange, row, col, customTheme)

-- CheckBox
luis.newCheckBox(value, size, onChange, row, col, customTheme)

-- Switch
luis.newSwitch(value, width, height, onChange, row, col, customTheme)

-- ProgressBar
luis.newProgressBar(value, width, height, row, col, customTheme)

-- FlexContainer (for dynamic layouts)
luis.newFlexContainer(width, height, row, col, customTheme, containerName)

-- And many more! See LUIS docs for full list
```

### Grid Positioning

```lua
-- Grid size (pixels per grid unit)
local gridSize = luis.gridSize  -- Default: 20

-- Convert screen coordinates to grid coordinates
local gridCol = math.floor(screenX / gridSize)
local gridRow = math.floor(screenY / gridSize)

-- Center positioning
local centerCol = math.floor(love.graphics.getWidth() / gridSize / 2)
local centerRow = math.floor(love.graphics.getHeight() / gridSize / 2)

-- Widget dimensions in grid units
local buttonWidth = 20  -- 20 grid units = 20 * 20 = 400 pixels
local buttonHeight = 3  -- 3 grid units = 3 * 20 = 60 pixels
```

### Adding Widgets to Layer

**CORRECT Pattern:**
```lua
-- 1. Create widget
local widget = luis.newButton(...)

-- 2. Add to layer
luis.insertElement(layerName, widget)
```

**INCORRECT Pattern:**
```lua
-- ❌ DON'T DO THIS!
local widget = luis.newButton(...)
luis.createElement(layerName, "Button", widget)  -- Creates ANOTHER button!
```

**Alternative (createElement creates widget):**
```lua
-- createElement can create the widget for you
luis.createElement(layerName, "Button", text, width, height, onClick, onRelease, row, col)
-- But we prefer explicit creation with newXXX for clarity
```

---

## Input Handling

### Global Input (Handled in SOCGame)

LUIS handles ALL input globally - scenes don't need to handle it:

```lua
-- In SOCGame:update()
self.luis.update(dt)

-- In SOCGame:draw()
self.luis.draw()

-- In SOCGame:mousepressed()
if self.luis.mousepressed(x, y, button, istouch, presses) then
    return  -- LUIS consumed the input
end

-- Similar for mousereleased, keypressed, keyreleased, wheelmoved, etc.
```

### Scene-Specific Input (Optional)

Only add input handlers if you need custom scene behavior:

```lua
function MyScene:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        -- Custom escape handling
        self.eventBus:publish("request_scene_change", {scene = "main_menu"})
    end
end
```

### Widget Callbacks

Widget interactions are handled via callbacks:

```lua
local button = luis.newButton(
    "Click Me",
    20, 3,
    function()  -- onClick - triggered when button is pressed
        print("Pressed!")
        self:handleButtonClick()
    end,
    function()  -- onRelease - triggered when button is released
        print("Released!")
    end,
    5, 5
)
```

---

## Common Pitfalls

### ❌ Pitfall 1: Not Disabling Layer on Exit

**Problem:**
```lua
function MyScene:exit()
    -- Layer is still enabled!
    -- Scene will remain visible over new scene
end
```

**Solution:**
```lua
function MyScene:exit()
    self.luis.disableLayer(self.layerName)  -- ✅ Must disable!
end
```

### ❌ Pitfall 2: Using createElement with Pre-created Widgets

**Problem:**
```lua
local button = luis.newButton(...)  -- Creates button
luis.createElement(layerName, "Button", button)  -- Creates ANOTHER button with wrong params!
```

**Solution:**
```lua
local button = luis.newButton(...)  -- Creates button
luis.insertElement(layerName, button)  -- ✅ Adds the button we created
```

### ❌ Pitfall 3: Forgetting Grid-Based Positioning

**Problem:**
```lua
-- Trying to use pixel coordinates
local button = luis.newButton("Text", 400, 60, onClick, nil, 300, 500)
-- 300 rows = 6000 pixels! Off screen!
```

**Solution:**
```lua
-- Use grid units
local gridSize = luis.gridSize
local row = math.floor(300 / gridSize)  -- 300px / 20 = 15 grid units
local col = math.floor(500 / gridSize)  -- 500px / 20 = 25 grid units
local button = luis.newButton("Text", 20, 3, onClick, nil, row, col)
```

### ❌ Pitfall 4: Manually Handling LUIS Input in Scenes

**Problem:**
```lua
function MyScene:update(dt)
    self.luis.update(dt)  -- ❌ SOCGame already does this!
end

function MyScene:mousepressed(x, y, button)
    self.luis.mousepressed(x, y, button)  -- ❌ SOCGame already does this!
end
```

**Solution:**
```lua
-- Remove all LUIS update/draw/input calls from scenes
-- SOCGame handles it globally
```

### ❌ Pitfall 5: Creating Multiple Layers with Same Name

**Problem:**
```lua
function MyScene:load()
    self.luis.newLayer("main")  -- ❌ "main" already exists!
end
```

**Solution:**
```lua
function MyScene:load()
    self.layerName = "my_unique_scene_name"  -- ✅ Unique per scene
    self.luis.newLayer(self.layerName)
end
```

---

## Complete Example

See `src/scenes/main_menu_luis.lua` for a complete, working example of a LUIS-based scene.

### Key Points from Example:

1. **Constructor** - Receives `luis` instance directly
2. **load()** - Creates and activates LUIS layer
3. **buildUI()** - Creates widgets with `newXXX()` and adds with `insertElement()`
4. **exit()** - Disables layer using `disableLayer()`
5. **No input handlers** - LUIS handles globally
6. **No update/draw** - LUIS updates/draws globally

### Migration Checklist

For each scene to migrate:

- [ ] Update constructor signature to accept `luis` parameter
- [ ] Update scene registration in `soc_game.lua` to pass `self.luis`
- [ ] Add `layerName` property with unique name
- [ ] Create LUIS layer in `load()`
- [ ] Build UI with LUIS widgets in `buildUI()`
- [ ] Use `insertElement()` to add widgets to layer
- [ ] Disable layer in `exit()`
- [ ] Remove SmartUIManager references
- [ ] Remove manual LUIS update/draw/input calls
- [ ] Test scene transitions (verify layer disables on exit)
- [ ] Test all UI interactions
- [ ] Verify no visual overlap with other scenes

---

## Debugging

### Enable LUIS Debug View

Press `TAB` (implemented in `SOCGame:keypressed`) to toggle:
- Grid overlay (shows grid positioning)
- Element outlines (shows widget boundaries)
- Layer names (shows active layers)

### Common Debug Checks

```lua
-- Check if layer exists
if self.luis.layers[self.layerName] then
    print("Layer exists")
end

-- Check if layer is enabled
if self.luis.isLayerEnabled(self.layerName) then
    print("Layer is visible")
end

-- Count elements in layer
if self.luis.elements[self.layerName] then
    print("Element count: " .. #self.luis.elements[self.layerName])
end

-- List all layers
for name, layer in pairs(self.luis.layers) do
    local enabled = self.luis.isLayerEnabled(name) and "ENABLED" or "disabled"
    print("Layer: " .. name .. " [" .. enabled .. "]")
end
```

---

## Next Steps

1. **Review `main_menu_luis.lua`** - Study the complete example
2. **Pick a scene to migrate** - Start with a simple one (e.g., `game_over.lua`)
3. **Follow the step-by-step guide** - Use the checklist
4. **Test thoroughly** - Verify scene transitions and interactions
5. **Repeat for remaining scenes** - `soc_view.lua`, `upgrade_shop.lua`, etc.

---

## Reference Documentation

- **LUIS API Docs**: https://github.com/SiENcE/luis/blob/main/luis-api-documentation.md
- **Main Menu Example**: `src/scenes/main_menu_luis.lua`
- **SOCGame LUIS Integration**: `src/soc_game.lua` (lines ~75-90 initialization, input handlers)

---

## Questions or Issues?

If you encounter issues during migration:

1. Check the **Common Pitfalls** section above
2. Compare your code to `main_menu_luis.lua`
3. Enable debug view (TAB) to inspect layers
4. Verify layer lifecycle (create → enable → disable → remove)

Good luck with the migration! 🚀
