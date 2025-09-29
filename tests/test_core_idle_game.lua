-- Test suite for core idle game mechanics
-- Validates that the simplified IdleGame works correctly

local function runCoreIdleGameTests()
    print("💼 Testing Core Idle Game Mechanics...")
    
    -- Set up test environment
    package.path = package.path .. ';./?.lua'
    
    -- Mock Love2D functions for testing
    love = {
        timer = {
            getTime = function() return os.time() end
        },
        filesystem = {
            getInfo = function(path) 
                local f = io.open(path, 'r')
                if f then 
                    f:close()
                    return true 
                end
                return false
            end,
            read = function(path)
                local f = io.open(path, 'r')
                if f then
                    local content = f:read('*all')
                    f:close()
                    return content
                end
                return nil
            end
        },
        graphics = {
            getDimensions = function() return 800, 600 end,
            setColor = function() end,
            rectangle = function() end,
            print = function() end,
            printf = function() end
        }
    }
    
    -- Import IdleGame
    local IdleGame = require("src.idle_game")
    
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
    
    -- Test 1: IdleGame creation and initialization
    runTest("IdleGame: Creation and initialization", function()
        local game = IdleGame.new()
        
        -- Test initial state
        assert(not game.initialized, "Should not be initialized initially")
        assert(game.currentState == "splash", "Should start in splash state")
        assert(game.resources.money == 1000, "Should start with $1000")
        assert(game.resources.reputation == 10, "Should start with 10 reputation")
        
        -- Test initialization
        local success = game:initialize()
        assert(success, "Initialization should succeed")
        assert(game.initialized, "Should be initialized after init")
    end)
    
    -- Test 2: Money generation rate calculation
    runTest("IdleGame: Money generation rate calculation", function()
        local game = IdleGame.new()
        game:initialize()
        
        -- Test base rate calculation
        local expectedRate = 10 + (game.resources.reputation * 0.5) -- $10 base + $0.50 per reputation
        assert(game.moneyGeneration.baseRate == expectedRate, 
               "Money generation rate should be $" .. expectedRate .. "/sec, got " .. game.moneyGeneration.baseRate)
        
        -- Test rate update when reputation changes
        game.resources.reputation = 20
        game:updateMoneyGenerationRate()
        local newExpectedRate = 10 + (20 * 0.5) -- $10 base + $10 reputation bonus = $20/sec
        assert(game.moneyGeneration.baseRate == newExpectedRate,
               "Updated money generation rate should be $" .. newExpectedRate .. "/sec")
    end)
    
    -- Test 3: Contract loading from JSON
    runTest("IdleGame: Contract loading from JSON", function()
        local game = IdleGame.new()
        game:initialize()
        
        -- Should have loaded at least 1 contract
        assert(#game.contracts > 0, "Should load contracts from JSON file")
        
        -- Check first contract structure
        local contract = game.contracts[1]
        assert(contract.id ~= nil, "Contract should have an ID")
        assert(contract.clientName ~= nil, "Contract should have a client name")
        assert(contract.baseBudget ~= nil, "Contract should have a budget")
        assert(contract.reputationReward ~= nil, "Contract should have reputation reward")
    end)
    
    -- Test 4: Contract starting and completion
    runTest("IdleGame: Contract starting and completion", function()
        local game = IdleGame.new()
        game:initialize()
        
        -- Should start with no active contract
        assert(game.activeContract == nil, "Should start with no active contract")
        
        -- Start a contract
        game:startContract(1)
        assert(game.activeContract ~= nil, "Should have active contract after starting")
        assert(game.activeContract.clientName ~= nil, "Active contract should have client name")
        
        -- Complete the contract manually
        local initialMoney = game.resources.money
        local initialReputation = game.resources.reputation
        
        game:completeContract(game.activeContract)
        
        assert(game.resources.money > initialMoney, "Money should increase after completing contract")
        assert(game.resources.reputation > initialReputation, "Reputation should increase after completing contract")
    end)
    
    -- Test 5: Auto-contract system
    runTest("IdleGame: Auto-contract system", function()
        local game = IdleGame.new()
        game:initialize()
        
        -- Should start disabled
        assert(not game.autoContracts.enabled, "Auto-contracts should start disabled")
        
        -- Test enabling
        game.autoContracts.enabled = true
        assert(game.autoContracts.enabled, "Should be able to enable auto-contracts")
        
        -- Test auto-contract completion
        local initialMoney = game.resources.money
        local initialReputation = game.resources.reputation
        
        game:completeAutoContract()
        
        assert(game.resources.money > initialMoney, "Money should increase from auto-contract")
        assert(game.resources.reputation > initialReputation, "Reputation should increase from auto-contract")
    end)
    
    -- Test 6: Game state transitions
    runTest("IdleGame: Game state transitions", function()
        local game = IdleGame.new()
        game:initialize()
        
        -- Should start in splash state
        assert(game.currentState == "splash", "Should start in splash state")
        
        -- Test advancing to game
        game:advanceToGame()
        
        -- Should transition to either playing or offline modal
        assert(game.currentState == "playing" or game.currentState == "offline_modal", 
               "Should transition to playing or offline modal state")
    end)
    
    -- Test 7: Offline progress calculation
    runTest("IdleGame: Offline progress calculation", function()
        local game = IdleGame.new()
        
        -- Set last save time to simulate being offline for 2 minutes
        game.offline.lastSaveTime = love.timer.getTime() - 120 -- 2 minutes ago
        
        game:initialize()
        
        -- Should show offline modal for being away > 30 seconds
        assert(game.offline.showModal, "Should show offline modal after being away > 30 seconds")
        assert(game.offline.moneyEarned > 0, "Should have earned money while offline")
        assert(game.offline.contractsCompleted > 0, "Should have completed contracts while offline")
    end)
    
    -- Print test results
    print("\n💼 Core Idle Game Test Results:")
    print("✅ Passed: " .. passed)
    print("❌ Failed: " .. failed)
    print("📊 Total: " .. (passed + failed))
    
    if failed == 0 then
        print("🎉 All core idle game tests passed!")
        return true
    else
        print("⚠️ Some tests failed. Check implementation.")
        return false
    end
end

-- Run tests if called directly
if debug.getinfo(2) == nil then
    runCoreIdleGameTests()
end

return {
    runCoreIdleGameTests = runCoreIdleGameTests
}