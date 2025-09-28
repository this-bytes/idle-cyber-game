-- System Base Class - ECS Core Component
-- Isolated logic processors that operate on entities possessing required components
-- Provides standard lifecycle: initialization, update, pause/resume, teardown

local System = {}
System.__index = System

-- Create new system base class
function System.new(name, world, eventBus)
    local self = setmetatable({}, System)
    
    -- System identification
    self.name = name or "UnnamedSystem"
    
    -- ECS World reference for entity/component operations
    self.world = world
    self.eventBus = eventBus
    
    -- System state
    self.initialized = false
    self.paused = false
    self.priority = 100 -- Default priority (lower = higher priority)
    
    -- Component requirements for this system
    self.requiredComponents = {}
    
    -- Performance tracking
    self.updateTime = 0
    self.updateCount = 0
    
    return self
end

-- Initialize the system (override in subclasses)
function System:initialize()
    if self.initialized then
        return
    end
    
    self.initialized = true
    
    if self.eventBus then
        self.eventBus:publish("system_initialized", {
            systemName = self.name
        })
    end
end

-- Main update logic (override in subclasses)
function System:update(dt)
    if not self.initialized or self.paused then
        return
    end
    
    local startTime = os.clock()
    
    -- Get entities that match this system's component requirements
    local entities = self:getMatchingEntities()
    
    -- Process each matching entity
    for _, entityId in ipairs(entities) do
        self:processEntity(entityId, dt)
    end
    
    -- Track performance
    local endTime = os.clock()
    self.updateTime = endTime - startTime
    self.updateCount = self.updateCount + 1
end

-- Process a single entity (override in subclasses)
function System:processEntity(entityId, dt)
    -- Default implementation does nothing
    -- Subclasses should override this method
end

-- Get entities that match this system's component requirements
function System:getMatchingEntities()
    if not self.world or #self.requiredComponents == 0 then
        return {}
    end
    
    return self.world.components:query(self.requiredComponents)
end

-- Pause system updates
function System:pause()
    self.paused = true
    
    if self.eventBus then
        self.eventBus:publish("system_paused", {
            systemName = self.name
        })
    end
end

-- Resume system updates
function System:resume()
    self.paused = false
    
    if self.eventBus then
        self.eventBus:publish("system_resumed", {
            systemName = self.name
        })
    end
end

-- Cleanup/teardown the system (override in subclasses)
function System:teardown()
    self.initialized = false
    self.paused = false
    
    if self.eventBus then
        self.eventBus:publish("system_teardown", {
            systemName = self.name
        })
    end
end

-- Set component requirements for this system
function System:setRequiredComponents(components)
    self.requiredComponents = components or {}
end

-- Add a component requirement
function System:addRequiredComponent(componentType)
    for _, existing in ipairs(self.requiredComponents) do
        if existing == componentType then
            return -- Already required
        end
    end
    table.insert(self.requiredComponents, componentType)
end

-- Remove a component requirement
function System:removeRequiredComponent(componentType)
    for i, existing in ipairs(self.requiredComponents) do
        if existing == componentType then
            table.remove(self.requiredComponents, i)
            return
        end
    end
end

-- Get system performance metrics
function System:getPerformanceMetrics()
    return {
        name = self.name,
        updateTime = self.updateTime,
        updateCount = self.updateCount,
        averageUpdateTime = self.updateCount > 0 and (self.updateTime / self.updateCount) or 0,
        initialized = self.initialized,
        paused = self.paused
    }
end

-- Helper method to get component data for an entity
function System:getComponent(entityId, componentType)
    if not self.world then
        return nil
    end
    return self.world.components:get(entityId, componentType)
end

-- Helper method to add component to an entity
function System:addComponent(entityId, componentType, componentData)
    if not self.world then
        return false
    end
    return self.world.components:add(entityId, componentType, componentData)
end

-- Helper method to remove component from an entity
function System:removeComponent(entityId, componentType)
    if not self.world then
        return false
    end
    return self.world.components:remove(entityId, componentType)
end

-- Helper method to check if entity has component
function System:hasComponent(entityId, componentType)
    if not self.world then
        return false
    end
    return self.world.components:has(entityId, componentType)
end

return System