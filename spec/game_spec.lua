-- Ensure love mock present before requiring game (some modules use love at require-time)
local helpers = require("spec.helpers.love_mock")
love = love or {}
love.timer = helpers.timer
love.filesystem = helpers.filesystem

local Game = require("src.game")

describe("src.game module", function()
    it("should expose core functions", function()
        assert.is_function(Game.init)
        assert.is_function(Game.update)
        assert.is_function(Game.draw)
        assert.is_function(Game.save)
    end)

    it("should allow getting state table", function()
        if Game.getState then
            local state = Game.getState()
            assert.is_table(state)
        else
            pending("getState not implemented yet")
        end
    end)
end)
