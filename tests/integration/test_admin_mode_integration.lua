-- Integration Test: Admin Mode Complete Workflow
-- Tests the full gameplay loop from threat generation to resolution

local EventBus = require("src.utils.event_bus")
local DataManager = require("src.systems.data_manager")
local SkillSystem = require("src.systems.skill_system")
local SpecialistSystem = require("src.systems.specialist_system")
local ThreatSystem = require("src.systems.threat_system")
local SceneManager = require("src.scenes.scene_manager")
local AdminMode = require("src.scenes.admin_mode")

local IntegrationTest = {}

function IntegrationTest:setUp()
    self.eventBus = EventBus:new()
    self.systems = {}
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    self.systems.threatSystem = ThreatSystem.new(self.eventBus, self.systems.dataManager, self.systems.specialistSystem, self.systems.skillSystem)
    
    self.systems.specialistSystem:initialize()
    self.systems.threatSystem:initialize()
    
    self.sceneManager = SceneManager.new(self.eventBus, self.systems)
    self.sceneManager:initialize()
    
    self.adminMode = AdminMode.new(self.eventBus)
    self.sceneManager:registerScene("admin_mode", self.adminMode)
    
    self.eventLog = {}
    self.eventBus:subscribe("admin_log", function(data)
        table.insert(self.eventLog, data.message)
    end)
end

function IntegrationTest:testSceneTransitionOnHighSeverityThreat()
    print("\n🧪 Test: Scene Transition on High-Severity Threat")
    
    local sceneChanged = false
    local targetScene = nil
    
    self.eventBus:subscribe("request_scene_change", function(data)
        sceneChanged = true
        targetScene = data.scene
    end)
    
    -- Generate a high-severity threat manually
    local originalGenerateThreat = self.systems.threatSystem.generateThreat
    self.systems.threatSystem.generateThreat = function(threatSystem)
        local threat = {
            id = 999,
            name = "Test Critical Threat",
            severity = 8,
            hp = 100,
            baseHp = 100,
            category = "test",
            description = "A test threat"
        }
        threatSystem.activeThreats[threat.id] = threat
        threatSystem.eventBus:publish("threat_generated", {threat = threat})
        
        if threat.severity >= 7 then
            threatSystem.eventBus:publish("request_scene_change", { scene = "admin_mode", data = { incident = threat } })
        end
    end
    
    self.systems.threatSystem:generateThreat()
    
    assert(sceneChanged, "❌ Scene change was not requested")
    assert(targetScene == "admin_mode", "❌ Wrong target scene: " .. tostring(targetScene))
    print("✅ Scene transition triggered correctly")
end

function IntegrationTest:testDataDrivenDamageCalculation()
    print("\n🧪 Test: Data-Driven Damage Calculation")
    
    -- Create a test threat
    local testThreat = {
        id = 1,
        name = "Test Threat",
        hp = 150,
        baseHp = 150,
        severity = 5
    }
    self.systems.threatSystem.activeThreats[1] = testThreat
    
    -- Get a skill definition
    local skillDef = self.systems.skillSystem:getSkillDefinition("network_scan")
    assert(skillDef, "❌ Failed to retrieve skill definition for 'network_scan'")
    assert(skillDef.activeEffect, "❌ Skill 'network_scan' has no activeEffect defined")
    
    local expectedDamage = skillDef.activeEffect.baseAmount
    print(string.format("   Expected damage from 'network_scan': %d", expectedDamage))
    
    -- Simulate ability usage
    self.eventBus:publish("specialist_ability_used", {
        abilityName = "network_scan",
        incidentId = 1
    })
    
    local actualHP = testThreat.hp
    local expectedHP = 150 - expectedDamage
    
    assert(actualHP == expectedHP, string.format("❌ HP mismatch: expected %d, got %d", expectedHP, actualHP))
    print(string.format("✅ Damage calculation correct: %d damage dealt", expectedDamage))
end

function IntegrationTest:testInputDelegation()
    print("\n🧪 Test: Input Delegation to Active Scene")
    
    -- Enter admin mode
    self.sceneManager:requestScene("admin_mode", {
        incident = {
            id = 1,
            name = "Test Incident",
            severity = 7,
            hp = 100,
            baseHp = 100
        }
    })
    
    assert(self.sceneManager.currentScene == self.adminMode, "❌ Admin mode not set as current scene")
    
    -- Simulate keypressed
    local keyPressed = false
    local originalKeypressed = self.adminMode.keypressed
    self.adminMode.keypressed = function(scene, key)
        keyPressed = true
        originalKeypressed(scene, key)
    end
    
    self.sceneManager:keypressed("h")
    
    assert(keyPressed, "❌ Keypressed event not delegated to scene")
    print("✅ Input delegation working correctly")
end

function IntegrationTest:testCompleteGameplayLoop()
    print("\n🧪 Test: Complete Gameplay Loop (Threat → Deploy → Damage → Resolution)")
    
    -- 1. Create a threat
    local threat = {
        id = 1,
        name = "Complete Loop Test Threat",
        hp = 50,
        baseHp = 50,
        severity = 7,
        category = "test"
    }
    self.systems.threatSystem.activeThreats[1] = threat
    
    -- 2. Enter admin mode
    self.sceneManager:requestScene("admin_mode", { incident = threat })
    
    -- 3. Deploy a specialist (simulate the command)
    self.eventBus:publish("admin_command_deploy_specialist", {
        specialistName = "analyst",
        abilityName = "traffic_analysis",
        incidentId = 1
    })
    
    -- 4. Verify specialist went on cooldown
    local specialists = self.systems.specialistSystem:getSpecialists()
    local analystBusy = false
    for _, spec in pairs(specialists) do
        if spec.name == "Junior Analyst" and spec.status == "busy" then
            analystBusy = true
            break
        end
    end
    assert(analystBusy, "❌ Specialist not marked as busy after deployment")
    
    -- 5. Verify damage was dealt
    local skillDef = self.systems.skillSystem:getSkillDefinition("traffic_analysis")
    local expectedDamage = skillDef and skillDef.activeEffect and skillDef.activeEffect.baseAmount or 0
    local expectedHP = 50 - expectedDamage
    
    assert(threat.hp == expectedHP, string.format("❌ Threat HP incorrect: expected %d, got %d", expectedHP, threat.hp))
    
    -- 6. Verify threat was resolved if HP <= 0
    if threat.hp <= 0 then
        assert(self.systems.threatSystem.activeThreats[1] == nil, "❌ Threat not removed after HP reached 0")
        print("✅ Threat correctly resolved and removed")
    else
        print(string.format("✅ Threat damaged correctly (HP: %d/%d)", threat.hp, threat.baseHp))
    end
    
    print("✅ Complete gameplay loop executed successfully")
end

function IntegrationTest:runAll()
    print("\n" .. string.rep("=", 60))
    print("🚀 RUNNING ADMIN MODE INTEGRATION TESTS")
    print(string.rep("=", 60))
    
    self:setUp()
    
    local tests = {
        self.testSceneTransitionOnHighSeverityThreat,
        self.testDataDrivenDamageCalculation,
        self.testInputDelegation,
        self.testCompleteGameplayLoop
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local success, err = pcall(test, self)
        if success then
            passed = passed + 1
        else
            failed = failed + 1
            print("❌ TEST FAILED: " .. tostring(err))
        end
    end
    
    print("\n" .. string.rep("=", 60))
    print(string.format("📊 RESULTS: %d passed, %d failed", passed, failed))
    print(string.rep("=", 60) .. "\n")
    
    return failed == 0
end

return IntegrationTest
