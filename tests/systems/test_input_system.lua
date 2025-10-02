-- Test Suite for Input System
-- Tests action mapping, debouncing, focus management, and event emission

local InputSystem = require("src.systems.input_system")
local EventBus = require("src.utils.event_bus")

-- Mock love.timer for testing
if not love then
    love = {
        timer = {
            getTime = function() return 0 end
        }
    }
end

local testResults = {}

-- Helper function to run a test
local function runTest(testName, testFunction)
    local success, errorMsg = pcall(testFunction)
    if success then
        print("✅ " .. testName)
        table.insert(testResults, { name = testName, success = true })
    else
        print("❌ " .. testName .. ": " .. tostring(errorMsg))
        table.insert(testResults, { name = testName, success = false, error = errorMsg })
    end
end

-- Test InputSystem initialization
runTest("InputSystem: Initialize system", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    assert(inputSystem ~= nil, "InputSystem should initialize")
    assert(inputSystem.actionMappings ~= nil, "Should have action mappings")
    assert(inputSystem.clickRegions ~= nil, "Should have click regions")
    assert(inputSystem:getActionCount() > 0, "Should have at least one action mapping")
end)

-- Test action mapping
runTest("InputSystem: Action mapping", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    -- Test key matching
    assert(inputSystem:keyMatchesAction("space", "manual_income"), "Space should match manual_income")
    assert(inputSystem:keyMatchesAction("m", "manual_income"), "M should match manual_income")
    assert(not inputSystem:keyMatchesAction("x", "manual_income"), "X should not match manual_income")
end)

-- Test keybind hints
runTest("InputSystem: Keybind hints", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    local hint = inputSystem:getKeybindHint("manual_income")
    assert(hint ~= "", "Should have keybind hint for manual_income")
    assert(string.find(hint, "SPACE") or string.find(hint, "M"), "Hint should contain SPACE or M")
end)

-- Test mouse region detection
runTest("InputSystem: Mouse region detection", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    -- Test money counter region (20,80 → 300,120)
    assert(inputSystem:mouseInRegion(50, 100, "money_counter"), "Should detect click in money counter")
    assert(not inputSystem:mouseInRegion(10, 10, "money_counter"), "Should not detect click outside money counter")
end)

-- Test debouncing
runTest("InputSystem: Debouncing", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    -- First trigger should work
    local result1 = inputSystem:shouldTriggerAction("test_action")
    assert(result1 == true, "First trigger should work")

    -- Immediate second trigger should be debounced
    local result2 = inputSystem:shouldTriggerAction("test_action")
    assert(result2 == false, "Second trigger should be debounced")

    -- Mock time passing
    love.timer.getTime = function() return 0.1 end -- 100ms later

    -- Third trigger should work
    local result3 = inputSystem:shouldTriggerAction("test_action")
    assert(result3 == true, "Third trigger should work after debounce time")
end)

-- Test focus management
runTest("InputSystem: Focus management", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    -- Mock focusable elements
    local element1 = { id = "button1", onFocusGained = function() end, onFocusLost = function() end }
    local element2 = { id = "button2", onFocusGained = function() end, onFocusLost = function() end }

    inputSystem:registerFocusable(element1, 1)
    inputSystem:registerFocusable(element2, 2)

    -- Should have focus on higher priority element
    assert(inputSystem.currentFocus.element == element2, "Should focus higher priority element")

    -- Test focus info
    local info = inputSystem:getCurrentFocusInfo()
    assert(string.find(info, "button2"), "Focus info should show button2")
end)

-- Test action triggering
runTest("InputSystem: Action triggering", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    local actionTriggered = false
    local triggerData = nil

    eventBus:subscribe("input_action_manual_income", function(event)
        actionTriggered = true
        triggerData = event
    end)

    -- Trigger action
    local result = inputSystem:triggerAction("manual_income", "test", {test = "data"})

    assert(result == true, "Action should trigger successfully")
    assert(actionTriggered == true, "Event should be emitted")
    assert(triggerData.source == "test", "Event should contain source")
    assert(triggerData.data.test == "data", "Event should contain data")
end)

-- Test keyboard input handling
runTest("InputSystem: Keyboard input", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    local actionTriggered = false
    eventBus:subscribe("input_action_manual_income", function(event)
        actionTriggered = true
    end)

    -- Simulate key press
    inputSystem:keypressed("space", "space", false)

    assert(actionTriggered == true, "Space key should trigger manual_income action")
end)

-- Test mouse input handling
runTest("InputSystem: Mouse input", function()
    local eventBus = EventBus.new()
    local inputSystem = InputSystem.new(eventBus)

    local actionTriggered = false
    eventBus:subscribe("input_action_manual_income", function(event)
        actionTriggered = true
    end)

    -- Simulate click in money counter region
    inputSystem:mousepressed(50, 100, 1, false, 1)

    assert(actionTriggered == true, "Click in money counter should trigger manual_income action")
end)

-- Run all tests
local function run_input_tests()
    print("🧪 Running Input System tests...")

    local passed = 0
    local failed = 0

    for _, result in ipairs(testResults) do
        if result.success then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end

    print(string.format("📊 Input System Test Results: %d passed, %d failed", passed, failed))
    return passed, failed
end

return {
    run_input_tests = run_input_tests
}
