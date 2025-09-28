-- OperationsUpgrades - Economic & Automation Upgrade Catalog for SOC progression

local OperationsUpgrades = {}
OperationsUpgrades.__index = OperationsUpgrades

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function OperationsUpgrades.new(eventBus, resourceManager, statsSystem)
    local self = setmetatable({}, OperationsUpgrades)
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.statsSystem = statsSystem
    self.owned = {}
    self.definitions = {}

    self:defineCatalog()
    self:subscribeToEvents()

    return self
end

function OperationsUpgrades:initialize()
    print("🏗️ OperationsUpgrades: Initialized operations catalog")
end

function OperationsUpgrades:update()
    -- No recurring work; calculations handled through events
end

function OperationsUpgrades:shutdown()
    print("🏗️ OperationsUpgrades: Shutdown complete")
end

function OperationsUpgrades:subscribeToEvents()
    self.eventBus:subscribe("get_operations_upgrades", function(data)
        if data and data.callback then
            data.callback(self:getAvailable())
        end
    end)
end

function OperationsUpgrades:defineCatalog()
    self:defineUpgrade("automationSuite", {
        name = "🤖 Automation Suite",
        description = "Automates low-risk contracts and increases idle cap.",
        category = "automation",
        tier = 1,
        cost = { money = 2500 },
        requirements = {},
        effects = {
            resources = { moneyGeneration = 5 },
            stats = { analysis = { multiplier = 0.05 } },
            idle = { offlineCapHours = 2 }
        }
    })

    self:defineUpgrade("threatIntelOps", {
        name = "📡 Threat Intel Ops",
        description = "Dedicated analysts improve detection and response.",
        category = "operations",
        tier = 2,
        cost = { money = 6500, reputation = 10 },
        requirements = { stats = { detection = 40 } },
        effects = {
            stats = {
                detection = { flat = 8, multiplier = 0.08 },
                analysis = { multiplier = 0.05 }
            },
            threats = { responseSpeed = 0.1 }
        }
    })

    self:defineUpgrade("socWarRoom", {
        name = "🏢 SOC War Room",
        description = "Dedicated command centre increases defense caps and mitigations.",
        category = "facilities",
        tier = 3,
        cost = { money = 12000, reputation = 25, xp = 250 },
        requirements = { stats = { defense = 60 } },
        effects = {
            caps = { defense = 650, detection = 600 },
            stats = { defense = { flat = 12, multiplier = 0.1 } },
            resources = { reputationGeneration = 1 }
        }
    })
end

function OperationsUpgrades:defineUpgrade(id, config)
    config.id = id
    self.definitions[id] = config
    self.owned[id] = 0
    self.eventBus:publish("operations_upgrade_defined", { id = id, config = config })
end

function OperationsUpgrades:getOwnedCount(id)
    return self.owned[id] or 0
end

function OperationsUpgrades:getAvailable()
    local list = {}
    for id, def in pairs(self.definitions) do
        local cost = self:calculateCost(id)
        list[id] = {
            definition = def,
            owned = self:getOwnedCount(id),
            cost = cost,
            canPurchase = self:canPurchase(id)
        }
    end
    return list
end

function OperationsUpgrades:calculateCost(id)
    local def = self.definitions[id]
    if not def then return {} end
    local growth = def.costGrowth or 1.15
    local owned = self:getOwnedCount(id)
    local cost = {}
    for resource, amount in pairs(def.cost or {}) do
        cost[resource] = math.floor(amount * math.pow(growth, owned))
    end
    return cost
end

function OperationsUpgrades:canPurchase(id)
    local def = self.definitions[id]
    if not def then return false, "Upgrade not found" end

    if def.maxCount and self:getOwnedCount(id) >= def.maxCount then
        return false, "Max ownership reached"
    end

    -- requirement check
    if def.requirements and def.requirements.stats then
        for stat, value in pairs(def.requirements.stats) do
            if self.statsSystem:getEffective(stat) < value then
                return false, "Requires higher " .. stat
            end
        end
    end

    -- cost check
    local cost = self:calculateCost(id)
    if not self.resourceManager:canAfford(cost) then
        return false, "Insufficient resources"
    end

    return true
end

function OperationsUpgrades:purchase(id)
    local canPurchase, reason = self:canPurchase(id)
    if not canPurchase then
        return false, reason
    end

    local cost = self:calculateCost(id)
    if not self.resourceManager:spendResources(cost) then
        return false, "Unable to spend resources"
    end

    self.owned[id] = self:getOwnedCount(id) + 1

    self:applyEffects(id)
    self.eventBus:publish("operations_upgrade_purchased", {
        upgradeId = id,
        count = self.owned[id],
        cost = cost,
        effects = deepCopy(self.definitions[id].effects)
    })

    return true
end

function OperationsUpgrades:applyEffects(id)
    local def = self.definitions[id]
    if not def or not def.effects then return end

    local effects = def.effects

    if effects.stats then
        self.eventBus:publish("apply_stat_modifier", {
            sourceId = "operations_upgrade:" .. id .. ":" .. self.owned[id],
            payload = effects.stats
        })
    end

    if effects.caps then
        for stat, cap in pairs(effects.caps) do
            self.eventBus:publish("set_stat_cap", { stat = stat, cap = cap })
        end
    end

    if effects.resources then
        if effects.resources.moneyGeneration then
            self.resourceManager:addGeneration("money", effects.resources.moneyGeneration)
        end
        if effects.resources.reputationGeneration then
            self.resourceManager:addGeneration("reputation", effects.resources.reputationGeneration)
        end
    end

    if effects.idle then
        self.eventBus:publish("idle_cap_increase", effects.idle)
    end

    if effects.threats then
        self.eventBus:publish("operations_threat_bonus", effects.threats)
    end
end

function OperationsUpgrades:getState()
    return {
        owned = deepCopy(self.owned)
    }
end

function OperationsUpgrades:loadState(state)
    if not state or not state.owned then return end
    self.owned = deepCopy(state.owned)
    print("🏗️ OperationsUpgrades: State loaded")
end

return OperationsUpgrades
