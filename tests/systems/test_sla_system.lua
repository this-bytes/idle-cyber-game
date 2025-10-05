-- Test file for SLASystem
-- Tests SLA tracking, compliance scoring, and reward/penalty calculation

local SLASystem = require("src.systems.sla_system")
local ContractSystem = require("src.systems.contract_system")
local ResourceManager = require("src.systems.resource_manager")
local DataManager = require("src.systems.data_manager")
local EventBus = require("src.utils.event_bus")

-- Test SLA system initialization
TestRunner.test("SLASystem - Initialization", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    
    TestRunner.assertNotNil(slaSystem, "SLASystem should initialize")
    TestRunner.assertNotNil(slaSystem.config, "Should have config")
    TestRunner.assertNotNil(slaSystem.metrics, "Should have metrics")
    TestRunner.assertEqual(type(slaSystem.contractSLAs), "table", "Contract SLAs should be a table")
end)

-- Test SLA initialization with config loading
TestRunner.test("SLASystem - Config Loading", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    slaSystem:initialize()
    
    TestRunner.assertNotNil(slaSystem.config.complianceThresholds, "Should have compliance thresholds")
    TestRunner.assertEqual(type(slaSystem.config.complianceThresholds.excellent), "number", "Excellent threshold should be a number")
end)

-- Test contract SLA tracking on acceptance
TestRunner.test("SLASystem - Contract Tracking on Accept", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    slaSystem:initialize()
    
    -- Simulate contract acceptance
    local testContract = {
        id = 1,
        clientName = "Test Client",
        slaRequirements = {
            maxAllowedIncidents = 10
        }
    }
    
    eventBus:publish("contract_accepted", { contract = testContract })
    
    -- Give a moment for event processing
    local tracker = slaSystem:getContractSLA(1)
    TestRunner.assertNotNil(tracker, "Should track accepted contract")
    TestRunner.assertEqual(tracker.contractId, 1, "Should track correct contract ID")
    TestRunner.assertEqual(tracker.active, true, "Contract should be active")
    TestRunner.assertEqual(tracker.incidentCount, 0, "Should start with 0 incidents")
end)

-- Test compliance score calculation
TestRunner.test("SLASystem - Compliance Score Calculation", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    
    -- Test perfect compliance
    local perfectTracker = {
        slaRequirements = { maxAllowedIncidents = 10 },
        incidentCount = 0,
        breachCount = 0
    }
    local perfectScore = slaSystem:calculateComplianceScore(perfectTracker)
    TestRunner.assertEqual(perfectScore, 1.0, "Perfect compliance should score 1.0")
    
    -- Test with incidents under limit
    local goodTracker = {
        slaRequirements = { maxAllowedIncidents = 10 },
        incidentCount = 8,
        breachCount = 0
    }
    local goodScore = slaSystem:calculateComplianceScore(goodTracker)
    TestRunner.assertEqual(goodScore, 1.0, "Under limit should score 1.0")
    
    -- Test with incidents over limit
    local badTracker = {
        slaRequirements = { maxAllowedIncidents = 10 },
        incidentCount = 15,
        breachCount = 0
    }
    local badScore = slaSystem:calculateComplianceScore(badTracker)
    TestRunner.assert(badScore < 1.0, "Over limit should reduce score")
    TestRunner.assert(badScore >= 0.5, "Score should not drop below minimum")
end)

-- Test incident recording
TestRunner.test("SLASystem - Incident Recording", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    slaSystem:initialize()
    
    -- Create a tracked contract
    local testContract = {
        id = 1,
        slaRequirements = { maxAllowedIncidents = 5 }
    }
    eventBus:publish("contract_accepted", { contract = testContract })
    
    -- Record incidents
    slaSystem:recordIncident(1, "security_breach")
    slaSystem:recordIncident(1, "security_breach")
    
    local tracker = slaSystem:getContractSLA(1)
    TestRunner.assertEqual(tracker.incidentCount, 2, "Should record incidents")
    TestRunner.assertEqual(tracker.breachCount, 0, "Should not breach yet")
    
    -- Record enough to breach
    for i = 1, 5 do
        slaSystem:recordIncident(1, "security_breach")
    end
    
    tracker = slaSystem:getContractSLA(1)
    TestRunner.assert(tracker.incidentCount > 5, "Should have many incidents")
    TestRunner.assert(tracker.breachCount > 0, "Should have breach recorded")
end)

-- Test state management
TestRunner.test("SLASystem - State Management", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    slaSystem:initialize()
    
    -- Add some test data
    slaSystem.metrics.totalContracts = 10
    slaSystem.metrics.compliantContracts = 8
    
    -- Get state
    local state = slaSystem:getState()
    TestRunner.assertNotNil(state, "Should return state")
    TestRunner.assertEqual(state.metrics.totalContracts, 10, "Should save metrics")
    
    -- Create new system and load state
    local newSlaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    newSlaSystem:loadState(state)
    
    TestRunner.assertEqual(newSlaSystem.metrics.totalContracts, 10, "Should load metrics")
    TestRunner.assertEqual(newSlaSystem.metrics.compliantContracts, 8, "Should load all metrics")
end)

-- Test compliance rating
TestRunner.test("SLASystem - Compliance Rating", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local contractSystem = ContractSystem.new(eventBus, dataManager, nil, nil, nil, nil, resourceManager)
    
    local slaSystem = SLASystem.new(eventBus, contractSystem, resourceManager, dataManager)
    
    TestRunner.assertEqual(slaSystem:getComplianceRating(0.96), "EXCELLENT", "Should rate excellent")
    TestRunner.assertEqual(slaSystem:getComplianceRating(0.88), "GOOD", "Should rate good")
    TestRunner.assertEqual(slaSystem:getComplianceRating(0.78), "ACCEPTABLE", "Should rate acceptable")
    TestRunner.assertEqual(slaSystem:getComplianceRating(0.65), "POOR", "Should rate poor")
    TestRunner.assertEqual(slaSystem:getComplianceRating(0.45), "CRITICAL", "Should rate critical")
end)
