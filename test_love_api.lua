-- Test API Integration in LÖVE 2D Environment
-- Run with: love . --test-api

local api = require("api")

local TestRunner = {
    tests = {},
    currentTest = 0,
    results = {},
    testStartTime = 0,
    totalTests = 0,
    passedTests = 0,
    failedTests = 0
}

function TestRunner:addTest(name, testFunc)
    table.insert(self.tests, {name = name, func = testFunc})
    self.totalTests = self.totalTests + 1
end

function TestRunner:runNextTest()
    if self.currentTest < #self.tests then
        self.currentTest = self.currentTest + 1
        local test = self.tests[self.currentTest]
        print("Running test " .. self.currentTest .. "/" .. #self.tests .. ": " .. test.name)
        self.testStartTime = love.timer.getTime()
        test.func()
    else
        self:printResults()
    end
end

function TestRunner:testComplete(name, success, message)
    local duration = love.timer.getTime() - self.testStartTime
    local result = {
        name = name,
        success = success,
        message = message or "",
        duration = duration
    }
    
    table.insert(self.results, result)
    
    if success then
        self.passedTests = self.passedTests + 1
        print("✅ " .. name .. " (" .. string.format("%.2fs", duration) .. ")")
    else
        self.failedTests = self.failedTests + 1
        print("❌ " .. name .. " (" .. string.format("%.2fs", duration) .. ")")
        print("   Error: " .. message)
    end
    
    -- Run next test after a brief delay
    local timer = love.timer.getTime()
    while love.timer.getTime() - timer < 0.5 do
        api.update() -- Keep processing async requests
    end
    
    self:runNextTest()
end

function TestRunner:printResults()
    print("\n" .. string.rep("=", 50))
    print("🧪 API Integration Test Results")
    print(string.rep("=", 50))
    print("Total Tests: " .. self.totalTests)
    print("Passed: " .. self.passedTests)
    print("Failed: " .. self.failedTests)
    print("Success Rate: " .. string.format("%.1f%%", (self.passedTests / self.totalTests) * 100))
    
    if self.failedTests > 0 then
        print("\nFailed Tests:")
        for _, result in ipairs(self.results) do
            if not result.success then
                print("  - " .. result.name .. ": " .. result.message)
            end
        end
    end
    
    print("\nTest completed in LÖVE 2D environment")
    print("Press ESC to exit")
end

-- Test 1: Connection Test
TestRunner:addTest("Connection Test", function()
    api.testConnection(function(success, result)
        TestRunner:testComplete("Connection Test", success, result)
    end)
end)

-- Test 2: Create Player
TestRunner:addTest("Create Player", function()
    local testUsername = "love_test_" .. os.time()
    api.createPlayer(testUsername, function(success, result)
        if success then
            -- Store username for later tests
            TestRunner.testUsername = testUsername
        end
        TestRunner:testComplete("Create Player", success, result)
    end)
end)

-- Test 3: Load Player
TestRunner:addTest("Load Player", function()
    if TestRunner.testUsername then
        api.loadPlayer(TestRunner.testUsername, function(success, result)
            TestRunner:testComplete("Load Player", success, result)
        end)
    else
        TestRunner:testComplete("Load Player", false, "No test username available")
    end
end)

-- Test 4: Save Player Data
TestRunner:addTest("Save Player Data", function()
    if TestRunner.testUsername then
        local additionalData = {
            reputation = 100,
            xp = 250,
            mission_tokens = 3
        }
        api.savePlayer(TestRunner.testUsername, 10000, 2, additionalData, function(success, result)
            TestRunner:testComplete("Save Player Data", success, result)
        end)
    else
        TestRunner:testComplete("Save Player Data", false, "No test username available")
    end
end)

-- Test 5: Load Updated Player
TestRunner:addTest("Load Updated Player", function()
    if TestRunner.testUsername then
        api.loadPlayer(TestRunner.testUsername, function(success, result)
            if success and result and result.player then
                local player = result.player
                local expectedCurrency = 10000
                local actualCurrency = player.current_currency
                
                if actualCurrency == expectedCurrency then
                    TestRunner:testComplete("Load Updated Player", true, "Data matches")
                else
                    TestRunner:testComplete("Load Updated Player", false, 
                        "Currency mismatch: expected " .. expectedCurrency .. ", got " .. actualCurrency)
                end
            else
                TestRunner:testComplete("Load Updated Player", false, result)
            end
        end)
    else
        TestRunner:testComplete("Load Updated Player", false, "No test username available")
    end
end)

-- Test 6: Global State
TestRunner:addTest("Global State", function()
    api.getGlobalState(function(success, result)
        TestRunner:testComplete("Global State", success, result)
    end)
end)

-- Love2D callbacks for test runner
function love.load()
    print("🧪 Starting API Integration Tests in LÖVE 2D...")
    print("Make sure the Flask server is running on localhost:5000")
    print("")
    
    -- Start the first test
    TestRunner:runNextTest()
end

function love.update(dt)
    -- Update API to handle async requests
    api.update()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("API Integration Test Running...", 10, 10)
    love.graphics.print("Check console for results", 10, 30)
    love.graphics.print("Press ESC to exit", 10, 50)
    
    -- Show current test status
    if TestRunner.currentTest > 0 and TestRunner.currentTest <= #TestRunner.tests then
        local test = TestRunner.tests[TestRunner.currentTest]
        love.graphics.print("Current: " .. test.name, 10, 80)
    end
    
    -- Show progress
    love.graphics.print("Progress: " .. TestRunner.currentTest .. "/" .. TestRunner.totalTests, 10, 100)
    love.graphics.print("Passed: " .. TestRunner.passedTests, 10, 120)
    love.graphics.print("Failed: " .. TestRunner.failedTests, 10, 140)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end