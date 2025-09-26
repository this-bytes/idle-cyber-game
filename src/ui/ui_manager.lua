-- UI Manager
-- Handles all user interface elements and screens

local UIManager = {}
UIManager.__index = UIManager

local TerminalTheme = require("src.ui.terminal_theme")

-- Create new UI manager
function UIManager.new(eventBus)
    local self = setmetatable({}, UIManager)
    self.eventBus = eventBus
    
    -- UI state
    self.activeScreens = {}
    self.showFPS = false
    
    -- Initialize terminal theme
    self.theme = TerminalTheme.new()
    
    return self
end

function UIManager:update(dt)
    -- Update terminal theme effects
    self.theme:update(dt)
    
    -- Update active UI screens
end

function UIManager:draw()
    -- Draw terminal background first
    self.theme:drawBackground()
    
    -- Draw UI elements
    if self.showFPS then
        self.theme:drawText("FPS: " .. love.timer.getFPS(), 10, 10, self.theme:getColor("warning"))
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