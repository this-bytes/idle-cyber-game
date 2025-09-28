-- ECS Core Framework Tests  
-- Comprehensive tests for Entity, Component, System, and World classes

-- Load test environment
local testEnv = dofile("tests/test_environment.lua")

-- Load ECS components
local Entity = require("src.ecs.entity")
local Component = require("src.ecs.component")
local System = require("src.ecs.system")
local World = require("src.ecs.world")
local EventBus = require("src.utils.event_bus")

local test = {}

-- Entity Manager Tests
function test.run_entity_tests()
    local passed = 0
    local failed = 0
    
    print("🔍 Entity Manager Tests")
    
    -- Test entity creation
    local success, error = pcall(function()
        local entityManager = Entity.new()
        
        -- Test entity creation
        local entity1 = entityManager:create()
        local entity2 = entityManager:create()
        
        assert(entity1 == 1, "First entity should have ID 1")
        assert(entity2 == 2, "Second entity should have ID 2")
        assert(entityManager:exists(entity1), "Entity 1 should exist")
        assert(entityManager:exists(entity2), "Entity 2 should exist")
        assert(entityManager:getEntityCount() == 2, "Should have 2 entities")
    end)
    
    if success then
        print("  ✅ Entity creation")
        passed = passed + 1
    else
        print("  ❌ Entity creation: " .. tostring(error))
        failed = failed + 1
    end
    
    -- Test entity destruction and recycling
    success, error = pcall(function()
        local entityManager = Entity.new()
        
        local entity1 = entityManager:create()  -- ID 1
        local entity2 = entityManager:create()  -- ID 2
        local entity3 = entityManager:create()  -- ID 3
        
        -- Destroy entity 2
        assert(entityManager:destroy(entity2), "Should successfully destroy entity")
        assert(not entityManager:exists(entity2), "Entity 2 should no longer exist")
        assert(entityManager:getEntityCount() == 2, "Should have 2 entities after destruction")
        
        -- Create new entity - should reuse ID 2
        local entity4 = entityManager:create()
        assert(entity4 == 2, "New entity should reuse recycled ID 2")
        assert(entityManager:getEntityCount() == 3, "Should have 3 entities again")
    end)
    
    if success then
        print("  ✅ Entity destruction and ID recycling")
        passed = passed + 1
    else
        print("  ❌ Entity destruction and ID recycling: " .. tostring(error))
        failed = failed + 1
    end
    
    return passed, failed
end

-- Component Registry Tests  
function test.run_component_tests()
    local passed = 0
    local failed = 0
    
    print("🔍 Component Registry Tests")
    
    -- Test component registration and management
    local success, error = pcall(function()
        local componentRegistry = Component.new()
        
        -- Register component types
        assert(componentRegistry:registerType("health"), "Should register health component")
        assert(componentRegistry:registerType("position"), "Should register position component")
        
        -- Add components to entities
        assert(componentRegistry:add(1, "health", {current = 100, max = 100}), "Should add health component")
        assert(componentRegistry:add(1, "position", {x = 0, y = 0}), "Should add position component")
        assert(componentRegistry:add(2, "health", {current = 50, max = 50}), "Should add health to entity 2")
        
        -- Check component existence
        assert(componentRegistry:has(1, "health"), "Entity 1 should have health component")
        assert(componentRegistry:has(1, "position"), "Entity 1 should have position component")
        assert(componentRegistry:has(2, "health"), "Entity 2 should have health component")
        assert(not componentRegistry:has(2, "position"), "Entity 2 should not have position component")
    end)
    
    if success then
        print("  ✅ Component registration and management")
        passed = passed + 1
    else
        print("  ❌ Component registration and management: " .. tostring(error))
        failed = failed + 1
    end
    
    -- Test component queries
    success, error = pcall(function()
        local componentRegistry = Component.new()
        
        componentRegistry:registerType("health")
        componentRegistry:registerType("position")
        componentRegistry:registerType("velocity")
        
        -- Set up test entities
        componentRegistry:add(1, "health", {value = 100})
        componentRegistry:add(1, "position", {x = 0, y = 0})
        
        componentRegistry:add(2, "health", {value = 50})
        
        componentRegistry:add(3, "position", {x = 10, y = 10})
        componentRegistry:add(3, "velocity", {dx = 1, dy = 1})
        
        -- Test queries
        local entitiesWithHealth = componentRegistry:query({"health"})
        assert(#entitiesWithHealth == 2, "Should find 2 entities with health")
        
        local entitiesWithHealthAndPosition = componentRegistry:query({"health", "position"})
        assert(#entitiesWithHealthAndPosition == 1, "Should find 1 entity with both health and position")
        
        local entitiesWithVelocity = componentRegistry:query({"velocity"})
        assert(#entitiesWithVelocity == 1, "Should find 1 entity with velocity")
    end)
    
    if success then
        print("  ✅ Component queries")
        passed = passed + 1
    else
        print("  ❌ Component queries: " .. tostring(error))
        failed = failed + 1
    end
    
    return passed, failed
end

-- System Base Class Tests
function test.run_system_tests()
    local passed = 0
    local failed = 0
    
    print("🔍 System Base Class Tests")
    
    -- Test system lifecycle
    local success, error = pcall(function()
        local eventBus = EventBus.new()
        local system = System.new("TestSystem", nil, eventBus)
        
        assert(system.name == "TestSystem", "System should have correct name")
        assert(not system.initialized, "System should not be initialized initially")
        assert(not system.paused, "System should not be paused initially")
        
        -- Test initialization
        system:initialize()
        assert(system.initialized, "System should be initialized after calling initialize")
        
        -- Test pause/resume
        system:pause()
        assert(system.paused, "System should be paused after calling pause")
        
        system:resume()
        assert(not system.paused, "System should not be paused after calling resume")
        
        -- Test teardown
        system:teardown()
        assert(not system.initialized, "System should not be initialized after teardown")
    end)
    
    if success then
        print("  ✅ System lifecycle")
        passed = passed + 1
    else
        print("  ❌ System lifecycle: " .. tostring(error))
        failed = failed + 1
    end
    
    -- Test system component requirements
    success, error = pcall(function()
        local system = System.new("TestSystem")
        
        -- Test setting component requirements
        system:setRequiredComponents({"health", "position"})
        assert(#system.requiredComponents == 2, "Should have 2 required components")
        
        -- Test adding component requirement
        system:addRequiredComponent("velocity")
        assert(#system.requiredComponents == 3, "Should have 3 required components after adding")
        
        -- Test removing component requirement
        system:removeRequiredComponent("position")
        assert(#system.requiredComponents == 2, "Should have 2 required components after removing")
    end)
    
    if success then
        print("  ✅ System component requirements")
        passed = passed + 1
    else
        print("  ❌ System component requirements: " .. tostring(error))
        failed = failed + 1
    end
    
    return passed, failed
end

-- World Coordinator Tests
function test.run_world_tests()
    local passed = 0
    local failed = 0
    
    print("🔍 World Coordinator Tests")
    
    -- Test world initialization and entity management
    local success, error = pcall(function()
        local eventBus = EventBus.new()
        local world = World.new(eventBus)
        
        -- Test world initialization
        world:initialize()
        assert(world.initialized, "World should be initialized")
        
        -- Test entity creation through world
        local entity1 = world:createEntity()
        local entity2 = world:createEntity()
        
        assert(world:entityExists(entity1), "Entity 1 should exist")
        assert(world:entityExists(entity2), "Entity 2 should exist")
        
        -- Test entity destruction
        assert(world:destroyEntity(entity1), "Should successfully destroy entity")
        assert(not world:entityExists(entity1), "Entity 1 should no longer exist")
    end)
    
    if success then
        print("  ✅ World entity management")
        passed = passed + 1
    else
        print("  ❌ World entity management: " .. tostring(error))
        failed = failed + 1
    end
    
    -- Test world component management
    success, error = pcall(function()
        local world = World.new()
        world:initialize()
        
        -- Register component types
        world:registerComponent("health")
        world:registerComponent("position")
        
        local entity = world:createEntity()
        
        -- Add components
        assert(world:addComponent(entity, "health", {current = 100}), "Should add health component")
        assert(world:addComponent(entity, "position", {x = 5, y = 10}), "Should add position component")
        
        -- Check components
        assert(world:hasComponent(entity, "health"), "Should have health component")
        assert(world:hasComponent(entity, "position"), "Should have position component")
        
        local healthData = world:getComponent(entity, "health")
        assert(healthData.current == 100, "Health component should have correct data")
        
        -- Remove component
        assert(world:removeComponent(entity, "health"), "Should remove health component")
        assert(not world:hasComponent(entity, "health"), "Should no longer have health component")
    end)
    
    if success then
        print("  ✅ World component management")
        passed = passed + 1
    else
        print("  ❌ World component management: " .. tostring(error))
        failed = failed + 1
    end
    
    -- Test system registration and updates
    success, error = pcall(function()
        local eventBus = EventBus.new()
        local world = World.new(eventBus)
        world:initialize()
        
        local testSystem = System.new("TestSystem", world, eventBus)
        testSystem.updateCalled = false
        
        -- Override update method to track calls
        function testSystem:update(dt)
            System.update(self, dt)
            self.updateCalled = true
        end
        
        -- Register system
        world:registerSystem(testSystem, 1)
        
        local retrievedSystem = world:getSystem("TestSystem")
        assert(retrievedSystem == testSystem, "Should retrieve the same system")
        
        -- Test world update
        world:update(0.016) -- 60 FPS
        assert(testSystem.updateCalled, "System update should have been called")
    end)
    
    if success then
        print("  ✅ World system management")
        passed = passed + 1
    else
        print("  ❌ World system management: " .. tostring(error))
        failed = failed + 1
    end
    
    return passed, failed
end

-- Integration Tests
function test.run_integration_tests()
    local passed = 0
    local failed = 0
    
    print("🔍 ECS Integration Tests")
    
    -- Test complete ECS workflow
    local success, error = pcall(function()
        local eventBus = EventBus.new()
        local world = World.new(eventBus)
        world:initialize()
        
        -- Register component types
        world:registerComponent("position")
        world:registerComponent("velocity")
        world:registerComponent("health")
        
        -- Create a movement system
        local movementSystem = System.new("MovementSystem", world, eventBus)
        movementSystem:setRequiredComponents({"position", "velocity"})
        
        function movementSystem:processEntity(entityId, dt)
            local position = self:getComponent(entityId, "position")
            local velocity = self:getComponent(entityId, "velocity")
            
            if position and velocity then
                position.x = position.x + velocity.dx * dt
                position.y = position.y + velocity.dy * dt
            end
        end
        
        world:registerSystem(movementSystem, 1)
        
        -- Create test entities
        local entity1 = world:createEntity()
        world:addComponent(entity1, "position", {x = 0, y = 0})
        world:addComponent(entity1, "velocity", {dx = 10, dy = 5})
        world:addComponent(entity1, "health", {current = 100})
        
        local entity2 = world:createEntity()
        world:addComponent(entity2, "position", {x = 100, y = 100})
        -- No velocity component - should not be processed by movement system
        
        -- Update world
        world:update(1.0) -- 1 second
        
        -- Check results
        local position1 = world:getComponent(entity1, "position")
        assert(position1.x == 10, "Entity 1 should have moved in X direction")
        assert(position1.y == 5, "Entity 1 should have moved in Y direction")
        
        local position2 = world:getComponent(entity2, "position")
        assert(position2.x == 100, "Entity 2 should not have moved in X direction")
        assert(position2.y == 100, "Entity 2 should not have moved in Y direction")
    end)
    
    if success then
        print("  ✅ Complete ECS workflow")
        passed = passed + 1
    else
        print("  ❌ Complete ECS workflow: " .. tostring(error))
        failed = failed + 1
    end
    
    return passed, failed
end

-- Run all ECS tests
function test.run_all_ecs_tests()
    print("🧪 Running ECS Core Framework Tests...")
    print("=" .. string.rep("=", 50))
    
    local totalPassed = 0
    local totalFailed = 0
    
    local passed, failed = test.run_entity_tests()
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
    
    passed, failed = test.run_component_tests()
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
    
    passed, failed = test.run_system_tests()
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
    
    passed, failed = test.run_world_tests()
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
    
    passed, failed = test.run_integration_tests()
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
    
    print("=" .. string.rep("=", 50))
    print(string.format("ECS Tests completed: %d passed, %d failed", totalPassed, totalFailed))
    
    return totalPassed, totalFailed
end

return test