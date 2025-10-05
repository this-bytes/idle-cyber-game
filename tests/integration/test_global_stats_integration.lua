-- Simple Integration Test for GlobalStatsSystem
-- This test can be run to verify the system integrates correctly

print("🧪 Testing GlobalStatsSystem Integration")
print("=" .. string.rep("=", 50))

-- Mock LÖVE framework
love = love or {
    timer = {
        getTime = function() return os.clock() end
    },
    filesystem = {
        getInfo = function() return nil end,
        read = function() return nil end,
        write = function() return true end
    }
}

-- Test 1: System can be required
print("\n📦 Test 1: Loading GlobalStatsSystem...")
local success, GlobalStatsSystem = pcall(require, "src.systems.global_stats_system")
if success then
    print("✅ GlobalStatsSystem loaded successfully")
else
    print("❌ Failed to load GlobalStatsSystem: " .. tostring(GlobalStatsSystem))
    os.exit(1)
end

-- Test 2: System can be instantiated
print("\n📦 Test 2: Creating GlobalStatsSystem instance...")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.systems.resource_manager")

local eventBus = EventBus.new()
local resourceManager = ResourceManager.new(eventBus)
local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)

if statsSystem then
    print("✅ GlobalStatsSystem instance created")
else
    print("❌ Failed to create GlobalStatsSystem instance")
    os.exit(1)
end

-- Test 3: System can be initialized
print("\n📦 Test 3: Initializing GlobalStatsSystem...")
statsSystem:initialize()
print("✅ GlobalStatsSystem initialized")

-- Test 4: Basic stats structure
print("\n📦 Test 4: Verifying stats structure...")
local stats = statsSystem:getStats()
assert(stats.company, "Missing company stats")
assert(stats.contracts, "Missing contract stats")
assert(stats.specialists, "Missing specialist stats")
assert(stats.incidents, "Missing incident stats")
assert(stats.performance, "Missing performance stats")
assert(stats.milestones, "Missing milestones")
print("✅ Stats structure is valid")

-- Test 5: Event handling
print("\n📦 Test 5: Testing event handling...")
eventBus:publish("contract_completed", {
    tier = 1,
    revenue = 1000
})
assert(stats.contracts.totalCompleted == 1, "Contract not tracked")
assert(stats.contracts.totalRevenue == 1000, "Revenue not tracked")
print("✅ Event handling works")

-- Test 6: Milestone system
print("\n📦 Test 6: Testing milestone system...")
local milestoneTriggered = false
eventBus:subscribe("milestone_unlocked", function(data)
    milestoneTriggered = true
end)

-- Trigger first contract milestone (already at 1)
assert(stats.milestones.firstContract == true, "First contract milestone should be unlocked")
print("✅ Milestone system works")

-- Test 7: Dashboard data
print("\n📦 Test 7: Testing dashboard data...")
local dashboard = statsSystem:getDashboardData()
assert(dashboard.overview, "Missing overview")
assert(dashboard.keyMetrics, "Missing key metrics")
assert(dashboard.recentActivity, "Missing recent activity")
assert(dashboard.performance, "Missing performance")
print("✅ Dashboard data generated")

-- Test 8: State management
print("\n📦 Test 8: Testing state management...")
local state = statsSystem:getState()
assert(state.stats, "Missing stats in state")

local statsSystem2 = GlobalStatsSystem.new(eventBus, resourceManager)
statsSystem2:loadState(state)
assert(statsSystem2.stats.contracts.totalCompleted == 1, "State not restored")
print("✅ State management works")

-- Test 9: Number formatting
print("\n📦 Test 9: Testing number formatting...")
assert(statsSystem:formatNumber(500) == "500", "Small number format failed")
assert(statsSystem:formatNumber(1500) == "1.5K", "Thousands format failed")
assert(statsSystem:formatNumber(1500000) == "1.5M", "Millions format failed")
print("✅ Number formatting works")

-- Summary
print("\n" .. string.rep("=", 50))
print("✅ All integration tests passed!")
print("📊 GlobalStatsSystem is working correctly")
print("\nStats Summary:")
print("  - Contracts Completed: " .. stats.contracts.totalCompleted)
print("  - Total Revenue: $" .. stats.contracts.totalRevenue)
print("  - Current Streak: " .. stats.contracts.currentStreak)
print("  - Company Tier: " .. stats.company.tier)
print("  - Milestones Unlocked: " .. (stats.milestones.firstContract and 1 or 0))
print(string.rep("=", 50))
