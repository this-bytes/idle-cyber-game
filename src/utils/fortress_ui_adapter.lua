-- Fortress UI Adapter - Bridge Legacy UI Calls to Fortress UIManager
-- SOC REFACTOR: Provides compatibility layer between legacy systems and fortress UI
-- Eliminates UI conflicts by routing all legacy UI calls to fortress architecture

local FortressUIAdapter = {}
FortressUIAdapter.__index = FortressUIAdapter

-- Create new fortress UI adapter
function FortressUIAdapter.new(fortressUIManager)
    local self = setmetatable({}, FortressUIAdapter)
    
    -- Reference to fortress UI manager
    self.fortressUI = fortressUIManager
    
    return self
end

-- Legacy UI method compatibility mapping
-- All methods route to fortress UI with appropriate translations

function FortressUIAdapter:showNotification(message, duration)
    if self.fortressUI then
        self.fortressUI:showNotification(message, "info", duration or 3.0)
    end
end

function FortressUIAdapter:showToast(message, type, duration)
    if self.fortressUI then
        self.fortressUI:showNotification(message, type or "info", duration or 3.0)
    end
end

function FortressUIAdapter:logDebug(message, severity, category)
    if self.fortressUI then
        -- Map to fortress notification system
        local notificationType = severity == "error" and "danger" or "info"
        self.fortressUI:showNotification(message, notificationType, 2.0)
    end
    print("🔧 [" .. (category or "DEBUG") .. "] " .. message)
end

function FortressUIAdapter:showOfflineProgress(progress, onClose)
    -- SOC REFACTOR: Fortress will handle offline progress display
    if self.fortressUI then
        local message = string.format("⏰ Welcome back! Offline for %ds, gained $%d", 
                                    progress.totalTime or 0, 
                                    progress.netGain or 0)
        self.fortressUI:showNotification(message, "success", 5.0)
    end
    
    if onClose then
        onClose()
    end
end

function FortressUIAdapter:toggleNavigationModal()
    if self.fortressUI then
        self.fortressUI:togglePanel("navigation")
    end
end

function FortressUIAdapter:draw()
    -- Fortress UI handles all drawing
    if self.fortressUI then
        self.fortressUI:draw()
    end
end

function FortressUIAdapter:update(dt)
    -- Fortress UI handles all updates
    if self.fortressUI then
        self.fortressUI:update(dt)
    end
end

function FortressUIAdapter:keypressed(key)
    -- Delegate to fortress UI if it has key handling
    if self.fortressUI and self.fortressUI.keypressed then
        self.fortressUI:keypressed(key)
    end
end

function FortressUIAdapter:keyreleased(key)
    -- Delegate to fortress UI if it has key handling
    if self.fortressUI and self.fortressUI.keyreleased then
        self.fortressUI:keyreleased(key)
    end
end

function FortressUIAdapter:mousepressed(x, y, button)
    -- Delegate to fortress UI if it has mouse handling
    if self.fortressUI and self.fortressUI.mousepressed then
        return self.fortressUI:mousepressed(x, y, button)
    end
    return false
end

function FortressUIAdapter:resize(w, h)
    -- Delegate to fortress UI
    if self.fortressUI and self.fortressUI.resize then
        self.fortressUI:resize(w, h)
    end
end

-- Additional methods for backward compatibility
function FortressUIAdapter:addLogMessage(message, severity)
    self:logDebug(message, severity, "GAME")
end

function FortressUIAdapter:showControlsModal()
    if self.fortressUI then
        self.fortressUI:togglePanel("help")
    end
end

function FortressUIAdapter:toggleControlsHUD()
    if self.fortressUI then
        self.fortressUI:togglePanel("hud")
    end
end

return FortressUIAdapter