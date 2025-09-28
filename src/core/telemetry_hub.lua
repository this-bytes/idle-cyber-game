-- TelemetryHub - Lightweight analytics collector for fortress systems

local TelemetryHub = {}
TelemetryHub.__index = TelemetryHub

local BUFFER_SIZE = 120 -- store last 120 samples (~2 minutes at 1 Hz)

function TelemetryHub.new(eventBus, gameLoop)
    local self = setmetatable({}, TelemetryHub)
    self.eventBus = eventBus
    self.gameLoop = gameLoop
    self.samples = {}
    self.cursor = 1

    self:subscribeToEvents()

    return self
end

function TelemetryHub:subscribeToEvents()
    local function pushSample(kind, payload)
        self.samples[self.cursor] = {
            kind = kind,
            payload = payload,
            timestamp = love.timer and love.timer.getTime() or os.clock()
        }
        self.cursor = self.cursor + 1
        if self.cursor > BUFFER_SIZE then
            self.cursor = 1
        end
    end

    self.eventBus:subscribe("resource_changed", function(data)
        pushSample("resource", data)
    end)

    self.eventBus:subscribe("stats_changed", function(data)
        pushSample("stats", data)
    end)

    self.eventBus:subscribe("contract_completed", function(data)
        pushSample("contract", data)
    end)

    self.eventBus:subscribe("threat_detected", function(data)
        pushSample("threat", data)
    end)

    self.eventBus:subscribe("idle_tick", function(data)
        pushSample("idle", data)
    end)
end

function TelemetryHub:initialize()
    print("📡 TelemetryHub: Initialized")
end

function TelemetryHub:update(dt)
    self.lastMetrics = self.gameLoop:getPerformanceMetrics()
    if self.lastMetrics.updateTime > 0.05 then
        self.eventBus:publish("telemetry_anomaly", {
            kind = "frame_time",
            value = self.lastMetrics.updateTime
        })
    end
end

function TelemetryHub:getSnapshots()
    local snapshots = {}
    local count = 0
    for i = 0, BUFFER_SIZE - 1 do
        local index = ((self.cursor - 1 - i) % BUFFER_SIZE) + 1
        local sample = self.samples[index]
        if sample then
            table.insert(snapshots, sample)
            count = count + 1
        end
    end
    return snapshots
end

function TelemetryHub:getLastMetrics()
    return self.lastMetrics
end

function TelemetryHub:shutdown()
    self.samples = {}
    print("📡 TelemetryHub: Shutdown complete")
end

return TelemetryHub
