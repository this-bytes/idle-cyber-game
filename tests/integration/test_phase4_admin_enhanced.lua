-- Integration Test for Phase 4: Enhanced Admin Mode
-- Tests manual assignment and enhanced dashboard functionality

print("🧪 Testing Phase 4: Enhanced Admin Mode Integration")
print("=" .. string.rep("=", 60))

-- Mock LÖVE framework
love = love or {
    timer = {
        getTime = function() return os.clock() end
    },
    filesystem = {
        getInfo = function() return nil end,
        read = function() return nil end,
        write = function() return true end
    },
    graphics = {
        getWidth = function() return 1920 end,
        getHeight = function() return 1080 end
    }
}

-- Test 1: IncidentSpecialistSystem - Manual Assignment Methods
print("\n📦 Test 1: Loading IncidentSpecialistSystem with new methods...")
local success, IncidentSpecialistSystem = pcall(require, "src.systems.incident_specialist_system")
if success then
    print("✅ IncidentSpecialistSystem loaded successfully")
else
    print("❌ Failed to load IncidentSpecialistSystem: " .. tostring(IncidentSpecialistSystem))
    os.exit(1)
end

-- Test 2: Create system and verify methods exist
print("\n📦 Test 2: Verifying new methods exist...")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.systems.resource_manager")

local eventBus = EventBus.new()
local resourceManager = ResourceManager.new(eventBus)
local incidentSystem = IncidentSpecialistSystem.new(eventBus, resourceManager)

if type(incidentSystem.getActiveIncidents) == "function" then
    print("✅ getActiveIncidents() method exists")
else
    print("❌ getActiveIncidents() method missing")
    os.exit(1)
end

if type(incidentSystem.getIncidentById) == "function" then
    print("✅ getIncidentById() method exists")
else
    print("❌ getIncidentById() method missing")
    os.exit(1)
end

if type(incidentSystem.manualAssignSpecialist) == "function" then
    print("✅ manualAssignSpecialist() method exists")
else
    print("❌ manualAssignSpecialist() method missing")
    os.exit(1)
end

if type(incidentSystem.setSpecialistSystem) == "function" then
    print("✅ setSpecialistSystem() method exists")
else
    print("❌ setSpecialistSystem() method missing")
    os.exit(1)
end

-- Test 3: GlobalStatsSystem - Manual Assignment Tracking
print("\n📦 Test 3: Loading GlobalStatsSystem with manual assignment tracking...")
local success, GlobalStatsSystem = pcall(require, "src.systems.global_stats_system")
if success then
    print("✅ GlobalStatsSystem loaded successfully")
else
    print("❌ Failed to load GlobalStatsSystem: " .. tostring(GlobalStatsSystem))
    os.exit(1)
end

-- Test 4: Verify manual assignment stats structure
print("\n📦 Test 4: Verifying manual assignment stats structure...")
local statsSystem = GlobalStatsSystem.new(eventBus, resourceManager)
statsSystem:initialize()

if statsSystem.stats.manualAssignmentStats then
    print("✅ manualAssignmentStats structure exists")
    
    if statsSystem.stats.manualAssignmentStats.totalManualAssignments ~= nil then
        print("✅ totalManualAssignments field exists")
    else
        print("❌ totalManualAssignments field missing")
        os.exit(1)
    end
    
    if statsSystem.stats.manualAssignmentStats.lastManualAssignment ~= nil then
        print("✅ lastManualAssignment field exists")
    else
        print("❌ lastManualAssignment field missing")
        os.exit(1)
    end
else
    print("❌ manualAssignmentStats structure missing")
    os.exit(1)
end

-- Test 5: Verify trackManualAssignment method
print("\n📦 Test 5: Verifying trackManualAssignment() method...")
if type(statsSystem.trackManualAssignment) == "function" then
    print("✅ trackManualAssignment() method exists")
else
    print("❌ trackManualAssignment() method missing")
    os.exit(1)
end

-- Test 6: Test manual assignment tracking
print("\n📦 Test 6: Testing manual assignment tracking...")
local testData = {
    specialistId = "test-specialist-1",
    incidentId = "test-incident-1",
    stage = "detect",
    timestamp = os.clock()
}

statsSystem:trackManualAssignment(testData)

if statsSystem.stats.manualAssignmentStats.totalManualAssignments == 1 then
    print("✅ Manual assignment counter incremented")
else
    print("❌ Manual assignment counter not updated")
    os.exit(1)
end

if statsSystem.stats.manualAssignmentStats.lastManualAssignment then
    print("✅ Last manual assignment recorded")
else
    print("❌ Last manual assignment not recorded")
    os.exit(1)
end

-- Test 7: Verify enhanced getDashboardData
print("\n📦 Test 7: Verifying enhanced getDashboardData()...")
local dashboardData = statsSystem:getDashboardData()

if dashboardData.workloadPercentage ~= nil then
    print("✅ workloadPercentage field in dashboard data")
else
    print("❌ workloadPercentage field missing from dashboard data")
    os.exit(1)
end

if dashboardData.slaComplianceRate ~= nil then
    print("✅ slaComplianceRate field in dashboard data")
else
    print("❌ slaComplianceRate field missing from dashboard data")
    os.exit(1)
end

if dashboardData.totalSpecialists ~= nil then
    print("✅ totalSpecialists field in dashboard data")
else
    print("❌ totalSpecialists field missing from dashboard data")
    os.exit(1)
end

-- Test 8: AdminModeEnhanced scene can be loaded
print("\n📦 Test 8: Loading AdminModeEnhanced scene...")
local success, AdminModeEnhanced = pcall(require, "src.scenes.admin_mode_enhanced_luis")
if success then
    print("✅ AdminModeEnhanced scene loaded successfully")
else
    print("❌ Failed to load AdminModeEnhanced: " .. tostring(AdminModeEnhanced))
    os.exit(1)
end

-- Test 9: Scene can be instantiated (with mock LUIS)
print("\n📦 Test 9: Creating AdminModeEnhanced instance...")
local mockLuis = {
    newLayer = function() end,
    setCurrentLayer = function() end,
    insertElement = function() end,
    newLabel = function() return {} end,
    newButton = function() return {} end,
    isLayerEnabled = function() return false end,
    disableLayer = function() end,
    gridSize = 16,
    setTheme = function() end
}

local mockSystems = {
    globalStatsSystem = statsSystem,
    Incident = incidentSystem,
    specialistSystem = {}
}

local scene = AdminModeEnhanced.new(eventBus, mockLuis, mockSystems)

if scene then
    print("✅ AdminModeEnhanced scene instantiated")
else
    print("❌ Failed to instantiate AdminModeEnhanced scene")
    os.exit(1)
end

-- Test 10: Verify scene methods
print("\n📦 Test 10: Verifying AdminModeEnhanced methods...")
if type(scene.load) == "function" then
    print("✅ load() method exists")
else
    print("❌ load() method missing")
    os.exit(1)
end

if type(scene.refreshData) == "function" then
    print("✅ refreshData() method exists")
else
    print("❌ refreshData() method missing")
    os.exit(1)
end

if type(scene.manuallyAssignSpecialist) == "function" then
    print("✅ manuallyAssignSpecialist() method exists")
else
    print("❌ manuallyAssignSpecialist() method missing")
    os.exit(1)
end

-- Test 11: Event flow test
print("\n📦 Test 11: Testing manual assignment event flow...")
local eventReceived = false
eventBus:subscribe("manual_assignment_requested", function(data)
    eventReceived = true
    print("✅ manual_assignment_requested event received")
end)

-- Simulate manual assignment
scene:manuallyAssignSpecialist("specialist-1", "incident-1")

if eventReceived then
    print("✅ Event flow working correctly")
else
    print("❌ Event not received")
    os.exit(1)
end

-- All tests passed
print("\n" .. string.rep("=", 60))
print("✅ All Phase 4 Integration Tests PASSED!")
print("\nPhase 4 Features Verified:")
print("  ✓ Manual assignment methods in IncidentSpecialistSystem")
print("  ✓ Manual assignment tracking in GlobalStatsSystem")
print("  ✓ Enhanced dashboard data fields")
print("  ✓ AdminModeEnhanced scene structure")
print("  ✓ Event-driven manual assignment workflow")
print(string.rep("=", 60))
