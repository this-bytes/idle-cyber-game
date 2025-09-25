-- UI Manager
-- Handles all user interface elements and screens

local UIManager = {}
UIManager.__index = UIManager

-- Create new UI manager
function UIManager.new(eventBus)
    local self = setmetatable({}, UIManager)
    self.eventBus = eventBus
    
    -- UI state
    self.activeScreens = {}
    self.showFPS = false
    
    return self
end

function UIManager:update(dt)
    -- Update active UI screens
end

function UIManager:draw()
    -- Draw UI elements
    if self.showFPS then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    end
end

function UIManager:mousepressed(x, y, button)
    -- Handle UI clicks
    return false
end

function UIManager:keypressed(key)
    if key == "f" then
        self.showFPS = not self.showFPS
    end
end

function UIManager:resize(w, h)
    -- Handle window resize
end

return UIManager