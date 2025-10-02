## Smart UI Framework - Copilot Development Instructions

**Priority**: CRITICAL - All UI development MUST use this framework
**Status**: Production Ready - Phase 1 Complete
**Documentation**: See `docs/SMART_UI_FRAMEWORK.md` and `docs/SMART_UI_QUICK_REFERENCE.md`

---

## Core Principles

### 1. Automatic Layout Philosophy
**NEVER manually position UI elements**. The framework handles all positioning automatically.

```lua
-- ❌ WRONG: Manual positioning
love.graphics.print("Text", 100, 200)
love.graphics.rectangle("line", 50, 50, 300, 400)

-- ✅ CORRECT: Component-based with automatic layout
local panel = Panel.new({title = "My Panel"})
panel:addChild(Text.new({text = "Content"}))
panel:measure(width, height)
panel:layout(x, y, width, height)
panel:render()
```

### 2. Component Composition Over Hardcoding
Build complex UIs from simple, reusable components.

```lua
-- ✅ CORRECT: Compose components
function createResourceDisplay(name, current, max)
    local container = Box.new({direction = "horizontal", align = "center", gap = 10})
    container:addChild(Text.new({text = name, minWidth = 100}))
    container:addChild(createProgressBar(current, max))
    container:addChild(Text.new({text = string.format("%d/%d", current, max)}))
    return container
end
```

### 3. Viewport Management is MANDATORY
All root-level UI MUST use ScrollContainer to prevent off-screen rendering.

```lua
-- ✅ CORRECT: Always use ScrollContainer for root UI
local root = ScrollContainer.new({
    backgroundColor = {0.05, 0.05, 0.1, 1},
    showScrollbars = true,
    scrollSpeed = 30
})

local content = Box.new({direction = "vertical", gap = 20})
root:addChild(content)

-- Add your UI components to content, not root
content:addChild(Panel.new({title = "Dashboard"}))
```

---

## Available Components

### Component Hierarchy
```
Component (base class)
├── Box (flexbox container) → Panel, Button
├── Grid (table layout)
├── Text (smart text rendering)
└── ScrollContainer (viewport with scrolling)
```

### Quick Import Reference
```lua
local Component = require("src.ui.components.component")
local Box = require("src.ui.components.box")
local Grid = require("src.ui.components.grid")
local Text = require("src.ui.components.text")
local Panel = require("src.ui.components.panel")
local Button = require("src.ui.components.button")
local ScrollContainer = require("src.ui.components.scroll_container")
```

---

## Mandatory Patterns

### Pattern 1: Root UI Structure
**ALWAYS structure game UI like this:**

```lua
function GameUI.new()
    local self = {}
    
    -- ScrollContainer as root (handles viewport)
    self.root = ScrollContainer.new({
        backgroundColor = {0.05, 0.05, 0.1, 1},
        showScrollbars = true
    })
    
    -- Content container (can grow beyond viewport)
    self.content = Box.new({
        direction = "vertical",
        gap = 15,
        padding = {10, 10, 10, 10}
    })
    
    self.root:addChild(self.content)
    
    -- Build UI sections
    self:createHeader()
    self:createMainContent()
    self:createFooter()
    
    return self
end
```

### Pattern 2: Lifecycle Management
**ALWAYS follow the measure → layout → render pipeline:**

```lua
-- In love.load()
local ui = GameUI.new()
local width, height = love.graphics.getDimensions()
ui.root:measure(width, height)
ui.root:layout(0, 0, width, height)

-- In love.resize(w, h)
ui.root:measure(w, h)
ui.root:layout(0, 0, w, h)

-- In love.draw()
ui.root:render()

-- In love.update(dt)
ui.root:update(dt)

-- In love.wheelmoved(x, y)
ui.root:onMouseWheel(x, y)
```

### Pattern 3: Dynamic Content Updates
**When content changes, invalidate layout:**

```lua
-- ✅ CORRECT: Update and invalidate
function updateResourceText(textComponent, newValue)
    textComponent:setText(newValue)
    -- setText automatically invalidates layout
end

-- ❌ WRONG: Updating without re-layout
textComponent.text = newValue  -- Don't do this!
```

### Pattern 4: Event Handling
**Use component callbacks, not global handlers:**

```lua
-- ✅ CORRECT: Component-level callbacks
local button = Button.new({
    label = "Deploy Specialist",
    onClick = function(btn)
        eventBus:publish("specialist_deployed")
    end
})

-- ❌ WRONG: Manual hit testing
function love.mousepressed(x, y, button)
    if x >= buttonX and x <= buttonX + buttonWidth then
        -- Don't do manual bounds checking!
    end
end
```

### Pattern 5: Scene Mouse Event Integration
**CRITICAL: When integrating Smart UI components in scenes, you MUST map LÖVE's mouse events to Component methods:**

The Component base class uses these method names:
- `onMouseMove(x, y)` - for mouse movement and hover detection
- `onMousePress(x, y, button)` - for mouse button press
- `onMouseRelease(x, y, button)` - for mouse button release
- `onMouseWheel(x, y)` - for scroll wheel events

**✅ CORRECT Scene Implementation:**
```lua
-- In your scene or UI manager class:
function MyScene:mousepressed(x, y, button)
    if self.root then
        return self.root:onMousePress(x, y, button)  -- Note: onMousePress, not mousepressed
    end
    return false
end

function MyScene:mousereleased(x, y, button)
    if self.root then
        return self.root:onMouseRelease(x, y, button)  -- Note: onMouseRelease
    end
    return false
end

function MyScene:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:onMouseMove(x, y)  -- Note: onMouseMove (only x, y)
    end
    return false
end

function MyScene:wheelmoved(x, y)
    if self.root and self.root.onMouseWheel then
        return self.root:onMouseWheel(x, y)  -- Note: onMouseWheel
    end
    return false
end
```

**❌ WRONG - Calling non-existent methods:**
```lua
-- DON'T do this - these methods don't exist on Component!
function MyScene:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:mousemoved(x, y, dx, dy)  -- ❌ Wrong method name
    end
end

function MyScene:wheelmoved(x, y)
    if self.root then
        return self.root:mouseWheel(x, y)  -- ❌ Wrong method name (also missing 'on' prefix)
    end
end
```

**Key Points:**
1. LÖVE events use lowercase names: `mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`
2. Component methods use camelCase with `on` prefix: `onMousePress`, `onMouseRelease`, `onMouseMove`, `onMouseWheel`
3. `onMouseMove` only takes `(x, y)`, not `(x, y, dx, dy)`
4. Always check if methods exist before calling (especially for optional ones like `onMouseWheel`)

---

## Viewport Management Rules

### Rule 1: ScrollContainer for All Root UIs
**NEVER create root UI without ScrollContainer:**

```lua
-- ❌ WRONG: Box as root (components can render off-screen)
self.root = Box.new({direction = "vertical"})

-- ✅ CORRECT: ScrollContainer as root
self.root = ScrollContainer.new({showScrollbars = true})
self.content = Box.new({direction = "vertical"})
self.root:addChild(self.content)
```

### Rule 2: Handle Window Resizing
**ALWAYS implement love.resize:**

```lua
function love.resize(w, h)
    if gameUI then
        gameUI.root:measure(w, h)
        gameUI.root:layout(0, 0, w, h)
    end
end
```

### Rule 3: Mouse Wheel for Scrolling
**ALWAYS implement love.wheelmoved:**

```lua
function love.wheelmoved(x, y)
    if gameUI then
        gameUI.root:onMouseWheel(x, y)
    end
end
```

### Rule 4: Content Size Independence
**Let content determine its size, don't force it:**

```lua
-- ❌ WRONG: Fixed sizes that might overflow
local panel = Panel.new({minWidth = 2000, minHeight = 1500})

-- ✅ CORRECT: Content-driven sizing
local panel = Panel.new({
    -- Let content determine size naturally
})
-- ScrollContainer will handle overflow
```

---

## Component Usage Guidelines

### Box Component
**Use for:** Most layout needs, container organization, flex layouts

```lua
-- Horizontal layout with spacing
local toolbar = Box.new({
    direction = "horizontal",
    gap = 10,
    align = "center"
})

-- Vertical stack
local sidebar = Box.new({
    direction = "vertical",
    gap = 15,
    padding = {10, 10, 10, 10}
})

-- Flex growing
local flexContainer = Box.new({direction = "horizontal"})
flexContainer:addChild(Box.new({minWidth = 200}))  -- Fixed
flexContainer:addChild(Box.new({flex = 1}))         -- Grows
flexContainer:addChild(Box.new({minWidth = 150}))  -- Fixed
```

### Grid Component
**Use for:** Data tables, specialist rosters, skill trees, structured data

```lua
local grid = Grid.new({
    columns = 4,
    columnGap = 8,
    rowGap = 4,
    cellBorderColor = {0, 0.5, 0.5, 0.5},
    cellBorderWidth = 1
})

-- Add headers
for _, header in ipairs({"Name", "Level", "Role", "Status"}) do
    grid:addChild(Text.new({text = header, bold = true}))
end

-- Add data rows
for _, specialist in ipairs(specialists) do
    grid:addChild(Text.new({text = specialist.name}))
    grid:addChild(Text.new({text = tostring(specialist.level)}))
    grid:addChild(Text.new({text = specialist.role}))
    grid:addChild(Text.new({text = specialist.status}))
end
```

### Panel Component
**Use for:** Sections, containers with titles, organized content areas

```lua
-- Standard panel
local panel = Panel.new({
    title = "ACTIVE THREATS",
    cornerStyle = "cut",  -- Options: "square", "rounded", "cut"
    glow = true,          -- Cyberpunk glow effect
    minWidth = 400
})

-- No title bar
local simplePanel = Panel.new({
    title = nil,
    cornerStyle = "rounded",
    shadow = true
})
```

### Text Component
**Use for:** Labels, paragraphs, data display, any text content

```lua
-- Simple label
local label = Text.new({text = "Credits:", fontSize = 14})

-- Wrapped paragraph
local description = Text.new({
    text = "Long description that will wrap...",
    wrap = true,
    maxWidth = 400,
    maxLines = 3
})

-- Truncated text with ellipsis
local truncated = Text.new({
    text = "Very long filename that gets truncated",
    truncate = true,
    maxWidth = 200
})
```

### Button Component
**Use for:** Actions, clickable elements, interactive controls

```lua
local deployBtn = Button.new({
    label = "DEPLOY",
    cornerStyle = "cut",
    onClick = function(btn)
        eventBus:publish("deploy_specialist", {id = specialistId})
    end,
    onHoverEnter = function(btn)
        statusText:setText("Deploy specialist to active Incident")
    end
})

-- Disabled state
local lockedBtn = Button.new({
    label = "LOCKED",
    enabled = false
})

-- Critical action styling
local criticalBtn = Button.new({
    label = "QUARANTINE",
    normalColor = {0.6, 0.1, 0.1, 1},
    hoverColor = {0.8, 0.2, 0.2, 1},
    normalBorderColor = {1, 0, 0, 1}
})
```

---

## Testing & Development

### UI Development Workflow

1. **Build UI structure** using components
2. **Run the demo** to see similar patterns: `love ui_demo`
3. **Test with resizing** - make window smaller/larger
4. **Test with scrolling** - add more content than fits
5. **Take screenshots** - Press F12 in demo/game

### Screenshot Testing
**ALWAYS use F12 to capture UI screenshots for verification:**

```lua
-- Screenshot utility is automatically available in demo
-- Press F12 to capture game window (privacy-safe)
-- Screenshots saved to: ~/.local/share/love/<game>/screenshots/

-- To add to your game:
local Screenshot = require("src.utils.screenshot")
local screenshot = Screenshot.new()

-- In love.keypressed(key)
if screenshot:keypressed(key) then
    return  -- Screenshot captured
end
```

### Common Issues & Solutions

**Issue**: Components not visible
**Solution**: Check measure/layout calls, verify ScrollContainer usage

**Issue**: Text wrapping incorrectly
**Solution**: Set maxWidth on Text component, ensure wrap = true

**Issue**: Layout not updating
**Solution**: Call component:invalidateLayout() after content changes

**Issue**: Mouse events not working
**Solution**: Ensure event handlers wired up (onMouseMove, onMouseClick, etc.)

**Issue**: Content renders off-screen
**Solution**: Use ScrollContainer as root, not Box

---

## Integration Requirements

### For idle_mode.lua Integration

```lua
-- Replace existing UI with Smart UI Framework

local Panel = require("src.ui.components.panel")
local Box = require("src.ui.components.box")
local Button = require("src.ui.components.button")
local Text = require("src.ui.components.text")
local ScrollContainer = require("src.ui.components.scroll_container")

-- Build SOC Dashboard
function IdleMode:createUI()
    self.ui = ScrollContainer.new({showScrollbars = true})
    self.content = Box.new({direction = "vertical", gap = 15, padding = {10, 10, 10, 10}})
    self.ui:addChild(self.content)
    
    -- Resource panel
    self.content:addChild(self:createResourcePanel())
    
    -- Contract list
    self.content:addChild(self:createContractList())
    
    -- Specialist roster
    self.content:addChild(self:createSpecialistRoster())
    
    -- Actions
    self.content:addChild(self:createActionPanel())
end

function IdleMode:createResourcePanel()
    local panel = Panel.new({
        title = "RESOURCES",
        cornerStyle = "cut"
    })
    
    -- Add resource displays using Box/Text components
    
    return panel
end
```

### For admin_mode.lua Integration

```lua
-- Replace existing terminal UI with Smart UI Framework

function AdminMode:createUI()
    self.ui = ScrollContainer.new({
        backgroundColor = {0, 0, 0, 0.9},
        showScrollbars = true
    })
    
    self.content = Box.new({direction = "vertical", gap = 10})
    self.ui:addChild(self.content)
    
    -- Terminal header
    self.content:addChild(Panel.new({
        title = ">> ADMIN TERMINAL - Incident RESPONSE",
        titleAlign = "center",
        cornerStyle = "square",
        borderColor = {0, 1, 0, 1}  -- Green terminal
    }))
    
    -- Incident log (scrollable)
    self.logPanel = self:createLogPanel()
    self.content:addChild(self.logPanel)
    
    -- Action buttons
    self.content:addChild(self:createActionButtons())
end
```

---

## Color Palette (Cyberpunk Theme)

**ALWAYS use these colors for consistency:**

```lua
local COLORS = {
    -- Primary accents
    CYAN = {0, 1, 1, 1},
    MAGENTA = {1, 0, 1, 1},
    GREEN = {0, 1, 0, 1},
    RED = {1, 0, 0, 1},
    AMBER = {1, 0.75, 0, 1},
    
    -- Backgrounds
    DARK_BG = {0.05, 0.05, 0.1, 1},
    PANEL_BG = {0.1, 0.1, 0.15, 0.9},
    
    -- Text
    TEXT_PRIMARY = {1, 1, 1, 1},
    TEXT_SECONDARY = {0.7, 0.7, 0.7, 1},
    TEXT_DISABLED = {0.4, 0.4, 0.4, 1}
}
```

---

## Performance Guidelines

1. **Layout Caching**: Framework automatically caches layout - don't invalidate unnecessarily
2. **Visibility Culling**: Hide components not in view: `component:setVisible(false)`
3. **Batch Updates**: When adding many children, add all then invalidate once
4. **Avoid Deep Nesting**: Keep component trees reasonably shallow (< 10 levels)
5. **Reuse Components**: Store and reuse components instead of creating new ones every frame

---

## Migration from Old UI

### Step 1: Identify Old UI Code
Look for:
- Manual `love.graphics.print()` calls
- Manual `love.graphics.rectangle()` for UI
- Hardcoded x,y positions
- Manual hit testing (bounds checking)

### Step 2: Replace with Components
```lua
-- Old code
love.graphics.rectangle("line", 100, 100, 300, 200)
love.graphics.print("Title", 120, 110)

-- New code
local panel = Panel.new({
    title = "Title",
    minWidth = 300,
    minHeight = 200
})
```

### Step 3: Wire Up Events
```lua
-- Old code
function love.mousepressed(x, y, button)
    if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
        doAction()
    end
end

-- New code
local btn = Button.new({
    label = "Action",
    onClick = function(b) doAction() end
})
```

---

## Forbidden Practices

**NEVER do these:**

1. ❌ Manual positioning: `love.graphics.print("text", x, y)`
2. ❌ Root UI without ScrollContainer: `self.root = Box.new()`
3. ❌ Ignoring measure/layout: Just calling `render()` without `measure()` and `layout()`
4. ❌ Modifying component internals: `component.x = 100` (use layout system)
5. ❌ Hardcoded sizes: `minWidth = 1920` (use responsive sizing)
6. ❌ Missing resize handler: Not implementing `love.resize()`
7. ❌ Manual hit testing: Checking `if x >= ... and x <= ...`
8. ❌ Creating fonts every frame: Cache fonts or use component.font property

---

## Quick Reference

**Component Creation Pattern:**
```lua
local comp = ComponentType.new({
    -- Common properties
    minWidth = 100, maxWidth = 500,
    padding = {10, 10, 10, 10},
    margin = {5, 5, 5, 5},
    flex = 0,
    visible = true,
    enabled = true,
    
    -- Component-specific properties
    -- (see docs/SMART_UI_QUICK_REFERENCE.md)
    
    -- Callbacks
    onClick = function(c, button) end,
    onHoverEnter = function(c) end,
    onHoverLeave = function(c) end
})
```

**Lifecycle Pattern:**
```lua
-- Initialize
ui = GameUI.new()
ui.root:measure(width, height)
ui.root:layout(0, 0, width, height)

-- Update
ui.root:update(dt)

-- Render
ui.root:render()

-- Events
ui.root:onMouseMove(x, y)
ui.root:onMouseClick(x, y, button)
ui.root:onMouseWheel(x, y)
```

---

## Documentation Links

- **Full Guide**: `docs/SMART_UI_FRAMEWORK.md` - Complete API reference and patterns
- **Quick Reference**: `docs/SMART_UI_QUICK_REFERENCE.md` - Cheat sheets and snippets
- **Implementation Summary**: `docs/UI_IMPLEMENTATION_SUMMARY.md` - What was built and why
- **Demo**: Run `love ui_demo` to see all components in action

---

## Contact Points for Coding Agent

When integrating UI framework:
1. Read this file FIRST
2. Review `docs/SMART_UI_FRAMEWORK.md` for detailed API
3. Run `love ui_demo` to see working examples
4. Use ScrollContainer as root for ALL new UI
5. Take screenshots (F12) to verify appearance
6. Test with window resizing and scrolling
7. Follow the color palette for consistency

**Remember**: The framework handles positioning automatically. Your job is to describe WHAT components you want, not WHERE they should be. Trust the layout engine!
