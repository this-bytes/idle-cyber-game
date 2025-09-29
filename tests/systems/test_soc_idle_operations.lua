-- Test file for SOCIdleOperations
-- Tests the SOC automation and idle mechanics system

local SOCIdleOperations = require("src.systems.soc_idle_operations")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")

-- Test SOC idle operations initialization
TestRunner.test("SOCIdleOperations - Initialization", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local socIdle = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    
    TestRunner.assertNotNil(socIdle, "SOCIdleOperations should initialize")
    TestRunner.assertEqual(socIdle.currentAutomationLevel, "MANUAL", "Should start with manual operations")
    TestRunner.assertNotNil(socIdle.passiveOperations, "Should have passive operations config")
    TestRunner.assertNotNil(socIdle.automationLevels, "Should have automation levels defined")
end)

-- Test automation level progression
TestRunner.test("SOCIdleOperations - Automation Level Progression", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local socIdle = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    socIdle:initialize()
    
    -- Test progression to basic automation
    socIdle:updateAutomationLevel("BASIC")
    TestRunner.assertEqual(socIdle.currentAutomationLevel, "BASIC", "Should upgrade to BASIC automation")
    
    -- Test progression to advanced automation
    socIdle:updateAutomationLevel("ENTERPRISE")
    TestRunner.assertEqual(socIdle.currentAutomationLevel, "ADVANCED", "Should upgrade to ADVANCED automation")
    
    -- Check that automation features are enabled
    TestRunner.assertEqual(socIdle.passiveOperations.threatMonitoring.enabled, true, "Threat monitoring should be enabled")
    TestRunner.assertEqual(socIdle.passiveOperations.incidentResponse.enabled, true, "Incident response should be enabled")
end)

-- Test offline progress calculation
TestRunner.test("SOCIdleOperations - Offline Progress", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local socIdle = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    socIdle:initialize()
    
    -- Set advanced automation for meaningful offline progress
    socIdle:updateAutomationLevel("ADVANCED")
    
    -- Add some reputation for bonus calculations
    resourceManager:addResource("reputation", 50)
    
    -- Test 1 hour offline progress
    local progress = socIdle:calculateOfflineProgress(3600) -- 1 hour
    
    TestRunner.assertNotNil(progress, "Should return offline progress")
    TestRunner.assert(progress.income > 0, "Should generate income during offline time")
    TestRunner.assert(progress.threatsHandled >= 0, "Should handle threats during offline time")
    TestRunner.assert(progress.incidentsResolved >= 0, "Should resolve incidents during offline time")
    TestRunner.assertNotNil(progress.summary, "Should provide progress summary")
end)

-- Test automation status reporting
TestRunner.test("SOCIdleOperations - Automation Status", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local socIdle = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    socIdle:initialize()
    
    socIdle:updateAutomationLevel("BASIC")
    
    local status = socIdle:getAutomationStatus()
    
    TestRunner.assertNotNil(status, "Should return automation status")
    TestRunner.assertEqual(status.level, "BASIC", "Should report correct automation level")
    TestRunner.assertNotNil(status.name, "Should have automation level name")
    TestRunner.assertNotNil(status.description, "Should have automation description")
    TestRunner.assert(status.threatMonitoring > 0, "Should report threat monitoring capability")
    TestRunner.assert(status.resourceMultiplier > 1, "Should have resource generation multiplier")
end)

-- Test state save/load
TestRunner.test("SOCIdleOperations - State Persistence", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local socIdle = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    socIdle:initialize()
    
    -- Set some state
    socIdle:updateAutomationLevel("ADVANCED") -- This maps to "INTERMEDIATE" automation level
    
    -- Get state
    local state = socIdle:getState()
    TestRunner.assertNotNil(state, "Should return state")
    TestRunner.assertEqual(state.currentAutomationLevel, "INTERMEDIATE", "Should save automation level")
    
    -- Create new instance and load state
    local socIdle2 = SOCIdleOperations.new(eventBus, resourceManager, nil, nil)
    socIdle2:initialize()
    socIdle2:loadState(state)
    
    TestRunner.assertEqual(socIdle2.currentAutomationLevel, "INTERMEDIATE", "Should load automation level")
end)