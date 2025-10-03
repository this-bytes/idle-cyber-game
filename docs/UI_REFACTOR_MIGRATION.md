# UI Refactor Migration Guide

## Overview

This document describes the migration from custom UI systems to community-maintained libraries for the Idle Cyber game.

### Libraries Being Integrated

1. **LUIS (Love UI System)** - Replaces `SmartUIManager` and custom UI components
2. **Scenery** - Replaces custom `SceneManager` 
3. **Lovely-Toasts** - Replaces custom `ToastManager`

### Key Goals

- **Maintainability**: Leverage well-tested community libraries
- **Compatibility**: Preserve existing scenes and overlays during migration
- **Gradual Migration**: Allow incremental conversion of scenes and components
- **Performance**: Maintain or improve current performance characteristics

## Architecture Changes

### Before (Current Architecture)

```
SOCGame
  ├── SceneManager (custom)
  │     ├── Scenes (enter/exit/update/draw)
  │     └── SmartUIManager per scene
  │           └── Custom components (Box, Panel, Button, etc.)
  ├── OverlayManager
  │     └── Overlays (debug, modals)
  └── ToastManager (custom)
```

### After (Target Architecture)

```
SOCGame
  ├── Scenery (community lib)
  │     ├── Scenes (load/update/draw callbacks)
  │     └── LUIS per scene
  │           └── LUIS widgets (Button, Slider, FlexContainer, etc.)
  ├── OverlayManager (adapted for LUIS)
  │     └── Overlays as LUIS layers
  └── LovelyToasts (community lib)
```

## Migration Strategy

### Phase 1: Library Integration ✅

- [x] Add libraries as git submodules
- [x] Create lib/ directory structure
- [x] Initialize LUIS, Scenery, and LovelyToasts

### Phase 2: Toast System Migration

**Goal**: Replace `src/ui/toast_manager.lua` with Lovely-Toasts

**Steps**:
1. Create wrapper `src/ui/lovely_toast_wrapper.lua` that provides same API as ToastManager
2. Initialize LovelyToasts in main.lua
3. Update all `toastManager:show()` calls to use new API
4. Add LovelyToasts update/draw calls to game loop
5. Configure styling to match game theme
6. Deprecate old ToastManager

**API Mapping**:
```lua
-- Old API
toastManager:show(message, {type = "success", duration = 3.0})

-- New API (via wrapper)
lovelyToasts.show(message, duration, "top")
-- With styling configured globally
```

### Phase 3: Scene Manager Migration

**Goal**: Replace `src/scenes/scene_manager.lua` with Scenery

**Steps**:
1. Create scene adapter `src/scenes/scenery_adapter.lua`
2. Convert SceneManager registration to Scenery format
3. Update scene structure to use Scenery callbacks:
   - `enter(params)` → `load(params)` 
   - Keep `exit()`, `update(dt)`, `draw()` as-is
4. Adapt scene transition API
5. Test all scene transitions
6. Deprecate old SceneManager

**Scene Structure Changes**:
```lua
-- Old scene structure
local Scene = {}
function Scene:enter(params) end
function Scene:exit() end
function Scene:update(dt) end
function Scene:draw() end
return Scene

-- New scene structure (Scenery)
local scene = {}
function scene:load(params) end -- renamed from enter
function scene:update(dt) end
function scene:draw() end
-- exit() optional in Scenery
return scene
```

### Phase 4: LUIS UI Integration

**Goal**: Replace SmartUIManager with LUIS incrementally

**Steps**:
1. Initialize LUIS in main.lua with grid configuration
2. Create LUIS layer management wrapper
3. Build adapter components that bridge SmartUI → LUIS:
   - Box → FlexContainer
   - Panel → Custom widget with border
   - Button → LUIS Button
   - Text → LUIS Label
4. Convert one simple scene (e.g., main_menu.lua) to use LUIS
5. Validate input handling and rendering
6. Gradually migrate remaining scenes

**Component Mapping**:
```lua
-- Old: SmartUI Box
local box = Box.new({direction = "vertical", gap = 20})

-- New: LUIS FlexContainer
local container = luis.newFlexContainer(30, 30, 10, 10)

-- Old: SmartUI Button
local btn = Button.new("Click Me", callback, {width = 100, height = 40})

-- New: LUIS Button
local btn = luis.newButton("Click Me", 15, 3, onClick, onRelease, 5, 2)
```

### Phase 5: Overlay System Adaptation

**Goal**: Ensure OverlayManager works with LUIS layers

**Steps**:
1. Analyze current overlay rendering (top of scene stack)
2. Integrate overlays as LUIS layers with high Z-index
3. Update overlay input handling for LUIS compatibility
4. Test debug overlay, modals, and dialogs
5. Validate input blocking and passthrough

### Phase 6: Cleanup and Documentation

**Goal**: Remove deprecated code and document new patterns

**Steps**:
1. Remove old SmartUIManager
2. Remove old SceneManager
3. Remove old ToastManager
4. Update ARCHITECTURE.md
5. Create UI development guide with LUIS examples
6. Add migration examples for future developers

## Compatibility Layer Design

### Scenery Adapter

Provides backward-compatible SceneManager API wrapping Scenery:

```lua
-- src/scenes/scenery_adapter.lua
local SceneryAdapter = {}

function SceneryAdapter.new(eventBus, systems)
  local adapter = {}
  local scenery = require("lib.scenery.scenery")
  
  -- Wrap Scenery's API to match old SceneManager
  function adapter:registerScene(name, scene)
    -- Convert enter → load
    if scene.enter and not scene.load then
      scene.load = scene.enter
    end
    scenery.addScene(name, scene)
  end
  
  function adapter:requestScene(name, params)
    scenery.setScene(name, params)
  end
  
  return adapter
end
```

### LUIS Component Adapter

Bridge between SmartUI components and LUIS widgets:

```lua
-- src/ui/luis_adapter.lua
local LuisAdapter = {}

function LuisAdapter.createButton(text, callback, options)
  local width = options.width or 100
  local height = options.height or 40
  
  -- Convert pixel dimensions to grid cells
  local gridWidth = width / luis.gridSize
  local gridHeight = height / luis.gridSize
  
  return luis.newButton(text, gridWidth, gridHeight, 
    callback, nil, options.col or 0, options.row or 0)
end

function LuisAdapter.createContainer(options)
  return luis.newFlexContainer(
    options.width or 20, 
    options.height or 20,
    options.col or 0,
    options.row or 0
  )
end

return LuisAdapter
```

### Toast Wrapper

Provides SmartUI ToastManager API using Lovely-Toasts:

```lua
-- src/ui/lovely_toast_wrapper.lua
local lovelyToasts = require("lib.lovely-toasts.lovelyToasts")

local ToastWrapper = {}

function ToastWrapper.new()
  -- Configure styling
  lovelyToasts.style.backgroundColor = {0.1, 0.15, 0.2, 0.95}
  lovelyToasts.style.textColor = {0.9, 0.9, 0.95, 1.0}
  
  return ToastWrapper
end

function ToastWrapper:show(message, options)
  options = options or {}
  local duration = options.duration or 3.0
  local position = options.position or "top"
  
  lovelyToasts.show(message, duration, position)
end

return ToastWrapper
```

## Testing Strategy

### Unit Testing
- Test each adapter in isolation
- Verify API compatibility
- Test edge cases (nil params, invalid scenes, etc.)

### Integration Testing
- Test scene transitions with new Scenery
- Verify LUIS rendering matches old SmartUI
- Validate toast positioning and stacking
- Test overlay interaction with LUIS layers

### Visual Regression Testing
- Screenshot comparison before/after migration
- Verify button positions, panel layouts
- Check text rendering and alignment
- Validate animations and transitions

## Rollback Strategy

If critical issues arise:

1. **Branch isolation**: All work on `feature/community-ui-refactor` branch
2. **Adapter fallback**: Keep old systems alongside adapters during transition
3. **Git revert**: Can revert submodule additions and adapter code
4. **Feature flag**: Use environment variable to toggle between old/new systems

## Performance Considerations

### LUIS Performance
- Grid-based layout reduces calculation overhead
- Retained-mode GUI caches element positions
- Monitor draw calls and batch rendering

### Scenery Performance  
- Minimal overhead (thin wrapper over Love callbacks)
- Scene state preserved between transitions

### Lovely-Toasts Performance
- Lightweight animation system
- Canvas-based rendering for smooth effects

## Known Issues and Limitations

### LUIS
- Grid-based system may require adjustment for pixel-perfect layouts
- TextInput widgets have some theme update issues
- Gamepad analog stick support incomplete for some widgets

### Scenery
- Simple callback-based system (no async transition support)
- One active scene at a time (no scene stacking)

### Lovely-Toasts
- Simpler than custom ToastManager (fewer features)
- Limited customization compared to component-based approach

## Migration Checklist

- [ ] Phase 1: Library integration ✅
- [ ] Phase 2: Toast system migration
- [ ] Phase 3: Scene manager migration  
- [ ] Phase 4: LUIS UI integration
- [ ] Phase 5: Overlay system adaptation
- [ ] Phase 6: Cleanup and documentation

## References

- [LUIS Documentation](https://github.com/SiENcE/luis/blob/main/luis-api-documentation.md)
- [Scenery Repository](https://github.com/paltze/scenery)
- [Lovely-Toasts Repository](https://github.com/Loucee/Lovely-Toasts)
- [Project Architecture](../ARCHITECTURE.md)
- [Scene & UI Architecture](./SCENE_UI_ARCHITECTURE.md)
