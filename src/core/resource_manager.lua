-- ResourceManager - Centralized Resource Management System
-- Fortress Refactor: Unified resource handling with clean interfaces and event-driven updates
-- Consolidates all resource operations from scattered systems into a single, maintainable manager

local ResourceManager = {}
ResourceManager.__index = ResourceManager

-- Resource categories for organization
local RESOURCE_CATEGORIES = {
    PRIMARY = "primary",     -- Core gameplay currencies
    SECONDARY = "secondary", -- Supporting resources
    DERIVED = "derived"      -- Calculated resources
}

-- Create new resource manager
function ResourceManager.new(eventBus)
    local self = setmetatable({}, ResourceManager)
    
    -- Core dependencies
    self.eventBus = eventBus
    
    -- Resource storage
    self.resources = {}
    self.generation = {}
    self.multipliers = {}
    self.storage = {}
    self.categories = {}
    
    -- Update tracking
    self.lastUpdateTime = 0
    
    -- Initialize default resources
    self:initializeResources()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Initialize the core cybersecurity business resources
function ResourceManager:initializeResources()
    -- Primary Resources (Core Mechanics)
    self:defineResource("money", {
        category = RESOURCE_CATEGORIES.PRIMARY,
        initialValue = 1000,
        generation = 0,
        multiplier = 1.0,
        description = "Currency for hiring, equipment, facilities"
    })
    
    self:defineResource("reputation", {
        category = RESOURCE_CATEGORIES.PRIMARY,
        initialValue = 0,
        generation = 0,
        multiplier = 1.0,
        description = "Unlocks higher-tier contracts and factions"
    })
    
    self:defineResource("xp", {
        category = RESOURCE_CATEGORIES.PRIMARY,
        initialValue = 0,
        generation = 0,
        multiplier = 1.0,
        description = "General experience for company growth"
    })
    
    self:defineResource("missionTokens", {
        category = RESOURCE_CATEGORIES.PRIMARY,
        initialValue = 0,
        generation = 0,
        multiplier = 1.0,
        description = "Rare resource from Crisis Mode for elite upgrades"
    })
    
    -- Secondary Resources (Business Operations)
    self:defineResource("contracts", {
        category = RESOURCE_CATEGORIES.SECONDARY,
        initialValue = 0,
        generation = 0,
        multiplier = 1.0,
        description = "Active contracts providing income"
    })
    
    self:defineResource("specialists", {
        category = RESOURCE_CATEGORIES.SECONDARY,
        initialValue = 1,
        generation = 0,
        multiplier = 1.0,
        description = "Team members (start with player)"
    })
    
    self:defineResource("facilities", {
        category = RESOURCE_CATEGORIES.SECONDARY,
        initialValue = 1,
        generation = 0,
        multiplier = 1.0,
        description = "Office space and equipment capacity"
    })
    
    print("💰 ResourceManager: Initialized cybersecurity business resources")
end

-- Define a new resource type
function ResourceManager:defineResource(name, config)
    if not name or not config then
        error("ResourceManager:defineResource requires name and config")
    end
    
    -- Store resource data
    self.resources[name] = config.initialValue or 0
    self.generation[name] = config.generation or 0
    self.multipliers[name] = config.multiplier or 1.0
    self.storage[name] = config.storage -- nil = unlimited
    self.categories[name] = config.category or RESOURCE_CATEGORIES.PRIMARY
    
    -- Notify listeners
    self.eventBus:publish("resource_defined", {
        name = name,
        config = config
    })
end

-- Subscribe to relevant events
function ResourceManager:subscribeToEvents()
    -- Handle upgrade effects on resources
    self.eventBus:subscribe("apply_upgrade_effect", function(data)
        self:applyUpgradeEffect(data.upgradeId, data.effectType, data.value)
    end)
    
    -- Handle contract completions
    self.eventBus:subscribe("contract_completed", function(data)
        if data.rewards then
            for resource, amount in pairs(data.rewards) do
                self:addResource(resource, amount)
            end
        end
    end)
    
    -- Handle facility upgrades
    self.eventBus:subscribe("facility_upgraded", function(data)
        if data.resourceEffects then
            for resource, effect in pairs(data.resourceEffects) do
                if effect.type == "multiplier" then
                    self:addMultiplier(resource, effect.value)
                elseif effect.type == "generation" then
                    self:addGeneration(resource, effect.value)
                end
            end
        end
    end)
end

-- Update resource generation
function ResourceManager:update(dt)
    local currentTime = love.timer and love.timer.getTime() or os.clock()
    
    if self.lastUpdateTime == 0 then
        self.lastUpdateTime = currentTime
        return
    end
    
    local deltaTime = dt or (currentTime - self.lastUpdateTime)
    self.lastUpdateTime = currentTime
    
    -- Generate resources
    for resourceName, rate in pairs(self.generation) do
        if rate > 0 then
            local generated = rate * self.multipliers[resourceName] * deltaTime
            self:addResource(resourceName, generated)
        end
    end
end

-- Add resource amount with validation
function ResourceManager:addResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    local currentAmount = self.resources[resourceName]
    local newAmount = currentAmount + amount
    
    -- Check storage limits
    local storageLimit = self.storage[resourceName]
    if storageLimit and newAmount > storageLimit then
        newAmount = storageLimit
    end
    
    -- Update resource
    local actualGain = newAmount - currentAmount
    self.resources[resourceName] = newAmount
    
    -- Publish event if there was a change
    if actualGain ~= 0 then
        self.eventBus:publish("resource_changed", {
            resource = resourceName,
            amount = newAmount,
            change = actualGain,
            category = self.categories[resourceName]
        })
    end
    
    return actualGain
end

-- Spend resources with validation
function ResourceManager:spendResource(resourceName, amount)
    if not self.resources[resourceName] then
        return false
    end
    
    if self.resources[resourceName] < amount then
        return false
    end
    
    return self:addResource(resourceName, -amount) < 0
end

-- Check if resources can be spent
function ResourceManager:canAfford(costs)
    if not costs then return true end
    
    for resourceName, amount in pairs(costs) do
        if not self.resources[resourceName] or self.resources[resourceName] < amount then
            return false
        end
    end
    
    return true
end

-- Spend multiple resources at once
function ResourceManager:spendResources(costs)
    if not self:canAfford(costs) then
        return false
    end
    
    for resourceName, amount in pairs(costs) do
        self:spendResource(resourceName, amount)
    end
    
    return true
end

-- Get resource amount
function ResourceManager:getResource(resourceName)
    return self.resources[resourceName] or 0
end

-- Get all resources
function ResourceManager:getAllResources()
    return self.resources
end

-- Legacy compatibility - alias for getAllResources
function ResourceManager:getResources()
    return self.resources
end

-- Get resources by category
function ResourceManager:getResourcesByCategory(category)
    local filtered = {}
    for name, value in pairs(self.resources) do
        if self.categories[name] == category then
            filtered[name] = value
        end
    end
    return filtered
end

-- Set generation rate
function ResourceManager:setGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = rate
        self.eventBus:publish("resource_generation_changed", {
            resource = resourceName,
            rate = rate
        })
    end
end

-- Add to generation rate
function ResourceManager:addGeneration(resourceName, rate)
    if self.generation[resourceName] ~= nil then
        self.generation[resourceName] = self.generation[resourceName] + rate
        self.eventBus:publish("resource_generation_changed", {
            resource = resourceName,
            rate = self.generation[resourceName]
        })
    end
end

-- Get generation rate
function ResourceManager:getGeneration(resourceName)
    return self.generation[resourceName] or 0
end

-- Set resource multiplier
function ResourceManager:setMultiplier(resourceName, multiplier)
    if self.multipliers[resourceName] ~= nil then
        self.multipliers[resourceName] = multiplier
        self.eventBus:publish("resource_multiplier_changed", {
            resource = resourceName,
            multiplier = multiplier
        })
    end
end

-- Add to resource multiplier
function ResourceManager:addMultiplier(resourceName, multiplier)
    if self.multipliers[resourceName] ~= nil then
        self.multipliers[resourceName] = self.multipliers[resourceName] + multiplier
        self.eventBus:publish("resource_multiplier_changed", {
            resource = resourceName,
            multiplier = self.multipliers[resourceName]
        })
    end
end

-- Get resource multiplier
function ResourceManager:getMultiplier(resourceName)
    return self.multipliers[resourceName] or 1.0
end

-- Apply upgrade effects
function ResourceManager:applyUpgradeEffect(upgradeId, effectType, value)
    if effectType == "generation" then
        -- Upgrade affects resource generation
        for resource, amount in pairs(value) do
            self:addGeneration(resource, amount)
        end
    elseif effectType == "multiplier" then
        -- Upgrade affects resource multipliers
        for resource, multiplier in pairs(value) do
            self:addMultiplier(resource, multiplier)
        end
    elseif effectType == "storage" then
        -- Upgrade affects resource storage
        for resource, storage in pairs(value) do
            if self.storage[resource] then
                self.storage[resource] = self.storage[resource] + storage
            else
                self.storage[resource] = storage
            end
        end
    end
end

-- Get comprehensive resource state
function ResourceManager:getState()
    return {
        resources = self.resources,
        generation = self.generation,
        multipliers = self.multipliers,
        storage = self.storage,
        categories = self.categories
    }
end

-- Load resource state
function ResourceManager:loadState(state)
    if not state then return end
    
    if state.resources then
        for name, value in pairs(state.resources) do
            self.resources[name] = value
        end
    end
    
    if state.generation then
        for name, value in pairs(state.generation) do
            self.generation[name] = value
        end
    end
    
    if state.multipliers then
        for name, value in pairs(state.multipliers) do
            self.multipliers[name] = value
        end
    end
    
    if state.storage then
        self.storage = state.storage
    end
    
    if state.categories then
        self.categories = state.categories
    end
    
    print("💰 ResourceManager: State loaded successfully")
end

-- Initialize method for GameLoop integration
function ResourceManager:initialize()
    -- Use love.timer if available (in LÖVE environment), otherwise use os.clock
    if love and love.timer then
        self.lastUpdateTime = love.timer.getTime()
    else
        self.lastUpdateTime = os.clock()
    end
    print("💰 ResourceManager: Fortress architecture integration complete")
end

-- Shutdown method for GameLoop integration
function ResourceManager:shutdown()
    print("💰 ResourceManager: Shutdown complete")
end

return ResourceManager
