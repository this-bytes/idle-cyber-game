-- Smart UI Framework: Base Component
-- Production-ready component system with automatic layout and responsive design

local Component = {}
Component.__index = Component

function Component.new(props)
    local self = setmetatable({}, Component)
    
    -- Component properties
    self.props = props or {}
    self.children = {}
    self.parent = nil
    
    -- Layout properties (in pixels)
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.minWidth = props.minWidth or 0
    self.maxWidth = props.maxWidth or math.huge
    self.minHeight = props.minHeight or 0
    self.maxHeight = props.maxHeight or math.huge
    
    -- Flex/Layout properties
    self.flex = props.flex or 0              -- Flex grow factor (0 = fixed, >0 = grows)
    self.padding = props.padding or {0, 0, 0, 0}  -- {top, right, bottom, left}
    self.margin = props.margin or {0, 0, 0, 0}    -- {top, right, bottom, left}
    
    -- Display properties
    self.visible = props.visible ~= false
    self.enabled = props.enabled ~= false
    self.id = props.id or nil
    self.className = props.className or nil
    
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
    return child
end

-- Remove child component
function Component:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            self:invalidateLayout()
            return true
        end
    end
    return false
end

-- Clear all children
function Component:clearChildren()
    for _, child in ipairs(self.children) do
        child.parent = nil
    end
    self.children = {}
    self:invalidateLayout()
end

-- Mark layout as needing recalculation
function Component:invalidateLayout()
    self.layoutDirty = true
    if self.parent then
        self.parent:invalidateLayout()
    end
end

-- Set visibility
function Component:setVisible(visible)
    if self.visible ~= visible then
        self.visible = visible
        self:invalidateLayout()
    end
end

-- Measure intrinsic size (override in subclasses)
-- This calculates the "natural" size of the component based on its content
function Component:measure(availableWidth, availableHeight)
    local width = self.minWidth
    local height = self.minHeight
    
    -- Default: measure children and sum vertically
    for _, child in ipairs(self.children) do
        if child.visible then
            local childSize = child:measure(availableWidth, availableHeight)
            width = math.max(width, childSize.width + child.margin[2] + child.margin[4])
            height = height + childSize.height + child.margin[1] + child.margin[3]
        end
    end
    
    -- Add padding
    width = width + self.padding[2] + self.padding[4]
    height = height + self.padding[1] + self.padding[3]
    
    -- Clamp to min/max
    self.intrinsicSize = {
        width = math.min(math.max(width, self.minWidth), self.maxWidth),
        height = math.min(math.max(height, self.minHeight), self.maxHeight)
    }
    
    return self.intrinsicSize
end

-- Layout children (override in subclasses)
-- This positions children within the component's bounds
function Component:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Apply padding to get inner bounds
    local innerX = x + self.padding[4]  -- left padding
    local innerY = y + self.padding[1]  -- top padding
    local innerWidth = width - self.padding[2] - self.padding[4]
    local innerHeight = height - self.padding[1] - self.padding[3]
    
    -- Default: stack children vertically
    local currentY = innerY
    for _, child in ipairs(self.children) do
        if child.visible then
            currentY = currentY + child.margin[1]  -- top margin
            
            local childHeight = child.intrinsicSize.height
            local childWidth = child.intrinsicSize.width
            
            child:layout(innerX + child.margin[4], currentY, childWidth, childHeight)
            
            currentY = currentY + childHeight + child.margin[3]  -- bottom margin
        end
    end
end

-- Render (override in subclasses)
function Component:render()
    if not self.visible then return end
    -- Draw debug overlay for this component when DEBUG_UI is enabled
    if DEBUG_UI then
        local r, g, b, a = love.graphics.getColor()
        -- pressed: red, hovered: yellow, normal: green (translucent)
        if self.pressed then
            love.graphics.setColor(1, 0, 0, 0.15)
        elseif self.hovered then
            love.graphics.setColor(1, 1, 0, 0.12)
        else
            love.graphics.setColor(0, 1, 0, 0.06)
        end
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        love.graphics.setColor(r, g, b, a)
    end

    -- Render children (back to front)
    for _, child in ipairs(self.children) do
        child:render()
    end
end

-- Update (for animations, state changes, etc.)
function Component:update(dt)
    if not self.visible then return end
    
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

-- Event handling
function Component:onMouseMove(x, y)
    if not self.visible or not self.enabled then return false end
    
    local wasHovered = self.hovered
    self.hovered = self:containsPoint(x, y)
    
    -- Fire hover events
    if self.hovered and not wasHovered then
        if self.props.onHoverEnter then
            self.props.onHoverEnter(self)
        end
    elseif not self.hovered and wasHovered then
        if self.props.onHoverLeave then
            self.props.onHoverLeave(self)
        end
    end
    
    -- Propagate to children (front to back for proper hover detection)
    local handled = false
    for i = #self.children, 1, -1 do
        if self.children[i]:onMouseMove(x, y) then
            handled = true
            break  -- Stop at first child that handles it
        end
    end
    
    return handled or self.hovered
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
    if self:containsPoint(x, y) then
        if self.props.onClick then
            self.props.onClick(self, button)
            return true
        end
        return self.enabled  -- Consume event if enabled
    end
    
    return false
end

function Component:onMousePress(x, y, button)
    if not self.visible or not self.enabled then return false end
    -- Defensive: ensure layout is up-to-date for the whole tree to avoid stale bounds
    local root = self
    while root.parent do root = root.parent end
    if root and root.layoutDirty and root.measure then
        -- Re-measure and layout root to current window size
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        root:measure(w, h)
        root:layout(0, 0, w, h)
        print("[UI DEBUG] Forced re-layout of root component before hit testing")
    end
    
    -- Check children first
    for i = #self.children, 1, -1 do
        if self.children[i]:onMousePress(x, y, button) then
            -- Child handled the press
            -- Debug: report which child handled it
            if self.children[i].id or self.children[i].className then
                print(string.format("[UI DEBUG] onMousePress handled by child id=%s class=%s", tostring(self.children[i].id), tostring(self.children[i].className)))
            else
                print("[UI DEBUG] onMousePress handled by unnamed child")
            end
            return true
        end
    end
    
    -- Check self - only if we have click handlers OR we're an interactive component
    -- This prevents non-interactive children (like text labels) from blocking parent clicks
    local isInteractive = self.props.onClick or self.props.onPress or self.props.onRelease
    if self:containsPoint(x, y) and isInteractive then
        self.pressed = true
        if self.props.onPress then
            self.props.onPress(self, button)
        end
        -- Debug: report press on this component
        print(string.format("[UI DEBUG] onMousePress on component id=%s class=%s x=%.1f y=%.1f w=%.1f h=%.1f -> pressed=true", tostring(self.id), tostring(self.className), self.x, self.y, self.width, self.height))
        return true
    end
    
    return false
end

function Component:onMouseRelease(x, y, button)
    if not self.visible then return false end
    
    local wasPressed = self.pressed
    self.pressed = false
    
    -- Check children first
    for i = #self.children, 1, -1 do
        if self.children[i]:onMouseRelease(x, y, button) then
            return true
        end
    end
    
    -- Check self
    if wasPressed and self:containsPoint(x, y) then
        -- Debug: report release and click
        print(string.format("[UI DEBUG] onMouseRelease on component id=%s class=%s x=%.1f y=%.1f w=%.1f h=%.1f -> wasPressed=%s", tostring(self.id), tostring(self.className), self.x, self.y, self.width, self.height, tostring(wasPressed)))
        
        local handled = false
        -- Prefer explicit onRelease, but also trigger onClick for convenience
        if self.props.onRelease then
            print(string.format("[UI DEBUG] Calling onRelease callback for component id=%s", tostring(self.id)))
            self.props.onRelease(self, button)
            handled = true
        end
        if self.props.onClick then
            print(string.format("[UI DEBUG] Calling onClick callback for component id=%s", tostring(self.id)))
            -- onClick is a higher-level convenience callback (press+release)
            self.props.onClick(self, button)
            handled = true
        else
            print(string.format("[UI DEBUG] NO onClick callback for component id=%s class=%s", tostring(self.id), tostring(self.className)))
        end
        -- Only return true if we actually handled the event (had a callback)
        return handled
    end

    return false
end

function Component:containsPoint(x, y)
    return x >= self.x and x < self.x + self.width and
           y >= self.y and y < self.y + self.height
end

-- Find component by ID
function Component:findById(id)
    if self.id == id then
        return self
    end
    
    for _, child in ipairs(self.children) do
        local found = child:findById(id)
        if found then
            return found
        end
    end
    
    return nil
end

-- Find components by class name
function Component:findByClassName(className)
    local results = {}
    
    if self.className == className then
        table.insert(results, self)
    end
    
    for _, child in ipairs(self.children) do
        local childResults = child:findByClassName(className)
        for _, result in ipairs(childResults) do
            table.insert(results, result)
        end
    end
    
    return results
end

return Component
