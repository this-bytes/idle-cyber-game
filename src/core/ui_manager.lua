-- UIManager - Modern reactive UI system
-- Handles UI updates, panels, notifications, cybersecurity theming

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(eventBus, resourceManager, securityUpgrades, threatSimulation, gameLoop)
    local self = setmetatable({}, UIManager)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.securityUpgrades = securityUpgrades
    self.threatSimulation = threatSimulation
    self.gameLoop = gameLoop
    
    -- UI state
    self.panels = {}
    self.notifications = {}
    
    return self
end

function UIManager:initialize()
    -- Subscribe to events
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function(data)
            self:handleThreatDetected(data)
        end)
    end
    return true
end

function UIManager:handleThreatDetected(data)
    -- Handle threat notification
    table.insert(self.notifications, {
        type = "threat",
        message = "Threat detected: " .. (data.name or "Unknown"),
        timestamp = os.time()
    })
end

return UIManager