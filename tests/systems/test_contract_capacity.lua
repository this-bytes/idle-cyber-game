-- Test file for Contract Capacity Management
-- Tests capacity calculation, performance degradation, and capacity limits

local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local DataManager = require("src.systems.data_manager")
local ResourceManager = require("src.systems.resource_manager")
local SkillSystem = require("src.systems.skill_system")
local EventBus = require("src.utils.event_bus")

-- Test capacity calculation with no specialists
TestRunner.test("ContractCapacity - No Specialists", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    
    local capacity = contractSystem:calculateWorkloadCapacity()
    TestRunner.assertEqual(capacity, 1, "Minimum capacity should be 1")
end)

-- Test capacity calculation with specialists
TestRunner.test("ContractCapacity - With Specialists", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    
    -- Add 5 specialists (1 contract capacity)
    for i = 1, 5 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    local capacity = contractSystem:calculateWorkloadCapacity()
    TestRunner.assertEqual(capacity, 1, "5 specialists should give 1 capacity")
    
    -- Add 5 more specialists (2 contract capacity)
    for i = 6, 10 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    capacity = contractSystem:calculateWorkloadCapacity()
    TestRunner.assertEqual(capacity, 2, "10 specialists should give 2 capacity")
end)

-- Test average specialist efficiency
TestRunner.test("ContractCapacity - Average Efficiency", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    
    -- Test with no specialists
    local avgEfficiency = contractSystem:getAverageSpecialistEfficiency()
    TestRunner.assertEqual(avgEfficiency, 1.0, "No specialists should have 1.0 efficiency")
    
    -- Add level 1 specialists (1.0 efficiency each)
    for i = 1, 5 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    avgEfficiency = contractSystem:getAverageSpecialistEfficiency()
    TestRunner.assertEqual(avgEfficiency, 1.0, "Level 1 specialists should have 1.0 efficiency")
    
    -- Add higher level specialists
    table.insert(specialistSystem.specialists, {
        id = 6,
        name = "Senior Specialist",
        level = 5
    })
    
    avgEfficiency = contractSystem:getAverageSpecialistEfficiency()
    TestRunner.assert(avgEfficiency > 1.0, "Higher level specialists should increase efficiency")
end)

-- Test performance multiplier at capacity
TestRunner.test("ContractCapacity - Performance at Capacity", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    contractSystem:initialize()
    
    -- Add 10 specialists (2 capacity)
    for i = 1, 10 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    -- No active contracts - should be 100%
    local multiplier = contractSystem:getPerformanceMultiplier()
    TestRunner.assertEqual(multiplier, 1.0, "No contracts should have 100% performance")
    
    -- Add 2 contracts (at capacity)
    contractSystem.activeContracts[1] = { id = 1, reward = 1000, duration = 60 }
    contractSystem.activeContracts[2] = { id = 2, reward = 1000, duration = 60 }
    
    multiplier = contractSystem:getPerformanceMultiplier()
    TestRunner.assertEqual(multiplier, 1.0, "At capacity should have 100% performance")
end)

-- Test performance degradation when over capacity
TestRunner.test("ContractCapacity - Performance Degradation", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    contractSystem:initialize()
    
    -- Add 5 specialists (1 capacity)
    for i = 1, 5 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    -- Add 2 contracts (1 over capacity)
    contractSystem.activeContracts[1] = { id = 1, reward = 1000, duration = 60 }
    contractSystem.activeContracts[2] = { id = 2, reward = 1000, duration = 60 }
    
    local multiplier = contractSystem:getPerformanceMultiplier()
    TestRunner.assertEqual(multiplier, 0.85, "1 over capacity should be 85% performance")
    
    -- Add 3rd contract (2 over capacity)
    contractSystem.activeContracts[3] = { id = 3, reward = 1000, duration = 60 }
    
    multiplier = contractSystem:getPerformanceMultiplier()
    TestRunner.assertEqual(multiplier, 0.70, "2 over capacity should be 70% performance")
    
    -- Add 4th contract (3 over capacity)
    contractSystem.activeContracts[4] = { id = 4, reward = 1000, duration = 60 }
    
    multiplier = contractSystem:getPerformanceMultiplier()
    TestRunner.assertEqual(multiplier, 0.50, "3+ over capacity should be 50% performance minimum")
end)

-- Test canAcceptContract validation
TestRunner.test("ContractCapacity - Accept Validation", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    contractSystem:initialize()
    
    -- Add 5 specialists (1 capacity)
    for i = 1, 5 do
        table.insert(specialistSystem.specialists, {
            id = i,
            name = "Specialist " .. i,
            level = 1
        })
    end
    
    local testContract = { id = 1 }
    
    -- Should accept first contract
    local canAccept, message = contractSystem:canAcceptContract(testContract)
    TestRunner.assertEqual(canAccept, true, "Should accept first contract")
    TestRunner.assertEqual(message, "OK", "Should return OK message")
    
    -- Add contract to active
    contractSystem.activeContracts[1] = { id = 1 }
    
    -- Should accept second with warning
    canAccept, message = contractSystem:canAcceptContract(testContract)
    TestRunner.assertEqual(canAccept, true, "Should accept second contract with warning")
    TestRunner.assert(message:find("WARNING") ~= nil, "Should include warning in message")
    
    -- Add 3 more contracts (4 total, 3 over capacity)
    contractSystem.activeContracts[2] = { id = 2 }
    contractSystem.activeContracts[3] = { id = 3 }
    contractSystem.activeContracts[4] = { id = 4 }
    
    -- Should reject
    canAccept, message = contractSystem:canAcceptContract(testContract)
    TestRunner.assertEqual(canAccept, false, "Should reject at max overload")
    TestRunner.assert(message:find("Maximum") ~= nil, "Should indicate maximum capacity")
end)

-- Test state management
TestRunner.test("ContractCapacity - State Management", function()
    local eventBus = EventBus.new()
    local dataManager = DataManager.new(eventBus)
    dataManager:loadAllData()
    local resourceManager = ResourceManager.new(eventBus)
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    local upgradeSystem = UpgradeSystem.new(eventBus, dataManager)
    
    local contractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    contractSystem:initialize()
    
    -- Set some state
    contractSystem.autoAcceptEnabled = false
    contractSystem.maxActiveContracts = 5
    
    -- Get state
    local state = contractSystem:getState()
    TestRunner.assertNotNil(state, "Should return state")
    TestRunner.assertEqual(state.autoAcceptEnabled, false, "Should save auto-accept setting")
    TestRunner.assertEqual(state.maxActiveContracts, 5, "Should save max active contracts")
    
    -- Create new system and load state
    local newContractSystem = ContractSystem.new(eventBus, dataManager, upgradeSystem, specialistSystem, nil, nil, resourceManager)
    newContractSystem:loadState(state)
    
    TestRunner.assertEqual(newContractSystem.autoAcceptEnabled, false, "Should load auto-accept setting")
    TestRunner.assertEqual(newContractSystem.maxActiveContracts, 5, "Should load max active contracts")
end)
