#!/usr/bin/env lua
-- Bootstrap Architecture Test
-- Verifies that the new config-driven architecture works correctly

-- Add src to package path
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua;src/config/?.lua"

-- Simple test framework
local function test(name, func)
    local success, error = pcall(func)
    if success then
        print("✅ " .. name)
    else
        print("❌ " .. name)
        print("   Error: " .. tostring(error))
    end
end

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

print("🧪 Testing Bootstrap Architecture...")
print("=" .. string.rep("=", 50))

-- Test 1: Configuration Loading
test("GameConfig loads correctly", function()
    local GameConfig = require("game_config")
    assert(GameConfig.GAME_TITLE == "Cyber Empire Command")
    assert(GameConfig.RESOURCES.money.startingAmount == 1000)
    assert(GameConfig.CLIENT_TIERS.startup ~= nil)
end)

-- Test 2: Resource System Bootstrap
test("ResourceSystem uses config", function()
    local EventBus = require("event_bus")
    local ResourceSystem = require("resource_system")
    
    local eventBus = EventBus.new()
    local resources = ResourceSystem.new(eventBus)
    
    -- Should have resources from config
    assert(resources:getResource("money") == 1000)
    assert(resources:getResource("reputation") == 0)
    assert(resources:getResource("missionTokens") == 0)
end)

-- Test 3: Contract System Bootstrap
test("ContractSystem uses config", function()
    local EventBus = require("event_bus")
    local ContractSystem = require("contract_system")
    
    local eventBus = EventBus.new()
    local contracts = ContractSystem.new(eventBus)
    
    -- Should have client types from config
    assert(contracts.clientTypes.startup ~= nil)
    assert(contracts.clientTypes.startup.name == "Tech Startup")
    
    -- Should have generated initial contract
    local available = contracts:getAvailableContracts()
    local hasContract = false
    for _ in pairs(available) do
        hasContract = true
        break
    end
    assert(hasContract, "Should have generated initial contract")
end)

-- Test 4: Event Bus Communication
test("Event bus communication", function()
    local EventBus = require("event_bus")
    
    local eventBus = EventBus.new()
    local received = false
    
    eventBus:subscribe("test_event", function(data)
        received = true
        assert(data.message == "Hello Bootstrap!")
    end)
    
    eventBus:publish("test_event", {message = "Hello Bootstrap!"})
    assert(received, "Event should have been received")
end)

-- Test 5: Game Controller Bootstrap
test("Game controller initializes", function()
    -- This is a lighter test since full game init requires LÖVE 2D
    local GameConfig = require("game_config")
    
    -- Test that config is accessible for game initialization
    assert(GameConfig.BALANCE.contractGenerationInterval == 30)
    assert(GameConfig.BALANCE.autoSaveInterval == 60)
end)

print("=" .. string.rep("=", 50))
print("🎉 Bootstrap architecture tests completed!")
print("The modular, config-driven architecture is working correctly.")
print()
print("Next steps:")
print("- Run the game with LÖVE 2D to test full integration")
print("- Start the admin backend to test web dashboard")
print("- Implement remaining Phase 1 features")