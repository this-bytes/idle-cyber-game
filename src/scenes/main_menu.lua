-- Main Menu Scene - SOC Game Entry Point
-- Provides initial navigation for the SOC cybersecurity simulation
-- Clean, professional interface matching SOC environment theme

local MainMenu = {}
MainMenu.__index = MainMenu

-- Create new main menu scene
function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    
    -- Scene state
    self.eventBus = nil
    self.menuItems = {
        {text = "Start SOC Operations", action = "start_game"},
        {text = "Load Previous SOC", action = "load_game"},
        {text = "SOC Settings", action = "settings"},
        {text = "Exit", action = "quit"}
    }
    self.selectedItem = 1
    
    -- Visual elements
    self.titleText = "🛡️ SOC Command Center"
    self.subtitleText = "Cybersecurity Operations Management"
    
    return self
end

-- Initialize main menu
function MainMenu:initialize(eventBus)
    self.eventBus = eventBus
    print("🏠 MainMenu: Initialized SOC main menu")
end

-- Enter the main menu scene
function MainMenu:enter(data)
    print("🏠 MainMenu: Entered main menu")
end

-- Exit the main menu scene
function MainMenu:exit()
    print("🏠 MainMenu: Exited main menu")
end

-- Update main menu
function MainMenu:update(dt)
    -- Menu animations or state updates can go here
end

-- Draw main menu
function MainMenu:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.05, 0.1, 0.15, 1) -- Dark blue SOC theme
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1, 1) -- Bright cyan
    local titleFont = love.graphics.getFont()
    local titleWidth = titleFont:getWidth(self.titleText)
    love.graphics.print(self.titleText, (screenWidth - titleWidth) / 2, screenHeight * 0.2)
    
    -- Subtitle
    love.graphics.setColor(0.7, 0.9, 1, 1) -- Light cyan
    local subtitleWidth = titleFont:getWidth(self.subtitleText)
    love.graphics.print(self.subtitleText, (screenWidth - subtitleWidth) / 2, screenHeight * 0.25)
    
    -- Menu items
    local startY = screenHeight * 0.4
    local itemHeight = 40
    
    for i, item in ipairs(self.menuItems) do
        local y = startY + (i - 1) * itemHeight
        local isSelected = (i == self.selectedItem)
        
        -- Highlight selected item
        if isSelected then
            love.graphics.setColor(0.1, 0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", screenWidth * 0.3, y - 5, screenWidth * 0.4, itemHeight - 10)
        end
        
        -- Menu item text
        local textColor = isSelected and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 1}
        love.graphics.setColor(textColor)
        
        local itemWidth = titleFont:getWidth(item.text)
        love.graphics.print(item.text, (screenWidth - itemWidth) / 2, y)
    end
    
    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local instructionText = "Use ↑↓ to navigate, ENTER to select, ESC to quit"
    local instrWidth = titleFont:getWidth(instructionText)
    love.graphics.print(instructionText, (screenWidth - instrWidth) / 2, screenHeight * 0.8)
    
    -- SOC status indicator
    love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green
    love.graphics.print("SOC Status: READY", 20, screenHeight - 40)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle key input
function MainMenu:keypressed(key)
    if key == "up" then
        self.selectedItem = math.max(1, self.selectedItem - 1)
    elseif key == "down" then
        self.selectedItem = math.min(#self.menuItems, self.selectedItem + 1)
    elseif key == "return" or key == "enter" then
        self:activateMenuItem()
    elseif key == "escape" then
        self:activateMenuItem(4) -- Quit
    end
end

-- Handle mouse input
function MainMenu:mousepressed(x, y, button)
    if button == 1 then -- Left click
        local screenHeight = love.graphics.getHeight()
        local startY = screenHeight * 0.4
        local itemHeight = 40
        
        for i, item in ipairs(self.menuItems) do
            local itemY = startY + (i - 1) * itemHeight
            if y >= itemY and y <= itemY + itemHeight then
                self.selectedItem = i
                self:activateMenuItem()
                break
            end
        end
    end
end

-- Activate the selected menu item
function MainMenu:activateMenuItem(itemIndex)
    local index = itemIndex or self.selectedItem
    local item = self.menuItems[index]
    
    if not item then return end
    
    if item.action == "start_game" then
        self.eventBus:publish("scene_request", {scene = "soc_view"})
    elseif item.action == "load_game" then
        self.eventBus:publish("load_game_request", {})
        self.eventBus:publish("scene_request", {scene = "soc_view"})
    elseif item.action == "settings" then
        -- TODO: Implement settings scene
        print("⚙️ Settings menu not yet implemented")
    elseif item.action == "quit" then
        love.event.quit()
    end
end

return MainMenu