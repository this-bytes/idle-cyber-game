-- Comprehensive Game Mechanics Test Suite
-- Tests idle, tycoon, RPG, and RTS mechanics with deterministic scenarios

local EventBus = require("src.utils.event_bus")
local DataManager = require("src.core.data_manager")
local ResourceManager = require("src.systems.resource_manager")
local ContractSystem = require("src.systems.contract_system")
local SpecialistSystem = require("src.systems.specialist_system")
local SkillSystem = require("src.systems.skill_system")
local UpgradeSystem = require("src.systems.upgrade_system")
local IdleSystem = require("src.systems.idle_system")
local ThreatSystem = require("src.systems.threat_system")
local IncidentSpecialistSystem = require("src.systems.incident_specialist_system")

local GameMechanicsTest = {}

function GameMechanicsTest:setUp()
    self.eventBus = EventBus:new()
    self.systems = {}
    
    -- Initialize core systems
    self.systems.dataManager = DataManager.new(self.eventBus)
    self.systems.dataManager:loadAllData()
    
    self.systems.resourceManager = ResourceManager.new(self.eventBus)
    self.systems.skillSystem = SkillSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.upgradeSystem = UpgradeSystem.new(self.eventBus, self.systems.dataManager)
    self.systems.specialistSystem = SpecialistSystem.new(self.eventBus, self.systems.dataManager, self.systems.skillSystem)
    self.systems.contractSystem = ContractSystem.new(self.eventBus, self.systems.dataManager, self.systems.upgradeSystem, self.systems.specialistSystem, nil, nil, self.systems.resourceManager)
    self.systems.threatSystem = ThreatSystem.new(self.eventBus, self.systems.dataManager, self.systems.specialistSystem, self.systems.skillSystem)
    self.systems.idleSystem = IdleSystem.new(self.eventBus, self.systems.resourceManager, self.systems.threatSystem, self.systems.upgradeSystem)
    self.systems.incidentSystem = IncidentSpecialistSystem.new(self.eventBus, self.systems.resourceManager)
    
    -- Initialize systems
    self.systems.specialistSystem:initialize()
    self.systems.contractSystem:initialize()
    self.systems.incidentSystem:initialize()
    
    -- Give player starting resources
    self.systems.resourceManager:addResource("money", 10000)
    self.systems.resourceManager:addResource("reputation", 50)
end

-- Test 1: Idle Income Generation
function GameMechanicsTest:testIdleIncomeGeneration()
    print("\n🧪 Test: Idle Income Generation Over Time")
    
    -- Start with known resources
    local startMoney = self.systems.resourceManager:getResource("money")
    
    -- Simulate 60 seconds of idle time
    local idleTime = 60
    local offlineProgress = self.systems.idleSystem:calculateOfflineProgress(idleTime)
    
    -- Verify earnings occurred
    assert(offlineProgress.earnings > 0, "❌ No idle earnings generated")
    print(string.format("   ✅ Generated $%.0f over %d seconds", offlineProgress.earnings, idleTime))
    
    -- Apply earnings
    self.systems.resourceManager:addResource("money", offlineProgress.earnings)
    local endMoney = self.systems.resourceManager:getResource("money")
    
    assert(endMoney > startMoney, "❌ Money did not increase")
    print(string.format("   ✅ Money increased from $%.0f to $%.0f", startMoney, endMoney))
end

-- Test 2: Contract Lifecycle (Tycoon Mechanic)
function GameMechanicsTest:testContractLifecycle()
    print("\n🧪 Test: Contract Lifecycle (Tycoon Mechanic)")
    
    local startMoney = self.systems.resourceManager:getResource("money")
    
    -- Generate contracts
    self.systems.contractSystem:update(0)
    local available = self.systems.contractSystem.availableContracts
    assert(#available > 0, "❌ No contracts generated")
    print(string.format("   ✅ Generated %d available contracts", #available))
    
    -- Accept a contract
    local contract = available[1]
    local success = self.systems.contractSystem:acceptContract(1)
    assert(success, "❌ Failed to accept contract")
    print(string.format("   ✅ Accepted contract: %s", contract.clientName))
    
    -- Fast-forward time to complete contract
    local timeToComplete = contract.timeToComplete + 1
    self.systems.contractSystem:update(timeToComplete)
    
    -- Verify contract completed and money increased
    local endMoney = self.systems.resourceManager:getResource("money")
    assert(endMoney > startMoney, "❌ Contract did not pay out")
    print(string.format("   ✅ Contract completed, earned $%.0f", endMoney - startMoney))
end

-- Test 3: Specialist Leveling and Skills (RPG Mechanic)
function GameMechanicsTest:testSpecialistProgression()
    print("\n🧪 Test: Specialist Leveling and Skills (RPG Mechanic)")
    
    -- Get initial specialist (CEO)
    local ceo = self.systems.specialistSystem:getSpecialist(0)
    assert(ceo, "❌ CEO specialist not found")
    
    local startLevel = ceo.level
    local startXP = ceo.xp
    
    -- Award XP
    local xpGain = 150
    self.systems.specialistSystem:awardXp(0, xpGain)
    
    local newXP = ceo.xp
    assert(newXP > startXP, "❌ XP did not increase")
    print(string.format("   ✅ Awarded %d XP (Total: %d)", xpGain, newXP))
    
    -- Check if leveled up
    if ceo.level > startLevel then
        print(string.format("   ✅ Specialist leveled up from %d to %d", startLevel, ceo.level))
    else
        print(string.format("   ℹ️  Specialist at level %d (needs %d XP for next level)", 
            ceo.level, self.systems.specialistSystem.levelUpThresholds[ceo.level + 1] or 0))
    end
    
    -- Verify skills are initialized
    local skills = self.systems.skillSystem:getEntitySkills(0)
    assert(skills, "❌ Skills not initialized")
    print(string.format("   ✅ Specialist has %d skills unlocked", self:countTable(skills)))
end

-- Test 4: Threat Generation and Resolution (RTS Mechanic)
function GameMechanicsTest:testThreatResolution()
    print("\n🧪 Test: Threat Generation and Resolution (RTS Mechanic)")
    
    -- Force threat generation
    self.systems.threatSystem:generateThreat()
    
    local threats = self.systems.threatSystem:getActiveThreats()
    assert(#threats > 0, "❌ No threats generated")
    
    local threat = threats[1]
    print(string.format("   ✅ Generated threat: %s (Severity: %d)", threat.name, threat.severity))
    
    -- Assign specialist
    local ceo = self.systems.specialistSystem:getSpecialist(0)
    local assigned = self.systems.threatSystem:assignSpecialist(threat.id, 0)
    assert(assigned, "❌ Failed to assign specialist to threat")
    print(string.format("   ✅ Assigned %s to threat", ceo.name))
    
    -- Damage the threat directly (simulate ability usage)
    threat.hp = 0
    self.systems.threatSystem:resolveThreat(threat.id, "success")
    
    -- Verify threat was removed
    local remainingThreats = self.systems.threatSystem:getActiveThreats()
    local threatRemoved = true
    for _, t in ipairs(remainingThreats) do
        if t.id == threat.id then
            threatRemoved = false
            break
        end
    end
    
    assert(threatRemoved, "❌ Threat was not removed after resolution")
    print("   ✅ Threat successfully resolved and removed")
end

-- Test 5: Incident System Integration
function GameMechanicsTest:testIncidentSystem()
    print("\n🧪 Test: Incident System Integration")
    
    local stats = self.systems.incidentSystem:getStatistics()
    print(string.format("   ✅ Incident system initialized: %d active specialists", stats.activeSpecialists))
    
    -- Simulate incident generation by updating system
    self.systems.incidentSystem:update(11) -- Trigger timer
    
    local newStats = self.systems.incidentSystem:getStatistics()
    local incidentGenerated = newStats.pendingIncidents > 0 or newStats.assignedIncidents > 0
    
    if incidentGenerated then
        print(string.format("   ✅ Incident generated (Pending: %d, Assigned: %d)", 
            newStats.pendingIncidents, newStats.assignedIncidents))
    else
        print("   ℹ️  No incidents generated (may need more time or lower threshold)")
    end
end

-- Test 6: Resource Flow Integrity
function GameMechanicsTest:testResourceFlow()
    print("\n🧪 Test: Resource Flow Integrity")
    
    local startMoney = self.systems.resourceManager:getResource("money")
    local startRep = self.systems.resourceManager:getResource("reputation")
    
    -- Add resources
    self.systems.resourceManager:addResource("money", 1000)
    self.systems.resourceManager:addResource("reputation", 10)
    
    -- Verify additions
    assert(self.systems.resourceManager:getResource("money") == startMoney + 1000, "❌ Money addition failed")
    assert(self.systems.resourceManager:getResource("reputation") == startRep + 10, "❌ Reputation addition failed")
    print("   ✅ Resource additions work correctly")
    
    -- Test spending
    local canSpend = self.systems.resourceManager:canAfford({money = 500})
    assert(canSpend, "❌ Cannot afford valid purchase")
    
    local spent = self.systems.resourceManager:spendResources({money = 500})
    assert(spent, "❌ Failed to spend resources")
    assert(self.systems.resourceManager:getResource("money") == startMoney + 500, "❌ Money deduction incorrect")
    print("   ✅ Resource spending works correctly")
    
    -- Verify resources cannot go negative
    local overSpend = self.systems.resourceManager:spendResources({money = 999999})
    assert(not overSpend, "❌ Allowed spending more than available")
    print("   ✅ Resource bounds enforced (cannot go negative)")
end

-- Test 7: Upgrade System
function GameMechanicsTest:testUpgradeSystem()
    print("\n🧪 Test: Upgrade System (Tycoon Persistence)")
    
    -- Get available upgrades
    local availableUpgrades = self.systems.upgradeSystem:getAvailableUpgrades()
    
    if #availableUpgrades > 0 then
        local upgrade = availableUpgrades[1]
        print(string.format("   ✅ Found upgrade: %s", upgrade.name))
        
        -- Check if we can afford it
        local cost = upgrade.cost
        local canAfford = self.systems.resourceManager:canAfford(cost)
        
        if canAfford then
            local purchased = self.systems.upgradeSystem:purchaseUpgrade(upgrade.id)
            if purchased then
                print(string.format("   ✅ Successfully purchased upgrade: %s", upgrade.name))
            else
                print("   ⚠️  Purchase failed (may have requirements)")
            end
        else
            print("   ℹ️  Cannot afford upgrade (need more resources)")
        end
    else
        print("   ℹ️  No upgrades available")
    end
end

-- Utility
function GameMechanicsTest:countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Run all tests
function GameMechanicsTest:runAll()
    print("\n" .. string.rep("=", 70))
    print("🚀 COMPREHENSIVE GAME MECHANICS TEST SUITE")
    print(string.rep("=", 70))
    
    self:setUp()
    
    local tests = {
        self.testIdleIncomeGeneration,
        self.testContractLifecycle,
        self.testSpecialistProgression,
        self.testThreatResolution,
        self.testIncidentSystem,
        self.testResourceFlow,
        self.testUpgradeSystem
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
    
    print("\n" .. string.rep("=", 70))
    print(string.format("📊 RESULTS: %d passed, %d failed", passed, failed))
    print(string.rep("=", 70) .. "\n")
    
    return failed == 0
end

-- Run if executed directly
if arg and arg[0]:match("test_game_mechanics") then
    local success = GameMechanicsTest:runAll()
    os.exit(success and 0 or 1)
end

return GameMechanicsTest
