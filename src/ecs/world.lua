-- ECS World Coordinator - Central ECS Management
-- Coordinates Entity, Component, and System managers
-- Provides unified API for entity/component lifecycle and system orchestration

local Entity = require("src.ecs.entity")
local Component = require("src.ecs.component")

local World = {}
World.__index = World

-- Create new ECS world
function World.new(eventBus)
    local self = setmetatable({}, World)
    
    -- Core ECS managers
    self.entities = Entity.new()
    self.components = Component.new()
    
    -- Event system for decoupled communication
    self.eventBus = eventBus
    
    -- System management
    self.systems = {}
    self.systemOrder = {}
    
    -- World state
    self.initialized = false
    self.paused = false
    
    return self
end

-- Initialize the world
function World:initialize()
    if self.initialized then
        return
    end
    
    self.initialized = true
    
    if self.eventBus then
        self.eventBus:publish("world_initialized", {})
    end
end

-- == Entity Management ==

-- Create a new entity
function World:createEntity()
    return self.entities:create()
end

-- Destroy an entity and all its components
function World:destroyEntity(entityId)
    if not self.entities:exists(entityId) then
        return false
    end
    
    -- Remove all components first
    self.components:removeAllComponents(entityId)
    
    -- Remove entity
    local success = self.entities:destroy(entityId)
    
    if success and self.eventBus then
        self.eventBus:publish("entity_destroyed", {
            entityId = entityId
        })
    end
    
    return success
end

-- Check if entity exists
function World:entityExists(entityId)
    return self.entities:exists(entityId)
end

-- Get all entities
function World:getAllEntities()
    return self.entities:getAllEntities()
end

-- == Component Management ==

-- Register a component type
function World:registerComponent(componentType, schema)
    return self.components:registerType(componentType, schema)
end

-- Add component to entity
function World:addComponent(entityId, componentType, componentData)
    if not self.entities:exists(entityId) then
        return false
    end
    
    local success = self.components:add(entityId, componentType, componentData)
    
    if success and self.eventBus then
        self.eventBus:publish("component_added", {
            entityId = entityId,
            componentType = componentType,
            data = componentData
        })
    end
    
    return success
end

-- Remove component from entity
function World:removeComponent(entityId, componentType)
    local success = self.components:remove(entityId, componentType)
    
    if success and self.eventBus then
        self.eventBus:publish("component_removed", {
            entityId = entityId,
            componentType = componentType
        })
    end
    
    return success
end

-- Get component data
function World:getComponent(entityId, componentType)
    return self.components:get(entityId, componentType)
end

-- Check if entity has component
function World:hasComponent(entityId, componentType)
    return self.components:has(entityId, componentType)
end

-- Query entities by component requirements
function World:query(requiredComponents)
    return self.components:query(requiredComponents)
end

-- == System Management ==

-- Register a system with the world
function World:registerSystem(system, priority)
    if not system or not system.name then
        error("System must have a name")
    end
    
    -- Set world reference on system
    system.world = self
    system.priority = priority or system.priority or 100
    
    -- Store system
    self.systems[system.name] = system
    
    -- Insert into ordered list based on priority
    local inserted = false
    for i, entry in ipairs(self.systemOrder) do
        if system.priority < entry.priority then
            table.insert(self.systemOrder, i, {
                name = system.name,
                priority = system.priority
            })
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(self.systemOrder, {
            name = system.name,
            priority = system.priority
        })
    end
    
    -- Initialize system if world is already initialized
    if self.initialized and not system.initialized then
        system:initialize()
    end
    
    return true
end

-- Unregister a system
function World:unregisterSystem(systemName)
    local system = self.systems[systemName]
    if system then
        system:teardown()
        self.systems[systemName] = nil
        
        -- Remove from ordered list
        for i, entry in ipairs(self.systemOrder) do
            if entry.name == systemName then
                table.remove(self.systemOrder, i)
                break
            end
        end
    end
end

-- Get a registered system
function World:getSystem(systemName)
    return self.systems[systemName]
end

-- Update all systems
function World:update(dt)
    if not self.initialized or self.paused then
        return
    end
    
    -- Update systems in priority order
    for _, entry in ipairs(self.systemOrder) do
        local system = self.systems[entry.name]
        if system then
            system:update(dt)
        end
    end
end

-- Pause world updates
function World:pause()
    self.paused = true
    
    -- Pause all systems
    for _, system in pairs(self.systems) do
        system:pause()
    end
    
    if self.eventBus then
        self.eventBus:publish("world_paused", {})
    end
end

-- Resume world updates
function World:resume()
    self.paused = false
    
    -- Resume all systems
    for _, system in pairs(self.systems) do
        system:resume()
    end
    
    if self.eventBus then
        self.eventBus:publish("world_resumed", {})
    end
end

-- Clean shutdown
function World:teardown()
    -- Teardown all systems
    for _, system in pairs(self.systems) do
        system:teardown()
    end
    
    -- Clear all data
    self.entities:clear()
    self.components:clear()
    self.systems = {}
    self.systemOrder = {}
    
    self.initialized = false
    self.paused = false
    
    if self.eventBus then
        self.eventBus:publish("world_teardown", {})
    end
end

-- Get world statistics
function World:getStats()
    return {
        entityCount = self.entities:getEntityCount(),
        systemCount = #self.systemOrder,
        initialized = self.initialized,
        paused = self.paused
    }
end

return World