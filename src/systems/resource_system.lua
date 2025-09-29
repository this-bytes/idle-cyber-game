-- Resource System - Pure ECS Wrapper  
-- Provides legacy compatibility for tests while using pure ECS internally
-- This will be completely removed once all tests are migrated

local ECSResourceSystem = require("src.systems.ecs_resource_system")

local ResourceSystem = {}
ResourceSystem.__index = ResourceSystem

-- Legacy compatibility - ResourceSystem.new() now creates ECSResourceSystem
function ResourceSystem.new(eventBus)
    -- Create a minimal ECS world for the resource system
    local World = require("src.ecs.world")
    local world = World.new(eventBus)
    world:initialize()
    
    -- Register resource component
    world:registerComponent("resources", {
        money = "number",
        reputation = "number",
        xp = "number"
    })
    
    -- Create player entity with resources
    local playerEntity = world:createEntity()
    world:addComponent(playerEntity, "resources", {
        money = 1000,
        reputation = 0,
        xp = 0
    })
    
    -- Create ECS resource system
    local resourceSystem = ECSResourceSystem.new(world, eventBus)
    resourceSystem:initialize()
    
    -- Store references for legacy compatibility
    resourceSystem._world = world
    resourceSystem._playerEntity = playerEntity
    
    -- Add legacy methods for backward compatibility
    resourceSystem.getResources = function(self)
        return ECSResourceSystem.getResources(self, self._playerEntity)
    end
    
    resourceSystem.getResource = function(self, resourceType)
        local resources = ECSResourceSystem.getResources(self, self._playerEntity)
        return resources[resourceType] or 0
    end
    
    resourceSystem.addResource = function(self, resourceType, amount)
        local resources = {}
        resources[resourceType] = amount
        return ECSResourceSystem.addResources(self, self._playerEntity, resources)
    end
    
    return resourceSystem
end

return ResourceSystem