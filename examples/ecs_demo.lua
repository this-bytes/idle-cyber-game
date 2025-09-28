#!/usr/bin/env lua5.3
-- ECS Framework Demonstration
-- Shows how to use the Entity-Component-System architecture for game development

-- Load ECS components
local World = require("src.ecs.world")
local System = require("src.ecs.system")
local EventBus = require("src.utils.event_bus")

print("🎯 ECS Framework Demonstration")
print("=" .. string.rep("=", 50))

-- Create event bus for system communication
local eventBus = EventBus.new()

-- Create ECS world
local world = World.new(eventBus)
world:initialize()

print("✅ ECS World initialized")

-- Register component types
world:registerComponent("position", {x = "number", y = "number"})
world:registerComponent("velocity", {dx = "number", dy = "number"})
world:registerComponent("health", {current = "number", max = "number"})
world:registerComponent("threat", {type = "string", severity = "number"})

print("✅ Component types registered: position, velocity, health, threat")

-- Create a movement system
local MovementSystem = {}
MovementSystem.__index = MovementSystem
setmetatable(MovementSystem, {__index = System})

function MovementSystem.new(world, eventBus)
    local self = System.new("MovementSystem", world, eventBus)
    setmetatable(self, MovementSystem)
    
    self:setRequiredComponents({"position", "velocity"})
    return self
end

function MovementSystem:processEntity(entityId, dt)
    local position = self:getComponent(entityId, "position")
    local velocity = self:getComponent(entityId, "velocity")
    
    if position and velocity then
        position.x = position.x + velocity.dx * dt
        position.y = position.y + velocity.dy * dt
        
        -- Clamp to bounds
        position.x = math.max(0, math.min(100, position.x))
        position.y = math.max(0, math.min(100, position.y))
    end
end

-- Create a health system
local HealthSystem = {}
HealthSystem.__index = HealthSystem  
setmetatable(HealthSystem, {__index = System})

function HealthSystem.new(world, eventBus)
    local self = System.new("HealthSystem", world, eventBus)
    setmetatable(self, HealthSystem)
    
    self:setRequiredComponents({"health"})
    return self
end

function HealthSystem:processEntity(entityId, dt)
    local health = self:getComponent(entityId, "health")
    
    if health then
        -- Natural regeneration
        if health.current < health.max then
            health.current = math.min(health.max, health.current + 5 * dt)
        end
        
        -- Check for death
        if health.current <= 0 then
            print("💀 Entity " .. entityId .. " has died")
            self.world:destroyEntity(entityId)
        end
    end
end

-- Register systems with priority
world:registerSystem(MovementSystem.new(world, eventBus), 1)
world:registerSystem(HealthSystem.new(world, eventBus), 2)

print("✅ Systems registered: MovementSystem, HealthSystem")

-- Create some entities
print("\n🏭 Creating Entities...")

-- Player entity
local player = world:createEntity()
world:addComponent(player, "position", {x = 10, y = 10})
world:addComponent(player, "velocity", {dx = 5, dy = 3})
world:addComponent(player, "health", {current = 100, max = 100})

print("✅ Player entity created (ID: " .. player .. ") at position (10, 10)")

-- Enemy entities
local enemies = {}
for i = 1, 3 do
    local enemy = world:createEntity()
    world:addComponent(enemy, "position", {x = math.random(50, 90), y = math.random(20, 80)})
    world:addComponent(enemy, "velocity", {dx = math.random(-3, 3), dy = math.random(-3, 3)})
    world:addComponent(enemy, "health", {current = 50, max = 50})
    world:addComponent(enemy, "threat", {type = "malware", severity = math.random(1, 5)})
    
    table.insert(enemies, enemy)
    print("✅ Enemy entity " .. i .. " created (ID: " .. enemy .. ")")
end

-- Static entity (no movement)
local base = world:createEntity()
world:addComponent(base, "position", {x = 50, y = 50})
world:addComponent(base, "health", {current = 200, max = 200})

print("✅ Base entity created (ID: " .. base .. ") - static defense")

-- Simulate game updates
print("\n🎮 Running Simulation...")
print("=" .. string.rep("=", 50))

for frame = 1, 10 do
    local dt = 0.1 -- 100ms per frame
    
    print("Frame " .. frame .. ":")
    
    -- Update world (runs all systems)
    world:update(dt)
    
    -- Display entity positions
    local movableEntities = world:query({"position"})
    for _, entityId in ipairs(movableEntities) do
        local pos = world:getComponent(entityId, "position")
        local vel = world:getComponent(entityId, "velocity")
        local health = world:getComponent(entityId, "health")
        local threat = world:getComponent(entityId, "threat")
        
        local entityType = "Unknown"
        if entityId == player then
            entityType = "Player"
        elseif entityId == base then
            entityType = "Base"
        else
            entityType = "Enemy"
        end
        
        local status = string.format("  %s (ID:%d) at (%.1f, %.1f)", 
                                   entityType, entityId, pos.x, pos.y)
        
        if vel then
            status = status .. string.format(" moving (%.1f, %.1f)", vel.dx, vel.dy)
        end
        
        if health then
            status = status .. string.format(" HP: %.0f/%.0f", health.current, health.max)
        end
        
        if threat then
            status = status .. string.format(" [%s threat:%d]", threat.type, threat.severity)
        end
        
        print(status)
    end
    
    print()
end

-- Demonstrate component queries
print("🔍 Component Query Demonstrations:")
print("=" .. string.rep("=", 50))

local entitiesWithHealth = world:query({"health"})
print("Entities with health components: " .. #entitiesWithHealth)

local entitiesWithMovement = world:query({"position", "velocity"})
print("Entities with movement (position + velocity): " .. #entitiesWithMovement)

local threatEntities = world:query({"threat"})
print("Threat entities: " .. #threatEntities)

-- Show world statistics
local stats = world:getStats()
print("\n📊 World Statistics:")
print("=" .. string.rep("=", 50))
print("Total entities: " .. stats.entityCount)
print("Total systems: " .. stats.systemCount)
print("World initialized: " .. tostring(stats.initialized))
print("World paused: " .. tostring(stats.paused))

-- Demonstrate system performance metrics
local movementSystem = world:getSystem("MovementSystem")
local healthSystem = world:getSystem("HealthSystem")

if movementSystem and healthSystem then
    print("\n⚡ System Performance:")
    print("=" .. string.rep("=", 50))
    
    local movementMetrics = movementSystem:getPerformanceMetrics()
    local healthMetrics = healthSystem:getPerformanceMetrics()
    
    print("MovementSystem:")
    print("  Update count: " .. movementMetrics.updateCount)
    print("  Average update time: " .. string.format("%.6f", movementMetrics.averageUpdateTime) .. "s")
    
    print("HealthSystem:")
    print("  Update count: " .. healthMetrics.updateCount)
    print("  Average update time: " .. string.format("%.6f", healthMetrics.averageUpdateTime) .. "s")
end

-- Cleanup
print("\n🧹 Cleanup:")
print("=" .. string.rep("=", 50))

world:pause()
print("✅ World paused")

world:teardown() 
print("✅ World torn down - all entities and systems cleaned up")

print("\n🎯 ECS Framework Demonstration Complete!")
print("The ECS architecture provides:")
print("  • Clean separation of data (Components) and logic (Systems)")
print("  • Efficient entity queries and processing")
print("  • Modular system design with performance tracking")
print("  • Event-driven communication between systems")
print("  • Easy testing and debugging capabilities")