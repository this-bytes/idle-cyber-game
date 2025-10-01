-- Smart UI Framework: Box Component (Flexbox-like Layout)
-- Handles automatic layout with direction, alignment, and justification

local Component = require("src.ui.components.component")

local Box = setmetatable({}, {__index = Component})
Box.__index = Box

function Box.new(props)
    props = props or {}
    local self = Component.new(props)
    setmetatable(self, Box)
    
    -- Flexbox-like properties
    self.direction = props.direction or "vertical"  -- "vertical" | "horizontal"
    self.align = props.align or "start"             -- "start" | "center" | "end" | "stretch"
    self.justify = props.justify or "start"         -- "start" | "center" | "end" | "space-between" | "space-around" | "space-evenly"
    self.gap = props.gap or 0                       -- Space between children
    self.wrap = props.wrap or false                 -- Allow wrapping to next line/column
    
    -- Background styling
    self.backgroundColor = props.backgroundColor or nil
    self.borderColor = props.borderColor or nil
    self.borderWidth = props.borderWidth or 0
    
    return self
end

-- Measure intrinsic size based on children and layout direction
function Box:measure(availableWidth, availableHeight)
    local totalWidth = 0
    local totalHeight = 0
    local maxCrossSize = 0  -- Max size on the cross-axis
    
    -- Calculate padding
    local paddingX = self.padding[2] + self.padding[4]
    local paddingY = self.padding[1] + self.padding[3]
    local borderOffset = self.borderWidth * 2
    
    -- Measure all visible children
    for _, child in ipairs(self.children) do
        if child.visible then
            local childSize = child:measure(
                availableWidth - paddingX - borderOffset,
                availableHeight - paddingY - borderOffset
            )
            
            -- Add margins
            local childWidth = childSize.width + child.margin[2] + child.margin[4]
            local childHeight = childSize.height + child.margin[1] + child.margin[3]
            
            if self.direction == "horizontal" then
                totalWidth = totalWidth + childWidth
                maxCrossSize = math.max(maxCrossSize, childHeight)
            else  -- vertical
                totalHeight = totalHeight + childHeight
                maxCrossSize = math.max(maxCrossSize, childWidth)
            end
        end
    end
    
    -- Add gaps between children
    local visibleCount = 0
    for _, child in ipairs(self.children) do
        if child.visible then visibleCount = visibleCount + 1 end
    end
    
    if visibleCount > 1 then
        local gapTotal = self.gap * (visibleCount - 1)
        if self.direction == "horizontal" then
            totalWidth = totalWidth + gapTotal
        else
            totalHeight = totalHeight + gapTotal
        end
    end
    
    -- Calculate final size
    local width, height
    if self.direction == "horizontal" then
        width = totalWidth + paddingX + borderOffset
        height = math.max(maxCrossSize + paddingY + borderOffset, self.minHeight)
    else
        width = math.max(maxCrossSize + paddingX + borderOffset, self.minWidth)
        height = totalHeight + paddingY + borderOffset
    end
    
    -- Clamp to constraints
    self.intrinsicSize = {
        width = math.min(math.max(width, self.minWidth), self.maxWidth),
        height = math.min(math.max(height, self.minHeight), self.maxHeight)
    }
    
    return self.intrinsicSize
end

-- Layout children according to flexbox rules
function Box:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Calculate inner bounds
    local borderOffset = self.borderWidth
    local innerX = x + self.padding[4] + borderOffset
    local innerY = y + self.padding[1] + borderOffset
    local innerWidth = width - self.padding[2] - self.padding[4] - (borderOffset * 2)
    local innerHeight = height - self.padding[1] - self.padding[3] - (borderOffset * 2)
    
    -- Count visible children and calculate flex totals
    local visibleChildren = {}
    local totalFlexGrow = 0
    local fixedSize = 0
    
    for _, child in ipairs(self.children) do
        if child.visible then
            table.insert(visibleChildren, child)
            totalFlexGrow = totalFlexGrow + (child.flex or 0)
            
            -- Calculate size for fixed children (flex = 0)
            if not child.flex or child.flex == 0 then
                if self.direction == "horizontal" then
                    fixedSize = fixedSize + child.intrinsicSize.width + child.margin[2] + child.margin[4]
                else
                    fixedSize = fixedSize + child.intrinsicSize.height + child.margin[1] + child.margin[3]
                end
            end
        end
    end
    
    if #visibleChildren == 0 then return end
    
    -- Add gaps to fixed size
    local totalGaps = self.gap * (#visibleChildren - 1)
    fixedSize = fixedSize + totalGaps
    
    -- Calculate available space for flex items
    local availableFlexSpace = 0
    if self.direction == "horizontal" then
        availableFlexSpace = math.max(0, innerWidth - fixedSize)
    else
        availableFlexSpace = math.max(0, innerHeight - fixedSize)
    end
    
    -- Calculate positions based on justify
    local positions = self:calculateJustifyPositions(visibleChildren, innerX, innerY, innerWidth, innerHeight, availableFlexSpace, totalFlexGrow)
    
    -- Layout each child
    for i, child in ipairs(visibleChildren) do
        local childX, childY, childWidth, childHeight = positions[i].x, positions[i].y, positions[i].width, positions[i].height
        
        -- Apply child margins
        childX = childX + child.margin[4]  -- left margin
        childY = childY + child.margin[1]  -- top margin
        childWidth = childWidth - child.margin[2] - child.margin[4]
        childHeight = childHeight - child.margin[1] - child.margin[3]
        
        -- Apply alignment on cross-axis
        if self.direction == "horizontal" then
            -- Vertical alignment
            if self.align == "center" then
                childY = childY + (innerHeight - childHeight) / 2
            elseif self.align == "end" then
                childY = childY + innerHeight - childHeight
            elseif self.align == "stretch" then
                childHeight = innerHeight - child.margin[1] - child.margin[3]
            end
        else
            -- Horizontal alignment
            if self.align == "center" then
                childX = childX + (innerWidth - childWidth) / 2
            elseif self.align == "end" then
                childX = childX + innerWidth - childWidth
            elseif self.align == "stretch" then
                childWidth = innerWidth - child.margin[2] - child.margin[4]
            end
        end
        
        child:layout(childX, childY, childWidth, childHeight)
    end
end

-- Calculate positions based on justify property
function Box:calculateJustifyPositions(children, startX, startY, containerWidth, containerHeight, flexSpace, totalFlexGrow)
    local positions = {}
    local currentX = startX
    local currentY = startY
    
    -- Calculate spacing for space-between, space-around, space-evenly
    local spacing = 0
    local initialOffset = 0
    
    if self.justify == "space-between" and #children > 1 then
        spacing = flexSpace / (#children - 1)
    elseif self.justify == "space-around" then
        spacing = flexSpace / #children
        initialOffset = spacing / 2
    elseif self.justify == "space-evenly" then
        spacing = flexSpace / (#children + 1)
        initialOffset = spacing
    elseif self.justify == "center" then
        initialOffset = flexSpace / 2
    elseif self.justify == "end" then
        initialOffset = flexSpace
    end
    
    -- Apply initial offset
    if self.direction == "horizontal" then
        currentX = currentX + initialOffset
    else
        currentY = currentY + initialOffset
    end
    
    -- Position each child
    for i, child in ipairs(children) do
        local childWidth, childHeight
        
        -- Calculate size (considering flex)
        if child.flex and child.flex > 0 and totalFlexGrow > 0 then
            local flexAmount = (flexSpace * child.flex) / totalFlexGrow
            if self.direction == "horizontal" then
                childWidth = child.intrinsicSize.width + flexAmount
                childHeight = child.intrinsicSize.height
            else
                childWidth = child.intrinsicSize.width
                childHeight = child.intrinsicSize.height + flexAmount
            end
        else
            childWidth = child.intrinsicSize.width
            childHeight = child.intrinsicSize.height
        end
        
        -- Store position
        table.insert(positions, {
            x = currentX,
            y = currentY,
            width = childWidth,
            height = childHeight
        })
        
        -- Advance position
        if self.direction == "horizontal" then
            currentX = currentX + childWidth + child.margin[2] + child.margin[4] + self.gap
            if self.justify == "space-around" or self.justify == "space-evenly" then
                currentX = currentX + spacing
            elseif self.justify == "space-between" and i < #children then
                currentX = currentX + spacing
            end
        else
            currentY = currentY + childHeight + child.margin[1] + child.margin[3] + self.gap
            if self.justify == "space-around" or self.justify == "space-evenly" then
                currentY = currentY + spacing
            elseif self.justify == "space-between" and i < #children then
                currentY = currentY + spacing
            end
        end
    end
    
    return positions
end

-- Render background and children
function Box:render()
    if not self.visible then return end
    
    local love = love or _G.love
    
    -- Save previous state
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw background
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    
    -- Draw border
    if self.borderColor and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", 
            self.x + self.borderWidth/2, 
            self.y + self.borderWidth/2, 
            self.width - self.borderWidth, 
            self.height - self.borderWidth
        )
    end
    
    -- Restore color and render children
    love.graphics.setColor(r, g, b, a)
    
    for _, child in ipairs(self.children) do
        child:render()
    end
end

return Box
