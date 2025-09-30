#!/usr/bin/env lua5.3
-- Test choice-based events specifically

-- Seed random number generator
math.randomseed(os.time() + os.clock() * 1000000)

-- Mock Love2D filesystem
local love = {
    filesystem = {
        newFile = function(path)
            local file = io.open(path, "r")
            if not file then return nil, "File not found" end
            return {
                read = function() 
                    local content = file:read("*a")
                    file:close()
                    return content
                end
            }
        end
    }
}
_G.love = love

-- Load required modules
package.path = package.path .. ";./src/?.lua;./?.lua"

local EventBus = require("src.utils.event_bus")
local DataManager = require("src.utils.data_manager")
local EventSystem = require("src.systems.event_system")
local ResourceManager = require("src.core.resource_manager")

print("🧪 Testing Choice-Based Event...")

-- Create test environment
local eventBus = EventBus.new()
local dataManager = DataManager:new()
local resourceManager = ResourceManager.new(eventBus)

-- Load event data
dataManager:loadDataFromFile("events", "src/data/events.json")

-- Create event system and modify it to force the choice event
local eventSystem = EventSystem.new(eventBus, dataManager)
eventSystem:initialize()

-- Force trigger the choice event (event_004)
local events = dataManager:getData("events")
local choiceEvent = nil
for _, event in ipairs(events) do
    if event.id == "event_004" then
        choiceEvent = event
        break
    end
end

if choiceEvent then
    print("💰 Initial money: " .. resourceManager:getResource("money"))
    print("⭐ Initial reputation: " .. resourceManager:getResource("reputation"))
    
    print("\n🎯 Triggering choice event: " .. choiceEvent.description)
    eventBus:publish("dynamic_event_triggered", { event = choiceEvent })
    
    -- Simulate choosing option 1 (Install the patch)
    print("\n🤖 Simulating choice 1: Install the patch")
    
    -- Manually process the probabilistic choice
    local choice = choiceEvent.choices[1]
    if choice.effects.chance then
        local random = math.random()
        local totalProbability = 0
        
        for _, outcome in ipairs(choice.effects.chance) do
            totalProbability = totalProbability + outcome.probability
            if random <= totalProbability then
                print("🎲 Outcome selected with " .. (outcome.probability * 100) .. "% chance")
                if outcome.effect then
                    eventBus:publish("resource_add", outcome.effect)
                end
                break
            end
        end
    end
    
    print("\n💰 Final money: " .. resourceManager:getResource("money"))
    print("⭐ Final reputation: " .. resourceManager:getResource("reputation"))
    
else
    print("❌ Could not find choice event")
end

print("\n✅ Choice-based event test complete!")