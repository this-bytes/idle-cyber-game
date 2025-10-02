-- Tests for Incident System and Specialist XP Progression
-- Tests Incident generation, lifecycle, specialist deployment, and XP/leveling

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua;src/core/?.lua;./?.lua"

local dkjson = require("src.utils.dkjson")

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

local IncidentSystem = require("Incident_system")
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
    print("🚀 Incident PROGRESSION BEHAVIOR TESTS")
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
-- Incident SYSTEM TESTS
-- ============================================================

TestRunner.test("IncidentSystem: Initialize and load Incident definitions", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local crises = IncidentSystem:getAllIncidentDefinitions()
    TestRunner.assert(crises ~= nil, "Incident definitions should be loaded")
    TestRunner.assert(crises.phishing_Incident ~= nil, "Should have phishing_Incident definition")
    TestRunner.assert(crises.ransomware_Incident ~= nil, "Should have ransomware_Incident definition")
    TestRunner.assert(crises.ddos_Incident ~= nil, "Should have ddos_Incident definition")
end)

TestRunner.test("IncidentSystem: Generate Incident from threat type", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local IncidentId = IncidentSystem:generateIncident("phishing_attempt")
    TestRunner.assertEqual("phishing_Incident", IncidentId, "Should generate phishing_Incident from phishing_attempt threat")
    
    local IncidentId2 = IncidentSystem:generateIncident("ransomware_detection")
    TestRunner.assertEqual("ransomware_Incident", IncidentId2, "Should generate ransomware_Incident from ransomware_detection threat")
end)

TestRunner.test("IncidentSystem: Start Incident and initialize state", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local success = IncidentSystem:startIncident("phishing_Incident")
    TestRunner.assert(success, "Should successfully start Incident")
    
    local activeIncident = IncidentSystem:getActiveIncident()
    TestRunner.assertNotNil(activeIncident, "Should have active Incident")
    TestRunner.assertEqual("phishing_Incident", activeIncident.id, "Active Incident should be phishing_Incident")
    TestRunner.assertEqual(180, activeIncident.timeLimit, "Should have correct time limit")
    TestRunner.assertNotNil(activeIncident.stages, "Should have stages")
end)

TestRunner.test("IncidentSystem: Stage progression and auto-complete", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    IncidentSystem:startIncident("phishing_Incident")
    local activeIncident = IncidentSystem:getActiveIncident()
    
    -- First stage should auto-complete
    TestRunner.assert(activeIncident.stages[1].completed, "First stage should be auto-completed")
    
    -- Current stage should be second stage
    local currentStage = IncidentSystem:getCurrentStage()
    TestRunner.assertEqual("analysis", currentStage.id, "Current stage should be analysis")
end)

TestRunner.test("IncidentSystem: Deploy specialist to Incident", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    IncidentSystem:startIncident("phishing_Incident")
    
    local deployed = IncidentSystem:deploySpecialist(0, "phishing_Incident", "basic_analysis")
    TestRunner.assert(deployed, "Should successfully deploy specialist")
end)

TestRunner.test("IncidentSystem: Calculate effectiveness based on abilities", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    -- Test with matching abilities
    local effectiveness = IncidentSystem:calculateEffectiveness(
        {"basic_analysis", "network_fundamentals"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(1.0, effectiveness, "Should have full effectiveness with all matching abilities")
    
    -- Test with partial match
    local effectiveness2 = IncidentSystem:calculateEffectiveness(
        {"basic_analysis"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(0.75, effectiveness2, "Should have 0.75 effectiveness with one matching ability")
    
    -- Test with no match
    local effectiveness3 = IncidentSystem:calculateEffectiveness(
        {"leadership"},
        {"basic_analysis", "network_fundamentals"}
    )
    TestRunner.assertEqual(0.5, effectiveness3, "Should have 0.5 effectiveness with no matching abilities")
end)

TestRunner.test("IncidentSystem: Complete Incident successfully", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local IncidentCompletedFired = false
    eventBus:subscribe("Incident_completed", function(data)
        IncidentCompletedFired = true
        TestRunner.assertEqual("phishing_Incident", data.IncidentId, "Event should have correct Incident ID")
        TestRunner.assertEqual("success", data.outcome, "Event should show success outcome")
    end)
    
    IncidentSystem:startIncident("phishing_Incident")
    IncidentSystem:resolveIncident("success")
    
    TestRunner.assert(IncidentCompletedFired, "Incident_completed event should fire")
    TestRunner.assert(IncidentSystem:getActiveIncident() == nil, "Active Incident should be cleared after resolution")
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

TestRunner.test("SpecialistSystem: Award XP from Incident completion", function()
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
    
    -- Simulate Incident completion event
    eventBus:publish("Incident_completed", {
        IncidentId = "phishing_Incident",
        outcome = "success",
        xpAwarded = 50,
        specialistsDeployed = {
            {specialistId = 0, abilityId = "basic_analysis"}
        }
    })
    
    -- XP should be base (50) + ability bonus (10)
    TestRunner.assertEqual(initialXp + 60, ceo.xp, "CEO should have 60 XP from Incident (50 base + 10 ability bonus)")
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

TestRunner.test("Integration: Full Incident lifecycle with XP reward", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    dataManager:loadFile("skills", "src/data/skills.json")
    local skillSystem = SkillSystem.new(eventBus, dataManager)
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local specialistSystem = SpecialistSystem.new(eventBus, dataManager, skillSystem)
    specialistSystem:initialize()
    
    local ceo = specialistSystem:getSpecialist(0)
    local initialXp = ceo.xp or 0
    
    -- Start Incident
    IncidentSystem:startIncident("phishing_Incident")
    
    -- Deploy specialist
    IncidentSystem:deploySpecialist(0, "phishing_Incident", "basic_analysis")
    
    -- Complete Incident
    IncidentSystem:resolveIncident("success")
    
    -- Check XP was awarded
    TestRunner.assert(ceo.xp > initialXp, "CEO should have gained XP from Incident")
end)

TestRunner.test("Integration: Incident timeout handling", function()
    local eventBus = EventBus.new()
    local dataManager = MockDataManager.new()
    dataManager:loadFile("crises", "src/data/crises.json")
    dataManager:loadFile("specialists", "src/data/specialists.json")
    
    
    local IncidentSystem = IncidentSystem.new(eventBus, dataManager)
    IncidentSystem:initialize()
    
    local timeoutEventFired = false
    eventBus:subscribe("Incident_completed", function(data)
        if data.outcome == "timeout" then
            timeoutEventFired = true
        end
    end)
    
    IncidentSystem:startIncident("phishing_Incident")
    
    -- Simulate time passing beyond limit
    for i = 1, 200 do
        IncidentSystem:update(1) -- 200 seconds, more than 180 second limit
    end
    
    TestRunner.assert(timeoutEventFired, "Timeout event should fire when time limit exceeded")
    TestRunner.assert(IncidentSystem:getActiveIncident() == nil, "Incident should be resolved after timeout")
end)

-- Run all tests
local success = TestRunner.run()
os.exit(success and 0 or 1)
