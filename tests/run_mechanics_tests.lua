#!/usr/bin/env lua
-- Headless Game Mechanics Test Runner
-- Runs without LÖVE/GUI dependencies

-- Mock LÖVE timer for headless environment
if not love then
    love = {
        timer = {
            getTime = function() return os.clock() end
        }
    }
end

-- Load the test suite
local GameMechanicsTest = require("tests.test_game_mechanics")

-- Run all tests
local success = GameMechanicsTest:runAll()

os.exit(success and 0 or 1)
