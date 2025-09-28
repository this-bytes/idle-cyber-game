-- Component Registry - ECS Core Component  
-- Manages pure data holders without behavior, designed for reuse and composability
-- Supports dynamic composition and modification of entities during runtime

local Component = {}
Component.__index = Component

-- Create new component registry
function Component.new()
    local self = setmetatable({}, Component)
    
    -- Component storage: componentType -> entityId -> componentData
    self.components = {}
    
    -- Entity-to-components mapping for efficient queries
    self.entityComponents = {}
    
    -- Component type registry for validation
    self.registeredTypes = {}
    
    return self
end

-- Register a component type with optional schema validation
function Component:registerType(componentType, schema)
    self.registeredTypes[componentType] = schema or {}
    self.components[componentType] = {}
    return true
end

-- Add a component to an entity
function Component:add(entityId, componentType, componentData)
    if not self.registeredTypes[componentType] then
        error("Component type '" .. componentType .. "' not registered")
    end
    
    -- Initialize component storage for this type if needed
    if not self.components[componentType] then
        self.components[componentType] = {}
    end
    
    -- Store component data
    self.components[componentType][entityId] = componentData or {}
    
    -- Update entity-to-components mapping
    if not self.entityComponents[entityId] then
        self.entityComponents[entityId] = {}
    end
    self.entityComponents[entityId][componentType] = true
    
    return true
end

-- Remove a component from an entity
function Component:remove(entityId, componentType)
    if self.components[componentType] then
        self.components[componentType][entityId] = nil
    end
    
    if self.entityComponents[entityId] then
        self.entityComponents[entityId][componentType] = nil
        
        -- Clean up empty entity record
        local hasComponents = false
        for _ in pairs(self.entityComponents[entityId]) do
            hasComponents = true
            break
        end
        if not hasComponents then
            self.entityComponents[entityId] = nil
        end
    end
    
    return true
end

-- Get a component from an entity
function Component:get(entityId, componentType)
    if not self.components[componentType] then
        return nil
    end
    return self.components[componentType][entityId]
end

-- Check if an entity has a specific component
function Component:has(entityId, componentType)
    return self.entityComponents[entityId] and 
           self.entityComponents[entityId][componentType] == true
end

-- Get all component types for an entity
function Component:getComponentTypes(entityId)
    if not self.entityComponents[entityId] then
        return {}
    end
    
    local types = {}
    for componentType, _ in pairs(self.entityComponents[entityId]) do
        table.insert(types, componentType)
    end
    return types
end

-- Query entities that have specific component types
function Component:query(requiredComponents)
    local matchingEntities = {}
    
    -- If no requirements, return empty set
    if not requiredComponents or #requiredComponents == 0 then
        return matchingEntities
    end
    
    -- Check each entity to see if it has all required components
    for entityId, components in pairs(self.entityComponents) do
        local hasAllComponents = true
        
        for _, requiredType in ipairs(requiredComponents) do
            if not components[requiredType] then
                hasAllComponents = false
                break
            end
        end
        
        if hasAllComponents then
            table.insert(matchingEntities, entityId)
        end
    end
    
    return matchingEntities
end

-- Get all components for an entity (returns component data, not just types)
function Component:getAllComponents(entityId)
    local entityData = {}
    
    if not self.entityComponents[entityId] then
        return entityData
    end
    
    for componentType, _ in pairs(self.entityComponents[entityId]) do
        entityData[componentType] = self.components[componentType][entityId]
    end
    
    return entityData
end

-- Remove all components from an entity (called when entity is destroyed)
function Component:removeAllComponents(entityId)
    if not self.entityComponents[entityId] then
        return
    end
    
    -- Remove from each component type storage
    for componentType, _ in pairs(self.entityComponents[entityId]) do
        if self.components[componentType] then
            self.components[componentType][entityId] = nil
        end
    end
    
    -- Remove entity record
    self.entityComponents[entityId] = nil
end

-- Get count of entities with a specific component type
function Component:getComponentCount(componentType)
    if not self.components[componentType] then
        return 0
    end
    
    local count = 0
    for _ in pairs(self.components[componentType]) do
        count = count + 1
    end
    return count
end

-- Clear all components (useful for testing/cleanup)
function Component:clear()
    self.components = {}
    self.entityComponents = {}
    self.registeredTypes = {}
end

return Component