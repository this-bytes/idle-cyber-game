-- Resource Management System - Cyber Empire Command
-- Handles resources for cybersecurity consultancy business

local ResourceSystem = {}
ResourceSystem.__index = ResourceSystem

-- Create new resource system
function ResourceSystem.new(eventBus)
    local self = setmetatable({}, ResourceSystem)
    self.eventBus = eventBus
    
    -- Core resources as defined in Cyber Empire Command instructions
    self.resources = {
        -- Primary Resources (Core Mechanics)
        money = 1000,           -- Currency for hiring, equipment, facilities
        reputation = 0,         -- Unlocks higher-tier contracts and factions
        xp = 0,                 -- General experience for company growth
        missionTokens = 0,      -- Rare resource from Crisis Mode for elite upgrades
        
        -- Secondary Resources (Business Operations)
        contracts = 0,          -- Active contracts providing income
        specialists = 1,        -- Team members (start with player)
        facilities = 1,         -- Office space and equipment capacity
    }
    
    -- Generation rates (per second) - mainly from active contracts
    self.generation = {
        money = 0,              -- From contracts and crisis resolutions
        reputation = 0,         -- From successful contracts
        xp = 0,                 -- From all activities
        missionTokens = 0,      -- Only from Crisis Mode successes
    }
    
    -- Resource multipliers from facilities and upgrades
    self.multipliers = {
        money = 1.0,
        reputation = 1.0,
        xp = 1.0,
        missionTokens = 1.0,
    }
    
    -- Storage limitations (can be expanded through upgrades if needed)
    self.storage = {
        -- Core resources have unlimited storage by default
    }
    
    self.lastUpdateTime = (love and love.timer and love.timer.getTime()) or os.clock()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to relevant events
function ResourceSystem:subscribeToEvents()
    -- Handle upgrade effects
    self.eventBus:subscribe("apply_upgrade_effect", function(data)
        self:applyUpgradeEffect(data.upgradeId, data.effectType, data.value)
    end)
    
    -- Handle resource spend requests
    self.eventBus:subscribe("check_can_afford", function(data)
        local canAfford = self:canAfford(data.cost)
        if data.callback then
            data.callback(canAfford)
        end
    end)
    
    self.eventBus:subscribe("spend_resources", function(data)
        self:spendResources(data.cost)
    end)
    
    -- Handle zone changes (updated for business-focused zones)
    self.eventBus:subscribe("zone_changed", function(data)
        -- The new zone system uses business capabilities instead of resource bonuses
        -- Apply reputation bonus if the zone has one
        if data.zone and data.zone.reputationBonus then
            -- Apply reputation multiplier based on zone
            local currentMultiplier = self:getMultiplier("reputation")
            self:setMultiplier("reputation", currentMultiplier * data.zone.reputationBonus)
        end
    end)
    
    -- Handle achievement rewards
    self.eventBus:subscribe("add_resource", function(data)
        self:addResource(data.resource, data.amount)
    end)
end

-- Apply upgrade effect
function ResourceSystem:applyUpgradeEffect(upgradeId, effectType, value)
    if effectType == "moneyGeneration" then
        self:addGeneration("money", value)
    elseif effectType == "reputationMultiplier" then
        local currentMultiplier = self:getMultiplier("reputation")
        self:setMultiplier("reputation", currentMultiplier + value)
    else
        print("⚠️ Unknown upgrade effect: " .. effectType)
    end
end

-- Apply business zone capabilities (updated for new zone system)
function ResourceSystem:applyZoneCapabilities(zone)
    -- Modern zone system focuses on business capabilities rather than resource multipliers
    -- Zone capabilities like maxContracts, contractTypes are handled by respective systems
    if zone and zone.reputationBonus then
        -- Apply reputation bonus from zone
        local currentMultiplier = self:getMultiplier("reputation")
        self:setMultiplier("reputation", currentMultiplier * zone.reputationBonus)
    end
end

-- Update resource generation
function ResourceSystem:update(dt)
    -- Use provided dt directly for deterministic testing
    local deltaTime = dt
    
    -- Generate resources based on rates
    for resourceName, rate in pairs(self.generation) do
        if rate > 0 then
            local generated = rate * deltaTime * self.multipliers[resourceName]
            self:addResource(resourceName, generated)
        end
    end
    
    -- Update last update time if in Love2D environment
    if love and love.timer then
        self.lastUpdateTime = love.timer.getTime()
    end
    
    -- Publish resource update event
    self.eventBus:publish("resources_updated", {
        resources = self.resources,
        generation = self.generation
    })
end

-- Add resource with storage limits
function ResourceSystem:addResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    local currentAmount = self.resources[resourceName]
    local maxStorage = self.storage[resourceName] or math.huge
    local newAmount = math.min(currentAmount + amount, maxStorage)
    
    self.resources[resourceName] = newAmount
    
    -- Publish resource changed event
    self.eventBus:publish("resource_changed", {
        resource = resourceName,
        oldAmount = currentAmount,
        newAmount = newAmount,
        addedAmount = newAmount - currentAmount
    })
    
    -- Publish resource earned event for progression system
    if newAmount > currentAmount then
        self.eventBus:publish("resource_earned", {
            resource = resourceName,
            amount = newAmount - currentAmount
        })
    end
    
    return true
end

-- Spend resource
function ResourceSystem:spendResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    if self.resources[resourceName] >= amount then
        local oldAmount = self.resources[resourceName]
        self.resources[resourceName] = self.resources[resourceName] - amount
        
        -- Publish resource spent event
        self.eventBus:publish("resource_spent", {
            resource = resourceName,
            amount = amount,
            remaining = self.resources[resourceName]
        })
        
        return true
    end
    
    return false
end

-- Check if player can afford cost
function ResourceSystem:canAfford(costs)
    for resourceName, amount in pairs(costs) do
        if not self.resources[resourceName] or self.resources[resourceName] < amount then
            return false
        end
    end
    return true
end

-- Spend multiple resources at once
function ResourceSystem:spendResources(costs)
    if not self:canAfford(costs) then
        return false
    end
    
    for resourceName, amount in pairs(costs) do
        self:spendResource(resourceName, amount)
    end
    
    return true
end

-- Set resource amount (for initialization/loading)
function ResourceSystem:setResource(resourceName, amount)
    if self.resources[resourceName] ~= nil then
        self.resources[resourceName] = amount
    end
end

-- Get resource amount
function ResourceSystem:getResource(resourceName)
    return self.resources[resourceName] or 0
end

-- Get all resources
function ResourceSystem:getAllResources()
    return self.resources
end

-- Set generation rate
function ResourceSystem:setGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = rate
    end
end

-- Add to generation rate
function ResourceSystem:addGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = self.generation[resourceName] + rate
    end
end

-- Get generation rate
function ResourceSystem:getGeneration(resourceName)
    return self.generation[resourceName] or 0
end

-- Get all generation rates
function ResourceSystem:getAllGeneration()
    return self.generation
end

-- Set resource multiplier
function ResourceSystem:setMultiplier(resourceName, multiplier)
    if self.multipliers[resourceName] ~= nil then
        self.multipliers[resourceName] = multiplier
    end
end

-- Get resource multiplier
function ResourceSystem:getMultiplier(resourceName)
    return self.multipliers[resourceName] or 1.0
end

-- Set storage limit
function ResourceSystem:setStorageLimit(resourceName, limit)
    if self.storage[resourceName] ~= nil then
        self.storage[resourceName] = limit
    end
end

-- Get storage limit
function ResourceSystem:getStorageLimit(resourceName)
    return self.storage[resourceName] or math.huge
end

-- Get state for saving
function ResourceSystem:getState()
    return {
        resources = self.resources,
        generation = self.generation,
        multipliers = self.multipliers,
        storage = self.storage
    }
end

-- Load state from save
function ResourceSystem:loadState(state)
    if state.resources then
        for name, value in pairs(state.resources) do
            self.resources[name] = value or 0
        end
    end
    
    if state.generation then
        for name, value in pairs(state.generation) do
            self.generation[name] = value or 0
        end
    end
    
    if state.multipliers then
        for name, value in pairs(state.multipliers) do
            self.multipliers[name] = value or 1.0
        end
    end
    
    if state.storage then
        for name, value in pairs(state.storage) do
            self.storage[name] = value
        end
    end
end

return ResourceSystem