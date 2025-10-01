-- Tests for Crisis System and Specialist XP Progression
-- Tests crisis generation, lifecycle, specialist deployment, and XP/leveling

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua;src/core/?.lua;./?.lua"

local dkjson = require("dkjson")

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

-- Simple DataManager mock for testing
local MockDataManager = {}
MockDataManager.__index = MockDataManager

function MockDataManager.new()
    local self = setmetatable({}, MockDataManager)
    self.data = {}
    return self
end

function MockDataManager:loadFile(key, filepath)
    local file = io.open(filepath, "r")
    if not file then
        print("Failed to open: " .. filepath)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, result = pcall(dkjson.decode, content)
    if success then
        self.data[key] = result
        return true
    else
        print("Failed to parse JSON from " .. filepath .. ": " .. tostring(result))
        return false
    end
end

function MockDataManager:getData(key)
    return self.data[key]
end

local CrisisSystem = require("crisis_system")
local SpecialistSystem = require("specialist_system")
local EventBus = require("event_bus")
local SkillSystem = require("skill_system")

-- Test runner helper
local TestRunner = {
    passed = 0,
    failed = 0,
    tests = {}
}

function TestRunner.test(name, func)
    table.insert(TestRunner.tests, {name = name, func = func})
end

function TestRunner.assertEqual(expected, actual, message)
    if expected ~= actual then
        error(message .. string.format(" (expected: %s, got: %s)", tostring(expected), tostring(actual)))
    end
end

function TestRunner.assert(condition, message)
    if not condition then
        error(message or "Assertion failed")
    end
end

function TestRunner.assertNotNil(value, message)
    if value == nil then
        error(message or "Value should not be nil")
    end
end

function TestRunner.run()
    print("============================================================")
    print("🚀 CRISIS PROGRESSION BEHAVIOR TESTS")
    print("============================================================\n")
    
    for _, test in ipairs(TestRunner.tests) do
        io.write("🧪 Test: " .. test.name .. "\n")
        local success, err = pcall(test.func)
        if success then
            TestRunner.passed = TestRunner.passed + 1
            io.write("✅ PASSED\n\n")
        else
            TestRunner.failed = TestRunner.failed + 1
            io.write("❌ FAILED: " .. tostring(err) .. "\n\n")
        end
    end
    
    print("============================================================")
    print(string.format("📊 RESULTS: %d passed, %d failed", TestRunner.passed, TestRunner.failed))
    print("============================================================")
    
    return TestRunner.failed == 0
end

-- ============================================================
-- CRISIS SYSTEM TESTS
-- ============================================================

TestRunner.test("CrisisSystem: Initialize and load crisis definitions", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local crises = crisisSystem:getAllCrisisDefinitions()
    TestRunner.assert(crises ~= nil, "Crisis definitions should be loaded")
    TestRunner.assert(crises.phishing_crisis ~= nil, "Should have phishing_crisis definition")
    TestRunner.assert(crises.ransomware_crisis ~= nil, "Should have ransomware_crisis definition")
    TestRunner.assert(crises.ddos_crisis ~= nil, "Should have ddos_crisis definition")
end)

TestRunner.test("CrisisSystem: Generate crisis from threat type", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local crisisId = crisisSystem:generateCrisis("phishing_attempt")
    TestRunner.assertEqual("phishing_crisis", crisisId, "Should generate phishing_crisis from phishing_attempt threat")
    
    local crisisId2 = crisisSystem:generateCrisis("ransomware_detection")
    TestRunner.assertEqual("ransomware_crisis", crisisId2, "Should generate ransomware_crisis from ransomware_detection threat")
end)

TestRunner.test("CrisisSystem: Start crisis and initialize state", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local success = crisisSystem:startCrisis("phishing_crisis")
    TestRunner.assert(success, "Should successfully start crisis")
    
    local activeCrisis = crisisSystem:getActiveCrisis()
    TestRunner.assertNotNil(activeCrisis, "Should have active crisis")
    TestRunner.assertEqual("phishing_crisis", activeCrisis.id, "Active crisis should be phishing_crisis")
    TestRunner.assertEqual(180, activeCrisis.timeLimit, "Should have correct time limit")
    TestRunner.assertNotNil(activeCrisis.stages, "Should have stages")
end)

TestRunner.test("CrisisSystem: Stage progression and auto-complete", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    crisisSystem:startCrisis("phishing_crisis")
    local activeCrisis = crisisSystem:getActiveCrisis()
    
    -- First stage should auto-complete
    TestRunner.assert(activeCrisis.stages[1].completed, "First stage should be auto-completed")
    
    -- Current stage should be second stage
    local currentStage = crisisSystem:getCurrentStage()
    TestRunner.assertEqual("analysis", currentStage.id, "Current stage should be analysis")
end)

TestRunner.test("CrisisSystem: Deploy specialist to crisis", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    crisisSystem:startCrisis("phishing_crisis")
    
    local deployed = crisisSystem:deploySpecialist(0, "phishing_crisis", "basic_analysis")
    TestRunner.assert(deployed, "Should successfully deploy specialist")
end)

TestRunner.test("CrisisSystem: Calculate effectiveness based on abilities", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    -- Test with matching abilities
    local effectiveness = crisisSystem:calculateEffectiveness(
        {"basic_analysis", "network_fundamentals"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(1.0, effectiveness, "Should have full effectiveness with all matching abilities")
    
    -- Test with partial match
    local effectiveness2 = crisisSystem:calculateEffectiveness(
        {"basic_analysis"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(0.75, effectiveness2, "Should have 0.75 effectiveness with one matching ability")
    
    -- Test with no match
    local effectiveness3 = crisisSystem:calculateEffectiveness(
        {"leadership"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(0.5, effectiveness3, "Should have 0.5 effectiveness with no matching abilities")
end)

TestRunner.test("CrisisSystem: Complete crisis successfully", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local crisisCompletedFired = false
    eventBus:subscribe("crisis_completed", function(data)
        crisisCompletedFired = true
        TestRunner.assertEqual("phishing_crisis", data.crisisId, "Event should have correct crisis ID")
        TestRunner.assertEqual("success", data.outcome, "Event should show success outcome")
    end)
    
    crisisSystem:startCrisis("phishing_crisis")
    crisisSystem:resolveCrisis("success")
    
    TestRunner.assert(crisisCompletedFired, "crisis_completed event should fire")
    TestRunner.assert(crisisSystem:getActiveCrisis() == nil, "Active crisis should be cleared after resolution")
end)

-- ============================================================
-- SPECIALIST XP AND PROGRESSION TESTS
-- ============================================================

TestRunner.test("SpecialistSystem: Award XP to specialist", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    -- Get CEO (id 0)
    local ceo = specialistSystem:getSpecialist(0)
    local initialXp = ceo.xp or 0
    
    specialistSystem:awardXp(0, 50)
    
    TestRunner.assertEqual(initialXp + 50, ceo.xp, "CEO should have 50 more XP")
end)

TestRunner.test("SpecialistSystem: Level up at correct threshold", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local levelUpFired = false
    eventBus:subscribe("specialist_leveled_up", function(data)
        levelUpFired = true
        TestRunner.assertEqual(1, data.oldLevel, "Old level should be 1")
        TestRunner.assertEqual(2, data.newLevel, "New level should be 2")
    end)
    
    local ceo = specialistSystem:getSpecialist(0)
    local initialEfficiency = ceo.efficiency
    
    -- Award enough XP to level up (threshold for level 2 is 100)
    specialistSystem:awardXp(0, 100)
    
    TestRunner.assert(levelUpFired, "specialist_leveled_up event should fire")
    TestRunner.assertEqual(2, ceo.level, "CEO should be level 2")
    TestRunner.assert(ceo.efficiency > initialEfficiency, "Efficiency should increase after level up")
end)

TestRunner.test("SpecialistSystem: Apply stat bonuses on level up", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local ceo = specialistSystem:getSpecialist(0)
    local initialEfficiency = ceo.efficiency
    local initialSpeed = ceo.speed
    local initialTrace = ceo.trace
    local initialDefense = ceo.defense
    
    -- Level up
    specialistSystem:awardXp(0, 100)
    
    -- Check all stats increased by ~10%
    TestRunner.assert(ceo.efficiency >= initialEfficiency * 1.09, "Efficiency should increase by ~10%")
    TestRunner.assert(ceo.speed >= initialSpeed * 1.09, "Speed should increase by ~10%")
    TestRunner.assert(ceo.trace >= initialTrace * 1.09, "Trace should increase by ~10%")
    TestRunner.assert(ceo.defense >= initialDefense * 1.09, "Defense should increase by ~10%")
end)

TestRunner.test("SpecialistSystem: Award XP from crisis completion", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local ceo = specialistSystem:getSpecialist(0)
    local initialXp = ceo.xp or 0
    
    -- Simulate crisis completion event
    eventBus:publish("crisis_completed", {
        crisisId = "phishing_crisis",
        outcome = "success",
        xpAwarded = 50,
        specialistsDeployed = {
            {specialistId = 0, abilityId = "basic_analysis"}
        }
    })
    
    -- XP should be base (50) + ability bonus (10)
    TestRunner.assertEqual(initialXp + 60, ceo.xp, "CEO should have 60 XP from crisis (50 base + 10 ability bonus)")
end)

TestRunner.test("SpecialistSystem: Check skill requirements", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local ceo = specialistSystem:getSpecialist(0)
    
    -- Give CEO enough XP to learn a skill
    ceo.xp = 500
    
    -- CEO starts with basic_analysis, can learn skills that require it
    local canLearn = specialistSystem:canLearnSkill(ceo, "network_fundamentals")
    TestRunner.assert(canLearn, "Should be able to learn network_fundamentals (no prerequisites)")
end)

-- ============================================================
-- INTEGRATION TESTS
-- ============================================================

TestRunner.test("Integration: Full crisis lifecycle with XP reward", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local ceo = specialistSystem:getSpecialist(0)
    local initialXp = ceo.xp or 0
    
    -- Start crisis
    crisisSystem:startCrisis("phishing_crisis")
    
    -- Deploy specialist
    crisisSystem:deploySpecialist(0, "phishing_crisis", "basic_analysis")
    
    -- Complete crisis
    crisisSystem:resolveCrisis("success")
    
    -- Check XP was awarded
    TestRunner.assert(ceo.xp > initialXp, "CEO should have gained XP from crisis")
end)

TestRunner.test("Integration: Crisis timeout handling", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local crisisSystem = CrisisSystem.new(eventBus, dataManager)
    crisisSystem:initialize()
    
    local timeoutEventFired = false
    eventBus:subscribe("crisis_completed", function(data)
        if data.outcome == "timeout" then
            timeoutEventFired = true
        end
    end)
    
    crisisSystem:startCrisis("phishing_crisis")
    
    -- Simulate time passing beyond limit
    for i = 1, 200 do
        crisisSystem:update(1) -- 200 seconds, more than 180 second limit
    end
    
    TestRunner.assert(timeoutEventFired, "Timeout event should fire when time limit exceeded")
    TestRunner.assert(crisisSystem:getActiveCrisis() == nil, "Crisis should be resolved after timeout")
end)

-- Run all tests
local success = TestRunner.run()
os.exit(success and 0 or 1)
