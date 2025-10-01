#!/usr/bin/env lua
-- Integration Test Runner
-- Runs comprehensive integration tests for the game systems

package.path = package.path .. ";./?.lua"

-- Install mock LÖVE environment
local MockLove = require("tests.mock_love")
MockLove.install()

local IntegrationTest = require("tests.integration.test_admin_mode_integration")

print("\n🎮 SOC Game Integration Test Suite")
print("===================================\n")

local testSuite = IntegrationTest
local success = testSuite:runAll()

if success then
    print("✅ All integration tests passed!")
    os.exit(0)
else
    print("❌ Some integration tests failed!")
    os.exit(1)
end
