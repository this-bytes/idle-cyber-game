-- Simple deterministic simulation runner to advance systems and collect metrics
local EventBus = require("src.utils.event_bus")

local SimulationRunner = {}
SimulationRunner.__index = SimulationRunner

function SimulationRunner.new()
    local self = setmetatable({}, SimulationRunner)
    self.eventBus = EventBus.new()
    self.systems = {}
    self.time = 0
    return self
end

function SimulationRunner:registerSystem(name, system)
    self.systems[name] = system
end

function SimulationRunner:tick(dt)
    self.time = self.time + dt
    for name, system in pairs(self.systems) do
        if system.update then
            system:update(dt)
        end
    end
end

function SimulationRunner:runFor(seconds, step)
    step = step or 0.1
    local steps = math.floor(seconds / step)
    for i = 1, steps do
        self:tick(step)
    end
end

return SimulationRunner
