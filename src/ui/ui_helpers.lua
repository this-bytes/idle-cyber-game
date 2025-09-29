-- UI Helpers - Reusable UI Components for Cybersecurity Game
-- Provides modal dialogs, menus, loading screens, and interactive components
-- with keyboard and mouse navigation support

local UIHelpers = {}

-- Color scheme for consistent UI theming
UIHelpers.colors = {
    background = {0.05, 0.05, 0.1, 1.0},
    backgroundLight = {0.1, 0.1, 0.15, 1.0},
    accent = {0.2, 0.8, 1.0, 1.0},
    success = {0.2, 0.8, 0.4, 1.0},
    warning = {1.0, 0.8, 0.2, 1.0},
    error = {1.0, 0.4, 0.2, 1.0},
    text = {0.9, 0.9, 0.9, 1.0},
    textDim = {0.6, 0.6, 0.6, 1.0},
    border = {0.4, 0.6, 0.8, 1.0},
    selection = {0.3, 0.5, 0.8, 0.5}
}

-- Modal Dialog Component
function UIHelpers.drawModal(title, content, buttons, options)
    options = options or {}
    local width, height = love.graphics.getDimensions()
    local modalWidth = options.width or 500
    local modalHeight = options.height or 300
    local x = (width - modalWidth) / 2
    local y = (height - modalHeight) / 2
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Modal background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, modalWidth, modalHeight)
    
    -- Modal border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, modalWidth, modalHeight)
    
    -- Title
    love.graphics.setColor(UIHelpers.colors.accent)
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, x + (modalWidth - titleWidth) / 2, y + 20)
    
    -- Content
    love.graphics.setColor(UIHelpers.colors.text)
    local contentY = y + 60
    if type(content) == "table" then
        for i, line in ipairs(content) do
            love.graphics.print(line, x + 20, contentY + (i - 1) * 20)
        end
    else
        love.graphics.print(content, x + 20, contentY)
    end
    
    -- Buttons
    if buttons then
        local buttonY = y + modalHeight - 60
        local buttonWidth = (modalWidth - 60) / #buttons
        for i, button in ipairs(buttons) do
            local buttonX = x + 20 + (i - 1) * (buttonWidth + 10)
            
            -- Button background
            if button.selected then
                love.graphics.setColor(UIHelpers.colors.selection)
                love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, 30)
            end
            
            -- Button border
            love.graphics.setColor(UIHelpers.colors.border)
            love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, 30)
            
            -- Button text
            love.graphics.setColor(button.selected and UIHelpers.colors.accent or UIHelpers.colors.text)
            local textWidth = font:getWidth(button.text)
            love.graphics.print(button.text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 8)
        end
    end
    
    return {x = x, y = y, width = modalWidth, height = modalHeight}
end

-- Loading Screen Component
function UIHelpers.drawLoading(message, progress)
    local width, height = love.graphics.getDimensions()
    
    -- Background
    love.graphics.setColor(UIHelpers.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Loading message
    love.graphics.setColor(UIHelpers.colors.accent)
    local font = love.graphics.getFont()
    local messageWidth = font:getWidth(message)
    love.graphics.print(message, (width - messageWidth) / 2, height / 2 - 50)
    
    -- Progress bar (if provided)
    if progress then
        local barWidth = 300
        local barHeight = 20
        local barX = (width - barWidth) / 2
        local barY = height / 2
        
        -- Progress bar background
        love.graphics.setColor(UIHelpers.colors.backgroundLight)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        
        -- Progress bar border
        love.graphics.setColor(UIHelpers.colors.border)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
        
        -- Progress fill
        love.graphics.setColor(UIHelpers.colors.success)
        love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
        
        -- Progress text
        love.graphics.setColor(UIHelpers.colors.text)
        local progressText = string.format("%.0f%%", progress * 100)
        local progressWidth = font:getWidth(progressText)
        love.graphics.print(progressText, (width - progressWidth) / 2, barY + 30)
    end
end

-- Menu Component
function UIHelpers.drawMenu(title, items, selectedIndex, x, y, width, height)
    x = x or 50
    y = y or 100
    width = width or 400
    height = height or 300
    
    -- Menu background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Menu border
    love.graphics.setColor(UIHelpers.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    if title then
        love.graphics.setColor(UIHelpers.colors.accent)
        local font = love.graphics.getFont()
        local titleWidth = font:getWidth(title)
        love.graphics.print(title, x + (width - titleWidth) / 2, y + 10)
    end
    
    -- Menu items
    local itemHeight = 25
    local startY = y + (title and 40 or 10)
    
    for i, item in ipairs(items) do
        local itemY = startY + (i - 1) * itemHeight
        
        -- Selection highlight
        if i == selectedIndex then
            love.graphics.setColor(UIHelpers.colors.selection)
            love.graphics.rectangle("fill", x + 5, itemY, width - 10, itemHeight)
        end
        
        -- Item text
        local color = item.enabled == false and UIHelpers.colors.textDim or 
                     (i == selectedIndex and UIHelpers.colors.accent or UIHelpers.colors.text)
        love.graphics.setColor(color)
        love.graphics.print(item.text or item, x + 15, itemY + 5)
        
        -- Item value/description (if provided)
        if item.value then
            love.graphics.setColor(UIHelpers.colors.textDim)
            local valueWidth = love.graphics.getFont():getWidth(item.value)
            love.graphics.print(item.value, x + width - valueWidth - 15, itemY + 5)
        end
    end
end

-- Quick Menu Component (for game interaction)
function UIHelpers.drawQuickMenu(items, selectedIndex, options)
    options = options or {}
    local width, height = love.graphics.getDimensions()
    local menuWidth = options.width or 250
    local menuHeight = #items * 30 + 20
    local x = options.x or (width - menuWidth - 20)
    local y = options.y or 20
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x - 5, y - 5, menuWidth + 10, menuHeight + 10)
    
    -- Menu background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, menuWidth, menuHeight)
    
    -- Menu items
    for i, item in ipairs(items) do
        local itemY = y + 10 + (i - 1) * 30
        
        -- Selection highlight
        if i == selectedIndex then
            love.graphics.setColor(UIHelpers.colors.selection)
            love.graphics.rectangle("fill", x + 2, itemY - 2, menuWidth - 4, 24)
        end
        
        -- Item icon and text
        love.graphics.setColor(i == selectedIndex and UIHelpers.colors.accent or UIHelpers.colors.text)
        local displayText = (item.icon or "•") .. " " .. item.text
        love.graphics.print(displayText, x + 10, itemY)
        
        -- Keyboard shortcut
        if item.key then
            love.graphics.setColor(UIHelpers.colors.textDim)
            local keyText = "[" .. item.key .. "]"
            local keyWidth = love.graphics.getFont():getWidth(keyText)
            love.graphics.print(keyText, x + menuWidth - keyWidth - 10, itemY)
        end
    end
    
    return {x = x, y = y, width = menuWidth, height = menuHeight}
end

-- Button Component
function UIHelpers.drawButton(text, x, y, width, height, style)
    style = style or "default"
    width = width or 120
    height = height or 30
    
    local colors = {
        default = UIHelpers.colors.border,
        primary = UIHelpers.colors.accent,
        success = UIHelpers.colors.success,
        warning = UIHelpers.colors.warning,
        danger = UIHelpers.colors.error
    }
    
    -- Button background
    love.graphics.setColor(UIHelpers.colors.backgroundLight)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Button border
    love.graphics.setColor(colors[style] or colors.default)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Button text
    love.graphics.setColor(colors[style] or UIHelpers.colors.text)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    love.graphics.print(text, x + (width - textWidth) / 2, y + (height - font:getHeight()) / 2)
    
    return {x = x, y = y, width = width, height = height}
end

-- Notification/Toast Component
function UIHelpers.drawNotification(message, type, duration, elapsed, x, y)
    local width, height = love.graphics.getDimensions()
    x = x or (width - 350)
    y = y or 50
    
    local notifWidth = 300
    local notifHeight = 60
    
    -- Fade out animation
    local alpha = 1.0
    if duration and elapsed then
        alpha = math.max(0, 1.0 - (elapsed / duration))
    end
    
    -- Type-specific colors
    local typeColors = {
        info = UIHelpers.colors.accent,
        success = UIHelpers.colors.success,
        warning = UIHelpers.colors.warning,
        error = UIHelpers.colors.error
    }
    
    -- Background
    love.graphics.setColor(UIHelpers.colors.backgroundLight[1], UIHelpers.colors.backgroundLight[2], 
                          UIHelpers.colors.backgroundLight[3], alpha)
    love.graphics.rectangle("fill", x, y, notifWidth, notifHeight)
    
    -- Left border (type indicator)
    local typeColor = typeColors[type] or UIHelpers.colors.accent
    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], alpha)
    love.graphics.rectangle("fill", x, y, 4, notifHeight)
    
    -- Message text
    love.graphics.setColor(UIHelpers.colors.text[1], UIHelpers.colors.text[2], 
                          UIHelpers.colors.text[3], alpha)
    love.graphics.print(message, x + 15, y + 20)
end

-- ASCII Art Helper for Room Generation
function UIHelpers.generateRoomASCII(room, building, floor)
    local ascii = {}
    local roomWidth = math.max(10, math.min(40, math.floor(room.width / 10)))
    local roomHeight = math.max(3, math.min(15, math.floor(room.height / 20)))
    
    -- Top border
    table.insert(ascii, "┌" .. string.rep("─", roomWidth - 2) .. "┐")
    
    -- Room content
    for i = 1, roomHeight - 2 do
        local line = "│"
        
        if i == 1 then
            -- Room name
            local name = room.name or "Room"
            local padding = math.max(0, roomWidth - 2 - #name)
            line = line .. name .. string.rep(" ", padding)
        elseif i == 2 and room.departments and #room.departments > 0 then
            -- Department info
            local dept = table.concat(room.departments, ",")
            local padding = math.max(0, roomWidth - 2 - #dept)
            line = line .. dept .. string.rep(" ", padding)
        elseif i == math.floor(roomHeight / 2) then
            -- Room atmosphere or description
            local desc = room.atmosphere or ""
            if #desc > roomWidth - 2 then
                desc = desc:sub(1, roomWidth - 5) .. "..."
            end
            local padding = math.max(0, roomWidth - 2 - #desc)
            line = line .. desc .. string.rep(" ", padding)
        else
            line = line .. string.rep(" ", roomWidth - 2)
        end
        
        line = line .. "│"
        table.insert(ascii, line)
    end
    
    -- Bottom border
    table.insert(ascii, "└" .. string.rep("─", roomWidth - 2) .. "┘")
    
    return ascii
end

-- Helper function to check if point is inside rectangle
function UIHelpers.pointInRect(px, py, x, y, width, height)
    return px >= x and px <= x + width and py >= y and py <= y + height
end

-- Keyboard navigation helper
function UIHelpers.handleMenuNavigation(key, currentSelection, itemCount, onSelect)
    if key == "up" or key == "w" then
        return math.max(1, currentSelection - 1)
    elseif key == "down" or key == "s" then
        return math.min(itemCount, currentSelection + 1)
    elseif key == "return" or key == "space" then
        if onSelect then onSelect(currentSelection) end
        return currentSelection
    end
    return currentSelection
end

return UIHelpers