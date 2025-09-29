-- Tests for Resource System - Idle Sec Ops

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua;src/core/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local ResourceManager = require("src.core.resource_manager")
local EventBus = require("src.utils.event_bus")

-- Test resource system initialization
TestRunner.test("ResourceManager: Initialize with correct resources", function()
    local eventBus = EventBus.new()
    local resources = ResourceManager.new(eventBus)
    resources:initialize()
    
    -- Test core Idle Sec Ops resources exist
    TestRunner.assertNotNil(resources:getResource("money"), "Should have money resource")
    TestRunner.assertNotNil(resources:getResource("reputation"), "Should have reputation resource")
    TestRunner.assertNotNil(resources:getResource("missionTokens"), "Should have mission tokens resource")
    
    -- Test starting values
    TestRunner.assertEqual(1000, resources:getResource("money"), "Should start with 1000 money")
    TestRunner.assertEqual(0, resources:getResource("reputation"), "Should start with 0 reputation")
    TestRunner.assertEqual(0, resources:getResource("missionTokens"), "Should start with 0 mission tokens")
end)

TestRunner.test("ResourceManager: Set and get resources", function()
    local eventBus = EventBus.new()
    local resources = ResourceManager.new(eventBus)
    resources:initialize()
    
    -- Test getting initial money
    local initialMoney = resources:getResource("money")
    TestRunner.assertEqual(1000, initialMoney, "Should start with 1000 money")
    
    -- Test spending resources
    local canSpend = resources:spendResource("money", 100)
    TestRunner.assertEqual(true, canSpend, "Should be able to spend 100 money")
    TestRunner.assertEqual(900, resources:getResource("money"), "Money should be 900 after spending 100")
    
    -- Test adding resources
    resources:addResource("money", 200)
    TestRunner.assertEqual(1100, resources:getResource("money"), "Money should be 1100 after adding 200")
end)

TestRunner.test("ResourceManager: Resource generation", function()
    local eventBus = EventBus.new()
    local resources = ResourceManager.new(eventBus)
    resources:initialize()
    
    local initialMoney = resources:getResource("money")
    
    -- Update for 1 second - ResourceManager should handle its own generation
    resources:update(1.0)
    
    local afterMoney = resources:getResource("money")
    
    -- Money should be same or increased (depending on generation setup)
    if afterMoney >= initialMoney then
        print("💰 ResourceManager: Generation test passed - money: " .. initialMoney .. " → " .. afterMoney)
    else
        error("Money decreased unexpectedly: " .. initialMoney .. " → " .. afterMoney)
    end
end)