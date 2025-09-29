-- ECS Resource System - Pure ECS Implementation
-- Manages player resources using Entity-Component-System architecture
-- Replaces legacy ResourceManager with pure ECS approach

local System = require("src.ecs.system")
local ECSResourceSystem = setmetatable({}, {__index = System})
ECSResourceSystem.__index = ECSResourceSystem

-- Create new ECS resource system
function ECSResourceSystem.new(world, eventBus)
    local self = System.new("ECSResourceSystem", world, eventBus)
    setmetatable(self, ECSResourceSystem)
    
    -- Set required components
    self:setRequiredComponents({"resources"})
    
    -- Resource generation rates
    self.baseGeneration = {
        money = 1.0,      -- $1 per second base
        reputation = 0.1, -- 0.1 reputation per second base  
        experience = 0.5, -- 0.5 XP per second base
        energy = 5.0      -- 5 energy per second regen
    }
    
    -- Resource limits
    self.resourceLimits = {
        money = 1000000,     -- $1M limit
        reputation = 10000,  -- 10k reputation limit
        experience = 100000, -- 100k XP limit  
        energy = 100         -- 100 energy limit
    }
    
    return self
end

-- Initialize the system
function ECSResourceSystem:initialize()
    System.initialize(self)
    
    -- Subscribe to resource events
    if self.eventBus then
        self.eventBus:subscribe("add_resources", function(data)
            self:addResources(data.entityId, data.resources)
        end)
        
        self.eventBus:subscribe("spend_resources", function(data)
            self:spendResources(data.entityId, data.resources)
        end)
        
        self.eventBus:subscribe("contract_completed", function(data)
            self:applyContractRewards(data.rewards)
        end)
    end
end

-- Process resource entities (passive generation)
function ECSResourceSystem:processEntity(entityId, dt)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return
    end
    
    -- Apply passive resource generation
    for resourceType, baseRate in pairs(self.baseGeneration) do
        if resources[resourceType] ~= nil then
            local generation = baseRate * dt
            local newValue = resources[resourceType] + generation
            local limit = self.resourceLimits[resourceType] or math.huge
            
            resources[resourceType] = math.min(newValue, limit)
        end
    end
end

-- Add resources to an entity
function ECSResourceSystem:addResources(entityId, resourceAmounts)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return false
    end
    
    local added = {}
    for resourceType, amount in pairs(resourceAmounts) do
        if resources[resourceType] ~= nil and amount > 0 then
            local oldValue = resources[resourceType]
            local limit = self.resourceLimits[resourceType] or math.huge
            local newValue = math.min(oldValue + amount, limit)
            
            resources[resourceType] = newValue
            added[resourceType] = newValue - oldValue
        end
    end
    
    if self.eventBus then
        self.eventBus:publish("resources_added", {
            entityId = entityId,
            added = added
        })
    end
    
    return true
end

-- Spend resources from an entity
function ECSResourceSystem:spendResources(entityId, resourceAmounts)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return false
    end
    
    -- Check if we have enough resources
    for resourceType, amount in pairs(resourceAmounts) do
        if resources[resourceType] == nil or resources[resourceType] < amount then
            return false -- Insufficient resources
        end
    end
    
    -- Spend the resources
    local spent = {}
    for resourceType, amount in pairs(resourceAmounts) do
        resources[resourceType] = resources[resourceType] - amount
        spent[resourceType] = amount
    end
    
    if self.eventBus then
        self.eventBus:publish("resources_spent", {
            entityId = entityId,
            spent = spent
        })
    end
    
    return true
end

-- Check if entity can afford resource costs
function ECSResourceSystem:canAfford(entityId, resourceAmounts)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return false
    end
    
    for resourceType, amount in pairs(resourceAmounts) do
        if resources[resourceType] == nil or resources[resourceType] < amount then
            return false
        end
    end
    
    return true
end

-- Get resources for an entity
function ECSResourceSystem:getResources(entityId)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return {}
    end
    
    -- Return a copy to prevent external modification
    local copy = {}
    for resourceType, amount in pairs(resources) do
        copy[resourceType] = amount
    end
    
    return copy
end

-- Set resource generation rate
function ECSResourceSystem:setGenerationRate(resourceType, rate)
    self.baseGeneration[resourceType] = rate
end

-- Get resource generation rate
function ECSResourceSystem:getGenerationRate(resourceType)
    return self.baseGeneration[resourceType] or 0
end

-- Set resource limit
function ECSResourceSystem:setResourceLimit(resourceType, limit)
    self.resourceLimits[resourceType] = limit
end

-- Get resource limit
function ECSResourceSystem:getResourceLimit(resourceType)
    return self.resourceLimits[resourceType] or math.huge
end

-- Apply contract completion rewards
function ECSResourceSystem:applyContractRewards(rewards)
    -- Find player entity with resources component
    local playerEntities = self:getMatchingEntities()
    
    for _, entityId in ipairs(playerEntities) do
        -- Apply rewards to first player entity found
        self:addResources(entityId, rewards)
        break
    end
end

-- Get total resources across all entities
function ECSResourceSystem:getTotalResources()
    local totals = {}
    local entities = self:getMatchingEntities()
    
    for _, entityId in ipairs(entities) do
        local resources = self:getComponent(entityId, "resources")
        if resources then
            for resourceType, amount in pairs(resources) do
                totals[resourceType] = (totals[resourceType] or 0) + amount
            end
        end
    end
    
    return totals
end

-- Get system statistics
function ECSResourceSystem:getStats()
    local entities = self:getMatchingEntities()
    local totalResources = self:getTotalResources()
    
    return {
        resourceEntityCount = #entities,
        totalResources = totalResources,
        generationRates = self.baseGeneration,
        resourceLimits = self.resourceLimits
    }
end

-- Reset resources for an entity
function ECSResourceSystem:resetResources(entityId, newResources)
    local resources = self:getComponent(entityId, "resources")
    if not resources then
        return false
    end
    
    -- Reset to new values
    for resourceType, amount in pairs(newResources) do
        resources[resourceType] = amount
    end
    
    if self.eventBus then
        self.eventBus:publish("resources_reset", {
            entityId = entityId,
            newResources = newResources
        })
    end
    
    return true
end

return ECSResourceSystem