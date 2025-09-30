#!/usr/bin/env lua5.3
-- Test the Event System integration

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

print("🧪 Testing Event System Integration...")

-- Create test environment
local eventBus = EventBus.new()
local dataManager = DataManager:new()
local resourceManager = ResourceManager.new(eventBus)

-- Load event data
local success = dataManager:loadDataFromFile("events", "src/data/events.json")
if not success then
    print("❌ Failed to load events data")
    return
end

-- Create event system
local eventSystem = EventSystem.new(eventBus, dataManager)
eventSystem:initialize()

-- Test resource tracking
local initialMoney = resourceManager:getResource("money")
print("💰 Initial money: " .. initialMoney)

-- Subscribe to event triggers for testing
eventBus:subscribe("dynamic_event_triggered", function(data)
    print("📢 Event received: " .. data.event.description)
    if data.event.type == "choice" then
        print("🎯 This is a choice event with " .. #data.event.choices .. " options")
        for i, choice in ipairs(data.event.choices) do
            print("   [" .. i .. "] " .. choice.text)
        end
    end
end)

-- Test triggering an event manually
print("\n🔥 Manually triggering a random event...")
eventSystem:triggerRandomEvent()

-- Simulate some time passing
print("\n⏰ Simulating 30 seconds...")
eventSystem:update(30)

-- Check if money changed
local finalMoney = resourceManager:getResource("money")
print("💰 Final money: " .. finalMoney)
print("💸 Money change: " .. (finalMoney - initialMoney))

print("\n✅ Event System integration test complete!")