#!/usr/bin/env lua5.3
-- Simple Test Runner for Cyber Empire Command
-- Usage: lua5.3 tests/test_runner.lua

local TestRunner = {}

-- Simple assertion functions
function TestRunner.assert(condition, message)
    if not condition then
        error("ASSERTION FAILED: " .. (message or "Unknown error"))
    end
end

function TestRunner.assertEqual(expected, actual, message)
    if expected ~= actual then
        error("ASSERTION FAILED: " .. (message or "") .. 
              "\n  Expected: " .. tostring(expected) .. 
              "\n  Actual: " .. tostring(actual))
    end
end

function TestRunner.assertNotNil(value, message)
    if value == nil then
        error("ASSERTION FAILED: " .. (message or "Value should not be nil"))
    end
end

-- Test suite structure
local tests = {}
local passed = 0
local failed = 0

function TestRunner.test(name, testFunc)
    table.insert(tests, {name = name, func = testFunc})
end

function TestRunner.run()
    print("🧪 Running Cyber Empire Command Tests...")
    print("=" .. string.rep("=", 50))
    
    for _, test in ipairs(tests) do
        local success, error = pcall(test.func)
        if success then
            print("✅ " .. test.name)
            passed = passed + 1
        else
            print("❌ " .. test.name)
            print("   Error: " .. tostring(error))
            failed = failed + 1
        end
    end
    
    print("=" .. string.rep("=", 50))
    print(string.format("Tests completed: %d passed, %d failed", passed, failed))
    
    if failed > 0 then
        os.exit(1)
    end
end

-- Export for use in test files
_G.TestRunner = TestRunner

-- If run directly, execute tests
if arg and arg[0] and arg[0]:match("test_runner%.lua$") then
    -- Load all test files
    local test_files = {
        "tests/systems/test_resource_system.lua",
        "tests/systems/test_contract_system.lua",
        "tests/systems/test_specialist_system.lua",
        "tests/systems/test_progression_system.lua",  -- NEW: Progression system tests
        "tests/systems/test_idle_system.lua"

        -- TODO: Add more test files as they're created
    }
    
    for _, file in ipairs(test_files) do
        if io.open(file, "r") then
            dofile(file)
        else
            print("⚠️  Test file not found: " .. file)
        end
    end
    
    TestRunner.run()
end

return TestRunner