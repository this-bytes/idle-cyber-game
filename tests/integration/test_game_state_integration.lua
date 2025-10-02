-- Integration Test for GameStateEngine with SOCGame
-- Tests the complete state management flow including save/load and offline earnings

package.path = package.path .. ";./src/?.lua;./?.lua"

local mockLove = require("tests.mock_love")
_G.love = mockLove

-- Load the GameStateEngine
local GameStateEngine = require("src.systems.game_state_engine")
local ResourceManager = require("src.systems.resource_manager")
local IdleSystem = require("src.systems.idle_system")

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

-- Mock ThreatSystem
local MockThreatSystem = {}
MockThreatSystem.__index = MockThreatSystem

function MockThreatSystem.new()
    local self = setmetatable({}, MockThreatSystem)
    self.threatReduction = 0.1
    return self
end

function MockThreatSystem:getState()
    return { threatReduction = self.threatReduction }
end

function MockThreatSystem:loadState(state)
    if state.threatReduction then
        self.threatReduction = state.threatReduction
    end
end

-- Mock UpgradeSystem
local MockUpgradeSystem = {}
MockUpgradeSystem.__index = MockUpgradeSystem

function MockUpgradeSystem.new()
    local self = setmetatable({}, MockUpgradeSystem)
    self.owned = {}
    return self
end

function MockUpgradeSystem:getState()
    return { owned = self.owned }
end

function MockUpgradeSystem:loadState(state)
    if state.owned then
        self.owned = state.owned
    end
end

-- Test Suite
local TestIntegration = {}

function TestIntegration.run_all_tests()
    print("🧪 Running GameStateEngine Integration Tests...")
    print("=" .. string.rep("=", 50))
    
    local passed = 0
    local failed = 0
    
    -- Test 1: Full Game State Flow
    local success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Create game systems
        local resourceManager = ResourceManager.new(eventBus)
        local threatSystem = MockThreatSystem.new()
        local upgradeSystem = MockUpgradeSystem.new()
        local idleSystem = IdleSystem.new(eventBus, resourceManager, threatSystem, upgradeSystem)
        
        -- Register systems
        engine:registerSystem("resourceManager", resourceManager)
        engine:registerSystem("threatSystem", threatSystem)
        engine:registerSystem("upgradeSystem", upgradeSystem)
        engine:registerSystem("idleSystem", idleSystem)
        
        -- Modify some state
        resourceManager:addResource("money", 5000)
        resourceManager:addResource("reputation", 10)
        
        -- Save state
        local saveSuccess = engine:saveState()
        assert(saveSuccess, "Save should succeed")
        
        -- Modify state
        resourceManager.resources.money = 0
        resourceManager.resources.reputation = 0
        
        -- Load state
        local loadSuccess = engine:loadState()
        assert(loadSuccess, "Load should succeed")
        
        -- Verify state restored
        local money = resourceManager:getResource("money")
        assert(money > 5000, "Money should be restored (includes generation)")
        
        print("✅ Test 1: Full Game State Flow")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 1: Full Game State Flow - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 2: Offline Earnings Calculation
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Create game systems
        local resourceManager = ResourceManager.new(eventBus)
        local threatSystem = MockThreatSystem.new()
        local upgradeSystem = MockUpgradeSystem.new()
        local idleSystem = IdleSystem.new(eventBus, resourceManager, threatSystem, upgradeSystem)
        
        -- Register systems
        engine:registerSystem("resourceManager", resourceManager)
        engine:registerSystem("idleSystem", idleSystem)
        
        -- Set up initial state
        resourceManager:addResource("money", 1000)
        resourceManager:addResource("reputation", 5)
        
        -- Simulate save with old timestamp
        engine.state.lastSaveTime = os.time() - 300 -- 5 minutes ago
        
        -- Calculate offline earnings
        local offlineProgress = engine:calculateOfflineEarnings()
        
        assert(offlineProgress ~= nil, "Offline progress should be calculated")
        assert(offlineProgress.idleTime >= 300, "Idle time should be at least 300 seconds")
        assert(offlineProgress.earnings > 0, "Should have some earnings")
        
        -- Check that events were published
        local foundEvent = false
        for _, event in ipairs(eventBus.events) do
            if event.name == "offline_earnings_calculated" then
                foundEvent = true
                break
            end
        end
        assert(foundEvent, "Offline earnings event should be published")
        
        print("✅ Test 2: Offline Earnings Calculation")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 2: Offline Earnings Calculation - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 3: Auto-save Functionality
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Create game systems
        local resourceManager = ResourceManager.new(eventBus)
        engine:registerSystem("resourceManager", resourceManager)
        
        -- Set very short auto-save interval for testing
        engine.autoSaveInterval = 0.1
        
        -- Update to trigger auto-save
        engine:update(0.15)
        
        -- Check that save event was published
        local foundEvent = false
        for _, event in ipairs(eventBus.events) do
            if event.name == "game_state_saved" then
                foundEvent = true
                break
            end
        end
        assert(foundEvent, "Auto-save event should be published")
        
        print("✅ Test 3: Auto-save Functionality")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 3: Auto-save Functionality - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 4: State Persistence Across Sessions
    success, err = pcall(function()
        -- Session 1: Save state
        local eventBus1 = MockEventBus.new()
        local engine1 = GameStateEngine.new(eventBus1)
        
        local resourceManager1 = ResourceManager.new(eventBus1)
        engine1:registerSystem("resourceManager", resourceManager1)
        
        resourceManager1:addResource("money", 12345)
        resourceManager1:addResource("reputation", 67)
        
        engine1:saveState()
        
        -- Session 2: Load state
        local eventBus2 = MockEventBus.new()
        local engine2 = GameStateEngine.new(eventBus2)
        
        local resourceManager2 = ResourceManager.new(eventBus2)
        engine2:registerSystem("resourceManager", resourceManager2)
        
        local loadSuccess = engine2:loadState()
        assert(loadSuccess, "State should load in new session")
        
        -- Verify persistence
        local money = resourceManager2:getResource("money")
        assert(money >= 12345, "Money should persist across sessions")
        
        print("✅ Test 4: State Persistence Across Sessions")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 4: State Persistence Across Sessions - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Test 5: Multiple System State Management
    success, err = pcall(function()
        local eventBus = MockEventBus.new()
        local engine = GameStateEngine.new(eventBus)
        
        -- Create multiple systems
        local resourceManager = ResourceManager.new(eventBus)
        local threatSystem = MockThreatSystem.new()
        local upgradeSystem = MockUpgradeSystem.new()
        
        -- Register all systems
        engine:registerSystem("resourceManager", resourceManager)
        engine:registerSystem("threatSystem", threatSystem)
        engine:registerSystem("upgradeSystem", upgradeSystem)
        
        -- Modify all systems
        resourceManager:addResource("money", 999)
        threatSystem.threatReduction = 0.5
        upgradeSystem.owned["firewall"] = 3
        
        -- Save
        engine:saveState()
        
        -- Reset
        resourceManager.resources.money = 0
        threatSystem.threatReduction = 0
        upgradeSystem.owned = {}
        
        -- Load
        engine:loadState()
        
        -- Verify all systems restored
        assert(resourceManager:getResource("money") >= 999, "ResourceManager restored")
        assert(threatSystem.threatReduction == 0.5, "ThreatSystem restored")
        assert(upgradeSystem.owned["firewall"] == 3, "UpgradeSystem restored")
        
        print("✅ Test 5: Multiple System State Management")
        passed = passed + 1
    end)
    
    if not success then
        print("❌ Test 5: Multiple System State Management - " .. tostring(err))
        failed = failed + 1
    end
    
    -- Summary
    print("=" .. string.rep("=", 50))
    print(string.format("📊 Results: %d passed, %d failed", passed, failed))
    
    return passed, failed
end

-- Run tests if called directly
if arg and arg[0] and arg[0]:match("test_game_state_integration") then
    TestIntegration.run_all_tests()
end

return TestIntegration
