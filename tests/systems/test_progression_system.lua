-- Test Progression System (Updated for modern architecture - no ResourceSystem dependency)-- Test Progression System (Updated for modern architecture - no ResourceSystem dependency)-- Test Progression System

local EventBus = require("src.utils.event_bus")

local ProgressionSystem = require("src.systems.progression_system")local EventBus = require("src.utils.event_bus")local EventBus = require("src.utils.event_bus")



local function test_progression_system_initialization()local ProgressionSystem = require("src.systems.progression_system")local ProgressionSystem = require("src.systems.progression_system")

    local eventBus = EventBus.new()

    local progressionSystem = ProgressionSystem.new(eventBus)

    

    -- Test basic initializationlocal function test_progression_system_initialization()local function test_progression_system_initialization()

    assert(progressionSystem ~= nil, "ProgressionSystem should initialize")

        local eventBus = EventBus.new()    local eventBus = EventBus.new()

    -- Test current tier

    local currentTier = progressionSystem:getCurrentTier()    local progressionSystem = ProgressionSystem.new(eventBus)    local progressionSystem = ProgressionSystem.new(eventBus)

    assert(currentTier ~= nil, "Should have a current tier")

            

    print("✅ ProgressionSystem: Initialize with default tier")

    return true    -- Test basic initialization    -- Test basic initialization

end

    assert(progressionSystem ~= nil, "ProgressionSystem should initialize")    assert(progressionSystem ~= nil, "ProgressionSystem should initialize")

local function test_currency_initialization()

    local eventBus = EventBus.new()        

    local progressionSystem = ProgressionSystem.new(eventBus)

        -- Test current tier    -- Test current tier

    -- Check that currencies were initialized from progression system

    local money = progressionSystem:getCurrency("money")    local currentTier = progressionSystem:getCurrentTier()    local currentTier = progressionSystem:getCurrentTier()

    local reputation = progressionSystem:getCurrency("reputation")

    local experience = progressionSystem:getCurrency("experience")    assert(currentTier ~= nil, "Should have a current tier")    assert(currentTier ~= nil, "Should have a current tier")

    

    assert(money and money > 0, "Money should be initialized")        

    assert(reputation and reputation >= 0, "Reputation should be initialized")

    assert(experience and experience >= 0, "Experience should be initialized")    print("✅ ProgressionSystem: Initialize with default tier")    print("✅ ProgressionSystem: Initialize with default tier")

    

    print("✅ ProgressionSystem: Currency initialization")    return true    return true

    return true

endendend



local function test_achievement_system()

    local eventBus = EventBus.new()

    local progressionSystem = ProgressionSystem.new(eventBus)local function test_currency_initialization()local function test_currency_initialization()

    

    -- Test achievement unlocking    local eventBus = EventBus.new()    local eventBus = EventBus.new()

    progressionSystem:unlockAchievement("first_move")

        local progressionSystem = ProgressionSystem.new(eventBus)    local progressionSystem = ProgressionSystem.new(eventBus)

    local achievements = progressionSystem:getAchievements()

    assert(achievements["first_move"] ~= nil, "Achievement should be unlocked")        

    

    print("✅ ProgressionSystem: Achievement unlocking")    -- Check that currencies were initialized from progression system    -- Check that currencies were initialized from progression system

    return true

end    local money = progressionSystem:getCurrency("money")    local money = progressionSystem:getCurrency("money")



local function test_statistics_tracking()    local reputation = progressionSystem:getCurrency("reputation")    local reputation = progressionSystem:getCurrency("reputation")

    local eventBus = EventBus.new()

    local progressionSystem = ProgressionSystem.new(eventBus)    local experience = progressionSystem:getCurrency("experience")    local experience = progressionSystem:getCurrency("experience")

    

    -- Simulate location change event        

    eventBus:publish("location_changed", {

        newBuilding = "home_office",    assert(money and money > 0, "Money should be initialized")    assert(money and money > 0, "Money should be initialized")

        newFloor = "main", 

        newRoom = "my_office",    assert(reputation and reputation >= 0, "Reputation should be initialized")    assert(reputation and reputation >= 0, "Reputation should be initialized")

        bonuses = {}

    })    assert(experience and experience >= 0, "Experience should be initialized")    assert(experience and experience >= 0, "Experience should be initialized")

    

    local stats = progressionSystem:getStatistics()        

    assert(stats.rooms_visited["home_office/main/my_office"] ~= nil, "Should track room visits")

        print("✅ ProgressionSystem: Currency initialization")    print("✅ ProgressionSystem: Currency initialization")

    print("✅ ProgressionSystem: Statistics tracking")

    return true    return true    return true

end

endend

local function test_progression_update()

    local eventBus = EventBus.new()

    local progressionSystem = ProgressionSystem.new(eventBus)

    local function test_achievement_system()local function test_achievement_system()

    -- Test update function doesn't crash

    progressionSystem:update(1.0) -- 1 second update    local eventBus = EventBus.new()    local eventBus = EventBus.new()

    

    -- Check that currencies are managed by progression system    local progressionSystem = ProgressionSystem.new(eventBus)    local resourceSystem = ResourceSystem.new(eventBus)

    local money = progressionSystem:getCurrency("money")

    assert(money ~= nil, "Money should exist after update")        local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)

    

    print("✅ ProgressionSystem: Update mechanics")    -- Test achievement unlocking    

    return true

end    progressionSystem:unlockAchievement("first_move")    -- Test achievement unlocking



local function test_state_persistence()        progressionSystem:unlockAchievement("first_move")

    local eventBus = EventBus.new()

    local progressionSystem = ProgressionSystem.new(eventBus)    local achievements = progressionSystem:getAchievements()    

    

    -- Unlock an achievement and change statistics    assert(achievements["first_move"] ~= nil, "Achievement should be unlocked")    local achievements = progressionSystem:getAchievements()

    progressionSystem:unlockAchievement("first_move")

    eventBus:publish("location_changed", {        assert(achievements["first_move"] ~= nil, "Achievement should be unlocked")

        newBuilding = "test",

        newFloor = "test",    print("✅ ProgressionSystem: Achievement unlocking")    

        newRoom = "test",

        bonuses = {}    return true    print("✅ ProgressionSystem: Achievement unlocking")

    })

    end    return true

    -- Get state

    local state = progressionSystem:getState()end

    assert(state.achievements["first_move"] ~= nil, "State should include achievements")

    assert(state.statistics ~= nil, "State should include statistics")local function test_statistics_tracking()

    

    -- Test state restoration    local eventBus = EventBus.new()local function test_statistics_tracking()

    local newProgressionSystem = ProgressionSystem.new(eventBus)

    newProgressionSystem:setState(state)    local progressionSystem = ProgressionSystem.new(eventBus)    local eventBus = EventBus.new()

    

    local restoredAchievements = newProgressionSystem:getAchievements()        local resourceSystem = ResourceSystem.new(eventBus)

    assert(restoredAchievements["first_move"] ~= nil, "Should restore achievements")

        -- Simulate location change event    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)

    print("✅ ProgressionSystem: State persistence")

    return true    eventBus:publish("location_changed", {    

end

        newBuilding = "home_office",    -- Simulate location change event

-- Run all tests

local function run_progression_tests()        newFloor = "main",     eventBus:publish("location_changed", {

    local tests = {

        test_progression_system_initialization,        newRoom = "my_office",        newBuilding = "home_office",

        test_currency_initialization,

        test_achievement_system,        bonuses = {}        newFloor = "main", 

        test_statistics_tracking,

        test_progression_update,    })        newRoom = "my_office",

        test_state_persistence

    }            bonuses = {}

    

    local passed = 0    local stats = progressionSystem:getStatistics()    })

    local failed = 0

        assert(stats.rooms_visited["home_office/main/my_office"] ~= nil, "Should track room visits")    

    for _, test in ipairs(tests) do

        local success, error_msg = pcall(test)        local stats = progressionSystem:getStatistics()

        if success then

            passed = passed + 1    print("✅ ProgressionSystem: Statistics tracking")    assert(stats.rooms_visited["home_office/main/my_office"] ~= nil, "Should track room visits")

        else

            failed = failed + 1    return true    

            print("❌ Test failed: " .. tostring(error_msg))

        endend    print("✅ ProgressionSystem: Statistics tracking")

    end

        return true

    return passed, failed

endlocal function test_progression_update()end



return {    local eventBus = EventBus.new()

    run_progression_tests = run_progression_tests

}    local progressionSystem = ProgressionSystem.new(eventBus)local function test_progression_update()


        local eventBus = EventBus.new()

    -- Test update function doesn't crash    local resourceSystem = ResourceSystem.new(eventBus)

    progressionSystem:update(1.0) -- 1 second update    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)

        

    -- Check that currencies are managed by progression system    -- Test update function doesn't crash

    local money = progressionSystem:getCurrency("money")    progressionSystem:update(1.0) -- 1 second update

    assert(money ~= nil, "Money should exist after update")    

        -- Check that resources might have changed (passive income)

    print("✅ ProgressionSystem: Update mechanics")    local money = resourceSystem:getResource("money")

    return true    assert(money ~= nil, "Money should exist after update")

end    

    print("✅ ProgressionSystem: Update mechanics")

local function test_state_persistence()    return true

    local eventBus = EventBus.new()end

    local progressionSystem = ProgressionSystem.new(eventBus)

    local function test_state_persistence()

    -- Unlock an achievement and change statistics    local eventBus = EventBus.new()

    progressionSystem:unlockAchievement("first_move")    local resourceSystem = ResourceSystem.new(eventBus)

    eventBus:publish("location_changed", {    local progressionSystem = ProgressionSystem.new(eventBus, resourceSystem)

        newBuilding = "test",    

        newFloor = "test",    -- Unlock an achievement and change statistics

        newRoom = "test",    progressionSystem:unlockAchievement("first_move")

        bonuses = {}    eventBus:publish("location_changed", {

    })        newBuilding = "test",

            newFloor = "test",

    -- Get state        newRoom = "test",

    local state = progressionSystem:getState()        bonuses = {}

    assert(state.achievements["first_move"] ~= nil, "State should include achievements")    })

    assert(state.statistics ~= nil, "State should include statistics")    

        -- Get state

    -- Test state restoration    local state = progressionSystem:getState()

    local newProgressionSystem = ProgressionSystem.new(eventBus)    assert(state.achievements["first_move"] ~= nil, "State should include achievements")

    newProgressionSystem:setState(state)    assert(state.statistics ~= nil, "State should include statistics")

        

    local restoredAchievements = newProgressionSystem:getAchievements()    -- Test state restoration

    assert(restoredAchievements["first_move"] ~= nil, "Should restore achievements")    local newProgressionSystem = ProgressionSystem.new(eventBus, resourceSystem)

        newProgressionSystem:setState(state)

    print("✅ ProgressionSystem: State persistence")    

    return true    local restoredAchievements = newProgressionSystem:getAchievements()

end    assert(restoredAchievements["first_move"] ~= nil, "Should restore achievements")

    

-- Run all tests    print("✅ ProgressionSystem: State persistence")

local function run_progression_tests()    return true

    local tests = {end

        test_progression_system_initialization,

        test_currency_initialization,-- Run all tests

        test_achievement_system,local function run_progression_tests()

        test_statistics_tracking,    local tests = {

        test_progression_update,        test_progression_system_initialization,

        test_state_persistence        test_currency_initialization,

    }        test_achievement_system,

            test_statistics_tracking,

    local passed = 0        test_progression_update,

    local failed = 0        test_state_persistence

        }

    for _, test in ipairs(tests) do    

        local success, error_msg = pcall(test)    local passed = 0

        if success then    local failed = 0

            passed = passed + 1    

        else    for _, test in ipairs(tests) do

            failed = failed + 1        local success, error_msg = pcall(test)

            print("❌ Test failed: " .. tostring(error_msg))        if success then

        end            passed = passed + 1

    end        else

                failed = failed + 1

    return passed, failed            print("❌ Test failed: " .. tostring(error_msg))

end        end

    end

return {    

    run_progression_tests = run_progression_tests    return passed, failed

}end


return {
    run_progression_tests = run_progression_tests
}
