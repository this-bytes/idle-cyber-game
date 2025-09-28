-- Test suite for SOC Stats System
-- SOC REFACTOR: Validate the statistical backbone of the Security Operations Centre

local test_module = {}

function test_module.run_soc_stats_tests()
    print("🛡️ Testing SOC Stats System...")
    
    -- Set up test environment
    local testEnv = require("tests.test_environment")
    testEnv.setup()
    
    -- Import required systems
    local SOCStats = require("src.core.soc_stats")
    local EventBus = require("src.utils.event_bus")
    local ResourceManager = require("src.core.resource_manager")
    local SecurityUpgrades = require("src.core.security_upgrades")
    local ThreatSimulation = require("src.core.threat_simulation")
    
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
    end
    
    -- Test 1: SOC Stats initialization and baseline capabilities
    runTest("SOC Stats: Initialization and baseline capabilities", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Test baseline capabilities exist
        local defenseCapability = socStats:getCapability("defense")
        assert(defenseCapability > 0, "Should have baseline defense capability")
        assert(defenseCapability == 15, "Defense should start at 15, got " .. defenseCapability)
        
        local offenseCapability = socStats:getCapability("offense")
        assert(offenseCapability == 5, "Offense should start at 5, got " .. offenseCapability)
        
        local detectionCapability = socStats:getCapability("detection")
        assert(detectionCapability == 8, "Detection should start at 8, got " .. detectionCapability)
        
        local analysisCapability = socStats:getCapability("analysis")
        assert(analysisCapability == 12, "Analysis should start at 12, got " .. analysisCapability)
    end)
    
    -- Test 2: Equipment capabilities from security upgrades
    runTest("SOC Stats: Equipment capabilities from upgrades", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        resourceManager:initialize()
        securityUpgrades:initialize()
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Get baseline defense
        local baselineDefense = socStats:getCapability("defense")
        
        -- Purchase basic firewall (should boost defense and detection)
        resourceManager:addResource("money", 1000)
        local purchased = securityUpgrades:purchaseUpgrade("basicFirewall")
        assert(purchased, "Should be able to purchase basic firewall")
        
        -- Defense should increase due to equipment bonus
        local newDefense = socStats:getCapability("defense")
        assert(newDefense > baselineDefense, "Defense should increase after firewall purchase")
        
        -- Detection should also increase
        local detection = socStats:getCapability("detection")
        assert(detection >= 10, "Detection should improve with firewall")
    end)
    
    -- Test 3: Personnel capabilities scaling
    runTest("SOC Stats: Personnel capabilities scaling", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        resourceManager:initialize()
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Get baseline coordination
        local baselineCoordination = socStats:getCapability("coordination")
        
        -- Add specialists (simulate hiring)
        resourceManager:addResource("specialists", 2) -- Total 3 specialists
        socStats:updatePersonnelCapabilities()
        socStats:recalculateCapabilities()  -- Need to recalculate after personnel change
        
        -- Coordination should improve with more personnel
        local newCoordination = socStats:getCapability("coordination")
        assert(newCoordination > baselineCoordination, "Coordination should improve with more specialists (" .. newCoordination .. " vs " .. baselineCoordination .. ")")
    end)
    
    -- Test 4: Experience gain from threat resolution
    runTest("SOC Stats: Experience gain from incidents", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Get baseline capabilities
        local baselineDefense = socStats:getCapability("defense")
        local baselineAnalysis = socStats:getCapability("analysis")
        
        -- Simulate threat resolution
        socStats:gainExperience("malware", 2)
        
        -- Capabilities should improve slightly
        local newDefense = socStats:getCapability("defense")
        local newAnalysis = socStats:getCapability("analysis")
        
        assert(newDefense >= baselineDefense, "Defense should not decrease from experience")
        assert(newAnalysis >= baselineAnalysis, "Analysis should not decrease from experience")
    end)
    
    -- Test 5: SOC status and recommendations
    runTest("SOC Stats: Status reporting and recommendations", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Get SOC status
        local status = socStats:getSOCStatus()
        
        assert(status.capabilities ~= nil, "Should have capabilities in status")
        assert(status.metrics ~= nil, "Should have metrics in status")
        assert(status.overallRating > 0, "Should have overall rating")
        assert(status.recommendations ~= nil, "Should have recommendations")
        
        -- Check that all capability types are present
        for capType, _ in pairs({offense=1, defense=1, detection=1, analysis=1, coordination=1, automation=1}) do
            assert(status.capabilities[capType] ~= nil, "Should have " .. capType .. " capability")
            assert(status.capabilities[capType].value > 0, capType .. " should have positive value")
            assert(status.capabilities[capType].tier ~= nil, capType .. " should have tier")
        end
    end)
    
    -- Test 6: State save and load
    runTest("SOC Stats: State persistence", function()
        local eventBus = EventBus.new()
        local resourceManager = ResourceManager.new(eventBus)
        local securityUpgrades = SecurityUpgrades.new(eventBus, resourceManager)
        local threatSim = ThreatSimulation.new(eventBus, resourceManager, securityUpgrades)
        
        local socStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        socStats:initialize()
        
        -- Modify some capabilities
        socStats:improveCapability("offense", 10)
        socStats.metrics.incidentsHandled = 5
        
        local originalOffense = socStats:getCapability("offense")
        local originalIncidents = socStats.metrics.incidentsHandled
        
        -- Save state
        local savedState = socStats:saveState()
        
        -- Create new instance and load state
        local newSOCStats = SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSim)
        newSOCStats:loadState(savedState)
        
        -- Verify state was preserved
        local loadedOffense = newSOCStats:getCapability("offense")
        local loadedIncidents = newSOCStats.metrics.incidentsHandled
        
        assert(loadedOffense == originalOffense, "Offense capability should be preserved")
        assert(loadedIncidents == originalIncidents, "Incidents handled should be preserved")
    end)
    
    
    -- Clean up test environment  
    testEnv.cleanup()
    
    return passed, failed
end

return test_module