-- Test file for SOCGame
-- Tests the new SOC-focused game architecture

local SOCGame = require("src.soc_game")

-- Test SOC game initialization
TestRunner.test("SOCGame - Initialization", function()
    local socGame = SOCGame.new()
    
    TestRunner.assertNotNil(socGame, "SOCGame should initialize")
    TestRunner.assertEqual(socGame.initialized, false, "Should start uninitialized")
    TestRunner.assertNotNil(socGame.socOperations, "Should have SOC operations state")
    TestRunner.assertEqual(socGame.socOperations.operationalLevel, "STARTING", "Should start at STARTING level")
end)

-- Test SOC operational level progression
TestRunner.test("SOCGame - Operational Level Progression", function()
    local socGame = SOCGame.new()
    
    -- Mock resource manager for testing
    socGame.systems = {
        resourceManager = {
            getResource = function(self, resource)
                if resource == "reputation" then return 15 end
                return 0
            end
        }
    }
    
    -- Simulate operations to trigger level progression
    socGame.socOperations.totalThreatsHandled = 5
    socGame.socOperations.totalIncidentsResolved = 5
    
    socGame:updateOperationalLevel()
    
    TestRunner.assertEqual(socGame.socOperations.operationalLevel, "BASIC", "Should progress to BASIC level")
end)

-- Test SOC statistics tracking
TestRunner.test("SOCGame - Statistics Tracking", function()
    local socGame = SOCGame.new()
    
    -- Set some test values
    socGame.socOperations.totalThreatsHandled = 25
    socGame.socOperations.totalIncidentsResolved = 15
    socGame.socOperations.operationalLevel = "ADVANCED"
    
    local stats = socGame:getSOCStats()
    
    TestRunner.assertNotNil(stats, "Should return statistics")
    TestRunner.assertEqual(stats.threatsHandled, 25, "Should track threats handled")
    TestRunner.assertEqual(stats.incidentsResolved, 15, "Should track incidents resolved")
    TestRunner.assertEqual(stats.operationalLevel, "ADVANCED", "Should track operational level")
    TestRunner.assertNotNil(stats.uptime, "Should track uptime")
end)

-- Test SOC state save/load structure
TestRunner.test("SOCGame - Save Structure", function()
    local socGame = SOCGame.new()
    
    -- Set some test state
    socGame.socOperations.totalThreatsHandled = 10
    socGame.socOperations.operationalLevel = "BASIC"
    
    -- Mock save system for testing
    socGame.saveSystem = {
        save = function(self, data)
            TestRunner.assertNotNil(data.socOperations, "Should save SOC operations")
            TestRunner.assertEqual(data.socOperations.totalThreatsHandled, 10, "Should save threat count")
            TestRunner.assertEqual(data.socOperations.operationalLevel, "BASIC", "Should save operational level")
            return true
        end
    }
    
    local success = socGame:saveGame()
    TestRunner.assertEqual(success, true, "Should save successfully")
end)

-- Test event integration
TestRunner.test("SOCGame - Event Integration", function()
    local socGame = SOCGame.new()
    socGame:initializeCore()
    
    local eventReceived = false
    
    -- Subscribe to test event
    socGame.eventBus:subscribe("test_event", function(data)
        eventReceived = true
    end)
    
    -- Publish test event
    socGame.eventBus:publish("test_event", {test = true})
    
    TestRunner.assertEqual(eventReceived, true, "Should handle events through event bus")
end)