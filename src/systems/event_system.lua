-- src/systems/event_system.lua

local EventSystem = {}
EventSystem.__index = EventSystem

function EventSystem.new(eventBus, dataManager)
    local self = setmetatable({}, EventSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.events = {}
    self.eventTimer = 0
    self.eventInterval = 25 -- Time in seconds between events
    return self
end

function EventSystem:initialize()
    local eventData = self.dataManager:getData("events")
    if eventData and type(eventData) == "table" then
        self.events = eventData
        print("🎉 Event System initialized with " .. #self.events .. " events.")
    else
        print("⚠️ WARNING: No event data found. Event system will be disabled.")
    end
end

function EventSystem:update(dt)
    if #self.events == 0 then return end

    self.eventTimer = self.eventTimer + dt
    if self.eventTimer >= self.eventInterval then
        self.eventTimer = 0
        self:triggerRandomEvent()
    end
end

function EventSystem:triggerRandomEvent()
    if #self.events == 0 then return end

    local randomEvent = self.events[math.random(#self.events)]
    
    print("EVENT TRIGGERED: " .. randomEvent.description)
    
    self.eventBus:publish("dynamic_event_triggered", { event = randomEvent })
end

return EventSystem
