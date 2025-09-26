-- Threat Management System
-- Handles cyber threats, attacks, and security interactions

local ThreatSystem = {}
ThreatSystem.__index = ThreatSystem

-- Create new threat system
function ThreatSystem.new(eventBus)
    local self = setmetatable({}, ThreatSystem)
    self.eventBus = eventBus
    
    -- Placeholder for now - will be expanded later
    self.activeThreats = {}
    self.threatReduction = 0
    
        -- Listen to events to update threat reduction
        if self.eventBus then
            self.eventBus:subscribe("threats_updated", function(data)
                if data and data.reduction then
                    self.threatReduction = data.reduction
                end
            end)
            self.eventBus:subscribe("player_department_interact", function(data)
                -- Optional: respond to generic interactions
            end)
        end
    
    return self
end

function ThreatSystem:update(dt)
    -- Placeholder implementation
end

function ThreatSystem:getState()
    return {
        activeThreats = self.activeThreats,
        threatReduction = self.threatReduction
    }
end

    function ThreatSystem:reduceThreat(amount)
        self.threatReduction = math.min((self.threatReduction or 0) + (amount or 0), 0.9)
        self.eventBus:publish("threats_updated", { reduction = self.threatReduction })
    end

function ThreatSystem:loadState(state)
    if state.activeThreats then
        self.activeThreats = state.activeThreats
    end
    if state.threatReduction then
        self.threatReduction = state.threatReduction
    end
end

return ThreatSystem