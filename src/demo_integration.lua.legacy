-- Integration Demo - SOC REFACTOR: Use fortress architecture
-- Demonstrates the fortress components working together with legacy systems

local EventBus = require("src.utils.event_bus")
local ResourceManager = require("src.core.resource_manager") -- SOC REFACTOR: Use fortress resource manager
local LocationSystem = require("src.systems.location_system")
local ProgressionSystem = require("src.systems.progression_system")
local EnhancedPlayerSystem = require("src.systems.enhanced_player_system")

local function demo_complete_workflow()
    print("🚀 Starting Integration Demo...")
    print("=" .. string.rep("=", 50))
    
    -- Initialize core systems with fortress architecture
    local eventBus = EventBus.new()
    local resourceManager = ResourceManager.new(eventBus) -- SOC REFACTOR: Use fortress resource manager
    resourceManager:initialize()
    local locationSystem = LocationSystem.new(eventBus)
    local progressionSystem = ProgressionSystem.new(eventBus, resourceManager) -- Updated to use fortress resources
    local playerSystem = EnhancedPlayerSystem.new(eventBus, locationSystem)
    
    print("\n📊 Initial State:")
    print("Money: " .. (resourceManager:getResource("money") or 0))
    print("Reputation: " .. (resourceManager:getResource("reputation") or 0)) 
    print("Experience: " .. (resourceManager:getResource("xp") or 0)) -- SOC REFACTOR: Use xp instead of experience
    print("Location: " .. locationSystem:getCurrentLocationString())
    
    -- Simulate player interactions
    print("\n🎮 Simulating Player Actions...")
    
    -- Move to kitchen (energy regen bonus)
    locationSystem:moveToRoom("home_office", "main", "kitchen")
    print("Moved to kitchen for energy regeneration")
    
    -- Simulate time passing (energy regen)
    progressionSystem:update(5.0) -- 5 seconds
    print("Energy after 5s in kitchen: " .. (resourceSystem:getResource("energy") or 0))
    
    -- Move back to office and work
    locationSystem:moveToRoom("home_office", "main", "my_office")
    print("Moved back to office")
    
    -- Simulate desk work (with focus bonus)
    local focusBonus = locationSystem:getCurrentLocationBonuses().focus or 1.0
    local workIncome = math.floor(50 * focusBonus)
    resourceSystem:addResource("money", workIncome)
    resourceSystem:addResource("experience", 25)
    print("Work completed with focus bonus " .. string.format("%.2f", focusBonus) .. "x")
    print("Earned: $" .. workIncome .. " and 25 XP")
    
    -- Complete a mock contract
    eventBus:publish("contract_completed", {
        experience = 100,
        reputation = 15
    })
    print("Contract completed!")
    
    -- Test achievement system
    eventBus:publish("location_changed", {
        newBuilding = "home_office",
        newFloor = "main", 
        newRoom = "kitchen",
        bonuses = {}
    })
    
    -- Show final state
    print("\n📈 Final State:")
    print("Money: " .. (resourceSystem:getResource("money") or 0))
    print("Reputation: " .. (resourceSystem:getResource("reputation") or 0))
    print("Experience: " .. (resourceSystem:getResource("experience") or 0))
    print("Energy: " .. (resourceSystem:getResource("energy") or 0))
    print("Current Tier: " .. progressionSystem.currentTier)
    
    -- Show achievements
    local achievements = progressionSystem:getAchievements()
    print("\n🏆 Achievements Unlocked:")
    for achievementId, data in pairs(achievements) do
        print("- " .. achievementId)
    end
    
    -- Show available locations
    print("\n🏢 Available Locations:")
    local buildings = locationSystem:getAvailableBuildings()
    for _, building in ipairs(buildings) do
        print("- " .. building.name .. " (Tier " .. building.tier .. ")")
    end
    
    print("\n🎯 Demo completed successfully!")
    print("Systems working together: Location bonuses affect progression,")
    print("achievements track player actions, and JSON data drives gameplay.")
    
    return true
end

-- Run the demo if this file is executed directly
if arg and arg[0] and arg[0]:match("demo_integration%.lua$") then
    demo_complete_workflow()
end

return {
    demo_complete_workflow = demo_complete_workflow
}