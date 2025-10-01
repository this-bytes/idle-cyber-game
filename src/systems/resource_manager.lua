-- Resource Manager System - Idle Sec Ops
-- Manages all player resources with proper initialization and state tracking
-- Makes numbers go UP and makes players feel PROGRESS

local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new(eventBus)
    local self = setmetatable({}, ResourceManager)
    self.eventBus = eventBus
    
    -- Initialize resources with GENEROUS starting amounts
    self.resources = {
        money = 1000,           -- Start with baseline expected by tests
        reputation = 0,          -- Build reputation through contracts
        xp = 0,                  -- Experience for progression
        missionTokens = 0,       -- Special currency from crises
        
        -- Tracking
        totalMoneyEarned = 0,
        totalMoneySpent = 0,
        totalReputationEarned = 0
    }
    
    -- Generation rates (per second)
    self.generationRates = {
        money = 50,              -- Start at $50/sec from base operations
        reputation = 0.1,        -- Slow reputation gain
        xp = 1.0                 -- Steady XP gain
    }
    
    -- Multipliers from upgrades/specialists
    self.multipliers = {
        money = 1.0,
        reputation = 1.0,
        xp = 1.0
    }
    
    -- Resource change tracking for visual feedback
    self.recentChanges = {}
    self.changeDisplayTime = 2.0
    
    -- Subscribe to resource events from other systems
    if eventBus then
        eventBus:subscribe("resource_add", function(event)
            for resourceType, amount in pairs(event) do
                self:addResource(resourceType, amount, "contract")
            end
        end)
    end
    
    local DebugLogger = require("src.utils.debug_logger")
    local logger = DebugLogger.get()
    logger:debug("ResourceManager initialized with starting resources:")
    logger:debug(string.format("   Money: $%d", self.resources.money))
    logger:debug(string.format("   Generation: $%.0f/sec", self.generationRates.money))
    
    return self
end

-- Update resource generation
function ResourceManager:update(dt)
    -- Generate passive resources
    for resourceType, rate in pairs(self.generationRates) do
        if rate > 0 then
            local amount = rate * self.multipliers[resourceType] * dt
            self:addResource(resourceType, amount, "passive")
        end
    end
    
    -- Clean up old change notifications
    for i = #self.recentChanges, 1, -1 do
        self.recentChanges[i].timer = self.recentChanges[i].timer - dt
        if self.recentChanges[i].timer <= 0 then
            table.remove(self.recentChanges, i)
        end
    end
end

-- Add resources with notification
function ResourceManager:addResource(resourceType, amount, source)
    if not self.resources[resourceType] then
        print("⚠️  Unknown resource type: " .. tostring(resourceType))
        return false
    end
    
    local oldValue = self.resources[resourceType]
    self.resources[resourceType] = self.resources[resourceType] + amount
    
    -- Track earnings
    if resourceType == "money" and amount > 0 then
        self.resources.totalMoneyEarned = self.resources.totalMoneyEarned + amount
    elseif resourceType == "reputation" and amount > 0 then
        self.resources.totalReputationEarned = self.resources.totalReputationEarned + amount
    end
    
    -- Add to recent changes for visual feedback
    if amount > 0.1 then  -- Don't show tiny changes
        table.insert(self.recentChanges, {
            type = resourceType,
            amount = amount,
            source = source or "unknown",
            timer = self.changeDisplayTime,
            timestamp = love.timer.getTime()
        })
    end
    
    -- Emit event for UI updates
    if self.eventBus then
        self.eventBus:publish("resource_changed", {
            resourceType = resourceType,
            oldValue = oldValue,
            newValue = self.resources[resourceType],
            change = amount,
            source = source
        })
    end
    
    return true
end

-- Spend resources (returns success/failure)
function ResourceManager:spendResource(resourceType, amount)
    if not self.resources[resourceType] then
        return false, "Unknown resource type"
    end
    
    if self.resources[resourceType] < amount then
        return false, "Insufficient " .. resourceType
    end
    
    local oldValue = self.resources[resourceType]
    self.resources[resourceType] = self.resources[resourceType] - amount
    
    -- Track spending
    if resourceType == "money" then
        self.resources.totalMoneySpent = self.resources.totalMoneySpent + amount
    end
    
    -- Emit event
    if self.eventBus then
        self.eventBus:publish("resource_changed", {
            resourceType = resourceType,
            oldValue = oldValue,
            newValue = self.resources[resourceType],
            change = -amount,
            source = "spending"
        })
    end
    
    return true
end

-- Spend multiple resources at once (all or nothing)
function ResourceManager:spendResources(costs)
    -- Check if we can afford everything first
    for resourceType, amount in pairs(costs) do
        if not self.resources[resourceType] or self.resources[resourceType] < amount then
            return false, "Insufficient " .. resourceType
        end
    end
    
    -- Spend all resources
    for resourceType, amount in pairs(costs) do
        self:spendResource(resourceType, amount)
    end
    
    return true
end

-- Get current resource amount
function ResourceManager:getResource(resourceType)
    return self.resources[resourceType] or 0
end

-- Get all resources (for UI display)
function ResourceManager:getState()
    return {
        money = self.resources.money,
        reputation = self.resources.reputation,
        xp = self.resources.xp,
        missionTokens = self.resources.missionTokens,
        
        -- Generation info
        moneyPerSecond = self.generationRates.money * self.multipliers.money,
        reputationPerSecond = self.generationRates.reputation * self.multipliers.reputation,
        xpPerSecond = self.generationRates.xp * self.multipliers.xp,
        
        -- Stats
        totalMoneyEarned = self.resources.totalMoneyEarned,
        totalMoneySpent = self.resources.totalMoneySpent,
        totalReputationEarned = self.resources.totalReputationEarned,
        
        -- Recent changes for visual feedback
        recentChanges = self.recentChanges
    }
end

-- Set generation rate for a resource type
function ResourceManager:setGenerationRate(resourceType, rate)
    if self.generationRates[resourceType] ~= nil then
        local oldRate = self.generationRates[resourceType]
        self.generationRates[resourceType] = rate
        
        if self.eventBus and math.abs(rate - oldRate) > 0.01 then
            self.eventBus:publish("generation_rate_changed", {
                resourceType = resourceType,
                oldRate = oldRate,
                newRate = rate
            })
        end
        
        return true
    end
    return false
end

-- Backwards-compatible alias used in tests
function ResourceManager:setGeneration(resourceType, rate)
    return self:setGenerationRate(resourceType, rate)
end

-- Add to generation rate (for incremental upgrades)
function ResourceManager:addGenerationRate(resourceType, amount)
    if self.generationRates[resourceType] ~= nil then
        return self:setGenerationRate(resourceType, self.generationRates[resourceType] + amount)
    end
    return false
end

-- Set multiplier for a resource type
function ResourceManager:setMultiplier(resourceType, multiplier)
    if self.multipliers[resourceType] ~= nil then
        self.multipliers[resourceType] = multiplier
        
        if self.eventBus then
            self.eventBus:publish("multiplier_changed", {
                resourceType = resourceType,
                multiplier = multiplier
            })
        end
        
        return true
    end
    return false
end

-- Can afford check
function ResourceManager:canAfford(costs)
    for resourceType, amount in pairs(costs) do
        if not self.resources[resourceType] or self.resources[resourceType] < amount then
            return false
        end
    end
    return true
end

-- Format money for display
function ResourceManager:formatMoney(amount)
    if amount >= 1000000 then
        return string.format("$%.2fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("$%.1fK", amount / 1000)
    else
        return string.format("$%.0f", amount)
    end
end

-- Get save data
function ResourceManager:getSaveData()
    return {
        resources = self.resources,
        generationRates = self.generationRates,
        multipliers = self.multipliers
    }
end

-- Load save data
function ResourceManager:loadSaveData(data)
    if data.resources then
        for k, v in pairs(data.resources) do
            self.resources[k] = v
        end
    end
    
    if data.generationRates then
        for k, v in pairs(data.generationRates) do
            self.generationRates[k] = v
        end
    end
    
    if data.multipliers then
        for k, v in pairs(data.multipliers) do
            self.multipliers[k] = v
        end
    end
    
    print("💰 Resources loaded from save")
end

-- Backwards-compatible helper: initialize (legacy tests expect this)
function ResourceManager:initialize()
    -- No-op: constructor already initializes resources
    return true
end

-- Backwards-compatible hook: allow plugging in idle generators so ResourceManager can query their generation
function ResourceManager:setIdleGenerators(idleGenerators)
    self.idleGenerators = idleGenerators
end

-- Backwards-compatible: get total generation including idle generators
function ResourceManager:getTotalGeneration()
    local total = {
        money = self.generationRates.money * (self.multipliers.money or 1),
        reputation = self.generationRates.reputation * (self.multipliers.reputation or 1),
        xp = self.generationRates.xp * (self.multipliers.xp or 1)
    }

    if self.idleGenerators and type(self.idleGenerators.getCurrentGeneration) == "function" then
        local ig = self.idleGenerators:getCurrentGeneration()
        for k, v in pairs(ig) do
            total[k] = (total[k] or 0) + v
        end
    end

    return total
end

return ResourceManager

