-- Tests for IdleDirector - deterministic idle controller

package.path = package.path .. ";src/?.lua;src/core/?.lua;src/utils/?.lua"

local testEnv = require("tests.test_environment")
testEnv.setup()

local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager")
local StatsSystem = require("src.core.stats_system")
local IdleDirector = require("src.core.idle_director")

TestRunner.test("IdleDirector: tick generates resources", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    local statsSystem = StatsSystem.new(eventBus)
    statsSystem:initialize()

    local idleDirector = IdleDirector.new(eventBus, resourceManager, statsSystem)
    idleDirector:initialize()

    idleDirector:update(1.0)
    local summary = idleDirector:getSummary()
    TestRunner.assert(summary.income > 0, "IdleDirector should generate income")
    TestRunner.assert(summary.reputation >= 0, "IdleDirector should generate reputation")
end)

TestRunner.test("IdleDirector: offline simulation respects cap", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    local statsSystem = StatsSystem.new(eventBus)
    statsSystem:initialize()

    local idleDirector = IdleDirector.new(eventBus, resourceManager, statsSystem)
    idleDirector:initialize()

    local offline = idleDirector:simulateOffline(60 * 60 * 24) -- simulate one day
    TestRunner.assert(offline.secondsSimulated <= idleDirector:getOfflineCapHours() * 3600,
        "Offline simulation should clamp to cap")
end)
