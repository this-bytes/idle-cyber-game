local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(eventBus)
    local self = setmetatable({}, NotificationSystem)
    self.eventBus = eventBus
    return self
end

function NotificationSystem:notify(message, type, duration)
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_notification", {message = message, type = type or "info", duration = duration or 3.0, timestamp = os.time()})
    else
        -- Fallback to console
        print("NOTIFY: " .. message)
    end
end

return NotificationSystem
