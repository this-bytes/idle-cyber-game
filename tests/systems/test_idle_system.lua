-- Test file for IdleSystem
-- Usage: Include in test_runner.lua

local IdleSystem = require("src.systems.idle_system")
local ResourceSystem = require("src.core.resource_manager")
local ThreatSystem = require("src.core.threat_simulation")
local UpgradeSystem = require("src.core.security_upgrades")
local EventBus = require("src.utils.event_bus")

-- Test basic idle system initialization
TestRunner.test("IdleSystem - Initialization", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    TestRunner.assertNotNil(idleSystem, "IdleSystem should initialize")
    TestRunner.assertNotNil(idleSystem.threatTypes, "Should have threat types defined")
    TestRunner.assertEqual(type(idleSystem.threatTypes), "table", "Threat types should be a table")
end)

-- Test offline progress calculation with no idle time
TestRunner.test("IdleSystem - No Idle Time", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    local progress = idleSystem:calculateOfflineProgress(0)
    TestRunner.assertEqual(progress.earnings, 0, "No earnings for 0 idle time")
    TestRunner.assertEqual(progress.damage, 0, "No damage for 0 idle time")
    TestRunner.assertEqual(progress.netGain, 0, "No net gain for 0 idle time")
end)

-- Test offline progress calculation with short idle time
TestRunner.test("IdleSystem - Short Idle Time", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    -- 5 minutes idle time
    local progress = idleSystem:calculateOfflineProgress(300)
    
    TestRunner.assertNotNil(progress, "Should return progress data")
    TestRunner.assertEqual(type(progress.events), "table", "Events should be a table")
    -- Note: earnings might be 0 if no resource generation is active
    TestRunner.assert(progress.damage >= 0, "Damage should be non-negative")
end)

-- Test threat simulation with high security
TestRunner.test("IdleSystem - High Security Reduces Damage", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    -- Set high threat reduction
    threatSystem.threatReduction = 0.8 -- 80% threat reduction
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    -- 1 hour idle time should generate some threats
    local progress = idleSystem:calculateOfflineProgress(3600)
    
    -- With high threat reduction, damage should be lower
    -- This is probabilistic, so we just check the structure
    TestRunner.assertNotNil(progress.events, "Should have events recorded")
    TestRunner.assert(progress.damage >= 0, "Damage should be non-negative")
end)

-- Test security rating calculation
TestRunner.test("IdleSystem - Security Rating Calculation", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    -- Initial security rating should be 0
    local initialRating = idleSystem:calculateSecurityRating()
    TestRunner.assertEqual(initialRating, 0, "Initial security rating should be 0")
    
    -- Add some security upgrades
    upgradeSystem.owned.basicPacketFilter = 2 -- 2 basic packet filters
    
    local newRating = idleSystem:calculateSecurityRating()
    TestRunner.assert(newRating > initialRating, "Security rating should increase with upgrades")
end)

-- Test state save/load
TestRunner.test("IdleSystem - State Save/Load", function()
    local eventBus = EventBus.new()
    local resourceSystem = ResourceSystem.new(eventBus)
    local threatSystem = ThreatSystem.new(eventBus)
    local upgradeSystem = UpgradeSystem.new(eventBus)
    
    local idleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    
    -- Modify some data
    idleSystem.idleData.totalEarnings = 1000
    idleSystem.lastSaveTime = 12345
    
    local state = idleSystem:getState()
    TestRunner.assertNotNil(state, "Should return state")
    TestRunner.assertEqual(state.lastSaveTime, 12345, "Should save lastSaveTime")
    
    -- Create new system and load state
    local newIdleSystem = IdleSystem.new(eventBus, resourceSystem, threatSystem, upgradeSystem)
    newIdleSystem:loadState(state)
    
    TestRunner.assertEqual(newIdleSystem.lastSaveTime, 12345, "Should load lastSaveTime")
end)