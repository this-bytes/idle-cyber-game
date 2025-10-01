-- Minimal SOC Stats shim for tests
local SOCStats = {}
SOCStats.__index = SOCStats

function SOCStats.new(eventBus)
    local self = setmetatable({}, SOCStats)
    self.eventBus = eventBus
    -- Metrics expected by tests
    self.metrics = {
        uptime = 0,
        handled_incidents = 0,
        threatsDetected = 0
    }
    return self
end

function SOCStats:initialize()
    -- no-op for tests
    -- Subscribe to threat_detected events to update metrics
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function()
            self.metrics.threatsDetected = (self.metrics.threatsDetected or 0) + 1
        end)
    end
    return true
end

function SOCStats:getStatistics()
    return self.metrics
end

return SOCStats
