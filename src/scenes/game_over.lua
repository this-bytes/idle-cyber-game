-- Game Over Scene - SOC Failure Management
-- Handles game over scenarios when SOC operations fail catastrophically
-- Provides restart and analysis options

local GameOver = {}
GameOver.__index = GameOver

function GameOver.new(eventBus)
    local self = setmetatable({}, GameOver)
    self.eventBus = eventBus
    self.reason = "Unknown failure"
    self.stats = {}
    print("💀 GameOver: Initialized game over scene")
    return self
end

-- No longer needed, logic moved to new()
-- function GameOver:initialize(eventBus)
--     self.eventBus = eventBus
--     print("💀 GameOver: Initialized game over scene")
-- end

function GameOver:enter(data)
    if data then
        self.reason = data.reason or "SOC operations failed"
        self.stats = data.stats or {}
    end
    print("💀 GameOver: SOC operations terminated - " .. self.reason)
end

function GameOver:exit()
    print("💀 GameOver: Exiting game over scene")
end

function GameOver:update(dt)
    -- TODO: Implement game over animations
end

function GameOver:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Game over title
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    local titleText = "💀 SOC OPERATIONS TERMINATED"
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, (screenWidth - titleWidth) / 2, screenHeight * 0.3)
    
    -- Failure reason
    love.graphics.setColor(1, 1, 1, 1)
    local reasonWidth = font:getWidth(self.reason)
    love.graphics.print(self.reason, (screenWidth - reasonWidth) / 2, screenHeight * 0.4)
    
    -- Options
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Press [R] to restart SOC", (screenWidth - 200) / 2, screenHeight * 0.6)
    love.graphics.print("Press [M] for main menu", (screenWidth - 200) / 2, screenHeight * 0.65)
    love.graphics.print("Press [Q] to quit", (screenWidth - 200) / 2, screenHeight * 0.7)
end

function GameOver:keypressed(key)
    if key == "r" then
        self.eventBus:publish("restart_game_request", {})
    elseif key == "m" then
        self.eventBus:publish("scene_request", {scene = "main_menu"})
    elseif key == "q" then
        love.event.quit()
    end
end

function GameOver:mousepressed(x, y, button)
    -- TODO: Implement clickable options
end

return GameOver