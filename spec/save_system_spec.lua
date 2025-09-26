
require("spec.spec_helper")

local SaveSystem = require("src.systems.save_system")

describe("SaveSystem", function()
    local ss

    before_each(function()
        -- create fresh save system
        ss = SaveSystem.new()
    end)

    it("saves and loads data", function()
        local ok = ss:save({resources = {dataBits = 123}})
        assert.is_true(ok)

        local loaded = ss:load()
        assert.is_table(loaded)
        assert.is_table(loaded.resources)
        assert.are.equal(123, loaded.resources.dataBits)
    end)

    it("deleteSave works and saveExists reflects it", function()
        ss:save({foo = "bar"})
        assert.is_true(ss:saveExists())
        local deleted = ss:deleteSave()
        assert.is_true(deleted)
        assert.is_false(ss:saveExists())
    end)
end)
