-- Event Bus System
-- Provides decoupled communication between game systems

local EventBus = {}
EventBus.__index = EventBus

-- Create new event bus
function EventBus.new()
    local self = setmetatable({}, EventBus)
    self.listeners = {}
    return self
end

-- Subscribe to an event
function EventBus:subscribe(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
end

-- Unsubscribe from an event
function EventBus:unsubscribe(event, callback)
    if not self.listeners[event] then
        return
    end
    
    for i, listener in ipairs(self.listeners[event]) do
        if listener == callback then
            table.remove(self.listeners[event], i)
            break
        end
    end
end

-- Publish an event
function EventBus:publish(event, data)
    if not self.listeners[event] then
        return
    end
    
    for _, callback in ipairs(self.listeners[event]) do
        callback(data)
    end
end

-- Clear all listeners for an event
function EventBus:clear(event)
    if event then
        self.listeners[event] = nil
    else
        self.listeners = {}
    end
end

-- Get number of listeners for an event
function EventBus:getListenerCount(event)
    if not self.listeners[event] then
        return 0
    end
    return #self.listeners[event]
end

return EventBus