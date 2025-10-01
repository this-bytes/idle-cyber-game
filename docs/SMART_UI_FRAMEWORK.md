# Smart UI Framework - Developer Guide

## Overview

The Smart UI Framework is a production-ready, component-based UI system for LÖVE 2D with automatic layout management, responsive design, and modern interaction patterns. Built specifically for Idle Sec Ops, but designed to be reusable and extensible.

## Design Philosophy

### Core Principles

1. **Automatic Layout**: Developers describe WHAT they want, not WHERE it should be
2. **Component Composition**: Build complex UIs from simple, reusable components
3. **Responsive Design**: UIs adapt to different screen sizes and content
4. **Event-Driven**: Components communicate through callbacks and event propagation
5. **Performance-Optimized**: Efficient measurement caching and rendering

### Inspiration

The framework draws inspiration from modern web frameworks (React, Flutter) and implements concepts like:
- Flexbox-like layout (Box component)
- Grid layout (Grid component)
- Component lifecycle (measure → layout → render)
- Event bubbling and capture
- State-based rendering

## Architecture

### Component Hierarchy

```
Component (base class)
├── Box (flexbox container)
│   ├── Panel (styled container with borders)
│   └── Button (interactive button)
├── Grid (table layout)
└── Text (smart text rendering)
```

### Layout Pipeline

Every component follows a three-phase rendering pipeline:

1. **Measure Phase**: Calculate intrinsic size based on content
2. **Layout Phase**: Position children within allocated space
3. **Render Phase**: Draw visual representation

```lua
-- Example of the full pipeline
root:measure(availableWidth, availableHeight)  -- Phase 1
root:layout(x, y, width, height)                -- Phase 2
root:render()                                   -- Phase 3
```

## Core Components

### Component (Base Class)

The foundation for all UI components. Provides:
- Layout properties (position, size, padding, margin, flex)
- Event handling (mouse events, keyboard events)
- Child management (add, remove, find)
- Lifecycle methods (measure, layout, render, update)

#### Common Properties

```lua
{
    -- Display
    visible = true,              -- Component visibility
    enabled = true,              -- Interactive state
    id = "myComponent",          -- Unique identifier
    className = "panel-header",  -- CSS-like class name
    
    -- Layout
    minWidth = 100,              -- Minimum width constraint
    maxWidth = 500,              -- Maximum width constraint
    minHeight = 50,              -- Minimum height constraint
    maxHeight = 300,             -- Maximum height constraint
    flex = 0,                    -- Flex grow factor (0 = fixed size)
    
    -- Spacing
    padding = {10, 15, 10, 15},  -- {top, right, bottom, left}
    margin = {5, 5, 5, 5},       -- {top, right, bottom, left}
    
    -- Callbacks
    onClick = function(component, button) end,
    onHoverEnter = function(component) end,
    onHoverLeave = function(component) end
}
```

#### Key Methods

```lua
-- Child management
component:addChild(child)
component:removeChild(child)
component:clearChildren()

-- Layout control
component:invalidateLayout()           -- Mark for re-layout
component:measure(width, height)       -- Calculate intrinsic size
component:layout(x, y, width, height)  -- Position children

-- Querying
component:findById("myId")             -- Find by ID
component:findByClassName("button")    -- Find by class name
component:containsPoint(x, y)          -- Hit testing

-- Rendering
component:render()                     -- Draw component
component:update(dt)                   -- Update animations
```

### Box Component

Flexbox-like container for automatic layout of children. Supports both horizontal and vertical layouts with alignment and justification.

#### Properties

```lua
{
    direction = "vertical",      -- "vertical" | "horizontal"
    align = "start",             -- Cross-axis: "start" | "center" | "end" | "stretch"
    justify = "start",           -- Main-axis: "start" | "center" | "end" | "space-between" | "space-around" | "space-evenly"
    gap = 10,                    -- Space between children
    wrap = false,                -- Allow wrapping (future)
    
    -- Styling
    backgroundColor = {0.1, 0.1, 0.15, 0.9},
    borderColor = {0, 1, 1, 1},
    borderWidth = 2
}
```

#### Examples

**Horizontal Layout with Center Alignment**
```lua
local horizontalBox = Box.new({
    direction = "horizontal",
    align = "center",
    gap = 15,
    padding = {10, 10, 10, 10}
})

horizontalBox:addChild(Text.new({text = "Button 1"}))
horizontalBox:addChild(Text.new({text = "Button 2"}))
horizontalBox:addChild(Text.new({text = "Button 3"}))
```

**Vertical Layout with Space Between**
```lua
local verticalBox = Box.new({
    direction = "vertical",
    justify = "space-between",
    minHeight = 300
})

verticalBox:addChild(Panel.new({title = "Header"}))
verticalBox:addChild(Panel.new({title = "Content", flex = 1}))
verticalBox:addChild(Panel.new({title = "Footer"}))
```

**Flex Growing Children**
```lua
local flexBox = Box.new({
    direction = "horizontal",
    gap = 10,
    minWidth = 600
})

-- Fixed-size child
flexBox:addChild(Text.new({text = "Label:", minWidth = 100}))

-- Grows to fill available space
flexBox:addChild(Text.new({text = "Dynamic content...", flex = 1}))

-- Another fixed-size child
flexBox:addChild(Button.new({label = "OK", minWidth = 80}))
```

### Grid Component

Table-like layout with flexible column and row sizing. Perfect for data tables, dashboards, and structured layouts.

#### Properties

```lua
{
    columns = 3,                     -- Number of columns
    rows = nil,                      -- Number of rows (nil = auto)
    columnGap = 8,                   -- Horizontal gap between cells
    rowGap = 4,                      -- Vertical gap between cells
    cellAlign = "start",             -- Cell alignment: "start" | "center" | "end" | "stretch"
    
    -- Column sizing (array)
    columnSizes = {100, "auto", "flex", 200},  -- Mix of fixed, auto, and flex
    
    -- Row sizing (array)
    rowSizes = {"auto", "auto", "auto"},
    
    -- Styling
    backgroundColor = {0.1, 0.1, 0.15, 0.9},
    borderColor = {0, 1, 1, 1},
    borderWidth = 2,
    cellBorderColor = {0, 0.5, 0.5, 0.5},
    cellBorderWidth = 1
}
```

#### Examples

**Simple Data Table**
```lua
local grid = Grid.new({
    columns = 3,
    columnGap = 10,
    rowGap = 5
})

-- Header row
grid:addChild(Text.new({text = "Name", bold = true}))
grid:addChild(Text.new({text = "Level", bold = true}))
grid:addChild(Text.new({text = "Status", bold = true}))

-- Data rows
grid:addChild(Text.new({text = "Alice"}))
grid:addChild(Text.new({text = "12"}))
grid:addChild(Text.new({text = "Active"}))

grid:addChild(Text.new({text = "Bob"}))
grid:addChild(Text.new({text = "15"}))
grid:addChild(Text.new({text = "Break"}))
```

**Dashboard Grid with Mixed Sizing**
```lua
local dashboard = Grid.new({
    columns = 3,
    columnSizes = {200, "flex", 150},  -- Fixed, flexible, fixed
    columnGap = 15,
    rowGap = 15
})

-- First row spans multiple cells (content-based)
dashboard:addChild(Panel.new({title = "Resource Panel"}))
dashboard:addChild(Panel.new({title = "Main View"}))
dashboard:addChild(Panel.new({title = "Actions"}))
```

### Text Component

Smart text rendering with automatic wrapping, truncation, and multi-line support.

#### Properties

```lua
{
    text = "Hello, World!",
    font = nil,                      -- LÖVE Font object (nil = default)
    fontSize = 14,
    color = {1, 1, 1, 1},            -- {r, g, b, a}
    
    -- Alignment
    textAlign = "left",              -- "left" | "center" | "right" | "justify"
    verticalAlign = "top",           -- "top" | "center" | "bottom"
    
    -- Wrapping & Truncation
    wrap = true,                     -- Enable text wrapping
    truncate = false,                -- Truncate with ellipsis
    maxLines = 3,                    -- Max number of lines (nil = unlimited)
    
    -- Styling
    bold = false,
    italic = false,
    underline = false,
    lineHeight = 1.2                 -- Line height multiplier
}
```

#### Examples

**Simple Text**
```lua
local text = Text.new({
    text = "Welcome to Idle Sec Ops!",
    fontSize = 16,
    color = {0, 1, 1, 1}
})
```

**Wrapped Paragraph**
```lua
local paragraph = Text.new({
    text = "This is a long paragraph that will automatically wrap to fit within the available width. The text component intelligently breaks lines at word boundaries.",
    wrap = true,
    maxWidth = 400,
    lineHeight = 1.4
})
```

**Truncated Text**
```lua
local truncated = Text.new({
    text = "This text is too long and will be truncated with ellipsis",
    truncate = true,
    maxWidth = 200
})
```

### Panel Component

Styled container with optional title bar, borders, shadows, and glow effects. Perfect for creating organized sections in your UI.

#### Properties

```lua
{
    title = "Panel Title",
    titleAlign = "left",             -- "left" | "center" | "right"
    titleColor = {0, 1, 1, 1},
    titleFontSize = 16,
    
    -- Corner styles
    cornerStyle = "square",          -- "square" | "rounded" | "cut"
    cornerSize = 8,
    
    -- Effects
    shadow = true,
    shadowColor = {0, 0, 0, 0.5},
    shadowOffset = {4, 4},
    
    glow = true,
    glowColor = {0, 1, 1, 0.3},
    glowSize = 4,
    
    -- Inherits Box properties
    backgroundColor = {0.1, 0.1, 0.15, 0.9},
    borderColor = {0, 1, 1, 1},
    borderWidth = 2,
    padding = {8, 8, 8, 8}
}
```

#### Examples

**Basic Panel**
```lua
local panel = Panel.new({
    title = "SOC Dashboard",
    minWidth = 400,
    minHeight = 300
})

panel:addChild(Text.new({text = "Panel content goes here"}))
```

**Cyberpunk Panel with Effects**
```lua
local glowPanel = Panel.new({
    title = "ACTIVE THREATS",
    titleAlign = "center",
    cornerStyle = "cut",
    cornerSize = 12,
    glow = true,
    glowColor = {1, 0, 0, 0.4},
    borderColor = {1, 0, 0, 1}
})
```

**Nested Panels**
```lua
local outerPanel = Panel.new({
    title = "Container",
    direction = "vertical",
    gap = 10
})

outerPanel:addChild(Panel.new({title = "Section 1"}))
outerPanel:addChild(Panel.new({title = "Section 2"}))
outerPanel:addChild(Panel.new({title = "Section 3"}))
```

### Button Component

Interactive button with hover, press, and disabled states. Automatically handles visual feedback and event callbacks.

#### Properties

```lua
{
    label = "Click Me",
    labelColor = {1, 1, 1, 1},
    labelFontSize = 14,
    
    -- State colors
    normalColor = {0.2, 0.2, 0.3, 1},
    hoverColor = {0.3, 0.3, 0.4, 1},
    pressColor = {0.1, 0.1, 0.2, 1},
    disabledColor = {0.15, 0.15, 0.2, 0.5},
    
    normalBorderColor = {0, 1, 1, 1},
    hoverBorderColor = {0, 1, 1, 1},
    pressBorderColor = {1, 0, 1, 1},
    disabledBorderColor = {0.5, 0.5, 0.5, 0.5},
    
    -- Styling
    cornerStyle = "cut",             -- "square" | "rounded" | "cut"
    borderWidth = 2,
    minWidth = 100,
    minHeight = 32,
    
    -- Callbacks
    onClick = function(button, mouseButton) end,
    onHoverEnter = function(button) end,
    onHoverLeave = function(button) end
}
```

#### Examples

**Simple Button**
```lua
local button = Button.new({
    label = "Deploy",
    onClick = function(btn)
        print("Button clicked!")
    end
})
```

**Critical Action Button**
```lua
local criticalBtn = Button.new({
    label = "QUARANTINE",
    normalColor = {0.6, 0.1, 0.1, 1},
    hoverColor = {0.8, 0.2, 0.2, 1},
    normalBorderColor = {1, 0, 0, 1},
    onClick = function(btn)
        -- Perform critical action
    end
})
```

**Button Group**
```lua
local buttonGroup = Box.new({
    direction = "horizontal",
    gap = 10
})

buttonGroup:addChild(Button.new({label = "Save"}))
buttonGroup:addChild(Button.new({label = "Cancel"}))
buttonGroup:addChild(Button.new({label = "Help"}))
```

## Advanced Patterns

### Responsive Layouts

Use flex to create layouts that adapt to available space:

```lua
local responsiveLayout = Box.new({
    direction = "horizontal",
    gap = 10,
    minWidth = 800
})

-- Fixed sidebar
responsiveLayout:addChild(Panel.new({
    title = "Sidebar",
    minWidth = 200
}))

-- Flexible main content
responsiveLayout:addChild(Panel.new({
    title = "Main Content",
    flex = 1  -- Grows to fill remaining space
}))

-- Fixed action panel
responsiveLayout:addChild(Panel.new({
    title = "Actions",
    minWidth = 150
}))
```

### Dynamic Content

Update components dynamically:

```lua
local statusText = Text.new({text = "Idle"})

-- Later, update the text
statusText:setText("Processing...")

-- Trigger re-layout if container size changed
statusText:invalidateLayout()
```

### Component Composition

Build complex components from simpler ones:

```lua
function createResourceBar(name, current, max, color)
    local container = Box.new({
        direction = "horizontal",
        align = "center",
        gap = 10
    })
    
    -- Label
    container:addChild(Text.new({
        text = name,
        minWidth = 100
    }))
    
    -- Bar background
    local barBg = Box.new({
        backgroundColor = {0.1, 0.1, 0.15, 1},
        borderColor = {0.3, 0.3, 0.4, 1},
        borderWidth = 1,
        minWidth = 200,
        minHeight = 20,
        flex = 1
    })
    
    -- Bar fill
    local fillWidth = (current / max) * 200
    local barFill = Box.new({
        backgroundColor = color,
        minWidth = fillWidth,
        minHeight = 18
    })
    
    barBg:addChild(barFill)
    container:addChild(barBg)
    
    -- Value text
    container:addChild(Text.new({
        text = string.format("%d/%d", current, max),
        color = color,
        minWidth = 80,
        textAlign = "right"
    }))
    
    return container
end

-- Usage
local healthBar = createResourceBar("Health", 750, 1000, {0, 1, 0, 1})
```

### Event Handling

Components support mouse events with automatic propagation:

```lua
local panel = Panel.new({
    title = "Interactive Panel",
    onClick = function(comp, button)
        print("Panel clicked with button:", button)
    end
})

local button = Button.new({
    label = "Inner Button",
    onClick = function(comp, button)
        print("Button clicked!")
        -- Event is consumed, won't reach panel
    end
})

panel:addChild(button)
```

### Finding Components

Use IDs and class names to query the component tree:

```lua
-- Assign IDs
local dashboard = Box.new({id = "dashboard"})
local panel = Panel.new({id = "resource-panel", className = "data-panel"})

-- Find by ID
local found = dashboard:findById("resource-panel")

-- Find by class name (returns array)
local dataPanels = dashboard:findByClassName("data-panel")
```

## Integration with Game

### Setting Up in LÖVE 2D

```lua
-- In love.load()
local Panel = require("src.ui.components.panel")
local Box = require("src.ui.components.box")

local ui = Box.new({
    direction = "vertical",
    gap = 10,
    padding = {10, 10, 10, 10}
})

-- Add components
ui:addChild(Panel.new({title = "My Panel"}))

-- Measure and layout
ui:measure(love.graphics.getWidth(), love.graphics.getHeight())
ui:layout(0, 0, love.graphics.getWidth(), love.graphics.getHeight())

-- In love.draw()
ui:render()

-- In love.update(dt)
ui:update(dt)

-- In love.mousemoved(x, y)
ui:onMouseMove(x, y)

-- In love.mousepressed(x, y, button)
ui:onMousePress(x, y, button)

-- In love.mousereleased(x, y, button)
ui:onMouseRelease(x, y, button)
```

### Integration with Event Bus

Connect UI events to game systems:

```lua
local button = Button.new({
    label = "Deploy Specialist",
    onClick = function(btn)
        eventBus:publish("deploy_specialist", {specialistId = "analyst_01"})
    end
})

-- Listen for game events to update UI
eventBus:subscribe("specialist_deployed", function(data)
    statusText:setText("Specialist deployed: " .. data.name)
end)
```

## Performance Optimization

### Layout Caching

The framework automatically caches layout calculations. Only call `invalidateLayout()` when content actually changes:

```lua
-- Good: Only invalidate when necessary
if text ~= currentText then
    textComponent:setText(text)
    -- invalidateLayout called automatically by setText
end

-- Bad: Invalidating every frame
function love.update(dt)
    textComponent:invalidateLayout()  -- Don't do this!
end
```

### Visibility Culling

Hidden components skip rendering and event handling:

```lua
-- Hide expensive component when not needed
heavyPanel:setVisible(false)

-- Show when needed
heavyPanel:setVisible(true)
```

### Batching Updates

When making multiple changes, batch them:

```lua
-- Less efficient
for i = 1, 100 do
    container:addChild(createItem(i))
    -- Layout recalculated 100 times
end

-- More efficient
for i = 1, 100 do
    local item = createItem(i)
    table.insert(container.children, item)
    item.parent = container
end
container:invalidateLayout()  -- Layout calculated once
```

## Styling Guide

### Cyberpunk Neon Palette

```lua
local colors = {
    cyan = {0, 1, 1, 1},
    magenta = {1, 0, 1, 1},
    green = {0, 1, 0, 1},
    red = {1, 0, 0, 1},
    amber = {1, 0.75, 0, 1},
    
    -- Backgrounds
    darkBg = {0.05, 0.05, 0.1, 1},
    panelBg = {0.1, 0.1, 0.15, 0.9},
    
    -- Text
    textPrimary = {1, 1, 1, 1},
    textSecondary = {0.7, 0.7, 0.7, 1},
    textDisabled = {0.4, 0.4, 0.4, 1}
}
```

### Spacing System

```lua
local spacing = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24,
    xxl = 32
}

-- Usage
Panel.new({
    padding = {spacing.md, spacing.md, spacing.md, spacing.md},
    gap = spacing.sm
})
```

### Typography Scale

```lua
local typography = {
    h1 = 24,
    h2 = 20,
    h3 = 16,
    body = 14,
    small = 12,
    tiny = 10
}
```

## Testing

### Unit Testing Components

```lua
-- Example test
local function testBoxLayout()
    local box = Box.new({
        direction = "horizontal",
        gap = 10,
        minWidth = 300
    })
    
    box:addChild(Text.new({text = "A", minWidth = 100}))
    box:addChild(Text.new({text = "B", minWidth = 100}))
    
    box:measure(300, 100)
    assert(box.intrinsicSize.width >= 210, "Width should include gap")
    
    box:layout(0, 0, 300, 100)
    assert(box.children[2].x == 110, "Second child should be offset by first + gap")
end
```

### Visual Testing

Run the demo to visually test all components:

```bash
cd /path/to/idle-cyber-game
love ui_demo
```

## Troubleshooting

### Common Issues

**Components Not Visible**
- Ensure `visible = true` (default)
- Check that parent container has sufficient size
- Verify colors aren't transparent
- Call `measure()` and `layout()` before `render()`

**Layout Not Updating**
- Call `invalidateLayout()` after changing content
- Ensure measure/layout called after invalidation
- Check for circular dependencies in flex calculations

**Events Not Firing**
- Verify `enabled = true` (default)
- Check z-order (children render front-to-back, events back-to-front)
- Ensure click position is within bounds
- Check parent containers aren't consuming events

**Performance Issues**
- Use visibility culling for off-screen components
- Batch layout updates when adding multiple children
- Profile with LÖVE's built-in profiler
- Consider using cached fonts instead of creating new ones

## Future Enhancements

### Planned Features

1. **Scrolling Containers**: Panels that can scroll content
2. **Input Fields**: Text input components with validation
3. **Dropdowns/Selects**: Dropdown menus and select boxes
4. **Tooltips**: Hover tooltips with automatic positioning
5. **Animations**: Built-in animation system for transitions
6. **Theming**: Centralized theme management
7. **Accessibility**: Keyboard navigation, screen reader support

### Extension Points

The framework is designed to be extended:

```lua
-- Create custom component
local MyComponent = setmetatable({}, {__index = Component})
MyComponent.__index = MyComponent

function MyComponent.new(props)
    local self = Component.new(props)
    setmetatable(self, MyComponent)
    
    -- Add custom properties
    self.customProp = props.customProp
    
    return self
end

-- Override measure
function MyComponent:measure(availableWidth, availableHeight)
    -- Custom measurement logic
end

-- Override render
function MyComponent:render()
    -- Custom rendering
end
```

## Conclusion

The Smart UI Framework provides a powerful, flexible foundation for building complex UIs in LÖVE 2D. Its automatic layout system, component composition model, and modern interaction patterns make it easy to create professional, responsive interfaces for Idle Sec Ops.

For more examples, see the demo in `src/ui/ui_demo.lua` and the comprehensive showcase in `demo_ui.lua`.

**Happy Building!** 🚀
