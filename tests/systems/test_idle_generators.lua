-- Test Suite for Idle Generators System
-- Tests dynamic item creation and resource generation

local IdleGenerators = require("src.systems.idle_generators")
local ResourceManager = require("src.core.resource_manager")
local EventBus = require("src.utils.event_bus")

-- Mock love.timer for testing but allow filesystem access
if not love then
    love = {
        timer = {
            getTime = function() return os.clock() end
        },
        filesystem = {
            getInfo = function(path) 
                -- Allow reading the idle generators JSON file
                if path == "src/data/idle_generators.json" then
                    local f = io.open(path, "r")
                    if f then
                        f:close()
                        return {type = "file"}
                    end
                end
                return nil
            end,
            read = function(path)
                local f = io.open(path, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    return content
                end
                return nil
            end
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

-- Test IdleGenerators initialization
runTest("IdleGenerators: Initialize system", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    local success = idleGenerators:initialize()
    
    assert(success == true, "Idle generators should initialize successfully")
    assert(idleGenerators:getTotalDefinitions() > 0, "Should have generator definitions")
    
    local categories = idleGenerators:getCategories()
    assert(next(categories) ~= nil, "Should have category definitions")
end)

-- Test generator purchase
runTest("IdleGenerators: Purchase generator", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    
    -- Add money to afford a generator
    local initialMoney = resourceManager:getResource("money") -- Should be 1000 (default)
    resourceManager:addResource("money", 2000)
    local totalMoney = resourceManager:getResource("money") -- Should be 3000
    
    -- Purchase a basic workstation
    local success, message = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    assert(success == true, "Should be able to purchase generator: " .. tostring(message))
    
    local owned = idleGenerators:getOwnedQuantity("equipment", "basic_workstation")
    assert(owned == 1, "Should own 1 basic workstation")
    
    -- Check money was spent
    local remainingMoney = resourceManager:getResource("money")
    assert(remainingMoney < totalMoney, "Money should have been spent (had " .. totalMoney .. ", now have " .. remainingMoney .. ")")
end)

-- Test generation from purchased generators
runTest("IdleGenerators: Resource generation", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    resourceManager:setIdleGenerators(idleGenerators)
    
    -- Set initial resources
    resourceManager:addResource("money", 2000)
    local initialMoney = resourceManager:getResource("money")
    
    -- Purchase a generator
    idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    
    -- Get current generation
    local generation = idleGenerators:getCurrentGeneration()
    assert(generation.money > 0, "Should generate money")
    assert(generation.xp > 0, "Should generate XP")
    
    -- Test total generation calculation
    local totalGen = resourceManager:getTotalGeneration()
    assert(totalGen.money > 0, "Total generation should include idle generators")
end)

-- Test cost scaling with multiple purchases
runTest("IdleGenerators: Cost scaling", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    
    -- Add lots of money
    resourceManager:addResource("money", 50000)
    
    -- Purchase first generator
    local success1 = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    assert(success1, "First purchase should succeed")
    
    local money1 = resourceManager:getResource("money")
    
    -- Purchase second generator (should cost more)
    local success2 = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    assert(success2, "Second purchase should succeed")
    
    local money2 = resourceManager:getResource("money")
    
    -- The cost difference should be greater than the base cost due to scaling
    local cost1 = 50000 - money1
    local cost2 = money1 - money2
    
    assert(cost2 > cost1, "Second purchase should cost more due to scaling")
end)

-- Test unlock requirements
runTest("IdleGenerators: Unlock requirements", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    
    -- Try to purchase a generator that requires reputation without having enough
    resourceManager:addResource("money", 50000)
    
    -- Check if we have any generators with unlock requirements
    local found_locked_generator = false
    for category, generators in pairs(idleGenerators.generatorDefinitions) do
        for _, generator in ipairs(generators) do
            if generator.unlockRequirements and next(generator.unlockRequirements) then
                -- Try to purchase this locked generator
                local success, message = idleGenerators:purchaseGenerator(category, generator.id, 1)
                assert(success == false, "Purchase should fail due to unlock requirements")
                assert(string.find(message, "not unlocked"), "Error message should mention unlock requirements")
                
                -- Add the required resources and try again
                for resource, required in pairs(generator.unlockRequirements) do
                    resourceManager:addResource(resource, required + 10) -- Add a bit extra
                end
                
                local success2, message2 = idleGenerators:purchaseGenerator(category, generator.id, 1)
                assert(success2 == true, "Purchase should succeed with requirements met: " .. tostring(message2))
                found_locked_generator = true
                break
            end
        end
        if found_locked_generator then break end
    end
    
    -- If no locked generators found, just test a basic one to ensure the test runs
    if not found_locked_generator then
        local success, message = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
        assert(success == true, "Basic generator should be purchasable")
    end
end)

-- Test max owned limits
runTest("IdleGenerators: Max owned limits", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    
    -- Add lots of money
    resourceManager:addResource("money", 100000)
    
    -- Basic workstation has maxOwned: 10
    -- Purchase 10 generators
    for i = 1, 10 do
        local success = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
        assert(success, "Purchase " .. i .. " should succeed")
    end
    
    -- Try to purchase the 11th one (should fail)
    local success, message = idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    assert(success == false, "Purchase should fail due to max owned limit")
    assert(string.find(message, "Maximum owned"), "Error message should mention max owned limit")
end)

-- Test state save/load
runTest("IdleGenerators: State persistence", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    
    -- Purchase some generators
    resourceManager:addResource("money", 10000)
    idleGenerators:purchaseGenerator("equipment", "basic_workstation", 3)
    
    -- Get state
    local state = idleGenerators:getState()
    assert(state.ownedGenerators ~= nil, "State should contain owned generators")
    
    -- Create new system and load state
    local newIdleGenerators = IdleGenerators.new(eventBus, resourceManager)
    newIdleGenerators:initialize()
    newIdleGenerators:loadState(state)
    
    -- Check that generators were restored
    local owned = newIdleGenerators:getOwnedQuantity("equipment", "basic_workstation")
    assert(owned == 3, "Owned generators should be restored from save")
end)

-- Test integration with ResourceManager update cycle
runTest("IdleGenerators: Integration with ResourceManager", function()
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus)
    resourceManager:initialize()
    
    local idleGenerators = IdleGenerators.new(eventBus, resourceManager)
    idleGenerators:initialize()
    resourceManager:setIdleGenerators(idleGenerators)
    
    -- Purchase a generator
    resourceManager:addResource("money", 2000)
    idleGenerators:purchaseGenerator("equipment", "basic_workstation", 1)
    
    local initialMoney = resourceManager:getResource("money")
    local initialXP = resourceManager:getResource("xp")
    
    -- Simulate time passing - need to update both systems
    idleGenerators:update(1.0) -- 1 second
    resourceManager:update(1.0) -- This should use idle generators for generation
    
    -- Basic workstation generates 2 money/sec and 0.1 xp/sec
    local finalMoney = resourceManager:getResource("money")
    local finalXP = resourceManager:getResource("xp")
    
    assert(finalMoney > initialMoney, "Money should have increased from generation (was " .. initialMoney .. ", now " .. finalMoney .. ")")
    assert(finalXP > initialXP, "XP should have increased from generation (was " .. initialXP .. ", now " .. finalXP .. ")")
end)

-- Print test results
print("\n🧪 Idle Generators Test Results:")
print("===============================================")

local passed = 0
local failed = 0

for _, result in ipairs(testResults) do
    if result.success then
        passed = passed + 1
    else
        failed = failed + 1
        print("❌ " .. result.name .. ": " .. (result.error or "Unknown error"))
    end
end

print("\n📊 Summary: " .. passed .. " passed, " .. failed .. " failed")

return {
    passed = passed,
    failed = failed,
    results = testResults
}