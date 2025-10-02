-- Tests for Specialist System - Idle Sec Ops

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local SpecialistSystem = require("specialist_system")
local EventBus = require("event_bus")

-- Test specialist system initialization
TestRunner.test("SpecialistSystem: Initialize with CEO", function()
    local eventBus = EventBus.new()
    
    -- Mock dataManager
    local mockDataManager = {
        getData = function(self, key)
            if key == "specialists" then
                return {
                    specialists = {
                        {id = "junior_analyst", name = "Junior Analyst"},
                        {id = "network_admin", name = "Network Admin"}
                    }
                }
            end
            return nil
        end
    }
    
    -- Mock skillSystem
    local mockSkillSystem = {
        initializeEntity = function() end,
        getSkillEffects = function() return {} end
    }
    
    local specialists = SpecialistSystem.new(eventBus, mockDataManager, mockSkillSystem)
    specialists:initialize()
    
    -- Should start with CEO (player)
    local allSpecialists = specialists:getAllSpecialists()
    local hasUser = false
    for id, specialist in pairs(allSpecialists) do
        if specialist.type == "ceo" then
            hasUser = true
            TestRunner.assertEqual("You (CEO)", specialist.name, "CEO should have correct name")
            break
        end
    end
    
    TestRunner.assert(hasUser, "Should start with CEO specialist")
    
    -- Should have some available specialists for hire
    local availableForHire = specialists:getAvailableForHire()
    TestRunner.assert(#availableForHire > 0, "Should have specialists available for hire")
end)

TestRunner.test("SpecialistSystem: Team bonuses calculation", function()
    local eventBus = EventBus.new()
    
    -- Mock dataManager
    local mockDataManager = {
        getData = function(self, key)
            if key == "specialists" then
                return {
                    specialists = {
                        {id = "junior_analyst", name = "Junior Analyst"},
                        {id = "network_admin", name = "Network Admin"}
                    }
                }
            end
            return nil
        end
    }
    
    -- Mock skillSystem
    local mockSkillSystem = {
        initializeEntity = function() end,
        getSkillEffects = function() return {} end
    }
    
    local specialists = SpecialistSystem.new(eventBus, mockDataManager, mockSkillSystem)
    specialists:initialize()
    
    -- Get team bonuses
    local bonuses = specialists:getTeamBonuses()
    
    TestRunner.assertNotNil(bonuses.efficiency, "Should have efficiency bonus")
    TestRunner.assertNotNil(bonuses.speed, "Should have speed bonus")
    TestRunner.assertNotNil(bonuses.defense, "Should have defense bonus")
    TestRunner.assert(bonuses.availableSpecialists >= 1, "Should have at least 1 available specialist (CEO)")
end)

TestRunner.test("SpecialistSystem: Specialist assignment", function()
    local eventBus = EventBus.new()
    
    -- Mock dataManager
    local mockDataManager = {
        getData = function(self, key)
            if key == "specialists" then
                return {
                    specialists = {
                        {id = "junior_analyst", name = "Junior Analyst"},
                        {id = "network_admin", name = "Network Admin"}
                    }
                }
            end
            return nil
        end
    }
    
    -- Mock skillSystem
    local mockSkillSystem = {
        initializeEntity = function() end,
        getSkillEffects = function() return {} end
    }
    
    local specialists = SpecialistSystem.new(eventBus, mockDataManager, mockSkillSystem)
    specialists:initialize()
    
    -- Find CEO
    local ceoId = nil
    for id, specialist in pairs(specialists:getAllSpecialists()) do
        if specialist.type == "ceo" then
            ceoId = id
            break
        end
    end
    
    TestRunner.assertNotNil(ceoId, "Should find CEO specialist")
    
    -- Assign CEO to activity
    local success = specialists:assignSpecialist(ceoId, 60) -- 60 second assignment
    TestRunner.assert(success, "Should successfully assign specialist")
    
    -- Check specialist is now busy
    local ceo = specialists:getSpecialist(ceoId)
    TestRunner.assertEqual("busy", ceo.status, "Specialist should be busy after assignment")
    
    -- Available specialists should be reduced
    local available = specialists:getAvailableSpecialists()
    local ceoAvailable = available[ceoId] ~= nil
    TestRunner.assert(not ceoAvailable, "CEO should not be in available list when busy")
end)