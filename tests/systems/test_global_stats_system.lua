-- Test file for GlobalStatsSystem
-- Tests statistics tracking, milestone unlocking, and dashboard data generation

local GlobalStatsSystem = require("src.systems.global_stats_system")
local ResourceManager = require("src.systems.resource_manager")
local EventBus = require("src.utils.event_bus")

-- Test GlobalStatsSystem initialization
TestRunner.test("GlobalStatsSystem - Initialization", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    
    TestRunner.assertNotNil(statsSystem, "GlobalStatsSystem should initialize")
    TestRunner.assertNotNil(statsSystem.stats, "Should have stats object")
    TestRunner.assertEqual(statsSystem.stats.contracts.totalCompleted, 0, "Should start with 0 completed contracts")
    TestRunner.assertEqual(statsSystem.stats.company.tier, "STARTUP", "Should start as STARTUP tier")
end)

-- Test contract completion tracking
TestRunner.test("GlobalStatsSystem - Contract Completion Tracking", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Simulate contract completion
    eventBus:publish("contract_completed", {
        tier = 2,
        revenue = 5000
    })
    
    TestRunner.assertEqual(statsSystem.stats.contracts.totalCompleted, 1, "Should track completed contract")
    TestRunner.assertEqual(statsSystem.stats.contracts.currentStreak, 1, "Should have streak of 1")
    TestRunner.assertEqual(statsSystem.stats.contracts.totalRevenue, 5000, "Should track revenue")
    TestRunner.assertEqual(statsSystem.stats.contracts.highestTierCompleted, 2, "Should track highest tier")
end)

-- Test contract failure tracking
TestRunner.test("GlobalStatsSystem - Contract Failure Tracking", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Build up a streak first
    eventBus:publish("contract_completed", { tier = 1, revenue = 1000 })
    eventBus:publish("contract_completed", { tier = 1, revenue = 1000 })
    
    TestRunner.assertEqual(statsSystem.stats.contracts.currentStreak, 2, "Should have streak of 2")
    
    -- Fail a contract
    eventBus:publish("contract_failed", { tier = 1 })
    
    TestRunner.assertEqual(statsSystem.stats.contracts.totalFailed, 1, "Should track failed contract")
    TestRunner.assertEqual(statsSystem.stats.contracts.currentStreak, 0, "Streak should reset to 0")
end)

-- Test incident resolution tracking
TestRunner.test("GlobalStatsSystem - Incident Resolution Tracking", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Simulate incident resolution
    eventBus:publish("incident_fully_resolved", {
        totalDuration = 120
    })
    
    TestRunner.assertEqual(statsSystem.stats.incidents.totalResolved, 1, "Should track resolved incident")
    TestRunner.assertEqual(statsSystem.stats.incidents.averageResolutionTime, 120, "Should track average resolution time")
    TestRunner.assertEqual(statsSystem.stats.incidents.fastestResolution, 120, "Should track fastest resolution")
    
    -- Add another resolution
    eventBus:publish("incident_fully_resolved", {
        totalDuration = 60
    })
    
    TestRunner.assertEqual(statsSystem.stats.incidents.totalResolved, 2, "Should track 2 resolved incidents")
    TestRunner.assertEqual(statsSystem.stats.incidents.averageResolutionTime, 90, "Average should be 90 seconds")
    TestRunner.assertEqual(statsSystem.stats.incidents.fastestResolution, 60, "Fastest should be 60 seconds")
    TestRunner.assertEqual(statsSystem.stats.incidents.slowestResolution, 120, "Slowest should be 120 seconds")
end)

-- Test specialist tracking
TestRunner.test("GlobalStatsSystem - Specialist Tracking", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Simulate specialist hiring
    eventBus:publish("specialist_hired", {})
    
    TestRunner.assertEqual(statsSystem.stats.specialists.totalHired, 1, "Should track hired specialist")
    TestRunner.assertEqual(statsSystem.stats.specialists.totalActive, 1, "Should track active specialist")
end)

-- Test milestone unlocking
TestRunner.test("GlobalStatsSystem - Milestone Unlocking", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    local milestoneUnlocked = false
    eventBus:subscribe("milestone_unlocked", function(data)
        milestoneUnlocked = true
    end)
    
    -- Complete first contract
    eventBus:publish("contract_completed", { tier = 1, revenue = 1000 })
    
    TestRunner.assertEqual(statsSystem.stats.milestones.firstContract, true, "First contract milestone should unlock")
    TestRunner.assertEqual(milestoneUnlocked, true, "Should publish milestone_unlocked event")
end)

-- Test success rate calculation
TestRunner.test("GlobalStatsSystem - Success Rate Calculation", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Resolve 8 incidents successfully and fail 2
    for i = 1, 8 do
        eventBus:publish("incident_fully_resolved", { totalDuration = 60 })
    end
    for i = 1, 2 do
        eventBus:publish("incident_failed", {})
    end
    
    local successRate = statsSystem:getSuccessRate()
    TestRunner.assertEqual(successRate, 80, "Success rate should be 80%")
end)

-- Test contract success rate calculation
TestRunner.test("GlobalStatsSystem - Contract Success Rate", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Complete 7 contracts and fail 3
    for i = 1, 7 do
        eventBus:publish("contract_completed", { tier = 1, revenue = 1000 })
    end
    for i = 1, 3 do
        eventBus:publish("contract_failed", { tier = 1 })
    end
    
    local successRate = statsSystem:getContractSuccessRate()
    TestRunner.assertEqual(successRate, 70, "Contract success rate should be 70%")
end)

-- Test dashboard data generation
TestRunner.test("GlobalStatsSystem - Dashboard Data", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Add some data
    eventBus:publish("contract_completed", { tier = 2, revenue = 5000 })
    eventBus:publish("incident_fully_resolved", { totalDuration = 60 })
    
    local dashboard = statsSystem:getDashboardData()
    
    TestRunner.assertNotNil(dashboard, "Should generate dashboard data")
    TestRunner.assertNotNil(dashboard.overview, "Should have overview")
    TestRunner.assertNotNil(dashboard.keyMetrics, "Should have key metrics")
    TestRunner.assertEqual(dashboard.recentActivity.contractsCompleted, 1, "Should show completed contracts")
end)

-- Test company tier progression
TestRunner.test("GlobalStatsSystem - Company Tier Progression", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    TestRunner.assertEqual(statsSystem.stats.company.tier, "STARTUP", "Should start as STARTUP")
    
    -- Complete 10 contracts and hire 4 specialists
    for i = 1, 10 do
        eventBus:publish("contract_completed", { tier = 1, revenue = 1000 })
    end
    for i = 1, 4 do
        eventBus:publish("specialist_hired", {})
    end
    
    -- Trigger tier update
    statsSystem:updateCompanyTier()
    
    TestRunner.assertEqual(statsSystem.stats.company.tier, "GROWING", "Should advance to GROWING tier")
end)

-- Test state save/load
TestRunner.test("GlobalStatsSystem - State Management", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem:initialize()
    
    -- Generate some data
    eventBus:publish("contract_completed", { tier = 3, revenue = 10000 })
    eventBus:publish("specialist_hired", {})
    
    -- Save state
    local state = statsSystem:getState()
    
    TestRunner.assertNotNil(state, "Should generate state")
    TestRunner.assertNotNil(state.stats, "State should have stats")
    
    -- Create new system and load state
    local statsSystem2 = GlobalStatsSystem.new(eventBus, resourceManager)
    statsSystem2:loadState(state)
    
    TestRunner.assertEqual(statsSystem2.stats.contracts.totalCompleted, 1, "Should restore completed contracts")
    TestRunner.assertEqual(statsSystem2.stats.contracts.totalRevenue, 10000, "Should restore revenue")
    TestRunner.assertEqual(statsSystem2.stats.specialists.totalHired, 1, "Should restore specialists")
end)

-- Test number formatting
TestRunner.test("GlobalStatsSystem - Number Formatting", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
    
    TestRunner.assertEqual(statsSystem:formatNumber(500), "500", "Should format small numbers")
    TestRunner.assertEqual(statsSystem:formatNumber(1500), "1.5K", "Should format thousands")
    TestRunner.assertEqual(statsSystem:formatNumber(1500000), "1.5M", "Should format millions")
end)

print("✅ All GlobalStatsSystem tests completed")
