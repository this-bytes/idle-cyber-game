# Smart UI Framework - Quick Reference

## Component Cheat Sheet

### Component (Base)
```lua
local Component = require("src.ui.components.component")
local comp = Component.new({
    minWidth = 100, maxWidth = 500,
    padding = {10, 10, 10, 10},  -- top, right, bottom, left
    margin = {5, 5, 5, 5},
    flex = 0,  -- 0 = fixed, >0 = grows
    onClick = function(c, button) end
})
```

### Box (Flexbox Container)
```lua
local Box = require("src.ui.components.box")
local box = Box.new({
    direction = "vertical",  -- or "horizontal"
    align = "start",         -- start|center|end|stretch
    justify = "start",       -- start|center|end|space-between|space-around|space-evenly
    gap = 10,
    backgroundColor = {0.1, 0.1, 0.15, 0.9},
    borderColor = {0, 1, 1, 1},
    borderWidth = 2
})
```

### Grid (Table Layout)
```lua
local Grid = require("src.ui.components.grid")
local grid = Grid.new({
    columns = 3,
    columnGap = 8, rowGap = 4,
    columnSizes = {100, "auto", "flex"},
    cellAlign = "start",
    cellBorderColor = {0, 0.5, 0.5, 0.5},
    cellBorderWidth = 1
})
```

### Text
```lua
local Text = require("src.ui.components.text")
local text = Text.new({
    text = "Hello, World!",
    fontSize = 14,
    color = {1, 1, 1, 1},
    textAlign = "left",      -- left|center|right|justify
    verticalAlign = "top",   -- top|center|bottom
    wrap = true,
    truncate = false,
    maxLines = 3,
    lineHeight = 1.2
})
```

### Panel (Styled Container)
```lua
local Panel = require("src.ui.components.panel")
local panel = Panel.new({
    title = "Panel Title",
    titleAlign = "left",     -- left|center|right
    cornerStyle = "square",  -- square|rounded|cut
    cornerSize = 8,
    shadow = true,
    shadowOffset = {4, 4},
    glow = true,
    glowColor = {0, 1, 1, 0.3}
})
```

### Button (Interactive)
```lua
local Button = require("src.ui.components.button")
local button = Button.new({
    label = "Click Me",
    cornerStyle = "cut",
    normalColor = {0.2, 0.2, 0.3, 1},
    hoverColor = {0.3, 0.3, 0.4, 1},
    pressColor = {0.1, 0.1, 0.2, 1},
    onClick = function(btn, mouseButton)
        print("Clicked!")
    end
})
```

## Common Patterns

### Dashboard Layout
```lua
local dashboard = Box.new({direction = "vertical", gap = 10})
dashboard:addChild(Panel.new({title = "Header", minHeight = 60}))
dashboard:addChild(Panel.new({title = "Content", flex = 1}))
dashboard:addChild(Panel.new({title = "Footer", minHeight = 40}))
```

### Sidebar + Main
```lua
local layout = Box.new({direction = "horizontal", gap = 10})
layout:addChild(Panel.new({title = "Sidebar", minWidth = 200}))
layout:addChild(Panel.new({title = "Main", flex = 1}))
```

### Data Table
```lua
local grid = Grid.new({columns = 3, columnGap = 8, rowGap = 4})
-- Headers
grid:addChild(Text.new({text = "Name", bold = true}))
grid:addChild(Text.new({text = "Value", bold = true}))
grid:addChild(Text.new({text = "Status", bold = true}))
-- Data
grid:addChild(Text.new({text = "Alice"}))
grid:addChild(Text.new({text = "100"}))
grid:addChild(Text.new({text = "OK"}))
```

### Button Group
```lua
local group = Box.new({direction = "horizontal", gap = 10})
group:addChild(Button.new({label = "Save"}))
group:addChild(Button.new({label = "Cancel"}))
```

### Resource Bar
```lua
local bar = Box.new({direction = "horizontal", align = "center", gap = 10})
bar:addChild(Text.new({text = "HP:", minWidth = 50}))
local bg = Box.new({
    backgroundColor = {0.1, 0.1, 0.1, 1},
    borderWidth = 1,
    minWidth = 200, minHeight = 20
})
bg:addChild(Box.new({
    backgroundColor = {0, 1, 0, 1},
    minWidth = 150,  -- 75% of 200
    minHeight = 18
}))
bar:addChild(bg)
bar:addChild(Text.new({text = "750/1000"}))
```

## Lifecycle

```lua
-- 1. Create component tree
local root = Box.new({...})
root:addChild(child1)
root:addChild(child2)

-- 2. Measure (calculates intrinsic sizes)
root:measure(availableWidth, availableHeight)

-- 3. Layout (positions children)
root:layout(x, y, width, height)

-- 4. Render (draws to screen)
root:render()

-- 5. Update (animations, state changes)
root:update(dt)

-- 6. Handle events
root:onMouseMove(x, y)
root:onMouseClick(x, y, button)
```

## Color Palette (Cyberpunk Neon)

```lua
local colors = {
    cyan = {0, 1, 1, 1},
    magenta = {1, 0, 1, 1},
    green = {0, 1, 0, 1},
    red = {1, 0, 0, 1},
    amber = {1, 0.75, 0, 1},
    darkBg = {0.05, 0.05, 0.1, 1},
    panelBg = {0.1, 0.1, 0.15, 0.9}
}
```

## Spacing Scale

```lua
local spacing = {xs=4, sm=8, md=12, lg=16, xl=24, xxl=32}
```

## Typography Scale

```lua
local fontSize = {h1=24, h2=20, h3=16, body=14, small=12, tiny=10}
```

## Useful Methods

```lua
-- Child management
comp:addChild(child)
comp:removeChild(child)
comp:clearChildren()

-- Layout control
comp:invalidateLayout()
comp:setVisible(true/false)

-- Querying
comp:findById("myId")
comp:findByClassName("myClass")
comp:containsPoint(x, y)

-- Text-specific
text:setText("new text")

-- Button-specific
button:setLabel("new label")
button:setEnabled(true/false)

-- Panel-specific
panel:setTitle("new title")
```

## Event Callbacks

```lua
{
    onClick = function(component, button) end,
    onPress = function(component, button) end,
    onRelease = function(component, button) end,
    onHoverEnter = function(component) end,
    onHoverLeave = function(component) end
}
```

## Running the Demo

```bash
cd /path/to/idle-cyber-game
love ui_demo
```

Press `R` to reload, `ESC` to quit.

## Tips

1. **Always call measure before layout**: `root:measure(w, h)` then `root:layout(x, y, w, h)`
2. **Use flex for responsive layouts**: Set `flex = 1` on components that should grow
3. **Invalidate after changes**: Call `comp:invalidateLayout()` when content changes
4. **Use IDs for querying**: Set `id` on components you need to find later
5. **Batch child additions**: Add multiple children then call `invalidateLayout()` once
6. **Hide unused components**: Set `visible = false` to skip rendering/events
7. **Use Box for most layouts**: It's the most versatile container
8. **Use Grid for tables**: Perfect for structured data display
9. **Compose complex components**: Build reusable component functions
10. **Test with the demo**: Modify `ui_demo.lua` to experiment

## Common Mistakes

❌ Forgetting to call measure/layout before render
✅ Always call in order: measure → layout → render

❌ Creating new fonts every frame
✅ Cache fonts or use default

❌ Invalidating layout every frame
✅ Only invalidate when content actually changes

❌ Not setting enabled = false for disabled buttons
✅ Use `button:setEnabled(false)`

❌ Hardcoding positions
✅ Use layout properties (flex, align, justify)

❌ Deep nesting without performance consideration
✅ Keep component trees reasonably shallow

## Integration Example

```lua
-- game_ui.lua
local Panel = require("src.ui.components.panel")
local Box = require("src.ui.components.box")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")

local GameUI = {}

function GameUI.new(eventBus, gameState)
    local self = {}
    
    self.root = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {10, 10, 10, 10}
    })
    
    -- Create UI sections
    local header = Panel.new({title = "Resources"})
    self.moneyText = Text.new({text = "Credits: 0"})
    header:addChild(self.moneyText)
    self.root:addChild(header)
    
    local actionPanel = Panel.new({title = "Actions"})
    local deployBtn = Button.new({
        label = "Deploy",
        onClick = function()
            eventBus:publish("deploy_specialist")
        end
    })
    actionPanel:addChild(deployBtn)
    self.root:addChild(actionPanel)
    
    function self:update(dt)
        -- Update text from game state
        self.moneyText:setText("Credits: " .. gameState.money)
        self.root:update(dt)
    end
    
    function self:render()
        self.root:render()
    end
    
    function self:resize(w, h)
        self.root:measure(w, h)
        self.root:layout(0, 0, w, h)
    end
    
    self:resize(love.graphics.getDimensions())
    
    return self
end

return GameUI
```

---

**For full documentation, see docs/SMART_UI_FRAMEWORK.md**
