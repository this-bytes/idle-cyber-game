-- Buff Display UI Component
-- Shows active buffs with icons, timers, and effect information

local BuffDisplay = {}
BuffDisplay.__index = BuffDisplay

-- Create new buff display
function BuffDisplay.new(buffSystem)
    local self = setmetatable({}, BuffDisplay)
    
    self.buffSystem = buffSystem
    self.x = 10 -- Position from left edge
    self.y = 10 -- Position from top edge
    self.width = 300
    self.height = 200
    self.visible = true
    
    -- Display settings
    self.iconSize = 24
    self.padding = 8
    self.fontSize = 12
    self.titleFontSize = 14
    
    -- Colors (cybersecurity theme)
    self.colors = {
        background = {0.1, 0.1, 0.2, 0.9},
        border = {0.2, 0.8, 1.0, 1.0},
        text = {0.9, 0.9, 0.9, 1.0},
        timer = {0.6, 0.9, 0.6, 1.0},
        expired = {0.9, 0.3, 0.3, 1.0},
        permanent = {1.0, 0.8, 0.2, 1.0},
        stackable = {0.8, 0.6, 1.0, 1.0}
    }
    
    return self
end

-- Set position of the buff display
function BuffDisplay:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set visibility
function BuffDisplay:setVisible(visible)
    self.visible = visible
end

-- Toggle visibility
function BuffDisplay:toggle()
    self.visible = not self.visible
end

-- Format time duration for display
function BuffDisplay:formatTime(seconds)
    if not seconds or seconds < 0 then
        return "∞"
    end
    
    if seconds < 60 then
        return string.format("%ds", math.floor(seconds))
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), math.floor(seconds % 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- Get color for buff based on type and remaining time
function BuffDisplay:getBuffColor(buff)
    if buff.permanent then
        return self.colors.permanent
    elseif buff.remainingTime and buff.remainingTime < 30 then
        return self.colors.expired
    elseif buff.stacks and buff.stacks > 1 then
        return self.colors.stackable
    else
        return self.colors.text
    end
end

-- Draw a single buff entry
function BuffDisplay:drawBuff(buff, x, y, width)
    local g = love.graphics
    local originalColor = {g.getColor()}
    
    -- Get buff color
    local buffColor = self:getBuffColor(buff)
    
    -- Draw buff icon
    g.setColor(buffColor)
    g.print(buff.icon or "⭐", x, y)
    
    -- Draw buff name and stacks
    local nameText = buff.name
    if buff.stacks and buff.stacks > 1 then
        nameText = nameText .. " (x" .. buff.stacks .. ")"
    end
    
    g.setColor(self.colors.text)
    g.print(nameText, x + self.iconSize + 4, y)
    
    -- Draw remaining time
    local timeText = self:formatTime(buff.remainingTime)
    local font = g.getFont()
    local timeWidth = font:getWidth(timeText)
    
    if buff.permanent then
        g.setColor(self.colors.permanent)
    elseif buff.remainingTime and buff.remainingTime < 30 then
        g.setColor(self.colors.expired)
    else
        g.setColor(self.colors.timer)
    end
    
    g.print(timeText, x + width - timeWidth, y)
    
    -- Draw description on second line if there's room
    if buff.description then
        g.setColor(0.7, 0.7, 0.7, 1.0)
        local descY = y + self.fontSize + 2
        local descText = buff.description
        
        -- Truncate description if too long
        local maxDescWidth = width - self.iconSize - 8
        if font:getWidth(descText) > maxDescWidth then
            while font:getWidth(descText .. "...") > maxDescWidth and #descText > 0 do
                descText = descText:sub(1, -2)
            end
            descText = descText .. "..."
        end
        
        g.print(descText, x + self.iconSize + 4, descY)
    end
    
    g.setColor(originalColor)
    
    -- Return height used for this buff entry
    return self.fontSize * 2 + 4
end

-- Draw the buff display panel
function BuffDisplay:draw()
    if not self.visible or not self.buffSystem then
        return
    end
    
    local g = love.graphics
    local originalColor = {g.getColor()}
    local originalFont = g.getFont()
    
    -- Get active buffs
    local activeBuffs = self.buffSystem:getActiveBuffs()
    
    if #activeBuffs == 0 then
        -- Don't show panel if no buffs
        return
    end
    
    -- Calculate panel height based on number of buffs
    local contentHeight = #activeBuffs * (self.fontSize * 2 + 4) + self.padding * 2 + self.titleFontSize + 4
    local panelHeight = math.min(contentHeight, self.height)
    
    -- Draw background panel
    g.setColor(self.colors.background)
    g.rectangle("fill", self.x, self.y, self.width, panelHeight)
    
    -- Draw border
    g.setColor(self.colors.border)
    g.setLineWidth(2)
    g.rectangle("line", self.x, self.y, self.width, panelHeight)
    
    -- Draw title
    g.setColor(self.colors.border)
    g.print("🔮 Active Buffs", self.x + self.padding, self.y + self.padding)
    
    -- Draw buffs
    local currentY = self.y + self.padding + self.titleFontSize + 4
    local buffWidth = self.width - self.padding * 2
    
    for i, buff in ipairs(activeBuffs) do
        if currentY + self.fontSize * 2 <= self.y + panelHeight - self.padding then
            local usedHeight = self:drawBuff(buff, self.x + self.padding, currentY, buffWidth)
            currentY = currentY + usedHeight + 2
        else
            -- Show "..." if there are more buffs that don't fit
            g.setColor(self.colors.text)
            g.print("... +" .. (#activeBuffs - i + 1) .. " more", self.x + self.padding, currentY)
            break
        end
    end
    
    g.setColor(originalColor)
    g.setFont(originalFont)
end

-- Handle mouse clicks on the buff display
function BuffDisplay:mousepressed(x, y, button)
    if not self.visible then
        return false
    end
    
    -- Check if click is within panel bounds
    if x >= self.x and x <= self.x + self.width and 
       y >= self.y and y <= self.y + self.height then
        
        if button == 1 then -- Left click
            -- Could implement buff details popup here
            return true
        elseif button == 2 then -- Right click
            -- Toggle visibility
            self:toggle()
            return true
        end
    end
    
    return false
end

-- Handle key presses
function BuffDisplay:keypressed(key)
    if key == "b" then -- 'B' key toggles buff display
        self:toggle()
        return true
    end
    return false
end

-- Update buff display (called each frame)
function BuffDisplay:update(dt)
    -- Nothing to update for static display
    -- Could add animations or auto-hide logic here
end

-- Create buff tooltip for detailed information
function BuffDisplay:createTooltip(buff, x, y)
    local g = love.graphics
    local originalColor = {g.getColor()}
    
    -- Tooltip content
    local lines = {
        buff.name,
        buff.description or "No description available",
        ""
    }
    
    -- Add effect information
    if buff.effects then
        table.insert(lines, "Effects:")
        for effectType, value in pairs(buff.effects) do
            if type(value) == "table" then
                for resource, amount in pairs(value) do
                    table.insert(lines, "  " .. resource .. ": +" .. (amount * 100) .. "%")
                end
            else
                table.insert(lines, "  " .. effectType .. ": +" .. (value * 100) .. "%")
            end
        end
    end
    
    -- Add timing information
    if buff.permanent then
        table.insert(lines, "Duration: Permanent")
    elseif buff.remainingTime then
        table.insert(lines, "Remaining: " .. self:formatTime(buff.remainingTime))
    end
    
    if buff.stacks and buff.stacks > 1 then
        table.insert(lines, "Stacks: " .. buff.stacks)
    end
    
    -- Calculate tooltip size
    local font = g.getFont()
    local maxWidth = 0
    for _, line in ipairs(lines) do
        local width = font:getWidth(line)
        if width > maxWidth then
            maxWidth = width
        end
    end
    
    local tooltipWidth = maxWidth + 16
    local tooltipHeight = #lines * (font:getHeight() + 2) + 16
    
    -- Adjust position if tooltip would go off screen
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if x + tooltipWidth > screenWidth then
        x = screenWidth - tooltipWidth
    end
    if y + tooltipHeight > screenHeight then
        y = screenHeight - tooltipHeight
    end
    
    -- Draw tooltip background
    g.setColor(0.0, 0.0, 0.0, 0.9)
    g.rectangle("fill", x, y, tooltipWidth, tooltipHeight)
    
    -- Draw tooltip border
    g.setColor(self.colors.border)
    g.setLineWidth(1)
    g.rectangle("line", x, y, tooltipWidth, tooltipHeight)
    
    -- Draw tooltip text
    g.setColor(self.colors.text)
    local lineY = y + 8
    for _, line in ipairs(lines) do
        g.print(line, x + 8, lineY)
        lineY = lineY + font:getHeight() + 2
    end
    
    g.setColor(originalColor)
end

return BuffDisplay