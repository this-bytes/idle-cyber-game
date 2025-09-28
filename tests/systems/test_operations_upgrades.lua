-- Tests for OperationsUpgrades - SOC economic upgrades

package.path = package.path .. ";src/?.lua;src/core/?.lua;src/utils/?.lua"

local testEnv = require("tests.test_environment")
testEnv.setup()

local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")
local StatsSystem = require("src.core.stats_system")
local OperationsUpgrades = require("src.core.operations_upgrades")

TestRunner.test("OperationsUpgrades: purchase applies effects", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    local statsSystem = StatsSystem.new(eventBus)
    statsSystem:initialize()

    -- Fund the organization
    resourceManager:addResource("money", 10000)
    resourceManager:addResource("reputation", 50)
    resourceManager:addResource("xp", 500)

    local upgrades = OperationsUpgrades.new(eventBus, resourceManager, statsSystem)
    upgrades:initialize()

    local success, reason = upgrades:canPurchase("automationSuite")
    TestRunner.assert(success, "Should be able to purchase automation suite: " .. tostring(reason))
    TestRunner.assert(upgrades:purchase("automationSuite"), "Purchase should succeed")

    local owned = upgrades:getOwnedCount("automationSuite")
    TestRunner.assertEqual(1, owned, "Should own one automation suite")

    -- Verify stats received modifier (update stats system to flush event)
    statsSystem:update(0.016)
    TestRunner.assert(statsSystem:getEffective("analysis") > 10, "Analysis stat should increase from upgrade")
end)
