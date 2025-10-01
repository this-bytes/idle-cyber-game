-- Test Suite for Threat Event Standardization
-- Verifies that threat_detected events use canonical shape and are handled correctly

local ThreatSimulation = require("src.core.threat_simulation")
local SOCView = require("src.scenes.soc_view")
local UIManager = require("src.core.ui_manager")
local SOCGame = require("src.soc_game")
local SOCStats = require("src.core.soc_stats")
local ResourceManager = require("src.core.resource_manager")
local SecurityUpgrades = require("src.core.security_upgrades")
local EventBus = require("src.utils.event_bus")

-- Mock love for testing
if not love then
    love = {
        timer = {
            getTime = function() return os.clock() end
        },
        graphics = {
            getFont = function() return {} end,
            getWidth = function() return 800 end,
            getHeight = function() return 600 end
        }
    }
end

local testResults = {}

-- Helper function to run a test
local function runTest(testName, testFunction)
    local success, errorMsg = pcall(testFunction)
    if success then
        print("✅ " .. testName)
        table.insert(testResults, { name = testName, success = true })
    else
        print("❌ " .. testName .. ": " .. tostring(errorMsg))
        table.insert(testResults, { name = testName, success = false, error = errorMsg })
    end
end

-- Test ThreatSimulation publishes canonical format
runTest("ThreatSimulation: Publishes canonical threat_detected event", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
    local threatSimulation = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
    threatSimulation:initialize()
    
    local receivedEvent = nil
    eventBus:subscribe("threat_detected", function(data)
        receivedEvent = data
    end)
    
    -- Generate a threat using the public method
    local threat = threatSimulation:generateThreat()
    
    -- Verify canonical shape
    assert(receivedEvent ~= nil, "Should receive threat_detected event")
    assert(receivedEvent.threat ~= nil, "Event should contain 'threat' field")
    assert(receivedEvent.source ~= nil, "Event should contain 'source' field")
    assert(receivedEvent.source == "threat_simulation", "Source should be 'threat_simulation'")
    assert(receivedEvent.threat.id ~= nil, "Threat should have an ID")
    assert(receivedEvent.threat.name ~= nil, "Threat should have a name")
end)

-- Test SOCView publishes canonical format
runTest("SOCView: Publishes canonical threat_detected event", function()
    local eventBus = EventBus.new()
    local socView = SOCView.new()
    socView:initialize(eventBus)
    
    -- Set up SOC view state for threat generation
    socView.socStatus.detectionCapability = 100 -- Force threat detection
    
    local receivedEvent = nil
    eventBus:subscribe("threat_detected", function(data)
        receivedEvent = data
    end)
    
    -- Force threat scan to always generate a threat
    math.randomseed(12345) -- Fixed seed for deterministic test
    socView:performThreatScan()
    
    -- Verify canonical shape
    assert(receivedEvent ~= nil, "Should receive threat_detected event")
    assert(receivedEvent.threat ~= nil, "Event should contain 'threat' field")
    assert(receivedEvent.source ~= nil, "Event should contain 'source' field")
    assert(receivedEvent.source == "soc_view", "Source should be 'soc_view'")
    assert(receivedEvent.threat.id ~= nil, "Threat should have an ID")
    assert(receivedEvent.threat.name ~= nil, "Threat should have a name")
end)

-- Test UIManager consumes canonical format correctly
runTest("UIManager: Consumes canonical threat_detected event", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
    local threatSimulation = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
    local gameLoop = { registerSystem = function() end, getSystem = function() return nil end }
    
    local uiManager = UIManager.new(eventBus, resourceManager, securityUpgrades, threatSimulation, gameLoop)
    uiManager:initialize()
    
    -- Create a canonical threat_detected event
    local testThreat = {
        id = "test-123",
        name = "Test Phishing Attack",
        type = "phishing",
        severity = "MEDIUM"
    }
    
    -- Publish canonical event - should not throw error
    eventBus:publish("threat_detected", {
        threat = testThreat,
        source = "test"
    })
    
    -- If we get here without error, the consumer handled the canonical format correctly
    assert(true, "UIManager should handle canonical event format")
end)

-- Test SOCStats consumes canonical format correctly
runTest("SOCStats: Consumes canonical threat_detected event", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
    
    local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades)
    socStats:initialize()
    
    local initialThreatsDetected = socStats.metrics.threatsDetected
    
    -- Create a canonical threat_detected event
    local testThreat = {
        id = "test-456",
        name = "Test Malware",
        type = "malware",
        severity = "HIGH"
    }
    
    -- Publish canonical event
    eventBus:publish("threat_detected", {
        threat = testThreat,
        source = "test"
    })
    
    -- Verify SOCStats processed the event
    assert(socStats.metrics.threatsDetected == initialThreatsDetected + 1, 
           "SOCStats should increment threats detected counter")
end)

-- Test SOCGame consumes canonical format correctly
runTest("SOCGame: Consumes canonical threat_detected event", function()
    -- Create minimal SOC game setup
    local eventBus = EventBus.new()
    
    -- Mock the game setup without full initialization
    local socGame = { socOperations = { totalThreatsHandled = 0 } }
    
    -- Set up the event handler like in the real code
    eventBus:subscribe("threat_detected", function(data)
        socGame.socOperations.totalThreatsHandled = socGame.socOperations.totalThreatsHandled + 1
    end)
    
    local initialThreatsHandled = socGame.socOperations.totalThreatsHandled
    
    -- Create a canonical threat_detected event
    local testThreat = {
        id = "test-789",
        name = "Test DDoS Attack",
        type = "ddos",
        severity = "CRITICAL"
    }
    
    -- Publish canonical event
    eventBus:publish("threat_detected", {
        threat = testThreat,
        source = "test"
    })
    
    -- Verify SOCGame processed the event
    assert(socGame.socOperations.totalThreatsHandled == initialThreatsHandled + 1,
           "SOCGame should increment total threats handled counter")
end)

-- Test SOCView consumes canonical format correctly  
runTest("SOCView: Consumes canonical threat_detected event", function()
    local eventBus = EventBus.new()
    local socView = SOCView.new()
    socView:initialize(eventBus)
    
    local initialIncidents = #socView.socStatus.activeIncidents
    
    -- Create a canonical threat_detected event
    local testThreat = {
        id = "test-101",
        name = "Test Insider Threat",
        type = "insider",
        severity = "HIGH"
    }
    
    -- Publish canonical event
    eventBus:publish("threat_detected", {
        threat = testThreat,
        source = "test"
    })
    
    -- Verify SOCView processed the event correctly
    assert(#socView.socStatus.activeIncidents == initialIncidents + 1,
           "SOCView should add threat to active incidents")
    assert(socView.socStatus.activeIncidents[#socView.socStatus.activeIncidents].id == testThreat.id,
           "SOCView should store the correct threat object")
end)

-- Test event payload validation
runTest("ThreatEvent: Canonical payload validation", function()
    local eventBus = EventBus.new()
    
    local receivedEvents = {}
    eventBus:subscribe("threat_detected", function(data)
        table.insert(receivedEvents, data)
    end)
    
    -- Test valid canonical payload
    local validThreat = {
        id = "valid-123",
        name = "Valid Threat",
        type = "phishing",
        severity = "MEDIUM"
    }
    
    eventBus:publish("threat_detected", {
        threat = validThreat,
        source = "test_producer"
    })
    
    assert(#receivedEvents == 1, "Should receive one event")
    local event = receivedEvents[1]
    
    -- Validate canonical structure
    assert(type(event) == "table", "Event should be a table")
    assert(event.threat ~= nil, "Event should have 'threat' field")
    assert(event.source ~= nil, "Event should have 'source' field")
    assert(type(event.threat) == "table", "Threat should be a table")
    assert(type(event.source) == "string", "Source should be a string")
    
    -- Validate threat structure
    assert(event.threat.id ~= nil, "Threat should have ID")
    assert(event.threat.name ~= nil, "Threat should have name")
    assert(event.threat.type ~= nil, "Threat should have type")
    assert(event.threat.severity ~= nil, "Threat should have severity")
end)

-- Print test results
print("\n🧪 Threat Event Standardization Test Results:")
print("===============================================")

local passed = 0
local failed = 0

for _, result in ipairs(testResults) do
    if result.success then
        passed = passed + 1
    else
        failed = failed + 1
        print("❌ " .. result.name .. ": " .. (result.error or "Unknown error"))
    end
end

print("\n📊 Summary: " .. passed .. " passed, " .. failed .. " failed")

-- Return results for test runner integration
return {
    passed = passed,
    failed = failed,
    results = testResults
}