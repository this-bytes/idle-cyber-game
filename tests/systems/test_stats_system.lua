-- Tests for StatsSystem - SOC capability vectors

package.path = package.path .. ";src/?.lua;src/core/?.lua;src/utils/?.lua"

local testEnv = require("tests.test_environment")
testEnv.setup()

local EventBus = require("src.utils.event_bus")
local StatsSystem = require("src.core.stats_system")

TestRunner.test("StatsSystem: initializes with default stats", function()
    local eventBus = EventBus.new()
    local stats = StatsSystem.new(eventBus)
    stats:initialize()
    TestRunner.assertEqual(10, stats:getEffective("offense"), "Offense should start at 10")
    TestRunner.assertEqual(10, stats:getEffective("defense"), "Defense should start at 10")
end)

TestRunner.test("StatsSystem: applies modifiers via event bus", function()
    local eventBus = EventBus.new()
    local stats = StatsSystem.new(eventBus)
    stats:initialize()

    eventBus:publish("apply_stat_modifier", {
        sourceId = "test_mod",
        payload = {
            offense = { flat = 10, multiplier = 0.2 },
            detection = { multiplier = 0.1 }
        }
    })

    stats:update(0.016)
    local offense = stats:getEffective("offense")
    TestRunner.assert(offense > 10, "Offense should increase after modifier")

    local derived = stats:getDerived()
    TestRunner.assert(derived.socRating > 10, "SOC rating should increase")
end)

TestRunner.test("StatsSystem: respects caps adjustments", function()
    local eventBus = EventBus.new()
    local stats = StatsSystem.new(eventBus)
    stats:initialize()

    eventBus:publish("set_stat_cap", { stat = "offense", cap = 20 })
    eventBus:publish("apply_stat_modifier", {
        sourceId = "cap_test",
        payload = { offense = { flat = 50 } }
    })

    stats:update(0.016)
    TestRunner.assertEqual(20, math.floor(stats:getEffective("offense")), "Offense should clamp to new cap")
end)
