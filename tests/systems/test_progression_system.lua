-- Test Progression System

local EventBus = require("src.utils.event_bus")
local ProgressionSystem = require("src.systems.progression_system")

local function test_progression_system_initialization()
    local eventBus = EventBus.new()
    local progressionSystem = ProgressionSystem.new(eventBus)

    -- Basic initialization
    assert(progressionSystem ~= nil, "ProgressionSystem should initialize")
    local currentTier = progressionSystem:getCurrentTier()
    assert(currentTier ~= nil, "Should have a current tier")

    print("✅ ProgressionSystem: Initialize with default tier")
    return true
end

local function test_currency_initialization()
    local eventBus = EventBus.new()
    local progressionSystem = ProgressionSystem.new(eventBus)

    local money = progressionSystem:getCurrency("money")
    local reputation = progressionSystem:getCurrency("reputation")
    local xp = progressionSystem:getCurrency("xp")

    assert(money and money >= 0, "Money should be initialized")
    assert(reputation and reputation >= 0, "Reputation should be initialized")
    assert(xp and xp >= 0, "XP should be initialized")

    print("✅ ProgressionSystem: Currency initialization")
    return true
end

local function test_achievement_system()
    local eventBus = EventBus.new()
    local progressionSystem = ProgressionSystem.new(eventBus)

    progressionSystem:unlockAchievement("first_move")
    local achievements = progressionSystem:getAchievements()
    assert(achievements["first_move"] ~= nil, "Achievement should be unlocked")

    print("✅ ProgressionSystem: Achievement unlocking")
    return true
end

local function test_statistics_tracking()
    local eventBus = EventBus.new()
    local progressionSystem = ProgressionSystem.new(eventBus)

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
    local progressionSystem = ProgressionSystem.new(eventBus)

    -- Ensure update runs without error
    progressionSystem:update(1.0)
    local money = progressionSystem:getCurrency("money")
    assert(money ~= nil, "Money should exist after update")

    print("✅ ProgressionSystem: Update mechanics")
    return true
end

local function test_state_persistence()
    local eventBus = EventBus.new()
    local progressionSystem = ProgressionSystem.new(eventBus)

    progressionSystem:unlockAchievement("first_move")
    eventBus:publish("location_changed", {
        newBuilding = "home_office",
        newFloor = "main",
        newRoom = "my_office",
        bonuses = {}
    })

    local state = progressionSystem:getState()
    assert(state.achievements["first_move"] ~= nil, "State should include achievements")
    assert(state.statistics ~= nil, "State should include statistics")

    -- Restore into new instance
    local newProgressionSystem = ProgressionSystem.new(eventBus)
    newProgressionSystem:setState(state)
    local restored = newProgressionSystem:getAchievements()
    assert(restored["first_move"] ~= nil, "Should restore achievements")

    print("✅ ProgressionSystem: State persistence")
    return true
end

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
        local success, err = pcall(test)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            print("❌ Test failed: " .. tostring(err))
        end
    end

    return passed, failed
end

return {
    run_progression_tests = run_progression_tests
}

