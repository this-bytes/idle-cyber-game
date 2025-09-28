-- IdleDirector - Deterministic Idle Progress Controller for SOC architecture

local IdleDirector = {}
IdleDirector.__index = IdleDirector

local DEFAULT_OFFLINE_CAP = 8 -- hours

function IdleDirector.new(eventBus, resourceManager, statsSystem)
    local self = setmetatable({}, IdleDirector)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.statsSystem = statsSystem

    self.tickInterval = 1.0 -- seconds
    self.accumulator = 0
    self.lastSummary = {
        income = 0,
        reputation = 0,
        xp = 0,
        threatsTriggered = 0
    }

    self.offlineCapHours = DEFAULT_OFFLINE_CAP

    self:subscribeToEvents()

    return self
end

function IdleDirector:subscribeToEvents()
    self.eventBus:subscribe("idle_cap_increase", function(data)
        if data and data.offlineCapHours then
            self.offlineCapHours = math.max(DEFAULT_OFFLINE_CAP, self.offlineCapHours + data.offlineCapHours)
        end
    end)

    self.eventBus:subscribe("stats_changed", function()
        self:recalculateCoefficients()
    end)
end

function IdleDirector:initialize()
    self:recalculateCoefficients()
    print("🕒 IdleDirector: Initialized")
end

function IdleDirector:update(dt)
    self.accumulator = self.accumulator + dt
    while self.accumulator >= self.tickInterval do
        self.accumulator = self.accumulator - self.tickInterval
        self:processTick(self.tickInterval)
    end
end

function IdleDirector:processTick(dt)
    local income = self.baseIncome * dt
    local rep = self.baseReputation * dt
    local xp = self.baseXP * dt

    local earnedMoney = self.resourceManager:addResource("money", income)
    local earnedRep = self.resourceManager:addResource("reputation", rep)
    local earnedXP = self.resourceManager:addResource("xp", xp)

    self.lastSummary.income = self.lastSummary.income + (earnedMoney or 0)
    self.lastSummary.reputation = self.lastSummary.reputation + (earnedRep or 0)
    self.lastSummary.xp = self.lastSummary.xp + (earnedXP or 0)

    self.eventBus:publish("idle_tick", {
        dt = dt,
        income = earnedMoney,
        reputation = earnedRep,
        xp = earnedXP,
        stats = self.statsSnapshot
    })
end

function IdleDirector:recalculateCoefficients()
    self.statsSnapshot = self.statsSystem:getSnapshot()
    local derived = self.statsSystem:getDerived()

    local analysisEff = derived.analysisEfficiency or 0
    local defenseEff = derived.defenseEfficiency or 0
    local detectionEff = derived.detectionEfficiency or 0

    self.baseIncome = 5 * (1 + analysisEff * 0.2)
    self.baseReputation = 0.1 * (1 + analysisEff * 0.3)
    self.baseXP = 0.5 * (1 + detectionEff * 0.2)

    self.threatRiskModifier = math.max(0.05, 1 - defenseEff)
    self.offlineCapHours = DEFAULT_OFFLINE_CAP + math.floor(detectionEff * 2)
end

function IdleDirector:simulateOffline(seconds)
    local clampedSeconds = math.min(seconds, self.offlineCapHours * 3600)
    local ticks = math.floor(clampedSeconds / self.tickInterval)

    local income = 0
    local rep = 0
    local xp = 0

    for _ = 1, ticks do
        income = income + (self.resourceManager:addResource("money", self.baseIncome) or 0)
        rep = rep + (self.resourceManager:addResource("reputation", self.baseReputation) or 0)
        xp = xp + (self.resourceManager:addResource("xp", self.baseXP) or 0)
    end

    self.eventBus:publish("offline_progress_complete", {
        secondsSimulated = clampedSeconds,
        ticks = ticks,
        income = income,
        reputation = rep,
        xp = xp
    })

    return {
        secondsSimulated = clampedSeconds,
        income = income,
        reputation = rep,
        xp = xp
    }
end

function IdleDirector:getSummary()
    local summary = self.lastSummary
    self.lastSummary = {
        income = 0,
        reputation = 0,
        xp = 0,
        threatsTriggered = 0
    }
    return summary
end

function IdleDirector:getOfflineCapHours()
    return self.offlineCapHours
end

function IdleDirector:shutdown()
    print("🕒 IdleDirector: Shutdown complete")
end

function IdleDirector:getState()
    return {
        offlineCapHours = self.offlineCapHours,
        accumulator = self.accumulator
    }
end

function IdleDirector:loadState(state)
    if not state then return end
    if state.offlineCapHours then
        self.offlineCapHours = state.offlineCapHours
    end
    if state.accumulator then
        self.accumulator = state.accumulator
    end
    print("🕒 IdleDirector: State loaded")
end

return IdleDirector
