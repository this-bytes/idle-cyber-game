-- SOCStats - SOC statistics and analytics (systems path)
local SOCStats = {}
SOCStats.__index = SOCStats

function SOCStats.new(eventBus, resourceManager)
    local self = setmetatable({}, SOCStats)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.metrics = { threatsDetected = 0, threatsResolved = 0, contractsCompleted = 0 }
    return self
end

function SOCStats:initialize()
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function(data) self.metrics.threatsDetected = self.metrics.threatsDetected + 1 end)
    end
    return true
end

return SOCStats
