# Smart UI Architecture — Idle Sec Ops

## Overview
This document defines a **production-ready, intelligent UI framework** that combines retro terminal aesthetics with modern layout management, responsive design, and dynamic component systems.

## Design Philosophy

### Core Principles
1. **Smart, Not Static** - Components auto-size and reflow based on content
2. **Responsive by Default** - Layouts adapt to screen size and content changes
3. **Component-Based** - Modular, reusable, composable UI elements
4. **Data-Driven Rendering** - UI updates automatically when data changes
5. **Retro Aesthetic, Modern UX** - Beautiful terminal look with intelligent behavior

### Anti-Patterns to Avoid
❌ Hardcoded coordinates and sizes
❌ Fixed-width ASCII art that breaks with content changes
❌ Manual layout calculations everywhere
❌ Copy-paste UI code
❌ String concatenation for layout

### Correct Patterns
✅ Flexible layout containers (Box, Grid, Stack)
✅ Constraint-based positioning
✅ Automatic text wrapping and truncation
✅ Responsive component sizing
✅ Centralized styling system

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              UI RENDERING PIPELINE              │
├─────────────────────────────────────────────────┤
│                                                 │
│  Data Model → Component Tree → Layout Pass →   │
│  Render Pass → Post-Processing → Screen         │
│                                                 │
└─────────────────────────────────────────────────┘

Component Hierarchy:
  Screen
    └─ Scene (manages full-screen layouts)
        ├─ Panel (containers with borders/backgrounds)
        │   ├─ Box (flex-like layout container)
        │   │   ├─ Text (smart text rendering)
        │   │   ├─ ProgressBar (dynamic bars)
        │   │   └─ Button (interactive element)
        │   └─ Grid (table-like layouts)
        └─ Toast (notification overlays)

Layout System:
  LayoutEngine
    ├─ Measure Phase (calculate intrinsic sizes)
    ├─ Constraint Phase (apply parent constraints)
    └─ Position Phase (final placement)

Rendering System:
  Renderer
    ├─ BufferManager (double buffering)
    ├─ StyleEngine (colors, effects, themes)
    ├─ TextRenderer (fonts, wrapping, alignment)
    └─ EffectProcessor (scanlines, glow, etc.)
```

---

## Core Component System

### Base Component Class

```lua
-- src/ui/components/base_component.lua

local Component = {}
Component.__index = Component

function Component.new(props)
    local self = setmetatable({}, Component)
    
    -- Component properties
    self.props = props or {}
    self.children = {}
    self.parent = nil
    
    -- Layout properties
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.minWidth = props.minWidth or 0
    self.maxWidth = props.maxWidth or math.huge
    self.minHeight = props.minHeight or 0
    self.maxHeight = props.maxHeight or math.huge
    
    -- Flex/Layout properties
    self.flex = props.flex or 0              -- Flex grow factor
    self.padding = props.padding or {0, 0, 0, 0}  -- top, right, bottom, left
    self.margin = props.margin or {0, 0, 0, 0}
    
    -- Display properties
    self.visible = props.visible ~= false
    self.enabled = props.enabled ~= false
    
    -- Style
    self.style = props.style or {}
    
    -- State
    self.hovered = false
    self.pressed = false
    self.focused = false
    
    -- Cached layout
    self.layoutDirty = true
    self.intrinsicSize = {width = 0, height = 0}
    
    return self
end

-- Add child component
function Component:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    self:invalidateLayout()
end

-- Mark layout as needing recalculation
function Component:invalidateLayout()
    self.layoutDirty = true
    if self.parent then
        self.parent:invalidateLayout()
    end
end

-- Measure intrinsic size (override in subclasses)
function Component:measure(availableWidth, availableHeight)
    -- Default: measure children and sum
    local width = self.minWidth
    local height = self.minHeight
    
    for _, child in ipairs(self.children) do
        if child.visible then
            local childSize = child:measure(availableWidth, availableHeight)
            width = math.max(width, childSize.width)
            height = height + childSize.height
        end
    end
    
    self.intrinsicSize = {
        width = math.min(width, self.maxWidth),
        height = math.min(height, self.maxHeight)
    }
    
    return self.intrinsicSize
end

-- Layout children (override in subclasses)
function Component:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Apply padding
    local innerX = x + self.padding[4]
    local innerY = y + self.padding[1]
    local innerWidth = width - self.padding[2] - self.padding[4]
    local innerHeight = height - self.padding[1] - self.padding[3]
    
    -- Default: stack children vertically
    local currentY = innerY
    for _, child in ipairs(self.children) do
        if child.visible then
            local childHeight = child.intrinsicSize.height
            child:layout(innerX, currentY, innerWidth, childHeight)
            currentY = currentY + childHeight + child.margin[3]
        end
    end
end

-- Render (override in subclasses)
function Component:render(renderer)
    if not self.visible then return end
    
    -- Render children
    for _, child in ipairs(self.children) do
        child:render(renderer)
    end
end

-- Event handling
function Component:onMouseMove(x, y)
    local wasHovered = self.hovered
    self.hovered = self:containsPoint(x, y)
    
    if self.hovered ~= wasHovered then
        if self.hovered and self.props.onHoverEnter then
            self.props.onHoverEnter()
        elseif not self.hovered and self.props.onHoverLeave then
            self.props.onHoverLeave()
        end
    end
    
    for _, child in ipairs(self.children) do
        child:onMouseMove(x, y)
    end
end

function Component:onMouseClick(x, y, button)
    if not self.visible or not self.enabled then return false end
    
    -- Check children first (front to back)
    for i = #self.children, 1, -1 do
        if self.children[i]:onMouseClick(x, y, button) then
            return true
        end
    end
    
    -- Check self
    if self:containsPoint(x, y) and self.props.onClick then
        self.props.onClick()
        return true
    end
    
    return false
end

function Component:containsPoint(x, y)
    return x >= self.x and x < self.x + self.width and
           y >= self.y and y < self.y + self.height
end

return Component
```

---

## Layout Containers

### Box Container (Flexbox-like)

```lua
-- src/ui/components/box.lua

local Component = require("src.ui.components.base_component")
local Box = setmetatable({}, {__index = Component})
Box.__index = Box

function Box.new(props)
    local self = Component.new(props)
    setmetatable(self, Box)
    
    -- Box-specific properties
    self.direction = props.direction or "vertical"  -- vertical, horizontal
    self.align = props.align or "start"             -- start, center, end, stretch
    self.justify = props.justify or "start"         -- start, center, end, space-between, space-around
    self.wrap = props.wrap or false
    self.gap = props.gap or 0
    
    return self
end

function Box:measure(availableWidth, availableHeight)
    local totalWidth = 0
    local totalHeight = 0
    local maxWidth = 0
    local maxHeight = 0
    
    for _, child in ipairs(self.children) do
        if child.visible then
            local childSize = child:measure(availableWidth, availableHeight)
            
            if self.direction == "horizontal" then
                totalWidth = totalWidth + childSize.width + self.gap
                maxHeight = math.max(maxHeight, childSize.height)
            else
                maxWidth = math.max(maxWidth, childSize.width)
                totalHeight = totalHeight + childSize.height + self.gap
            end
        end
    end
    
    -- Remove last gap
    if self.direction == "horizontal" then
        totalWidth = math.max(0, totalWidth - self.gap)
    else
        totalHeight = math.max(0, totalHeight - self.gap)
    end
    
    self.intrinsicSize = {
        width = math.max(self.minWidth, self.direction == "horizontal" and totalWidth or maxWidth),
        height = math.max(self.minHeight, self.direction == "vertical" and totalHeight or maxHeight)
    }
    
    return self.intrinsicSize
end

function Box:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Apply padding
    local innerX = x + self.padding[4]
    local innerY = y + self.padding[1]
    local innerWidth = width - self.padding[2] - self.padding[4]
    local innerHeight = height - self.padding[1] - self.padding[3]
    
    -- Count visible children and flex total
    local visibleChildren = {}
    local totalFlex = 0
    local fixedSize = 0
    
    for _, child in ipairs(self.children) do
        if child.visible then
            table.insert(visibleChildren, child)
            totalFlex = totalFlex + child.flex
            if child.flex == 0 then
                if self.direction == "horizontal" then
                    fixedSize = fixedSize + child.intrinsicSize.width
                else
                    fixedSize = fixedSize + child.intrinsicSize.height
                end
            end
        end
    end
    
    -- Calculate gap space
    local gapSpace = (#visibleChildren - 1) * self.gap
    
    -- Calculate available space for flex items
    local availableSpace = (self.direction == "horizontal" and innerWidth or innerHeight) - fixedSize - gapSpace
    
    -- Position children
    local currentPos = self.direction == "horizontal" and innerX or innerY
    
    for _, child in ipairs(visibleChildren) do
        local childWidth, childHeight
        
        if self.direction == "horizontal" then
            -- Horizontal layout
            if child.flex > 0 then
                childWidth = math.floor((availableSpace * child.flex) / totalFlex)
            else
                childWidth = child.intrinsicSize.width
            end
            
            -- Apply alignment
            if self.align == "stretch" then
                childHeight = innerHeight
            elseif self.align == "center" then
                childHeight = child.intrinsicSize.height
            else
                childHeight = child.intrinsicSize.height
            end
            
            local childY = innerY
            if self.align == "center" then
                childY = innerY + (innerHeight - childHeight) / 2
            elseif self.align == "end" then
                childY = innerY + innerHeight - childHeight
            end
            
            child:layout(currentPos, childY, childWidth, childHeight)
            currentPos = currentPos + childWidth + self.gap
        else
            -- Vertical layout
            if child.flex > 0 then
                childHeight = math.floor((availableSpace * child.flex) / totalFlex)
            else
                childHeight = child.intrinsicSize.height
            end
            
            -- Apply alignment
            if self.align == "stretch" then
                childWidth = innerWidth
            else
                childWidth = child.intrinsicSize.width
            end
            
            local childX = innerX
            if self.align == "center" then
                childX = innerX + (innerWidth - childWidth) / 2
            elseif self.align == "end" then
                childX = innerX + innerWidth - childWidth
            end
            
            child:layout(childX, currentPos, childWidth, childHeight)
            currentPos = currentPos + childHeight + self.gap
        end
    end
end

return Box
```

### Grid Container

```lua
-- src/ui/components/grid.lua

local Component = require("src.ui.components.base_component")
local Grid = setmetatable({}, {__index = Component})
Grid.__index = Grid

function Grid.new(props)
    local self = Component.new(props)
    setmetatable(self, Grid)
    
    -- Grid-specific properties
    self.columns = props.columns or 1
    self.rows = props.rows or "auto"  -- "auto" calculates based on children
    self.columnGap = props.columnGap or 0
    self.rowGap = props.rowGap or 0
    self.columnWidths = props.columnWidths or nil  -- nil = equal distribution
    self.rowHeights = props.rowHeights or nil      -- nil = equal distribution
    
    return self
end

function Grid:measure(availableWidth, availableHeight)
    local visibleCount = 0
    for _, child in ipairs(self.children) do
        if child.visible then
            visibleCount = visibleCount + 1
        end
    end
    
    local rows = self.rows == "auto" and math.ceil(visibleCount / self.columns) or self.rows
    
    -- Measure all children to get max sizes per column/row
    local columnMaxWidths = {}
    local rowMaxHeights = {}
    
    local index = 0
    for _, child in ipairs(self.children) do
        if child.visible then
            local col = (index % self.columns) + 1
            local row = math.floor(index / self.columns) + 1
            
            local childSize = child:measure(availableWidth / self.columns, availableHeight / rows)
            
            columnMaxWidths[col] = math.max(columnMaxWidths[col] or 0, childSize.width)
            rowMaxHeights[row] = math.max(rowMaxHeights[row] or 0, childSize.height)
            
            index = index + 1
        end
    end
    
    -- Calculate total size
    local totalWidth = 0
    for _, width in ipairs(columnMaxWidths) do
        totalWidth = totalWidth + width
    end
    totalWidth = totalWidth + (self.columns - 1) * self.columnGap
    
    local totalHeight = 0
    for _, height in ipairs(rowMaxHeights) do
        totalHeight = totalHeight + height
    end
    totalHeight = totalHeight + (rows - 1) * self.rowGap
    
    self.intrinsicSize = {
        width = math.max(self.minWidth, totalWidth),
        height = math.max(self.minHeight, totalHeight)
    }
    
    return self.intrinsicSize
end

function Grid:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Apply padding
    local innerX = x + self.padding[4]
    local innerY = y + self.padding[1]
    local innerWidth = width - self.padding[2] - self.padding[4]
    local innerHeight = height - self.padding[1] - self.padding[3]
    
    -- Calculate column widths and row heights
    local columnWidths = self.columnWidths or {}
    local rowHeights = self.rowHeights or {}
    
    -- If not specified, distribute equally
    if not self.columnWidths then
        local columnWidth = (innerWidth - (self.columns - 1) * self.columnGap) / self.columns
        for i = 1, self.columns do
            columnWidths[i] = columnWidth
        end
    end
    
    local visibleCount = 0
    for _, child in ipairs(self.children) do
        if child.visible then
            visibleCount = visibleCount + 1
        end
    end
    local rows = self.rows == "auto" and math.ceil(visibleCount / self.columns) or self.rows
    
    if not self.rowHeights then
        local rowHeight = (innerHeight - (rows - 1) * self.rowGap) / rows
        for i = 1, rows do
            rowHeights[i] = rowHeight
        end
    end
    
    -- Position children in grid
    local index = 0
    local currentY = innerY
    
    for row = 1, rows do
        local currentX = innerX
        
        for col = 1, self.columns do
            if index < #self.children then
                local child = self.children[index + 1]
                if child.visible then
                    child:layout(currentX, currentY, columnWidths[col], rowHeights[row])
                    index = index + 1
                end
                currentX = currentX + columnWidths[col] + self.columnGap
            end
        end
        
        if rowHeights[row] then
            currentY = currentY + rowHeights[row] + self.rowGap
        end
    end
end

return Grid
```

---

## Smart Text Component

```lua
-- src/ui/components/text.lua

local Component = require("src.ui.components.base_component")
local Text = setmetatable({}, {__index = Component})
Text.__index = Text

function Text.new(props)
    local self = Component.new(props)
    setmetatable(self, Text)
    
    -- Text-specific properties
    self.text = props.text or ""
    self.font = props.font or nil  -- nil = default
    self.fontSize = props.fontSize or 14
    self.color = props.color or {1, 1, 1}
    self.align = props.align or "left"  -- left, center, right
    self.verticalAlign = props.verticalAlign or "top"  -- top, center, bottom
    self.wrap = props.wrap ~= false  -- wrap by default
    self.ellipsis = props.ellipsis or "..."
    self.maxLines = props.maxLines or nil
    
    -- Cached wrapped text
    self.wrappedLines = {}
    self.textDirty = true
    
    return self
end

function Text:setText(text)
    if self.text ~= text then
        self.text = text
        self.textDirty = true
        self:invalidateLayout()
    end
end

function Text:measure(availableWidth, availableHeight)
    if self.textDirty or not self.wrappedLines then
        self:wrapText(availableWidth)
    end
    
    local font = self.font or love.graphics.getFont()
    local lineHeight = font:getHeight()
    
    local maxWidth = 0
    for _, line in ipairs(self.wrappedLines) do
        local lineWidth = font:getWidth(line)
        maxWidth = math.max(maxWidth, lineWidth)
    end
    
    local totalHeight = #self.wrappedLines * lineHeight
    
    self.intrinsicSize = {
        width = math.min(maxWidth, self.maxWidth),
        height = math.min(totalHeight, self.maxHeight)
    }
    
    return self.intrinsicSize
end

function Text:wrapText(maxWidth)
    local font = self.font or love.graphics.getFont()
    self.wrappedLines = {}
    
    if not self.wrap then
        -- No wrapping, just use the text as-is (may truncate)
        local textWidth = font:getWidth(self.text)
        if textWidth <= maxWidth then
            table.insert(self.wrappedLines, self.text)
        else
            -- Truncate with ellipsis
            local truncated = self.text
            while font:getWidth(truncated .. self.ellipsis) > maxWidth and #truncated > 0 do
                truncated = truncated:sub(1, -2)
            end
            table.insert(self.wrappedLines, truncated .. self.ellipsis)
        end
    else
        -- Wrap text
        local words = {}
        for word in self.text:gmatch("%S+") do
            table.insert(words, word)
        end
        
        local currentLine = ""
        for _, word in ipairs(words) do
            local testLine = currentLine == "" and word or (currentLine .. " " .. word)
            local testWidth = font:getWidth(testLine)
            
            if testWidth <= maxWidth then
                currentLine = testLine
            else
                if currentLine ~= "" then
                    table.insert(self.wrappedLines, currentLine)
                    currentLine = word
                else
                    -- Single word too long, force break
                    table.insert(self.wrappedLines, word)
                    currentLine = ""
                end
            end
        end
        
        if currentLine ~= "" then
            table.insert(self.wrappedLines, currentLine)
        end
        
        -- Apply max lines
        if self.maxLines and #self.wrappedLines > self.maxLines then
            self.wrappedLines = {table.unpack(self.wrappedLines, 1, self.maxLines)}
            -- Add ellipsis to last line
            local lastLine = self.wrappedLines[#self.wrappedLines]
            while font:getWidth(lastLine .. self.ellipsis) > maxWidth and #lastLine > 0 do
                lastLine = lastLine:sub(1, -2)
            end
            self.wrappedLines[#self.wrappedLines] = lastLine .. self.ellipsis
        end
    end
    
    self.textDirty = false
end

function Text:render(renderer)
    if not self.visible or #self.wrappedLines == 0 then return end
    
    local font = self.font or love.graphics.getFont()
    local lineHeight = font:getHeight()
    
    love.graphics.setFont(font)
    love.graphics.setColor(self.color)
    
    local y = self.y
    
    -- Vertical alignment
    if self.verticalAlign == "center" then
        local totalTextHeight = #self.wrappedLines * lineHeight
        y = self.y + (self.height - totalTextHeight) / 2
    elseif self.verticalAlign == "bottom" then
        local totalTextHeight = #self.wrappedLines * lineHeight
        y = self.y + self.height - totalTextHeight
    end
    
    for _, line in ipairs(self.wrappedLines) do
        local x = self.x
        
        -- Horizontal alignment
        if self.align == "center" then
            local lineWidth = font:getWidth(line)
            x = self.x + (self.width - lineWidth) / 2
        elseif self.align == "right" then
            local lineWidth = font:getWidth(line)
            x = self.x + self.width - lineWidth
        end
        
        love.graphics.print(line, x, y)
        y = y + lineHeight
    end
end

return Text
```

---

## Panel Component (with borders and backgrounds)

```lua
-- src/ui/components/panel.lua

local Box = require("src.ui.components.box")
local Panel = setmetatable({}, {__index = Box})
Panel.__index = Panel

function Panel.new(props)
    local self = Box.new(props)
    setmetatable(self, Panel)
    
    -- Panel-specific properties
    self.border = props.border ~= false  -- border enabled by default
    self.borderStyle = props.borderStyle or "single"  -- single, double, heavy, rounded
    self.borderColor = props.borderColor or {0.5, 0.5, 0.5}
    self.backgroundColor = props.backgroundColor or nil
    self.title = props.title or nil
    self.titleAlign = props.titleAlign or "left"
    
    -- Border characters
    self.borderChars = self:getBorderChars()
    
    -- Adjust padding to account for border
    if self.border then
        -- Add 1 character of padding on all sides for border
        self.padding = {
            self.padding[1] + 1,
            self.padding[2] + 1,
            self.padding[3] + 1,
            self.padding[4] + 1
        }
    end
    
    return self
end

function Panel:getBorderChars()
    local styles = {
        single = {tl="┌", tr="┐", bl="└", br="┘", h="─", v="│"},
        double = {tl="╔", tr="╗", bl="╚", br="╝", h="═", v="║"},
        heavy = {tl="┏", tr="┓", bl="┗", br="┛", h="━", v="┃"},
        rounded = {tl="╭", tr="╮", bl="╰", br="╯", h="─", v="│"}
    }
    return styles[self.borderStyle] or styles.single
end

function Panel:render(renderer)
    if not self.visible then return end
    
    -- Render background
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    
    -- Render border
    if self.border then
        self:renderBorder(renderer)
    end
    
    -- Render children
    for _, child in ipairs(self.children) do
        child:render(renderer)
    end
end

function Panel:renderBorder(renderer)
    local font = love.graphics.getFont()
    local charWidth = font:getWidth("X")
    local charHeight = font:getHeight()
    
    love.graphics.setColor(self.borderColor)
    
    -- Calculate border dimensions in characters
    local widthInChars = math.floor(self.width / charWidth)
    local heightInChars = math.floor(self.height / charHeight)
    
    local b = self.borderChars
    
    -- Top-left corner
    love.graphics.print(b.tl, self.x, self.y)
    
    -- Top-right corner
    love.graphics.print(b.tr, self.x + (widthInChars - 1) * charWidth, self.y)
    
    -- Bottom-left corner
    love.graphics.print(b.bl, self.x, self.y + (heightInChars - 1) * charHeight)
    
    -- Bottom-right corner
    love.graphics.print(b.br, self.x + (widthInChars - 1) * charWidth, self.y + (heightInChars - 1) * charHeight)
    
    -- Top and bottom horizontal lines
    for i = 1, widthInChars - 2 do
        love.graphics.print(b.h, self.x + i * charWidth, self.y)
        love.graphics.print(b.h, self.x + i * charWidth, self.y + (heightInChars - 1) * charHeight)
    end
    
    -- Left and right vertical lines
    for i = 1, heightInChars - 2 do
        love.graphics.print(b.v, self.x, self.y + i * charHeight)
        love.graphics.print(b.v, self.x + (widthInChars - 1) * charWidth, self.y + i * charHeight)
    end
    
    -- Render title if present
    if self.title then
        local titleX = self.x + charWidth
        if self.titleAlign == "center" then
            local titleWidth = font:getWidth(self.title)
            titleX = self.x + (self.width - titleWidth) / 2
        elseif self.titleAlign == "right" then
            local titleWidth = font:getWidth(self.title)
            titleX = self.x + self.width - titleWidth - charWidth
        end
        
        love.graphics.setColor(self.borderColor)
        love.graphics.print(" " .. self.title .. " ", titleX, self.y)
    end
end

return Panel
```

---

## Toast Notification System

```lua
-- src/ui/toast_manager.lua

local ToastManager = {}
ToastManager.__index = ToastManager

function ToastManager.new()
    local self = setmetatable({}, ToastManager)
    
    self.toasts = {}
    self.nextId = 1
    self.maxToasts = 5
    self.defaultDuration = 3.0  -- seconds
    self.spacing = 10  -- pixels between toasts
    self.position = "top-right"  -- top-right, top-left, bottom-right, bottom-left, top-center
    
    return self
end

function ToastManager:show(text, options)
    options = options or {}
    
    local toast = {
        id = self.nextId,
        text = text,
        type = options.type or "info",  -- success, error, warning, info
        duration = options.duration or self.defaultDuration,
        icon = options.icon or self:getDefaultIcon(options.type),
        time = 0,
        alpha = 0,
        targetAlpha = 1,
        y = 0,
        targetY = 0,
        dismissed = false
    }
    
    self.nextId = self.nextId + 1
    table.insert(self.toasts, toast)
    
    -- Remove oldest if exceeded max
    if #self.toasts > self.maxToasts then
        table.remove(self.toasts, 1)
    end
    
    self:recalculatePositions()
    
    return toast.id
end

function ToastManager:getDefaultIcon(type)
    local icons = {
        success = "✓",
        error = "✗",
        warning = "⚠",
        info = "ℹ",
        level_up = "⚡",
        Incident = "🚨",
        money = "💰",
        xp = "🎯"
    }
    return icons[type] or icons.info
end

function ToastManager:getColor(type)
    local colors = {
        success = {0.0, 1.0, 0.5},
        error = {1.0, 0.2, 0.2},
        warning = {1.0, 0.8, 0.0},
        info = {0.0, 0.9, 0.9},
        level_up = {1.0, 0.0, 0.8},
        Incident = {1.0, 0.4, 0.0},
        money = {0.0, 1.0, 0.4},
        xp = {0.5, 0.5, 1.0}
    }
    return colors[type] or colors.info
end

function ToastManager:dismiss(id)
    for i, toast in ipairs(self.toasts) do
        if toast.id == id then
            toast.dismissed = true
            toast.targetAlpha = 0
            break
        end
    end
end

function ToastManager:recalculatePositions()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local currentY = self.position:match("top") and 20 or (screenHeight - 20)
    
    for i, toast in ipairs(self.toasts) do
        if self.position:match("top") then
            toast.targetY = currentY
            currentY = currentY + 60 + self.spacing  -- toast height + spacing
        else
            currentY = currentY - 60 - self.spacing
            toast.targetY = currentY
        end
    end
end

function ToastManager:update(dt)
    local needsRecalc = false
    
    for i = #self.toasts, 1, -1 do
        local toast = self.toasts[i]
        toast.time = toast.time + dt
        
        -- Animate alpha (fade in/out)
        if toast.alpha < toast.targetAlpha then
            toast.alpha = math.min(toast.targetAlpha, toast.alpha + dt * 3)
        elseif toast.alpha > toast.targetAlpha then
            toast.alpha = math.max(toast.targetAlpha, toast.alpha - dt * 3)
        end
        
        -- Animate position (slide)
        if math.abs(toast.y - toast.targetY) > 1 then
            toast.y = toast.y + (toast.targetY - toast.y) * dt * 10
        else
            toast.y = toast.targetY
        end
        
        -- Auto-dismiss after duration
        if not toast.dismissed and toast.time >= toast.duration then
            toast.dismissed = true
            toast.targetAlpha = 0
        end
        
        -- Remove if fully faded out
        if toast.dismissed and toast.alpha <= 0.01 then
            table.remove(self.toasts, i)
            needsRecalc = true
        end
    end
    
    if needsRecalc then
        self:recalculatePositions()
    end
end

function ToastManager:render()
    local font = love.graphics.getFont()
    local screenWidth = love.graphics.getWidth()
    
    for _, toast in ipairs(self.toasts) do
        if toast.alpha > 0 then
            local color = self:getColor(toast.type)
            
            -- Calculate toast dimensions
            local maxWidth = 300
            local padding = 15
            local textWidth = math.min(font:getWidth(toast.text), maxWidth - padding * 2)
            local toastWidth = textWidth + padding * 2 + 30  -- +30 for icon
            local toastHeight = 50
            
            -- Calculate X position
            local x
            if self.position:match("right") then
                x = screenWidth - toastWidth - 20
            elseif self.position:match("left") then
                x = 20
            else  -- center
                x = (screenWidth - toastWidth) / 2
            end
            
            local y = toast.y
            
            -- Draw background
            love.graphics.setColor(0.1, 0.1, 0.15, toast.alpha * 0.95)
            love.graphics.rectangle("fill", x, y, toastWidth, toastHeight, 5, 5)
            
            -- Draw border
            love.graphics.setColor(color[1], color[2], color[3], toast.alpha)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x, y, toastWidth, toastHeight, 5, 5)
            
            -- Draw icon
            love.graphics.setColor(color[1], color[2], color[3], toast.alpha)
            love.graphics.print(toast.icon, x + padding, y + (toastHeight - font:getHeight()) / 2)
            
            -- Draw text
            love.graphics.setColor(0.9, 0.9, 1.0, toast.alpha)
            love.graphics.print(toast.text, x + padding + 25, y + (toastHeight - font:getHeight()) / 2)
        end
    end
end

return ToastManager
```

---

## Usage Examples

### Example 1: Responsive Dashboard Layout

```lua
local Box = require("src.ui.components.box")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Grid = require("src.ui.components.grid")

-- Create main dashboard layout
local dashboard = Box.new({
    direction = "vertical",
    padding = {10, 10, 10, 10},
    gap = 10
})

-- Header section (fixed height)
local header = Panel.new({
    title = "IDLE SEC OPS - SOC Dashboard",
    borderStyle = "double",
    minHeight = 50,
    flex = 0
})
header:addChild(Text.new({
    text = "System Status: ONLINE | Threat Level: ELEVATED",
    align = "center",
    color = {0, 1, 0.5}
}))
dashboard:addChild(header)

-- Main content area (flex grow)
local mainContent = Box.new({
    direction = "horizontal",
    gap = 10,
    flex = 1
})

-- Left sidebar (fixed width or flex)
local sidebar = Box.new({
    direction = "vertical",
    gap = 10,
    flex = 1,
    minWidth = 200
})

local contractsPanel = Panel.new({
    title = "Contracts [3 Active]",
    borderStyle = "single",
    flex = 1
})
-- Add contract items...
sidebar:addChild(contractsPanel)

mainContent:addChild(sidebar)

-- Main panel (flexible)
local mainPanel = Panel.new({
    title = "Operations Center",
    borderStyle = "single",
    flex = 2
})
mainContent:addChild(mainPanel)

-- Right sidebar
local teamPanel = Panel.new({
    title = "Team Roster [5/8]",
    borderStyle = "single",
    flex = 1,
    minWidth = 250
})
mainContent:addChild(teamPanel)

dashboard:addChild(mainContent)

-- Footer (fixed height)
local footer = Text.new({
    text = "⚡ System Response: 0.047s | Frame: 60 FPS",
    align = "center",
    color = {0.5, 0.5, 0.5},
    minHeight = 20,
    flex = 0
})
dashboard:addChild(footer)

-- Layout and render
dashboard:measure(love.graphics.getWidth(), love.graphics.getHeight())
dashboard:layout(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
dashboard:render()
```

### Example 2: Toast Notifications

```lua
local toastManager = ToastManager.new()

-- Show success toast
toastManager:show("Incident resolved! +50 XP", {type = "success", duration = 3.0})

-- Show level up toast
toastManager:show("LEVEL UP! Alex reached Level 8", {type = "level_up", icon = "⚡", duration = 5.0})

-- Show warning toast
toastManager:show("SLA at risk for FinTech Inc", {type = "warning", duration = 4.0})

-- Show error toast
toastManager:show("Failed to deploy specialist (on cooldown)", {type = "error", duration = 3.0})

-- In game loop
function love.update(dt)
    toastManager:update(dt)
end

function love.draw()
    -- ... render other UI ...
    toastManager:render()
end
```

---

## Implementation Roadmap

### Phase 1: Core Layout Engine ✅
- [x] Base Component class
- [x] Box container (flexbox-like)
- [x] Grid container
- [x] Measure/Layout/Render pipeline
- [x] Event handling

### Phase 2: Essential Components ✅
- [x] Text component with wrapping
- [x] Panel component with borders
- [x] ProgressBar component
- [x] Button component

### Phase 3: Toast & Effects 🚧
- [x] Toast notification manager
- [ ] CRT shader effects
- [ ] Animation system
- [ ] Transition effects

### Phase 4: Advanced Features 📋
- [ ] ScrollView component
- [ ] Table/List component
- [ ] Input components
- [ ] Modal/Dialog system

### Phase 5: Performance & Polish 📋
- [ ] Render caching
- [ ] Dirty region optimization
- [ ] Accessibility features
- [ ] Theme system

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Layout Calculation**
   - Only recalculate when `layoutDirty` is true
   - Cache intrinsic sizes
   - Propagate invalidation up the tree only

2. **Render Culling**
   - Don't render components outside viewport
   - Check visibility before rendering children
   - Skip transparent/hidden components early

3. **Text Caching**
   - Cache wrapped text lines
   - Only rewrap when text or width changes
   - Use texture caching for static text

4. **Event Optimization**
   - Early exit on disabled/invisible components
   - Reverse iteration for click detection (front to back)
   - Spatial indexing for large component trees

5. **Memory Management**
   - Reuse component instances
   - Pool frequently created/destroyed components
   - Weak references for large data structures

---

## Conclusion

This smart UI architecture provides:

✅ **Responsive Layouts** - Components adapt to content and screen size
✅ **Maintainable Code** - Component-based, not spaghetti
✅ **Retro Aesthetic** - Terminal look with modern UX
✅ **Performance** - Optimized rendering and layout
✅ **Extensible** - Easy to add new component types
✅ **Professional** - Production-ready patterns

The system handles dynamic content gracefully - no more broken layouts from variable-length strings!
