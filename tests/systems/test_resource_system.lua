-- Tests for Resource System - Cyber Empire Command

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local ResourceSystem = require("resource_system")
local EventBus = require("event_bus")

-- Test resource system initialization
TestRunner.test("ResourceSystem: Initialize with correct resources", function()
    local eventBus = EventBus.new()
    local resources = ResourceSystem.new(eventBus)
    
    -- Test core Cyber Empire Command resources exist
    TestRunner.assertNotNil(resources.resources.money, "Should have money resource")
    TestRunner.assertNotNil(resources.resources.reputation, "Should have reputation resource")
    TestRunner.assertNotNil(resources.resources.xp, "Should have XP resource")
    TestRunner.assertNotNil(resources.resources.missionTokens, "Should have mission tokens resource")
    
    -- Test starting values
    TestRunner.assertEqual(1000, resources.resources.money, "Should start with 1000 money")
    TestRunner.assertEqual(0, resources.resources.reputation, "Should start with 0 reputation")
    TestRunner.assertEqual(0, resources.resources.xp, "Should start with 0 XP")
    TestRunner.assertEqual(0, resources.resources.missionTokens, "Should start with 0 mission tokens")
end)

TestRunner.test("ResourceSystem: Set and get resources", function()
    local eventBus = EventBus.new()
    local resources = ResourceSystem.new(eventBus)
    
    -- Test setting resources
    resources:setResource("money", 5000)
    TestRunner.assertEqual(5000, resources:getResource("money"), "Should set money correctly")
    
    resources:setResource("reputation", 50)
    TestRunner.assertEqual(50, resources:getResource("reputation"), "Should set reputation correctly")
    
    -- Test adding resources
    resources:addResource("money", 1000)
    TestRunner.assertEqual(6000, resources:getResource("money"), "Should add money correctly")
end)

TestRunner.test("ResourceSystem: Resource generation", function()
    local eventBus = EventBus.new()
    local resources = ResourceSystem.new(eventBus)
    
    -- Set generation rate
    resources:setGeneration("money", 100) -- 100 money per second
    
    -- Update for 1 second
    resources:update(1.0)
    
    TestRunner.assertEqual(1100, resources:getResource("money"), "Should generate money over time")
end)