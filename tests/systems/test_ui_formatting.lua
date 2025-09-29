-- Tests for UI Formatting Functions - Phase 1 Core UI
-- Validates the UI formatting helpers and display logic

-- Add src to package path for testing
package.path = package.path .. ";src/?.lua;src/systems/?.lua;src/utils/?.lua;src/core/?.lua"

-- Mock love.timer for testing
love = love or {}
love.timer = love.timer or {}
love.timer.getTime = function() return os.clock() end

local UIManager = require("src.core.ui_manager")
local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")

-- Test UI number formatting
TestRunner.test("UIManager: Format numbers correctly", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    local uiManager = UIManager.new(eventBus, resourceManager, nil, nil, nil)
    
    -- Test small numbers
    TestRunner.assertEqual("0", uiManager:formatNumber(0), "Should format 0 correctly")
    TestRunner.assertEqual("42", uiManager:formatNumber(42), "Should format small numbers correctly")
    TestRunner.assertEqual("999", uiManager:formatNumber(999), "Should format hundreds correctly")
    
    -- Test thousands
    TestRunner.assertEqual("1.00k", uiManager:formatNumber(1000), "Should format thousands correctly")
    TestRunner.assertEqual("1.23k", uiManager:formatNumber(1234), "Should format thousands with decimals")
    TestRunner.assertEqual("12.50k", uiManager:formatNumber(12500), "Should format tens of thousands")
    
    -- Test millions
    TestRunner.assertEqual("1.00m", uiManager:formatNumber(1000000), "Should format millions correctly")
    TestRunner.assertEqual("2.50m", uiManager:formatNumber(2500000), "Should format millions with decimals")
end)

-- Test income per second formatting
TestRunner.test("UIManager: Format income per second correctly", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    local uiManager = UIManager.new(eventBus, resourceManager, nil, nil, nil)
    
    -- Test various income rates
    TestRunner.assertEqual("0/sec", uiManager:formatIncomePerSec(0), "Should format zero income correctly")
    TestRunner.assertEqual("10/sec", uiManager:formatIncomePerSec(10), "Should format small income correctly")
    TestRunner.assertEqual("1.50k/sec", uiManager:formatIncomePerSec(1500), "Should format large income correctly")
    TestRunner.assertEqual("2.25m/sec", uiManager:formatIncomePerSec(2250000), "Should format millions income correctly")
end)

-- Test HUD data updates
TestRunner.test("UIManager: Update HUD data correctly", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local uiManager = UIManager.new(eventBus, resourceManager, nil, nil, nil)
    uiManager:initializePanels()
    
    -- Set some test values
    resourceManager:addResource("money", 5000) -- Should have 6000 total (1000 starting + 5000)
    resourceManager:addResource("reputation", 25)
    resourceManager:setGeneration("money", 150)
    
    -- Update HUD display
    uiManager:updateHUDDisplay()
    
    -- Check HUD data
    local hudData = uiManager.panelData[uiManager.UI_PANELS and uiManager.UI_PANELS.HUD or "hud"]
    TestRunner.assertEqual(6000, hudData.money, "Should update money correctly")
    TestRunner.assertEqual(25, hudData.reputation, "Should update reputation correctly")
    TestRunner.assertEqual(150, hudData.incomePerSec, "Should update income per second correctly")
end)

-- Test roster data initialization
TestRunner.test("UIManager: Initialize roster data correctly", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    local uiManager = UIManager.new(eventBus, resourceManager, nil, nil, nil)
    uiManager:initializePanels()
    
    -- Update roster display to initialize starter specialists
    uiManager:updateRosterDisplay()
    
    -- Check roster data
    local rosterData = uiManager.panelData[uiManager.UI_PANELS and uiManager.UI_PANELS.ROSTER or "roster"]
    TestRunner.assertNotNil(rosterData, "Roster data should exist")
    TestRunner.assertNotNil(rosterData.starterSpecialists, "Starter specialists should exist")
    TestRunner.assertEqual(3, #rosterData.starterSpecialists, "Should have 3 starter specialists")
    
    -- Check first specialist (CEO)
    local ceo = rosterData.starterSpecialists[1]
    TestRunner.assertEqual("You (CEO)", ceo.name, "CEO should have correct name")
    TestRunner.assertEqual("Security Lead", ceo.role, "CEO should have correct role")
    TestRunner.assertEqual(1, ceo.level, "CEO should start at level 1")
    TestRunner.assertEqual("Active", ceo.status, "CEO should be active")
    
    -- Check second specialist
    local analyst = rosterData.starterSpecialists[2]
    TestRunner.assertEqual("Alex Rivera", analyst.name, "Analyst should have correct name")
    TestRunner.assertEqual("Junior Analyst", analyst.role, "Analyst should have correct role")
    TestRunner.assertEqual("Ready", analyst.status, "Analyst should be ready")
    
    -- Check third specialist
    local admin = rosterData.starterSpecialists[3]
    TestRunner.assertEqual("Sam Chen", admin.name, "Admin should have correct name")
    TestRunner.assertEqual("Network Admin", admin.role, "Admin should have correct role")
    TestRunner.assertEqual("Ready", admin.status, "Admin should be ready")
end)

-- Test panel visibility for Phase 1
TestRunner.test("UIManager: Phase 1 panel visibility", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    local uiManager = UIManager.new(eventBus, resourceManager, nil, nil, nil)
    uiManager:initializePanels()
    
    -- Check that required panels are visible
    TestRunner.assertEqual(true, uiManager.panelVisibility.hud, "HUD panel should be visible")
    TestRunner.assertEqual(true, uiManager.panelVisibility.roster, "Roster panel should be visible")
    TestRunner.assertEqual(true, uiManager.panelVisibility.resources, "Resources panel should be visible")
    TestRunner.assertEqual(true, uiManager.panelVisibility.notifications, "Notifications panel should be visible")
    
    -- Check that optional panels start hidden
    TestRunner.assertEqual(false, uiManager.panelVisibility.threats, "Threats panel should start hidden")
    TestRunner.assertEqual(false, uiManager.panelVisibility.upgrades, "Upgrades panel should start hidden")
    TestRunner.assertEqual(false, uiManager.panelVisibility.stats, "Stats panel should start hidden")
end)