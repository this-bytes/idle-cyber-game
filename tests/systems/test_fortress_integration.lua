-- Test suite for the fortress integration
-- Validates that fortress architecture works with legacy systems

local function runFortressIntegrationTests()
    print("🏰 Testing Fortress Integration...")
    
    -- Set up test environment
    local testEnv = require("tests.test_environment")
    testEnv.setup()
    
    -- Import fortress components
    local FortressGame = require("src.core.fortress_game")
    
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Helper function to run a test
    local function runTest(name, testFunc)
        local success, error = pcall(testFunc)
        if success then
            print("✅ " .. name)
            passed = passed + 1
        else
            print("❌ " .. name .. ": " .. tostring(error))
            failed = failed + 1
        end
        table.insert(tests, {name = name, passed = success, error = error})
    end
    
    -- Test 1: Fortress game initialization
    runTest("FortressGame: Initialization and system setup", function()
        local fortressGame = FortressGame.new()
        
        -- Test initial state
        assert(not fortressGame.initialized, "Should not be initialized initially")
        assert(fortressGame.currentMode == "idle", "Should default to idle mode")
        assert(fortressGame.flowState == "splash", "Should start in splash state")
        
        -- Test initialization
        local success = fortressGame:initialize()
        assert(success, "Initialization should succeed")
        assert(fortressGame.initialized, "Should be initialized after init")
        
        -- Test system availability
        assert(fortressGame.systems.resourceManager ~= nil, "Should have ResourceManager")
        assert(fortressGame.systems.securityUpgrades ~= nil, "Should have SecurityUpgrades")
        assert(fortressGame.systems.threatSimulation ~= nil, "Should have ThreatSimulation")
        assert(fortressGame.systems.uiManager ~= nil, "Should have UIManager")
        
        -- Test legacy system integration
        assert(fortressGame.systems.contracts ~= nil, "Should have ContractSystem")
        assert(fortressGame.systems.specialists ~= nil, "Should have SpecialistSystem")
        assert(fortressGame.systems.idle ~= nil, "Should have IdleSystem")
        assert(fortressGame.systems.skills ~= nil, "Should have SkillSystem")
        
        -- Test game loop registration
        assert(fortressGame.gameLoop:getSystem("resourceManager") ~= nil, "ResourceManager should be registered")
        assert(fortressGame.gameLoop:getSystem("contracts") ~= nil, "ContractSystem should be registered")
        
        -- Test game modes
        assert(fortressGame.modes.idle ~= nil, "Should have idle mode")
        assert(fortressGame.modes.admin ~= nil, "Should have admin mode")
        
        -- Test shutdown
        fortressGame:shutdown()
        assert(not fortressGame.initialized, "Should not be initialized after shutdown")
    end)
    
    -- Test 2: Fortress game update cycle
    runTest("FortressGame: Update cycle and system coordination", function()
        local fortressGame = FortressGame.new()
        fortressGame:initialize()
        
        -- Test update without errors
        fortressGame:update(0.016) -- ~60 FPS
        
        -- Test multiple updates
        for i = 1, 10 do
            fortressGame:update(0.016)
        end
        
        -- Test performance metrics
        local metrics = fortressGame.gameLoop:getPerformanceMetrics()
        assert(metrics.fps >= 0, "Should have FPS metrics")
        assert(metrics.updateTime >= 0, "Should have update time metrics")
        
        fortressGame:shutdown()
    end)
    
    -- Test 3: System integration and event flow
    runTest("FortressGame: System integration and event communication", function()
        local fortressGame = FortressGame.new()
        fortressGame:initialize()
        
        -- Test resource operations through fortress
        local resourceManager = fortressGame.systems.resourceManager
        local initialMoney = resourceManager:getResource("money")
        
        -- Test resource addition
        resourceManager:addResource("money", 500)
        assert(resourceManager:getResource("money") == initialMoney + 500, "Money should increase")
        
        -- Test security upgrade purchase
        local securityUpgrades = fortressGame.systems.securityUpgrades
        local canPurchase = securityUpgrades:canPurchaseUpgrade("basicFirewall")
        if canPurchase then
            local purchased = securityUpgrades:purchaseUpgrade("basicFirewall")
            assert(purchased, "Should be able to purchase basic firewall")
        end
        
        -- Test threat generation
        local threatSim = fortressGame.systems.threatSimulation
        local threat = threatSim:generateThreat()
        assert(threat ~= nil, "Should generate a threat")
        
        -- Test UI manager notifications
        local uiManager = fortressGame.systems.uiManager
        uiManager:showNotification("Test notification", "info")
        assert(#uiManager.notifications > 0, "Should have notifications")
        
        fortressGame:shutdown()
    end)
    
    -- Test 4: Save and load functionality
    runTest("FortressGame: Save and load system state", function()
        local fortressGame = FortressGame.new()
        fortressGame:initialize()
        
        -- Modify some state
        fortressGame.systems.resourceManager:addResource("money", 1000)
        fortressGame.systems.resourceManager:setGeneration("reputation", 5)
        fortressGame.currentMode = "admin"
        fortressGame.debugMode = true
        
        -- Save state
        local saveData = fortressGame:save()
        assert(saveData ~= nil, "Should generate save data")
        assert(saveData.fortress ~= nil, "Should have fortress state")
        assert(saveData.systems ~= nil, "Should have system states")
        
        -- Create new instance and load
        local fortressGame2 = FortressGame.new()
        fortressGame2:initialize()
        fortressGame2:load(saveData)
        
        -- Verify loaded state
        assert(fortressGame2.currentMode == "admin", "Should load current mode")
        assert(fortressGame2.debugMode == true, "Should load debug mode")
        
        -- Verify system state loaded
        local money = fortressGame2.systems.resourceManager:getResource("money")
        assert(money >= 1000, "Should load resource state")
        
        fortressGame:shutdown()
        fortressGame2:shutdown()
    end)
    
    -- Test 5: Game mode integration
    runTest("FortressGame: Game mode integration and switching", function()
        local fortressGame = FortressGame.new()
        fortressGame:initialize()
        
        -- Test initial mode
        assert(fortressGame.currentMode == "idle", "Should start in idle mode")
        
        -- Test splash screen handling
        assert(fortressGame.flowState == "splash", "Should start in splash state")
        
        -- Simulate key press to advance from splash
        fortressGame:keypressed("space") -- Any key should advance
        assert(fortressGame.flowState == "game", "Should advance to game state")
        
        -- Test mode access
        local idleMode = fortressGame.modes.idle
        assert(idleMode ~= nil, "Should have idle mode")
        
        fortressGame:shutdown()
    end)
    
    -- Test 6: Input handling and controls
    runTest("FortressGame: Input handling and control systems", function()
        local fortressGame = FortressGame.new()
        fortressGame:initialize()
        
        -- Advance from splash
        fortressGame:keypressed("enter")
        
        -- Test pause toggle
        local initialPauseState = fortressGame.gameLoop.isPaused
        fortressGame:keypressed("p")
        assert(fortressGame.gameLoop.isPaused ~= initialPauseState, "Pause state should toggle")
        
        -- Test debug toggle
        local initialDebugState = fortressGame.debugMode
        fortressGame:keypressed("d")
        assert(fortressGame.debugMode ~= initialDebugState, "Debug mode should toggle")
        
        -- Test mouse input (should not crash)
        fortressGame:mousepressed(100, 100, 1)
        
        -- Test resize (should not crash)
        fortressGame:resize(800, 600)
        
        fortressGame:shutdown()
    end)
    
    print("🏰 Fortress Integration Tests Complete")
    print("===================================================")
    print("Tests passed: " .. passed)
    print("Tests failed: " .. failed)
    print("===================================================")
    
    -- Clean up test environment  
    testEnv.cleanup()
    
    return tests, passed, failed
end

return runFortressIntegrationTests
