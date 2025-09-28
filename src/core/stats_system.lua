-- StatsSystem - SOC Capability Vector Manager
-- Oversees offensive, defensive, detection, and analysis stats for the fortress architecture

local StatsSystem = {}
StatsSystem.__index = StatsSystem

local DEFAULT_BASE = {
    offense = 10,
    defense = 10,
    detection = 10,
    analysis = 10
}

local DEFAULT_CAP = {
    offense = 500,
    defense = 500,
    detection = 500,
    analysis = 500
}

local VALID_STATS = {
    offense = true,
    defense = true,
    detection = true,
    analysis = true
}

local function cloneTable(source)
    local copy = {}
    for k, v in pairs(source) do
        copy[k] = v
    end
    return copy
end

local function deepCopy(source)
    if type(source) ~= "table" then
        return source
    end
    local copy = {}
    for k, v in pairs(source) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function safeStatName(stat)
    if not VALID_STATS[stat] then
        error("StatsSystem: invalid stat '" .. tostring(stat) .. "'")
    end
    return stat
end

function StatsSystem.new(eventBus)
    local self = setmetatable({}, StatsSystem)
    self.eventBus = eventBus

    self.baseStats = cloneTable(DEFAULT_BASE)
    self.caps = cloneTable(DEFAULT_CAP)
    self.modifiers = {}       -- sourceId -> modifier payload
    self.breakdown = {}       -- stat -> {flatTotal, multiplierTotal}
    self.effective = {}       -- stat -> effective value
    self.previousEffective = {}
    self.derived = {}

    self.pendingNotifications = {}

    self:recalculate(true)
    self:subscribeToEvents()

    return self
end

function StatsSystem:subscribeToEvents()
    self.eventBus:subscribe("apply_stat_modifier", function(data)
        if data and data.sourceId and data.payload then
            self:applyModifier(data.sourceId, data.payload)
        end
    end)

    self.eventBus:subscribe("remove_stat_modifier", function(data)
        if data and data.sourceId then
            self:removeModifier(data.sourceId)
        end
    end)

    self.eventBus:subscribe("set_stat_cap", function(data)
        if data and data.stat and data.cap then
            local stat = safeStatName(data.stat)
            self.caps[stat] = math.max(1, data.cap)
            self:recalculate()
        end
    end)

    self.eventBus:subscribe("adjust_base_stat", function(data)
        if data and data.stat and data.amount then
            local stat = safeStatName(data.stat)
            self.baseStats[stat] = math.max(0, (self.baseStats[stat] or 0) + data.amount)
            self:recalculate()
        end
    end)
end

function StatsSystem:initialize()
    self:recalculate(true)
    print("📊 StatsSystem: Initialized with SOC vectors")
end

function StatsSystem:update()
    if #self.pendingNotifications == 0 then
        return
    end

    for _, payload in ipairs(self.pendingNotifications) do
        self.eventBus:publish("stats_changed", payload)
    end
    self.pendingNotifications = {}
end

function StatsSystem:shutdown()
    self.modifiers = {}
    self.pendingNotifications = {}
    print("📊 StatsSystem: Shutdown complete")
end

function StatsSystem:getBase(stat)
    stat = safeStatName(stat)
    return self.baseStats[stat]
end

function StatsSystem:setBase(stat, value)
    stat = safeStatName(stat)
    self.baseStats[stat] = math.max(0, value)
    self:recalculate()
end

function StatsSystem:getCap(stat)
    stat = safeStatName(stat)
    return self.caps[stat]
end

function StatsSystem:getEffective(stat)
    stat = safeStatName(stat)
    return self.effective[stat] or 0
end

function StatsSystem:getBreakdown(stat)
    stat = safeStatName(stat)
    return self.breakdown[stat] or {flat = 0, multiplier = 0}
end

function StatsSystem:applyModifier(sourceId, payload)
    if not sourceId then
        error("StatsSystem:applyModifier requires sourceId")
    end

    -- payload example: { offense = { flat = 5, multiplier = 0.1 }, detection = { multiplier = 0.05 } }
    self.modifiers[sourceId] = payload
    self:recalculate()
end

function StatsSystem:removeModifier(sourceId)
    if not sourceId then return end
    if self.modifiers[sourceId] then
        self.modifiers[sourceId] = nil
        self:recalculate()
    end
end

function StatsSystem:getDerived()
    return cloneTable(self.derived)
end

function StatsSystem:getSnapshot()
    local snapshot = { base = cloneTable(self.baseStats), effective = cloneTable(self.effective), caps = cloneTable(self.caps), derived = self:getDerived() }
    return snapshot
end

function StatsSystem:getState()
    return {
        base = cloneTable(self.baseStats),
        caps = cloneTable(self.caps),
        modifiers = deepCopy(self.modifiers)
    }
end

function StatsSystem:loadState(state)
    if not state then return end
    if state.base then
        self.baseStats = cloneTable(state.base)
    end
    if state.caps then
        self.caps = cloneTable(state.caps)
    end
    if state.modifiers then
        self.modifiers = deepCopy(state.modifiers)
    end
    self:recalculate(true)
    print("📊 StatsSystem: State loaded")
end

function StatsSystem:recalculate(forceEvent)
    local newBreakdown = {}
    local newEffective = {}

    for stat in pairs(VALID_STATS) do
        local base = self.baseStats[stat] or 0
        local flat = 0
        local multiplier = 0

        for _, payload in pairs(self.modifiers) do
            local modifier = payload[stat]
            if modifier then
                flat = flat + (modifier.flat or 0)
                multiplier = multiplier + (modifier.multiplier or 0)
            end
        end

        local capped = self.caps[stat] or DEFAULT_CAP[stat]
        local effective = math.min((base + flat) * (1 + multiplier), capped)

        newBreakdown[stat] = { flat = flat, multiplier = multiplier }
        newEffective[stat] = effective
    end

    self.breakdown = newBreakdown
    self.previousEffective = self.effective
    self.effective = newEffective

    self:recalculateDerived()

    if forceEvent then
        table.insert(self.pendingNotifications, self:createNotificationPayload())
        return
    end

    if not self.previousEffective then
        return
    end

    local changed = false
    for stat in pairs(VALID_STATS) do
        if math.abs((self.effective[stat] or 0) - (self.previousEffective[stat] or 0)) > 0.001 then
            changed = true
            break
        end
    end

    if changed then
        table.insert(self.pendingNotifications, self:createNotificationPayload())
    end
end

function StatsSystem:recalculateDerived()
    local offense = self.effective.offense or 0
    local defense = self.effective.defense or 0
    local detection = self.effective.detection or 0
    local analysis = self.effective.analysis or 0

    local socRating = 0
    if offense > 0 and defense > 0 and detection > 0 and analysis > 0 then
        socRating = (offense * defense * detection * analysis) ^ 0.25
    end

    local detectionEff = detection / 100
    local offenseEff = offense / 100
    local defenseEff = defense / 100
    local analysisEff = analysis / 100

    self.derived = {
        socRating = socRating,
        incidentResponseSpeed = 1 + detectionEff + offenseEff * 0.5,
        damageMitigation = math.min(defenseEff, 0.95),
        rewardMultiplier = 1 + analysisEff * 0.3,
        detectionEfficiency = detectionEff,
        offenseEfficiency = offenseEff,
        defenseEfficiency = defenseEff,
        analysisEfficiency = analysisEff
    }
end

function StatsSystem:createNotificationPayload()
    local payload = {
        stats = cloneTable(self.effective),
        base = cloneTable(self.baseStats),
        caps = cloneTable(self.caps),
        breakdown = {},
        derived = self:getDerived()
    }

    for stat, data in pairs(self.breakdown) do
        payload.breakdown[stat] = { flat = data.flat, multiplier = data.multiplier }
    end

    return payload
end

return StatsSystem
