#!/usr/bin/env lua
-- Headless Game Mechanics Test Runner
-- Runs without LÖVE/GUI dependencies

-- Add project paths BEFORE loading anything
package.path = package.path .. ";./?.lua;./src/?.lua"

-- Initialize LÖVE mocks for headless environment
require("tests.headless_mock")

-- Load the test suite
local GameMechanicsTest = require("tests.test_game_mechanics")

-- Run all tests
local success = GameMechanicsTest:runAll()

os.exit(success and 0 or 1)
