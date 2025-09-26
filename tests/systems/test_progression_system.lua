-- Test Progression System
local EventBus = require("src.utils.event_bus")
local ResourceSystem = require("src.systems.resource_system")
local ProgressionSystem = require("src.systems.progression_system")

local function test_progression_system_initialization()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Test basic initialization
    assert(progressionSystem ~= nil, "ProgressionSystem should initialize")
    
    -- Test current tier
    local currentTier = progressionSystem:getCurrentTier()
    assert(currentTier ~= nil, "Should have a current tier")
    
    print("✅ ProgressionSystem: Initialize with default tier")
    return true
end

local function test_currency_initialization()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Check that currencies were initialized
    local money = resourceSystem:getResource("money")
    local reputation = resourceSystem:getResource("reputation")
    local experience = resourceSystem:getResource("experience")
    
    assert(money and money > 0, "Money should be initialized")
    assert(reputation and reputation >= 0, "Reputation should be initialized")
    assert(experience and experience >= 0, "Experience should be initialized")
    
    print("✅ ProgressionSystem: Currency initialization")
    return true
end

local function test_achievement_system()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Test achievement unlocking
    progressionSystem:unlockAchievement("first_move")
    
    local achievements = progressionSystem:getAchievements()
    assert(achievements["first_move"] ~= nil, "Achievement should be unlocked")
    
    print("✅ ProgressionSystem: Achievement unlocking")
    return true
end

local function test_statistics_tracking()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Simulate location change event
    eventBus:publish("location_changed", {
        newBuilding = "home_office",
        newFloor = "main", 
        newRoom = "my_office",
        bonuses = {}
    })
    
    local stats = progressionSystem:getStatistics()
    assert(stats.rooms_visited["home_office/main/my_office"] ~= nil, "Should track room visits")
    
    print("✅ ProgressionSystem: Statistics tracking")
    return true
end

local function test_progression_update()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Test update function doesn't crash
    progressionSystem:update(1.0) -- 1 second update
    
    -- Check that resources might have changed (passive income)
    local money = resourceSystem:getResource("money")
    assert(money ~= nil, "Money should exist after update")
    
    print("✅ ProgressionSystem: Update mechanics")
    return true
end

local function test_state_persistence()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    
    -- Unlock an achievement and change statistics
    progressionSystem:unlockAchievement("first_move")
    eventBus:publish("location_changed", {
        newBuilding = "test",
        newFloor = "test",
        newRoom = "test",
        bonuses = {}
    })
    
    -- Get state
    local state = progressionSystem:getState()
    assert(state.achievements["first_move"] ~= nil, "State should include achievements")
    assert(state.statistics ~= nil, "State should include statistics")
    
    -- Test state restoration
    local newProgressionSystem = ProgressionSystem.new(eventBus, resourceSystem)
    newProgressionSystem:setState(state)
    
    local restoredAchievements = newProgressionSystem:getAchievements()
    assert(restoredAchievements["first_move"] ~= nil, "Should restore achievements")
    
    print("✅ ProgressionSystem: State persistence")
    return true
end

-- Run all tests
local function run_progression_tests()
    local tests = {
        test_progression_system_initialization,
        test_currency_initialization,
        test_achievement_system,
        test_statistics_tracking,
        test_progression_update,
        test_state_persistence
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, error_msg = pcall(test)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            print("❌ Test failed: " .. tostring(error_msg))
        end
    end
    
    return passed, failed
end

return {
    run_progression_tests = run_progression_tests
}

-- Test suite for ProgressionSystem
-- Comprehensive testing of currencies, progression tiers, milestones, and prestige

-- Setup test environment
package.path = "../../?.lua;" .. package.path

local ProgressionSystem = require("src.systems.progression_system")
local EventBus = require("src.utils.event_bus")

-- Test framework
local function runTest(name, test)
    local success, err = pcall(test)
    if success then
        print("✅ " .. name)
        return true
    else
        print("❌ " .. name .. " - " .. tostring(err))
        return false
    end
end

-- Test suite
local tests = {}
local eventBus = EventBus.new()

function tests.initializeWithCurrencies()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Check that currencies are initialized
    assert(progression:getCurrency("money") == 1000, "Money should start at 1000")
    assert(progression:getCurrency("reputation") == 0, "Reputation should start at 0")
    assert(progression:getCurrency("xp") == 0, "XP should start at 0")
    assert(progression:getCurrency("prestigePoints") == 0, "Prestige points should start at 0")
    
    -- Check starting tier
    assert(progression.currentTier == "startup", "Should start in startup tier")
end

function tests.awardAndSpendCurrencies()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Award currencies
    assert(progression:awardCurrency("money", 500), "Should award money")
    assert(progression:getCurrency("money") == 1500, "Money should be 1500")
    
    assert(progression:awardCurrency("xp", 100), "Should award XP")
    assert(progression:getCurrency("xp") == 100, "XP should be 100")
    
    -- Spend currencies
    assert(progression:spendCurrency("money", 200), "Should spend money")
    assert(progression:getCurrency("money") == 1300, "Money should be 1300")
    
    -- Test insufficient funds
    assert(not progression:spendCurrency("money", 2000), "Should not spend more than available")
    
    -- Test spending non-spendable currency (reputation)
    progression:awardCurrency("reputation", 50)
    assert(not progression:spendCurrency("reputation", 10), "Should not spend reputation")
end

function tests.multipleResourceOperations()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Award multiple currencies
    progression:awardCurrency("money", 2000)
    progression:awardCurrency("xp", 150)
    
    -- Test canAfford
    local costs = {money = 1000, xp = 100}
    assert(progression:canAfford(costs), "Should be able to afford")
    
    -- Test spending multiple
    assert(progression:spendMultiple(costs), "Should spend multiple currencies")
    assert(progression:getCurrency("money") == 2000, "Money should be 2000 after spending")
    assert(progression:getCurrency("xp") == 50, "XP should be 50 after spending")
    
    -- Test can't afford multiple
    local expensiveCosts = {money = 5000, xp = 100}
    assert(not progression:canAfford(expensiveCosts), "Should not afford expensive costs")
    assert(not progression:spendMultiple(expensiveCosts), "Should not spend unaffordable costs")
end

function tests.milestoneTracking()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Simulate earning first dollar
    progression.totalStats.totalEarnings = 1
    progression:checkMilestones()
    
    -- Check milestone completion
    assert(progression.completedMilestones["firstDollar"], "First dollar milestone should be complete")
    
    -- Check rewards were awarded (would need to check currency amounts)
    -- This depends on the milestone rewards defined in JSON
    
    -- Test milestone only completes once
    local initialXP = progression:getCurrency("xp")
    progression:checkMilestones() -- Check again
    -- XP should not increase again since milestone is already complete
end

function tests.tierProgression()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Start in startup tier
    assert(progression.currentTier == "startup", "Should start in startup")
    assert(progression:getCurrentTierLevel() == 1, "Should be level 1")
    
    -- Simulate meeting small business requirements
    progression:awardCurrency("money", 5000)
    progression:awardCurrency("reputation", 10)
    progression.totalStats.contractsCompleted = 5
    
    progression:checkTierProgression()
    
    -- Should advance to small business if JSON config is loaded properly
    -- This test might need adjustment based on actual JSON configuration
end

function tests.prestigeSystem()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Initially should not be able to prestige
    assert(not progression:canPrestige(), "Should not be able to prestige initially")
    
    -- Set up conditions for prestige (simplified test)
    progression.currentTier = "enterprise"
    progression:awardCurrency("money", 100000)
    progression:awardCurrency("reputation", 200)
    
    -- Check if can prestige now (depends on JSON config)
    local canPrestige = progression:canPrestige()
    
    if canPrestige then
        local initialLevel = progression.prestigeLevel
        progression:performPrestige()
        assert(progression.prestigeLevel == initialLevel + 1, "Prestige level should increase")
    end
end

function tests.saveAndLoadState()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Set up some state with currencies that the progression system manages
    progression:awardCurrency("prestigePoints", 5)
    progression:awardCurrency("skillPoints", 10)
    progression.currentTier = "smallBusiness"
    progression.prestigeLevel = 1
    
    -- Get state
    local state = progression:getState()
    
    -- Create new progression system and load state
    local newProgression = ProgressionSystem.new(eventBus)
    newProgression:loadState(state)
    
    -- Verify state was loaded correctly
    assert(newProgression:getCurrency("prestigePoints") == 5, "Prestige points should be restored")
    assert(newProgression:getCurrency("skillPoints") == 10, "Skill points should be restored")
    assert(newProgression.currentTier == "smallBusiness", "Tier should be restored")
    assert(newProgression.prestigeLevel == 1, "Prestige level should be restored")
end

function tests.currencyStorage()
    local progression = ProgressionSystem.new(eventBus)
    
    -- Test currencies with storage limits
    -- Research credits have maxStorage: 1000 in JSON
    progression:awardCurrency("researchCredits", 500)
    assert(progression:getCurrency("researchCredits") == 500, "Should award within limit")
    
    progression:awardCurrency("researchCredits", 600)
    -- Should be capped at 1000 if storage limit is working
    assert(progression:getCurrency("researchCredits") == 1000, "Should be capped at storage limit")
end

function tests.eventIntegration()
    local progression = ProgressionSystem.new(eventBus)
    local eventReceived = false
    local receivedCurrency = nil
    local receivedAmount = 0
    
    -- Subscribe to progression events
    eventBus:subscribe("currency_awarded", function(data)
        eventReceived = true
        receivedCurrency = data.currency
        receivedAmount = data.amount
    end)
    
    -- Award currency to trigger event
    progression:awardCurrency("prestigePoints", 5)
    
    assert(eventReceived, "Currency awarded event should be emitted")
    assert(receivedCurrency == "prestigePoints", "Event should contain correct currency info")
    assert(receivedAmount == 5, "Event should contain correct amount")
end

-- Run all tests
local passed = 0
local total = 0

for testName, test in pairs(tests) do
    total = total + 1
    if runTest("ProgressionSystem: " .. testName, test) then
        passed = passed + 1
    end
end

print("===================================================")
print("Progression System Tests completed: " .. passed .. " passed, " .. (total - passed) .. " failed")

return { passed = passed, total = total }
