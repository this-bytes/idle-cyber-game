-- Resource Manager System - Manages player resources and currencies
-- ======================================================================
-- Critical system that tracks money, reputation, XP, and mission tokens
-- Supports passive generation, spending, and event-driven changes
-- Integrates with event bus for UI updates and notifications
-- ======================================================================
-- Needs to be robust and flexible to support various game mechanics
-- Should provide clear APIs for other systems to interact with resources
-- Should support saving/loading state and be testable in isolation
-- Should provide visual feedback for resource changes (e.g. floating text)
-- Should handle edge cases like overspending, negative resources, and large numbers
-- Should allow for dynamic generation rates and multipliers from upgrades/specialists
-- Should track statistics like total earned/spent for player feedback and achievements
-- Should be easy to extend with new resource types if needed in the future
-- Should be efficient and not cause performance issues during frequent updates
-- Should log important events for debugging and analytics
-- Should be compatible with existing test suites and pass all relevant tests
-- Should provide helper functions for formatting and displaying resources in the UI
-- Should support both incremental and bulk resource changes
-- Should allow for resource change notifications to be customized (e.g. source of change)


local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new(eventBus)
    local self = setmetatable({}, ResourceManager)
    self.eventBus = eventBus
    
    -- Initialize resources with starting amounts
    self.resources = {
        money = 10000,           -- Start with enough to hire first specialist
        reputation = 10,          -- Build reputation through contracts
        xp = 1,                  -- Experience for progression
        missionTokens = 0,       -- Special currency from crises
        
        -- Tracking
        totalMoneyEarned = 0,
        totalMoneySpent = 0,
        totalReputationEarned = 0
    }
    
    -- Generation rates (per second)
    self.generationRates = {
        money = 50,              -- Start at $50/sec from base operations
        reputation = 0.2,        -- Slow reputation gain
        xp = 1.0                 -- Steady XP gain
    }
    
    -- Multipliers from upgrades/specialists
    self.multipliers = {
        money = 10.0,
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
    
    print("💰 ResourceManager initialized with starting resources:")
    print(string.format("   Money: $%d", self.resources.money))
    print(string.format("   Generation: $%.0f/sec", self.generationRates.money))
    
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

-- Get state (standard method for GameStateEngine)
function ResourceManager:getState()
    return self:getSaveData()
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

-- Load state (standard method for GameStateEngine)
function ResourceManager:loadState(state)
    self:loadSaveData(state)
end

return ResourceManager
