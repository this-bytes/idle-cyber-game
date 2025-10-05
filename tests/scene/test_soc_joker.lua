-- Test: SOC Joker Scene Instantiation and Basic Functionality
-- Verifies the scene can be created and basic methods work

package.path = package.path .. ";./?.lua;./src/?.lua"

-- Mock LUIS
local mockLuis = {
    newLayer = function() end,
    setCurrentLayer = function() end,
    clearLayer = function() end,
    insertElement = function() end,
    newLabel = function() return {} end,
    newButton = function() return {} end,
    setTheme = function() end,
    gridSize = 16,
    isLayerEnabled = function() return false end
}

-- Mock EventBus
local mockEventBus = {
    subscribe = function(self, event, callback) end,
    publish = function(self, event, data) end
}

-- Mock Systems
local mockSystems = {
    runManager = {
        startRun = function(self, ante) end,
        getRunState = function(self) return "menu" end,
        getCurrentAnte = function(self) return 1 end,
        getCurrentWave = function(self) return 1 end,
        getCurrency = function(self) return 100 end,
        getWaveConfig = function(self) return {threats = 5, boss = false} end,
        getState = function(self) return {
            totalRuns = 0,
            totalVictories = 0,
            highScore = 0
        } end,
        currentRun = nil
    },
    deckManager = {
        getHand = function(self) return {} end,
        getDeckSize = function(self) return 10 end,
        getDiscardSize = function(self) return 3 end,
        playCard = function(self, index, target) return {damage = 2} end,
        endTurn = function(self) end,
        getAvailableCards = function(self) 
            return {
                {id = "test1", name = "Test Card", effect = "Test", cost = 50},
                {id = "test2", name = "Test Card 2", effect = "Test 2", cost = 75}
            }
        end,
        addCardToDeck = function(self, id) return true end
    },
    resourceManager = {
        getResource = function(self, name) return 1000 end
    }
}

print("🧪 Testing SOC Joker Scene...")

-- Load the scene
local SOCJoker = require("src.scenes.soc_joker")

-- Test 1: Scene instantiation
print("\n1. Testing scene instantiation...")
local scene = SOCJoker.new(mockEventBus, mockLuis, mockSystems)
assert(scene ~= nil, "Scene should instantiate")
assert(scene.layerName == "soc_joker", "Layer name should be set")
print("✅ Scene instantiation successful")

-- Test 2: Load with menu state
print("\n2. Testing menu state load...")
scene:load({})
print("✅ Menu load successful")

-- Test 3: Generate threats
print("\n3. Testing threat generation...")
scene:generateWaveThreats()
assert(#scene.threats > 0, "Should generate threats")
print(string.format("✅ Generated %d threats", #scene.threats))

-- Test 4: Generate shop offerings
print("\n4. Testing shop generation...")
scene:generateShopOfferings()
assert(#scene.shopOfferings == 3, "Should generate 3 shop offerings")
print("✅ Shop generation successful")

-- Test 5: Random threat names
print("\n5. Testing random threat name generation...")
local threatName = scene:getRandomThreatName()
assert(type(threatName) == "string", "Should generate threat name")
assert(#threatName > 0, "Threat name should not be empty")
print(string.format("✅ Generated threat name: %s", threatName))

-- Test 6: Random threat types
print("\n6. Testing random threat type generation...")
local threatType = scene:getRandomThreatType()
assert(type(threatType) == "string", "Should generate threat type")
local validTypes = {network = true, malware = true, social = true, data = true}
assert(validTypes[threatType], "Should generate valid threat type")
print(string.format("✅ Generated threat type: %s", threatType))

-- Test 7: Play card mechanics
print("\n7. Testing card play mechanics...")
scene.threats = {
    {id = "test_threat", name = "Test", type = "network", health = 10, maxHealth = 10, damage = 2}
}
mockSystems.deckManager.getHand = function() 
    return {{id = "test_card", name = "Test Card", effect = "Deal damage", damage = 5}}
end
local initialHealth = scene.threats[1].health
scene:playCard(1, 1)
assert(scene.threats[1].health < initialHealth, "Threat should take damage")
print("✅ Card play mechanics work")

-- Test 8: Purchase card
print("\n8. Testing card purchase...")
mockSystems.runManager.currentRun = {currency = 100}
scene:generateShopOfferings()
local initialCurrency = mockSystems.runManager.currentRun.currency
scene:purchaseCard(1)
assert(mockSystems.runManager.currentRun.currency < initialCurrency, "Should deduct currency")
print("✅ Card purchase works")

-- Test 9: Update hover state
print("\n9. Testing hover state updates...")
scene:updateHover(0, 0)
-- Just verify it doesn't crash
print("✅ Hover state updates work")

-- Test 10: Scene methods exist
print("\n10. Verifying all required scene methods exist...")
local requiredMethods = {
    "load", "exit", "update", "draw", "mousepressed", "keypressed",
    "buildMenuUI", "buildWaveUI", "buildShopUI", "buildResultsUI"
}
for _, method in ipairs(requiredMethods) do
    assert(type(scene[method]) == "function", string.format("Method %s should exist", method))
end
print("✅ All required methods exist")

print("\n🎉 All SOC Joker scene tests passed!")
print("\n📊 Test Summary:")
print("   Total Tests: 10")
print("   Passed: 10")
print("   Failed: 0")
print("\n✅ SOC Joker scene is ready for integration!")

return true
