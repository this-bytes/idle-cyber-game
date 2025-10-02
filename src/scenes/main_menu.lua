-- Main Menu Scene - SOC Game Entry Point
-- Provides initial navigation for the SOC cybersecurity simulation
-- Uses SmartUIManager for modern component-based UI

local SmartUIManager = require("src.ui.smart_ui_manager")

local MainMenu = {}
MainMenu.__index = MainMenu

-- Create new main menu scene
function MainMenu.new(eventBus)
    local self = setmetatable({}, MainMenu)
    
    -- Scene state
    self.eventBus = eventBus
    self.uiManager = nil
    
    print("🏠 MainMenu: Initialized SOC main menu")
    return self
end

-- Enter the main menu scene
function MainMenu:enter(data)
    print("🏠 Main Menu: Entered main menu")
    
    -- Initialize Smart UI Manager for menu
    self.uiManager = SmartUIManager.new(self.eventBus, nil) -- No resource manager needed for menu
    self.uiManager:initialize()
    self.uiManager.currentState = "menu"
    self.uiManager:buildUI()
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
    if self.uiManager then
        self.uiManager:draw()
    end
end

-- Handle key input
function MainMenu:keypressed(key)
    -- Pass input to UI manager for component interactions
    if self.uiManager then
        self.uiManager:keypressed(key)
    end
end

-- Handle mouse input
function MainMenu:mousepressed(x, y, button)
    -- Pass input to UI manager for button interactions
    if self.uiManager then
        self.uiManager:mousepressed(x, y, button)
    end
end

return MainMenu
