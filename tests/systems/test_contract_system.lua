-- Tests for Contract System - Idle Sec Ops

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local ContractSystem = require("contract_system")
local EventBus = require("event_bus")

-- Test contract system initialization
TestRunner.test("ContractSystem: Initialize with basic contract", function()
    local eventBus = EventBus.new()
    local contracts = ContractSystem.new(eventBus)
    
    -- Should generate initial contract
    local available = contracts:getAvailableContracts()
    local availableCount = 0
    for _ in pairs(available) do
        availableCount = availableCount + 1
    end
    
    TestRunner.assertEqual(1, availableCount, "Should start with one available contract")
end)

TestRunner.test("ContractSystem: Accept and complete contract", function()
    local eventBus = EventBus.new()
    local contracts = ContractSystem.new(eventBus)
    
    -- Get first available contract
    local available = contracts:getAvailableContracts()
    local contractId = nil
    for id in pairs(available) do
        contractId = id
        break
    end
    
    TestRunner.assertNotNil(contractId, "Should have an available contract")
    
    -- Accept the contract
    local success = contracts:acceptContract(contractId)
    TestRunner.assert(success, "Should successfully accept contract")
    
    -- Check it moved to active contracts
    local active = contracts:getActiveContracts()
    TestRunner.assertNotNil(active[contractId], "Contract should be in active contracts")
    
    -- Complete the contract manually
    success = contracts:completeContract(contractId)
    TestRunner.assert(success, "Should successfully complete contract")
    
    -- Check it's removed from active contracts
    active = contracts:getActiveContracts()
    TestRunner.assertEqual(nil, active[contractId], "Contract should be removed from active contracts")
end)

TestRunner.test("ContractSystem: Contract income generation", function()
    local eventBus = EventBus.new()
    local contracts = ContractSystem.new(eventBus)
    
    -- Accept a contract
    local available = contracts:getAvailableContracts()
    local contractId = nil
    for id in pairs(available) do
        contractId = id
        break
    end
    
    contracts:acceptContract(contractId)
    
    -- Get income rate
    local incomeRate = contracts:getTotalIncomeRate()
    TestRunner.assert(incomeRate > 0, "Should have positive income rate from active contract")
    
    -- Test contract stats
    local stats = contracts:getStats()
    TestRunner.assertEqual(1, stats.activeContracts, "Should have 1 active contract")
    TestRunner.assertEqual(0, stats.availableContracts, "Should have 0 available contracts")
end)