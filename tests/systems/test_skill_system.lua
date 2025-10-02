-- Tests for Skill System - Idle Sec Ops

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local SkillSystem = require("skill_system")
local EventBus = require("event_bus")

-- Test: Initialize skill system with default skills
TestRunner.test("SkillSystem: Initialize with default skills", function()
    local eventBus = EventBus.new()
    
    -- Mock dataManager
    local mockDataManager = {
        getData = function(self, key)
            if key == "skills" then
                return {
                    skills = {
                        basic_analysis = {name = "Basic Analysis", maxLevel = 5},
                        network_fundamentals = {name = "Network Fundamentals", maxLevel = 5},
                        team_coordination = {name = "Team Coordination", maxLevel = 5}
                    },
                    categories = {}
                }
            end
            return nil
        end
    }
    
    local skillSystem = SkillSystem.new(eventBus, mockDataManager)
    
    TestRunner.assertNotNil(skillSystem, "Skill system should be created")
    
    local skills = skillSystem:getAvailableSkills()
    TestRunner.assertNotNil(skills, "Should have available skills")
    TestRunner.assertNotNil(skills["basic_analysis"], "Should have basic analysis skill")
    TestRunner.assertNotNil(skills["network_fundamentals"], "Should have network fundamentals skill")
    TestRunner.assertNotNil(skills["team_coordination"], "Should have team coordination skill")
end)

-- Test: Initialize entity with skills
TestRunner.test("SkillSystem: Initialize entity with appropriate skills", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    -- Initialize CEO
    skillSystem:initializeEntity(0, "ceo")
    
    local ceoSkills = skillSystem:getEntitySkills(0)
    TestRunner.assertNotNil(ceoSkills, "CEO should have skills")
    TestRunner.assert(skillSystem:isSkillUnlocked(0, "basic_analysis"), "CEO should have basic analysis unlocked")
    TestRunner.assert(skillSystem:isSkillUnlocked(0, "team_coordination"), "CEO should have team coordination unlocked")
    
    -- Initialize network specialist
    skillSystem:initializeEntity(1, "network_admin")
    
    local networkSkills = skillSystem:getEntitySkills(1)
    TestRunner.assertNotNil(networkSkills, "Network admin should have skills")
    TestRunner.assert(skillSystem:isSkillUnlocked(1, "basic_analysis"), "Network admin should have basic analysis unlocked")
    TestRunner.assert(skillSystem:isSkillUnlocked(1, "network_fundamentals"), "Network admin should have network fundamentals unlocked")
end)

-- Test: XP award and skill level up
TestRunner.test("SkillSystem: XP award and skill level up", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    skillSystem:initializeEntity(0, "ceo")
    
    -- Award XP
    local success = skillSystem:awardXp(0, "basic_analysis", 50)
    TestRunner.assert(success, "Should successfully award XP")
    
    -- Check XP was added
    local ceoSkills = skillSystem:getEntitySkills(0)
    TestRunner.assertEqual(50, ceoSkills["basic_analysis"].xp, "XP should be awarded correctly")
    
    -- Award enough XP to level up (baseXpCost = 100)
    skillSystem:awardXp(0, "basic_analysis", 60)
    TestRunner.assertEqual(1, ceoSkills["basic_analysis"].level, "Should level up to level 1")
    TestRunner.assertEqual(10, ceoSkills["basic_analysis"].xp, "Should carry over excess XP")
end)

-- Test: Skill unlock prerequisites
TestRunner.test("SkillSystem: Skill unlock prerequisites", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    skillSystem:initializeEntity(0, "ceo")
    
    -- Advanced scanning should not be unlockable initially
    TestRunner.assert(not skillSystem:isSkillUnlocked(0, "advanced_scanning"), "Advanced scanning should not be unlocked initially")
    
    -- Level up basic analysis to level 3
    for i = 1, 3 do
        skillSystem:awardXp(0, "basic_analysis", math.floor(100 * (1.2 ^ (i - 1))))
    end
    
    -- Check if advanced scanning gets unlocked
    skillSystem:checkSkillUnlocks(0)
    TestRunner.assert(skillSystem:isSkillUnlocked(0, "advanced_scanning"), "Advanced scanning should be unlocked after meeting prerequisites")
end)

-- Test: Skill effects calculation
TestRunner.test("SkillSystem: Skill effects calculation", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    skillSystem:initializeEntity(0, "ceo")
    
    -- Get initial effects (should be mostly 0)
    local initialEffects = skillSystem:getSkillEffects(0)
    TestRunner.assertEqual(0, initialEffects.efficiency, "Initial efficiency should be 0")
    
    -- Level up basic analysis (gives +5% efficiency per level)
    skillSystem:awardXp(0, "basic_analysis", 100)
    
    local effectsAfterLevelUp = skillSystem:getSkillEffects(0)
    TestRunner.assertEqual(0.05, effectsAfterLevelUp.efficiency, "Should have +5% efficiency after level 1")
    
    -- Level up team coordination (gives +2% team efficiency bonus per level)  
    skillSystem:awardXp(0, "team_coordination", 200)
    
    local effectsWithMultipleSkills = skillSystem:getSkillEffects(0)
    TestRunner.assertEqual(0.02, effectsWithMultipleSkills.teamEfficiencyBonus, "Should have +2% team efficiency bonus")
end)

-- Test: Save and load state
TestRunner.test("SkillSystem: Save and load state", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    skillSystem:initializeEntity(0, "ceo")
    skillSystem:awardXp(0, "basic_analysis", 150)
    
    -- Save state
    local state = skillSystem:getState()
    TestRunner.assertNotNil(state, "Should be able to get state")
    TestRunner.assertNotNil(state.skillProgress, "State should contain skill progress")
    
    -- Create new skill system and load state
    local newSkillSystem = SkillSystem.new(EventBus.new())
    newSkillSystem:loadState(state)
    
    -- Check if data was loaded correctly
    local loadedSkills = newSkillSystem:getEntitySkills(0)
    TestRunner.assertEqual(1, loadedSkills["basic_analysis"].level, "Loaded skill level should match")
    TestRunner.assertEqual(50, loadedSkills["basic_analysis"].xp, "Loaded XP should match")
end)

-- Test: Data-driven skill system
TestRunner.test("SkillSystem: Data-driven skill definitions", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    -- Test skill categories
    local categories = skillSystem:getSkillCategories()
    TestRunner.assertNotNil(categories, "Should have skill categories")
    TestRunner.assertNotNil(categories["analysis"], "Should have analysis category")
    TestRunner.assertNotNil(categories["network"], "Should have network category")
    TestRunner.assertNotNil(categories["leadership"], "Should have leadership category")
    
    -- Test skills by category
    local analysisSkills = skillSystem:getSkillsByCategory("analysis")
    TestRunner.assertNotNil(analysisSkills, "Should have analysis skills")
    TestRunner.assertNotNil(analysisSkills["basic_analysis"], "Should have basic analysis in analysis category")
    
    -- Test prerequisite chain
    local prerequisites = skillSystem:getPrerequisiteChain("threat_hunting")
    TestRunner.assert(#prerequisites >= 2, "Threat hunting should have prerequisite chain")
end)

-- Test: Extended skill effects
TestRunner.test("SkillSystem: Extended skill effects", function()
    local eventBus = EventBus.new()
    local skillSystem = SkillSystem.new(eventBus)
    
    skillSystem:initializeEntity(0, "ceo")
    
    -- Get initial effects
    local initialEffects = skillSystem:getSkillEffects(0)
    TestRunner.assertEqual(0, initialEffects.IncidentSuccessRate, "Initial Incident success rate should be 0")
    TestRunner.assertEqual(0, initialEffects.contractGenerationRate, "Initial contract generation rate should be 0")
    
    -- Level up a skill with advanced effects (if we had one unlocked)
    skillSystem:awardXp(0, "team_coordination", 200) -- Level 1
    
    local effectsAfterLevelUp = skillSystem:getSkillEffects(0)
    TestRunner.assertEqual(0.02, effectsAfterLevelUp.teamEfficiencyBonus, "Should have team efficiency bonus")
    TestRunner.assertEqual(0.1, effectsAfterLevelUp.contractCapacity, "Should have contract capacity bonus")
end)