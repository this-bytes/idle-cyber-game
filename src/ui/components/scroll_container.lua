-- Smart UI Framework: ScrollContainer Component
-- Provides scrollable viewport for content that exceeds available space

local Box = require("src.ui.components.box")

local ScrollContainer = setmetatable({}, {__index = Box})
ScrollContainer.__index = ScrollContainer

function ScrollContainer.new(props)
    props = props or {}
    local self = Box.new(props)
    setmetatable(self, ScrollContainer)
    
    -- Scroll properties
    self.scrollX = 0
    self.scrollY = 0
    self.scrollSpeed = props.scrollSpeed or 30
    
    -- Scroll bars
    self.showScrollbars = props.showScrollbars ~= false
    self.scrollbarWidth = props.scrollbarWidth or 12
    self.scrollbarColor = props.scrollbarColor or {0, 1, 1, 0.5}
    self.scrollbarBgColor = props.scrollbarBgColor or {0.1, 0.1, 0.15, 0.5}
    
    -- Scrollable content size (calculated during measure)
    self.contentWidth = 0
    self.contentHeight = 0
    
    -- Viewport clipping
    self.clipContent = props.clipContent ~= false
    
    return self
end

-- Measure content (may exceed viewport)
function ScrollContainer:measure(availableWidth, availableHeight)
    -- Reserve space for scrollbars if needed
    local reserveWidth = self.showScrollbars and self.scrollbarWidth or 0
    local reserveHeight = self.showScrollbars and self.scrollbarWidth or 0
    
    -- Measure content without constraints to get full size
    local contentSize = Box.measure(self, math.huge, math.huge)
    
    self.contentWidth = contentSize.width
    self.contentHeight = contentSize.height
    
    -- Viewport size (constrained to available space)
    self.intrinsicSize = {
        width = math.min(availableWidth, contentSize.width + reserveWidth),
        height = math.min(availableHeight, contentSize.height + reserveHeight)
    }
    
    return self.intrinsicSize
end

-- Layout content within scrollable viewport
function ScrollContainer:layout(x, y, width, height)
    -- Store viewport bounds (for rendering background/borders/clipping)
    self.viewportX = x
    self.viewportY = y
    self.viewportWidth = width
    self.viewportHeight = height
    
    -- For compatibility with Component base class
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Calculate viewport bounds
    local viewportWidth = width
    local viewportHeight = height
    
    if self.showScrollbars then
        if self.contentHeight > height then
            viewportWidth = width - self.scrollbarWidth
        end
        if self.contentWidth > width then
            viewportHeight = height - self.scrollbarWidth
        end
    end
    
    -- Clamp scroll position
    self.scrollX = math.max(0, math.min(self.scrollX, math.max(0, self.contentWidth - viewportWidth)))
    self.scrollY = math.max(0, math.min(self.scrollY, math.max(0, self.contentHeight - viewportHeight)))
    
    -- Layout content at scrolled position (content can extend beyond viewport)
    local contentX = x - self.scrollX
    local contentY = y - self.scrollY
    
    -- Calculate inner bounds for content
    local innerX = x + self.padding[4]
    local innerY = y + self.padding[1]
    local innerWidth = self.contentWidth - self.padding[2] - self.padding[4]
    local innerHeight = self.contentHeight - self.padding[1] - self.padding[3]
    
    -- Layout children within content area
    local currentY = contentY + self.padding[1]
    for _, child in ipairs(self.children) do
        if child.visible then
            currentY = currentY + child.margin[1]
            
            local childWidth = child.intrinsicSize.width
            local childHeight = child.intrinsicSize.height
            
            child:layout(contentX + child.margin[4] + self.padding[4], currentY, childWidth, childHeight)
            
            currentY = currentY + childHeight + child.margin[3]
        end
    end
end

-- Render with viewport clipping
function ScrollContainer:render()
    if not self.visible then return end
    
    local love = love or _G.love
    
    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()
    
    -- Use viewport bounds (not content bounds)
    local vx = self.viewportX or self.x
    local vy = self.viewportY or self.y
    local vw = self.viewportWidth or self.width
    local vh = self.viewportHeight or self.height
    
    -- Render background
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", vx, vy, vw, vh)
    end
    
    -- Render border
    if self.borderColor and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", 
            vx + self.borderWidth/2, 
            vy + self.borderWidth/2, 
            vw - self.borderWidth, 
            vh - self.borderWidth
        )
    end
    
    -- Set up scissor (clipping) for viewport
    if self.clipContent then
        love.graphics.setScissor(vx, vy, vw, vh)
    end
    
    -- Render children (clipped to viewport)
    love.graphics.setColor(r, g, b, a)
    for _, child in ipairs(self.children) do
        child:render()
    end
    
    -- Reset scissor
    if self.clipContent then
        love.graphics.setScissor()
    end
    
    -- Draw scrollbars
    if self.showScrollbars then
        self:renderScrollbars()
    end
    
    -- Restore state
    love.graphics.setColor(r, g, b, a)
end

-- Render scrollbars
function ScrollContainer:renderScrollbars()
    local love = love or _G.love
    
    local vx = self.viewportX or self.x
    local vy = self.viewportY or self.y
    local vw = self.viewportWidth or self.width
    local vh = self.viewportHeight or self.height
    
    -- Vertical scrollbar
    if self.contentHeight > vh then
        local scrollbarHeight = vh - (self.contentWidth > vw and self.scrollbarWidth or 0)
        local thumbHeight = math.max(20, (vh / self.contentHeight) * scrollbarHeight)
        local thumbY = (self.scrollY / (self.contentHeight - vh)) * (scrollbarHeight - thumbHeight)
        
        -- Scrollbar background
        love.graphics.setColor(self.scrollbarBgColor)
        love.graphics.rectangle("fill", 
            vx + vw - self.scrollbarWidth,
            vy,
            self.scrollbarWidth,
            scrollbarHeight
        )
        
        -- Scrollbar thumb
        love.graphics.setColor(self.scrollbarColor)
        love.graphics.rectangle("fill",
            vx + vw - self.scrollbarWidth + 2,
            vy + thumbY + 2,
            self.scrollbarWidth - 4,
            thumbHeight - 4
        )
    end
    
    -- Horizontal scrollbar
    if self.contentWidth > vw then
        local scrollbarWidth = vw - (self.contentHeight > vh and self.scrollbarWidth or 0)
        local thumbWidth = math.max(20, (vw / self.contentWidth) * scrollbarWidth)
        local thumbX = (self.scrollX / (self.contentWidth - vw)) * (scrollbarWidth - thumbWidth)
        
        -- Scrollbar background
        love.graphics.setColor(self.scrollbarBgColor)
        love.graphics.rectangle("fill",
            vx,
            vy + vh - self.scrollbarWidth,
            scrollbarWidth,
            self.scrollbarWidth
        )
        
        -- Scrollbar thumb
        love.graphics.setColor(self.scrollbarColor)
        love.graphics.rectangle("fill",
            vx + thumbX + 2,
            vy + vh - self.scrollbarWidth + 2,
            thumbWidth - 4,
            self.scrollbarWidth - 4
        )
    end
end

-- Scroll by delta
function ScrollContainer:scroll(dx, dy)
    self.scrollX = self.scrollX + dx
    self.scrollY = self.scrollY + dy
    
    -- Clamp to bounds
    local maxScrollX = math.max(0, self.contentWidth - self.width)
    local maxScrollY = math.max(0, self.contentHeight - self.height)
    
    self.scrollX = math.max(0, math.min(self.scrollX, maxScrollX))
    self.scrollY = math.max(0, math.min(self.scrollY, maxScrollY))
    
    -- Re-layout with new scroll position
    self:layout(self.x, self.y, self.width, self.height)
end

-- Handle mouse wheel scrolling
function ScrollContainer:onMouseWheel(x, y)
    if not self.visible or not self.enabled then return false end
    
    -- Scroll vertically by default
    self:scroll(0, -y * self.scrollSpeed)
    return true
end

-- Scroll to specific position
function ScrollContainer:scrollTo(x, y)
    self.scrollX = x or self.scrollX
    self.scrollY = y or self.scrollY
    self:layout(self.x, self.y, self.width, self.height)
end

-- Scroll to make a child visible
function ScrollContainer:scrollToChild(child)
    if not child then return end
    
    local padding = 20  -- Padding around child
    
    -- Calculate scroll needed to show child
    if child.x < self.x then
        self:scroll(child.x - self.x - padding, 0)
    elseif child.x + child.width > self.x + self.width then
        self:scroll(child.x + child.width - self.x - self.width + padding, 0)
    end
    
    if child.y < self.y then
        self:scroll(0, child.y - self.y - padding)
    elseif child.y + child.height > self.y + self.height then
        self:scroll(0, child.y + child.height - self.y - self.height + padding)
    end
end

-- Check if content needs scrolling
function ScrollContainer:needsScrolling()
    return self.contentWidth > self.width or self.contentHeight > self.height
end

-- Get scroll percentage (0-1)
function ScrollContainer:getScrollPercentage()
    local maxScrollX = math.max(1, self.contentWidth - self.width)
    local maxScrollY = math.max(1, self.contentHeight - self.height)
    
    return {
        x = self.scrollX / maxScrollX,
        y = self.scrollY / maxScrollY
    }
end

return ScrollContainer
