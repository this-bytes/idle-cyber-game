-- Unsure if relevant, but here is the full file content you asked for:
-- If in use core to the active game, ensure to merge any necessary changes.
-- Incident System - Dynamic Incident Generation and Management
-- Handles Incident lifecycle, specialist deployment, and outcomes

-- Thin adapter for backwards compatibility
-- Delegates to the canonical IncidentSpecialistSystem where possible

local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

local Wrapper = {}

function Wrapper.new(eventBus, dataManager)
    -- Construct the canonical system and return a facade exposing similar API
    local instance = IncidentSpecialistSystem.new(eventBus, eventBus and eventBus.resourceManager or nil)
    -- Provide a compatibility layer by copying commonly-expected methods
    local facade = {}
    facade.__index = facade

    -- Pass-throughs for common calls
    function facade:initialize()
        if instance.initialize then return instance:initialize() end
    end

    function facade:newIncidentFromTemplate(id)
        -- Keep a compatibility method name if callers expect it
        if instance.createIncidentFromTemplate then
            return instance:createIncidentFromTemplate(id)
        end
        return nil
    end

    -- Generic pass-through metatable
    setmetatable(facade, { __index = function(_, k)
        return instance[k]
    end })

    return facade
end



function IncidentSystem:getCurrentStage()
    if not self.activeIncident then return nil end
    return self.activeIncident.stages[self.currentStageIndex]
end

-- Get time remaining
function IncidentSystem:getTimeRemaining()
    if not self.activeIncident then return 0 end
    return math.max(0, self.activeIncident.timeLimit - self.elapsedTime)
end

-- Get all Incident definitions
function IncidentSystem:getAllIncidentDefinitions()
    return self.IncidentDefinitions
end

-- Get state for saving
function IncidentSystem:getState()
    return {
        activeIncident = self.activeIncident,
        currentStageIndex = self.currentStageIndex,
        IncidentProgress = self.IncidentProgress,
        deployedSpecialists = self.deployedSpecialists,
        elapsedTime = self.elapsedTime
    }
end

-- Load state from save
function IncidentSystem:loadState(state)
    if state then
        self.activeIncident = state.activeIncident
        self.currentStageIndex = state.currentStageIndex or 1
        self.IncidentProgress = state.IncidentProgress or 0
        self.deployedSpecialists = state.deployedSpecialists or {}
        self.elapsedTime = state.elapsedTime or 0
    end
end

return Wrapper, IncidentSystem

