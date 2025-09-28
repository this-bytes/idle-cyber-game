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

-- Ensure test modules can require source files by short names
do
    local src_paths = "./?.lua;./?/init.lua;src/?.lua;src/?/init.lua;src/systems/?.lua;src/utils/?.lua;"
    package.path = src_paths .. package.path
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
    -- Load all test files and run them
    local test_files = {
        "tests/systems/test_resource_system.lua",
        "tests/systems/test_contract_system.lua",
        "tests/systems/test_specialist_system.lua",
        "tests/systems/test_skill_system.lua",
        "tests/systems/test_contract_system.lua", 
        "tests/systems/test_specialist_system.lua",
        "tests/systems/test_location_system.lua",     -- NEW: Location system tests
        "tests/systems/test_progression_system.lua", -- NEW: Progression system tests
        "tests/systems/test_idle_system.lua",        -- NEW: Idle system tests from main
        "tests/systems/test_soc_stats.lua"           -- SOC REFACTOR: SOC Stats system tests
    }
    
    -- Track total tests across all modules
    local total_passed = 0
    local total_failed = 0
    
    for _, file in ipairs(test_files) do
        if io.open(file, "r") then
            -- Load the test module
            local test_module = dofile(file)
            
            -- Run tests if the module has a test runner function
            if test_module and type(test_module) == "table" then
                for func_name, func in pairs(test_module) do
                    if type(func) == "function" and func_name:match("^run_.*_tests$") then
                        print("\n🧪 Running " .. func_name:gsub("run_", ""):gsub("_tests", "") .. " tests...")
                        local passed, failed = func()
                        total_passed = total_passed + passed
                        total_failed = total_failed + failed
                    end
                end
            end
        else
            print("⚠️  Test file not found: " .. file)
        end
    end
    
    -- Load legacy test files that use the old system
    dofile("tests/systems/test_resource_system.lua")
    dofile("tests/systems/test_contract_system.lua")
    dofile("tests/systems/test_specialist_system.lua")
    
    TestRunner.run()
    
    -- Add the legacy tests to the total
    total_passed = total_passed + passed
    total_failed = total_failed + failed
    
    print("\n🎯 FINAL RESULTS:")
    print("=" .. string.rep("=", 50))
    print(string.format("Total tests: %d passed, %d failed", total_passed, total_failed))
    
    if total_failed > 0 then
        os.exit(1)
    end
end

return TestRunner