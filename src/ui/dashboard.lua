local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard.new(systems)
    local self = setmetatable({}, Dashboard)
    self.systems = systems or {}
    return self
end

function Dashboard:enter()
    -- Initialize or refresh dashboard data
    if self.systems and self.systems.uiManager then
        self.systems.uiManager:clearSelectables()
        -- Example: register a placeholder selectable
        local Selectable = require("src.ui.selectable")
        local s = Selectable.new("placeholder", 50, 200, 120, 40, "Open Contracts", function() 
            if self.systems and self.systems.eventBus then
                self.systems.eventBus:publish("ui_action", {action = "open_contracts"})
            end
        end)
        self.systems.uiManager:registerSelectable(s)
    end
end

function Dashboard:update(dt)
    -- Dashboard-specific updates
end

function Dashboard:draw()
    -- Drawing handled centrally by UIManager for now
end

return Dashboard
