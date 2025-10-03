-- src/ui/notification_panel.lua

local NotificationPanel = {}
NotificationPanel.__index = NotificationPanel

function NotificationPanel.new(eventBus)
    local self = setmetatable({}, NotificationPanel)
    self.eventBus = eventBus
    self.notifications = {}
    self.maxNotifications = 5
    self.notificationDuration = 8 -- seconds
    
    if self.eventBus then
        self:subscribeToEvents()
    end
    
    return self
end

function NotificationPanel:subscribeToEvents()
    self.eventBus:subscribe("threat_detected", function(data)
        self:addNotification("🚨 Threat Detected: " .. data.threat.name, "threat")
    end)
    
    self.eventBus:subscribe("dynamic_event_triggered", function(data)
        self:addNotification("✨ Event: " .. data.event.description, "event")
    end)

    -- Allow publishers to attach metadata to notifications (e.g. panel navigation)
    self.eventBus:subscribe("specialist_leveled_up", function(data)
        -- include specialist id in meta so the UI can react to clicks
        local meta = { action = "open_panel", panel = "specialists", highlightSpecialistId = data.specialistId or (data.specialist and data.specialist.id) }
        self:addNotification(string.format("⭐ %s is now Level %d!", data.specialist and data.specialist.name or ("Specialist " .. tostring(meta.highlightSpecialistId)), data.newLevel or (data.specialist and data.specialist.level) or "?"), "positive", meta)
    end)

    self.eventBus:subscribe("ui_notification", function(data)
        local prefix = "ℹ️"
        if data.type == "success" then prefix = "✅"
        elseif data.type == "error" then prefix = "❌"
        end
        self:addNotification(prefix .. " " .. data.message, data.type)
    end)
end

function NotificationPanel:addNotification(text, type, meta)
    local notification = {
        text = text,
        type = type,
        timer = 0,
        meta = meta
    }
    table.insert(self.notifications, 1, notification)
    
    if #self.notifications > self.maxNotifications then
        table.remove(self.notifications)
    end
end

function NotificationPanel:update(dt)
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]
        notif.timer = notif.timer + dt
        if notif.timer >= self.notificationDuration then
            table.remove(self.notifications, i)
        end
    end
end

function NotificationPanel:draw()
    local screenWidth = love.graphics.getWidth()
    local y = 50
    
    for _, notif in ipairs(self.notifications) do
        local r, g, b = 1, 1, 1
        if notif.type == "threat" or notif.type == "error" then
            r, g, b = 1, 0.4, 0.4 -- Reddish
        elseif notif.type == "positive" or notif.type == "success" then
            r, g, b = 0.4, 1, 0.4 -- Greenish
        elseif notif.type == "event" then
            r, g, b = 0.6, 0.8, 1 -- Bluish
        end
        
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.printf(notif.text, screenWidth - 410, y, 400, "right")
        y = y + 25
    end
    
    love.graphics.setColor(1, 1, 1)
end

-- Return bounding boxes for notifications (in draw order) for hit testing
function NotificationPanel:getNotificationBounds()
    local screenWidth = love.graphics.getWidth()
    local y = 50
    local bounds = {}
    for i, notif in ipairs(self.notifications) do
        local h = 20
        table.insert(bounds, { x = screenWidth - 410, y = y, width = 400, height = h, meta = notif.meta })
        y = y + 25
    end
    return bounds
end

-- Handle a mouse click at (x,y). Returns true if a notification was clicked.
function NotificationPanel:handleClick(x, y)
    local bounds = self:getNotificationBounds()
    for _, b in ipairs(bounds) do
        if x >= b.x and x <= b.x + b.width and y >= b.y and y <= b.y + b.height then
            -- Publish a notification click event so scenes can react
            if self.eventBus then
                self.eventBus:publish("notification_clicked", { meta = b.meta })
            end
            return true
        end
    end
    return false
end

return NotificationPanel
