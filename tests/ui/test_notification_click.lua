-- Test for NotificationPanel click publishing

local NotificationPanel = require("src.ui.notification_panel")

-- Mock event bus that records published events
local function createMockEventBus()
    local events = {}
    return {
        publish = function(self, event, data)
            events[event] = events[event] or {}
            table.insert(events[event], data)
        end,
        subscribe = function(self, event, cb) end,
        getEvents = function(self) return events end
    }
end

TestRunner.test("NotificationPanel - click publishes notification_clicked", function()
    local eventBus = createMockEventBus()
    local panel = NotificationPanel.new(eventBus)

    -- Add a notification with meta
    panel:addNotification("Test", "info", { action = "open_panel", panel = "specialists", highlightSpecialistId = 42 })

    -- Mock love.graphics dimensions for getNotificationBounds
    local love = require("tests.mock_love")
    _G.love = love

    local bounds = panel:getNotificationBounds()
    TestRunner.assert(#bounds >= 1, "Should have at least one notification bound")

    -- Click at the center of the first bound
    local b = bounds[1]
    local cx = b.x + b.width/2
    local cy = b.y + b.height/2

    local clicked = panel:handleClick(cx, cy)
    TestRunner.assert(clicked, "Click should be handled")

    local events = eventBus:getEvents()
    TestRunner.assert(events.notification_clicked and #events.notification_clicked == 1, "Should have published notification_clicked once")
    TestRunner.assert(events.notification_clicked[1].meta and events.notification_clicked[1].meta.panel == "specialists", "Meta should include panel = specialists")
end)
