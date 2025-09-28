-- Entity Manager - ECS Core Component
-- Manages lightweight entity IDs and their lifecycle
-- Entities are just unique identifiers with no embedded data or logic

local Entity = {}
Entity.__index = Entity

-- Create new entity manager
function Entity.new()
    local self = setmetatable({}, Entity)
    
    -- Entity tracking
    self.nextEntityId = 1
    self.activeEntities = {}
    self.recycledIds = {}
    
    return self
end

-- Create a new entity and return its unique ID
function Entity:create()
    local entityId
    
    -- Reuse recycled IDs when available for memory efficiency
    if #self.recycledIds > 0 then
        entityId = table.remove(self.recycledIds)
    else
        entityId = self.nextEntityId
        self.nextEntityId = self.nextEntityId + 1
    end
    
    self.activeEntities[entityId] = true
    return entityId
end

-- Destroy an entity and recycle its ID
function Entity:destroy(entityId)
    if not self.activeEntities[entityId] then
        return false -- Entity doesn't exist
    end
    
    self.activeEntities[entityId] = nil
    table.insert(self.recycledIds, entityId)
    
    return true
end

-- Check if an entity exists
function Entity:exists(entityId)
    return self.activeEntities[entityId] == true
end

-- Get all active entity IDs
function Entity:getAllEntities()
    local entities = {}
    for entityId, _ in pairs(self.activeEntities) do
        table.insert(entities, entityId)
    end
    return entities
end

-- Get count of active entities
function Entity:getEntityCount()
    local count = 0
    for _ in pairs(self.activeEntities) do
        count = count + 1
    end
    return count
end

-- Clear all entities (useful for testing/cleanup)
function Entity:clear()
    self.activeEntities = {}
    self.recycledIds = {}
    self.nextEntityId = 1
end

return Entity