
require("spec.spec_helper")

local EventBus = require("src.utils.event_bus")
local ResourceSystem = require("src.systems.resource_system")

describe("ResourceSystem", function()
    local eventBus, rs

    before_each(function()
        eventBus = EventBus.new()
        rs = ResourceSystem.new(eventBus)
    end)

    it("initializes with default resources", function()
        local resources = rs:getAllResources()
        assert.is_table(resources)
        assert.are.equal(0, resources.dataBits)
    end)

    it("can add and spend resources", function()
        rs:addResource("dataBits", 100)
        assert.are.equal(100, rs:getResource("dataBits"))
        local ok = rs:spendResource("dataBits", 30)
        assert.is_true(ok)
        assert.are.equal(70, rs:getResource("dataBits"))
    end)

    it("can check affordability and spend multiple resources", function()
        rs:setResource("dataBits", 50)
        rs:setResource("processingPower", 10)
        assert.is_true(rs:canAfford({dataBits = 20, processingPower = 5}))
        assert.is_false(rs:canAfford({dataBits = 1000}))
        local ok = rs:spendResources({dataBits = 20, processingPower = 5})
        assert.is_true(ok)
        assert.are.equal(30, rs:getResource("dataBits"))
        assert.are.equal(5, rs:getResource("processingPower"))
    end)

    it("handles clicks and returns a table", function()
        local result = rs:click()
        assert.is_table(result)
        assert.is_number(result.reward)
        assert.is_number(result.combo)
    end)
end)
