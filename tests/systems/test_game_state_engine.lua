-- Tests for GameStateEngine
-- Verifies state management, save/load, and offline earnings

-- Mock LÖVE filesystem and timer
package.path = package.path .. ";./src/?.lua;./?.lua"

local mockLove = require("tests.mock_love")
_G.love = mockLove

-- Load the GameStateEngine
local GameStateEngine = require("src.systems.game_state_engine")

-- Mock EventBus
local MockEventBus = {}
MockEventBus.__index = MockEventBus

function MockEventBus.new()
    local self = setmetatable({}, MockEventBus)
    self.events = {}
    self.subscriptions = {}
    return self
end

function MockEventBus:publish(eventName, data)
    table.insert(self.events, {name = eventName, data = data})
end

function MockEventBus:subscribe(eventName, callback)
    if not self.subscriptions[eventName] then
        self.subscriptions[eventName] = {}
    end
    table.insert(self.subscriptions[eventName], callback)
end

-- Mock System with state management
local MockSystem = {}
MockSystem.__index = MockSystem

function MockSystem.new()
    local self = setmetatable({}, MockSystem)
    self.value = 100
    self.counter = 0
    return self
end

function MockSystem:getState()
    return {
        value = self.value,
        counter = self.counter
    }
end

function MockSystem:loadState(state)
    if state.value then
        self.value = state.value
    end
    if state.counter then
        self.counter = state.counter
    end
end

function MockSystem:update(dt)
    self.value = self.value + dt
    self.counter = self.counter + 1
end

-- Test Suite
local TestGameStateEngine = {}

function TestGameStateEngine.run_all_tests()
    print("🧪 Running GameStateEngine Tests...")
    print("=" .. string.rep("=", 50))
    
    local passed = 0
    local failed = 0
    
    -- Test 1: Initialization
    local success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        assert(engine ~= nil, "Engine should be created")
        assert(engine.state ~= nil, "Engine should have state")
        assert(engine.state.version == "1.0.0", "Version should be set")
        assert(engine.autoSaveEnabled == true, "Auto-save should be enabled by default")
        
        print("✅ Test 1: Initialization")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 1: Initialization - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 2: System Registration
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        local result = engine:registerSystem("testSystem", mockSystem)
        
        assert(result == true, "System should register successfully")
        assert(engine.systems.testSystem == mockSystem, "System should be stored")
        assert(engine.state.systemsReady.testSystem == true, "System should be marked ready")
        
        print("✅ Test 2: System Registration")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 2: System Registration - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 3: Get Complete State
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        mockSystem.value = 500
        mockSystem.counter = 10
        
        engine:registerSystem("testSystem", mockSystem)
        
        local state = engine:getCompleteState()
        
        assert(state ~= nil, "State should be returned")
        assert(state.version ~= nil, "State should have version")
        assert(state.systems ~= nil, "State should have systems")
        assert(state.systems.testSystem ~= nil, "State should include registered system")
        assert(state.systems.testSystem.value == 500, "System state should be captured")
        assert(state.systems.testSystem.counter == 10, "System state should be complete")
        
        print("✅ Test 3: Get Complete State")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 3: Get Complete State - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 4: Load Complete State
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        engine:registerSystem("testSystem", mockSystem)
        
        -- Create a state to load
        local stateToLoad = {
            version = "1.0.0",
            totalPlayTime = 1000,
            lastSaveTime = os.time() - 3600,
            systems = {
                testSystem = {
                    value = 999,
                    counter = 42
                }
            }
        }
        
        local result = engine:loadCompleteState(stateToLoad)
        
        assert(result == true, "State should load successfully")
        assert(mockSystem.value == 999, "System value should be loaded")
        assert(mockSystem.counter == 42, "System counter should be loaded")
        assert(engine.state.totalPlayTime == 1000, "Play time should be restored")
        
        print("✅ Test 4: Load Complete State")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 4: Load Complete State - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 5: Save and Load State
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        mockSystem.value = 777
        mockSystem.counter = 123
        
        engine:registerSystem("testSystem", mockSystem)
        
        -- Save state
        local saveResult = engine:saveState()
        assert(saveResult == true, "Save should succeed")
        
        -- Modify system state
        mockSystem.value = 0
        mockSystem.counter = 0
        
        -- Load state
        local loadResult = engine:loadState()
        assert(loadResult == true, "Load should succeed")
        
        -- Verify state was restored
        assert(mockSystem.value == 777, "System value should be restored")
        assert(mockSystem.counter == 123, "System counter should be restored")
        
        print("✅ Test 5: Save and Load State")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 5: Save and Load State - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 6: Auto-save Configuration
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Test enable/disable
        engine:setAutoSave(false)
        assert(engine.autoSaveEnabled == false, "Auto-save should be disabled")
        
        engine:setAutoSave(true)
        assert(engine.autoSaveEnabled == true, "Auto-save should be enabled")
        
        -- Test interval
        local result = engine:setAutoSaveInterval(30)
        assert(result == true, "Valid interval should be accepted")
        assert(engine.autoSaveInterval == 30, "Interval should be set")
        
        local invalidResult = engine:setAutoSaveInterval(5)
        assert(invalidResult == false, "Too short interval should be rejected")
        
        print("✅ Test 6: Auto-save Configuration")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 6: Auto-save Configuration - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 7: State Summary
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        engine:registerSystem("testSystem", mockSystem)
        
        local summary = engine:getStateSummary()
        
        assert(summary ~= nil, "Summary should be returned")
        assert(summary.version ~= nil, "Summary should have version")
        assert(summary.totalPlayTime ~= nil, "Summary should have play time")
        assert(summary.systemsRegistered == 1, "Summary should count systems")
        assert(summary.autoSaveEnabled ~= nil, "Summary should have auto-save status")
        
        print("✅ Test 7: State Summary")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 7: State Summary - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 8: Export and Import State
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        mockSystem.value = 555
        mockSystem.counter = 99
        
        engine:registerSystem("testSystem", mockSystem)
        
        -- Export state
        local exportedState = engine:exportState()
        assert(exportedState ~= nil, "Export should return string")
        assert(type(exportedState) == "string", "Export should be string")
        assert(#exportedState > 0, "Export should not be empty")
        
        -- Modify system
        mockSystem.value = 0
        mockSystem.counter = 0
        
        -- Import state
        local importResult = engine:importState(exportedState)
        assert(importResult == true, "Import should succeed")
        assert(mockSystem.value == 555, "System value should be restored from import")
        assert(mockSystem.counter == 99, "System counter should be restored from import")
        
        print("✅ Test 8: Export and Import State")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 8: Export and Import State - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 9: Reset State
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Modify state
        engine.state.totalPlayTime = 5000
        engine.timeSinceLastSave = 100
        
        -- Reset
        engine:resetState()
        
        assert(engine.state.totalPlayTime == 0, "Play time should be reset")
        assert(engine.timeSinceLastSave == 0, "Time since save should be reset")
        assert(engine.state.version == "1.0.0", "Version should be preserved")
        
        print("✅ Test 9: Reset State")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 9: Reset State - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 10: Update with Auto-save
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        local mockSystem = MockSystem.new()
        
        engine:registerSystem("testSystem", mockSystem)
        engine:setAutoSaveInterval(1) -- Set to 1 second for testing
        -- Override the interval check for testing
        engine.autoSaveInterval = 0.1
        
        local initialPlayTime = engine.state.totalPlayTime
        
        -- Update for 0.15 seconds (should trigger auto-save)
        engine:update(0.15)
        
        assert(engine.state.totalPlayTime > initialPlayTime, "Play time should increase")
        
        print("✅ Test 10: Update with Auto-save")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 10: Update with Auto-save - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Summary
    print("=" .. string.rep("=", 50))
    print(string.format("📊 Results: %d passed, %d failed", passed, failed))
    
    return passed, failed
end

-- Run tests if called directly
if arg and arg[0] and arg[0]:match("test_game_state_engine") then
    TestGameStateEngine.run_all_tests()
end

return TestGameStateEngine
