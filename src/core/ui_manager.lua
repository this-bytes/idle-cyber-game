-- UIManager - Modern Reactive UI Management System
-- Fortress Refactor: Clean UI state management with event-driven updates
-- Implements centralized UI control with component-based architecture

local UIManager = {}
UIManager.__index = UIManager

-- UI State tracking
local UI_STATES = {
    LOADING = "loading",
    SPLASH = "splash", 
    GAME = "game",
    DASHBOARD = "dashboard",
    PAUSED = "paused"
}

-- UI Panels for organization
local UI_PANELS = {
    HUD = "hud",           -- Always visible game info
    RESOURCES = "resources", -- Resource display
    THREATS = "threats",   -- Active threats panel
    UPGRADES = "upgrades", -- Security upgrades panel
    CONTRACTS = "contracts", -- Business contracts
    STATS = "stats",       -- Performance statistics
    NOTIFICATIONS = "notifications" -- Floating notifications
}

-- Create new UI manager
function UIManager.new(eventBus, resourceManager, securityUpgrades, threatSimulation, gameLoop)
    local self = setmetatable({}, UIManager)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.securityUpgrades = securityUpgrades
    self.threatSimulation = threatSimulation
    self.gameLoop = gameLoop
    
    -- UI State
    self.currentState = UI_STATES.LOADING
    self.panelVisibility = {}
    self.panelData = {}
    
    -- Display settings
    self.screenWidth = 1024
    self.screenHeight = 768
    self.margin = 20
    self.padding = 10
    
    -- Color scheme - cybersecurity theme
    self.colors = {
        background = {0.05, 0.05, 0.1, 1.0},
        panel = {0.1, 0.15, 0.2, 0.9},
        text = {0.9, 0.9, 0.95, 1.0},
        accent = {0.2, 0.8, 0.9, 1.0},
        success = {0.2, 0.8, 0.3, 1.0},
        warning = {0.9, 0.7, 0.2, 1.0},
        danger = {0.9, 0.3, 0.2, 1.0},
        border = {0.3, 0.4, 0.5, 1.0}
    }
    
    -- Notification system
    self.notifications = {}
    self.nextNotificationId = 1

    -- Selectable components registry
    self.selectables = {}
    self.focusIndex = 1
    
    -- Initialize panels
    self:initializePanels()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Initialize UI panels
function UIManager:initializePanels()
    -- Set default panel visibility
    self.panelVisibility = {
        [UI_PANELS.HUD] = true,
        [UI_PANELS.RESOURCES] = true,
        [UI_PANELS.THREATS] = false, -- Hidden until threats appear
        [UI_PANELS.UPGRADES] = false, -- Hidden until upgrades available
        [UI_PANELS.CONTRACTS] = false, -- Hidden until contracts available  
        [UI_PANELS.STATS] = false,   -- Hidden by default
        [UI_PANELS.NOTIFICATIONS] = true
    }
    
    -- Initialize panel data
    self.panelData = {
        [UI_PANELS.HUD] = {
            title = "Cyber Empire Command",
            subtitle = "Cybersecurity Consultancy Simulator"
        },
        [UI_PANELS.RESOURCES] = {
            resources = {}
        },
        [UI_PANELS.THREATS] = {
            activeThreats = {},
            recentHistory = {}
        },
        [UI_PANELS.UPGRADES] = {
            availableUpgrades = {},
            categories = {}
        },
        [UI_PANELS.CONTRACTS] = {
            availableContracts = {},
            activeContracts = {}
        },
        [UI_PANELS.STATS] = {
            performance = {},
            statistics = {}
        },
        [UI_PANELS.NOTIFICATIONS] = {
            messages = self.notifications
        }
    }
    
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_initialized", {time = os.time()})
    else
        print("UIManager: Initialized cybersecurity-themed UI panels")
    end
end

-- Subscribe to relevant events
function UIManager:subscribeToEvents()
    -- Resource changes
    self.eventBus:subscribe("resource_changed", function(data)
        self:updateResourceDisplay(data)
        self:showNotification("💰 " .. data.resource .. ": " .. 
                             (data.change > 0 and "+" or "") .. 
                             string.format("%.0f", data.change), "success")
    end)
    
    -- Threat events
    self.eventBus:subscribe("threat_detected", function(data)
        self:updateThreatDisplay()
        self:showNotification("🚨 Threat Detected: " .. data.threat.name, "danger")
        self.panelVisibility[UI_PANELS.THREATS] = true
    end)
    
    self.eventBus:subscribe("threat_completed", function(data)
        self:updateThreatDisplay()
        if data.mitigated then
            self:showNotification("🛡️ Threat Mitigated: " .. data.threat.name, "success")
        else
            self:showNotification("💥 Security Breach: " .. data.threat.name, "danger")
        end
    end)
    
    -- Upgrade events
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self:updateUpgradeDisplay()
        local upgrade = self.securityUpgrades.upgradeDefinitions[data.upgradeId]
        if upgrade then
            self:showNotification("🛡️ Purchased: " .. upgrade.name, "success")
        end
        self.panelVisibility[UI_PANELS.UPGRADES] = true
    end)
    
    -- Contract events
    self.eventBus:subscribe("contract_accepted", function(data)
        self:updateContractDisplay()
        self:showNotification("📋 Contract Accepted: " .. (data.contract.name or "Unknown"), "success")
        self.panelVisibility[UI_PANELS.CONTRACTS] = true
    end)
    
    -- Game loop events
    self.eventBus:subscribe("game_loop_paused", function(data)
        if data.paused then
            self.currentState = UI_STATES.PAUSED
        else
            self.currentState = UI_STATES.GAME
        end
    end)
    
    -- Offline progress should show an away summary popout rather than printing
    self.eventBus:subscribe("offline_progress_calculated", function(data)
        -- data expected: {netGain = number, totalTime = seconds, details = {..}}
        self:showAwaySummary(data)
    end)
end

-- Update resource display
function UIManager:updateResourceDisplay(data)
    if not self.panelData[UI_PANELS.RESOURCES] then
        self.panelData[UI_PANELS.RESOURCES] = {resources = {}}
    end
    
    -- Get fresh resource data
    self.panelData[UI_PANELS.RESOURCES].resources = self.resourceManager:getAllResources()
end

-- Update threat display
function UIManager:updateThreatDisplay()
    if not self.panelData[UI_PANELS.THREATS] then
        self.panelData[UI_PANELS.THREATS] = {activeThreats = {}, recentHistory = {}}
    end
    
    self.panelData[UI_PANELS.THREATS].activeThreats = self.threatSimulation:getActiveThreats()
    self.panelData[UI_PANELS.THREATS].recentHistory = self.threatSimulation:getThreatHistory(5)
end

-- Update upgrade display
function UIManager:updateUpgradeDisplay()
    if not self.panelData[UI_PANELS.UPGRADES] then
        self.panelData[UI_PANELS.UPGRADES] = {availableUpgrades = {}, categories = {}}
    end
    
    self.panelData[UI_PANELS.UPGRADES].availableUpgrades = self.securityUpgrades:getAvailableUpgrades()
    
    -- Group by categories
    local categories = {}
    for upgradeId, data in pairs(self.panelData[UI_PANELS.UPGRADES].availableUpgrades) do
        local category = data.upgrade.category
        if not categories[category] then
            categories[category] = {}
        end
        categories[category][upgradeId] = data
    end
    self.panelData[UI_PANELS.UPGRADES].categories = categories
end

-- Update contract display
function UIManager:updateContractDisplay()
    -- Placeholder for contract system integration
    if not self.panelData[UI_PANELS.CONTRACTS] then
        self.panelData[UI_PANELS.CONTRACTS] = {availableContracts = {}, activeContracts = {}}
    end
end

-- Show notification
function UIManager:showNotification(message, type, duration)
    type = type or "info"
    duration = duration or 3.0
    
    local notification = {
        id = self.nextNotificationId,
        message = message,
        type = type,
        timestamp = love.timer and love.timer.getTime() or os.clock(),
        duration = duration,
        alpha = 1.0
    }
    
    self.nextNotificationId = self.nextNotificationId + 1
    table.insert(self.notifications, notification)

    -- Publish notification event for other systems (e.g., sound)
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_notification", notification)
    end
end

-- Register a selectable component
function UIManager:registerSelectable(selectable)
    table.insert(self.selectables, selectable)
    return #self.selectables
end

-- Clear selectables
function UIManager:clearSelectables()
    self.selectables = {}
    self.focusIndex = 1
end

-- Focus management
function UIManager:focusNext()
    if #self.selectables == 0 then return end
    self.selectables[self.focusIndex].focused = false
    self.focusIndex = (self.focusIndex % #self.selectables) + 1
    self.selectables[self.focusIndex].focused = true
end

function UIManager:focusPrevious()
    if #self.selectables == 0 then return end
    self.selectables[self.focusIndex].focused = false
    self.focusIndex = ((self.focusIndex - 2) % #self.selectables) + 1
    self.selectables[self.focusIndex].focused = true
end

function UIManager:activateFocused()
    if #self.selectables == 0 then return end
    local s = self.selectables[self.focusIndex]
    if s and s.activate then s:activate() end
end

-- Away summary popout (shown when player returns)
function UIManager:showAwaySummary(data)
    self.panelData.awaySummary = data or {netGain = 0, totalTime = 0, details = {}}
    -- Make sure dashboard is visible
    self.panelVisibility[UI_PANELS.HUD] = true
    -- Show a notification too
    local minutes = math.floor((data and data.totalTime or 0) / 60)
    self:showNotification("Welcome back! You earned " .. tostring(math.floor((data and data.netGain) or 0)) .. " while away (" .. minutes .. "m)", "success", 5.0)
end

-- Update UI system
function UIManager:update(dt)
    -- Update notifications
    self:updateNotifications(dt)
    
    -- Update performance stats
    if self.gameLoop then
        self.panelData[UI_PANELS.STATS].performance = self.gameLoop:getPerformanceMetrics()
    end
    
    -- Update threat panel data if visible
    if self.panelVisibility[UI_PANELS.THREATS] then
        self:updateThreatDisplay()
    end
    
    -- Update resource display
    self:updateResourceDisplay()
end

-- Update notifications (fade out over time)
function UIManager:updateNotifications(dt)
    local notificationsToRemove = {}
    
    for i, notification in ipairs(self.notifications) do
        local currentTime = love.timer and love.timer.getTime() or os.clock()
        local age = currentTime - notification.timestamp
        
        if age > notification.duration then
            table.insert(notificationsToRemove, i)
        elseif age > notification.duration * 0.7 then
            -- Start fading out in last 30% of duration
            local fadeProgress = (age - notification.duration * 0.7) / (notification.duration * 0.3)
            notification.alpha = 1.0 - fadeProgress
        end
    end
    
    -- Remove expired notifications (in reverse order to maintain indices)
    for i = #notificationsToRemove, 1, -1 do
        table.remove(self.notifications, notificationsToRemove[i])
    end
end

-- Draw the UI
function UIManager:draw()
    if self.currentState == UI_STATES.LOADING then
        self:drawLoadingScreen()
    elseif self.currentState == UI_STATES.SPLASH then
        self:drawSplashScreen()
    elseif self.currentState == UI_STATES.DASHBOARD then
        self:drawDashboard()
    elseif self.currentState == UI_STATES.GAME or self.currentState == UI_STATES.PAUSED then
        self:drawGameUI()
        if self.currentState == UI_STATES.PAUSED then
            self:drawPauseOverlay()
        end
    end
end

-- Draw Dashboard (main screen) with away summary popout
function UIManager:drawDashboard()
    -- Background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw title
    love.graphics.setColor(self.colors.accent)
    love.graphics.printf("CYBER EMPIRE COMMAND - DASHBOARD", 0, 50, self.screenWidth, "center")
    
    -- Draw selectables
    for _, selectable in ipairs(self.selectables) do
        selectable:draw(self)
    end
    
    -- Draw away summary if present
    if self.panelData and self.panelData.awaySummary and self.panelData.awaySummary.totalTime and self.panelData.awaySummary.totalTime > 0 then
        -- Draw a centered popout
        local w, h = 480, 180
        local x = (self.screenWidth - w) / 2
        local y = (self.screenHeight - h) / 2
        love.graphics.setColor(self.colors.panel)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(self.colors.border)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.setColor(self.colors.accent)
        love.graphics.print("Away Summary", x + self.padding, y + self.padding)
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Time away: " .. tostring(math.floor(self.panelData.awaySummary.totalTime)) .. "s", x + self.padding, y + 40)
        love.graphics.print("Net gain: " .. tostring(math.floor(self.panelData.awaySummary.netGain)), x + self.padding, y + 60)
        local yOff = 90
        for k, v in pairs(self.panelData.awaySummary.details or {}) do
            love.graphics.print(k .. ": " .. tostring(v), x + self.padding, y + yOff)
            yOff = yOff + 18
            if yOff > h - 20 then break end
        end
    end
end

-- Draw loading screen
function UIManager:drawLoadingScreen()
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    love.graphics.setColor(self.colors.text)
    local text = "Loading Cyber Empire Command..."
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (self.screenWidth - textWidth) / 2, self.screenHeight / 2)
end

-- Draw splash screen
function UIManager:drawSplashScreen()
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    local title = self.panelData[UI_PANELS.HUD].title
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, (self.screenWidth - titleWidth) / 2, self.screenHeight / 2 - 50)
    
    -- Subtitle
    love.graphics.setColor(self.colors.text)
    local subtitle = self.panelData[UI_PANELS.HUD].subtitle
    local subtitleWidth = font:getWidth(subtitle)
    love.graphics.print(subtitle, (self.screenWidth - subtitleWidth) / 2, self.screenHeight / 2 - 20)
    
    -- Continue prompt
    love.graphics.setColor(self.colors.warning)
    local prompt = "Press any key to continue..."
    local promptWidth = font:getWidth(prompt)
    love.graphics.print(prompt, (self.screenWidth - promptWidth) / 2, self.screenHeight / 2 + 50)
end

-- Draw game UI
function UIManager:drawGameUI()
    -- Background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Draw panels
    if self.panelVisibility[UI_PANELS.HUD] then
        self:drawHUDPanel()
    end
    
    if self.panelVisibility[UI_PANELS.RESOURCES] then
        self:drawResourcePanel()
    end
    
    if self.panelVisibility[UI_PANELS.THREATS] then
        self:drawThreatPanel()
    end
    
    if self.panelVisibility[UI_PANELS.UPGRADES] then
        self:drawUpgradePanel()
    end
    
    if self.panelVisibility[UI_PANELS.STATS] then
        self:drawStatsPanel()
    end
    
    if self.panelVisibility[UI_PANELS.NOTIFICATIONS] then
        self:drawNotifications()
    end
end

-- Draw HUD panel
function UIManager:drawHUDPanel()
    local x, y = self.margin, self.margin
    local width = 300
    local height = 60
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print(self.panelData[UI_PANELS.HUD].title, x + self.padding, y + self.padding)
    
    -- Subtitle
    love.graphics.setColor(self.colors.text)
    love.graphics.print(self.panelData[UI_PANELS.HUD].subtitle, x + self.padding, y + self.padding + 20)
end

-- Draw resource panel
function UIManager:drawResourcePanel()
    local x, y = self.margin, self.margin + 80
    local width = 300
    local height = 200
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("💰 Resources", x + self.padding, y + self.padding)
    
    -- Resources
    love.graphics.setColor(self.colors.text)
    local yOffset = 30
    for resourceName, amount in pairs(self.panelData[UI_PANELS.RESOURCES].resources) do
        local displayName = resourceName:gsub("^%l", string.upper)
        local text = displayName .. ": " .. string.format("%.0f", amount)
        love.graphics.print(text, x + self.padding, y + self.padding + yOffset)
        yOffset = yOffset + 20
    end
end

-- Draw threat panel
function UIManager:drawThreatPanel()
    local x, y = self.screenWidth - 320 - self.margin, self.margin
    local width = 320
    local height = 250
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("🚨 Active Threats", x + self.padding, y + self.padding)
    
    -- Active threats
    love.graphics.setColor(self.colors.text)
    local yOffset = 30
    local count = 0
    for _, threat in pairs(self.panelData[UI_PANELS.THREATS].activeThreats) do
        if count < 8 then -- Limit display
            local severityColor = self.colors.text
            if threat.severity == "HIGH" then
                severityColor = self.colors.warning
            elseif threat.severity == "CRITICAL" then
                severityColor = self.colors.danger
            end
            
            love.graphics.setColor(severityColor)
            local text = threat.name .. " (" .. threat.severity .. ")"
            love.graphics.print(text, x + self.padding, y + self.padding + yOffset)
            
            -- Progress bar
            local progressWidth = 200
            local progressHeight = 4
            local progressX = x + self.padding
            local progressY = y + self.padding + yOffset + 15
            
            love.graphics.setColor(self.colors.border)
            love.graphics.rectangle("fill", progressX, progressY, progressWidth, progressHeight)
            
            love.graphics.setColor(self.colors.success)
            local progress = (threat.mitigationProgress or 0) / 100
            love.graphics.rectangle("fill", progressX, progressY, progressWidth * progress, progressHeight)
            
            yOffset = yOffset + 35
            count = count + 1
        end
    end
    
    if count == 0 then
        love.graphics.setColor(self.colors.success)
        love.graphics.print("All systems secure", x + self.padding, y + self.padding + yOffset)
    end
end

-- Draw upgrade panel (simplified)
function UIManager:drawUpgradePanel()
    local x, y = self.screenWidth - 320 - self.margin, self.margin + 270
    local width = 320
    local height = 200
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("🛡️ Security Upgrades", x + self.padding, y + self.padding)
    
    -- Available upgrades count
    love.graphics.setColor(self.colors.text)
    local availableCount = 0
    for _ in pairs(self.panelData[UI_PANELS.UPGRADES].availableUpgrades) do
        availableCount = availableCount + 1
    end
    
    love.graphics.print("Available: " .. availableCount, x + self.padding, y + self.padding + 25)
end

-- Draw statistics panel
function UIManager:drawStatsPanel()
    local x, y = self.margin, self.screenHeight - 150 - self.margin
    local width = 400
    local height = 150
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("📊 Performance", x + self.padding, y + self.padding)
    
    -- Performance metrics
    love.graphics.setColor(self.colors.text)
    local perf = self.panelData[UI_PANELS.STATS].performance
    if perf then
        love.graphics.print("FPS: " .. (perf.fps or 0), x + self.padding, y + self.padding + 25)
        love.graphics.print("Update: " .. string.format("%.2fms", (perf.updateTime or 0) * 1000), 
                           x + self.padding, y + self.padding + 45)
        love.graphics.print("Time Scale: " .. string.format("%.1fx", perf.timeScale or 1.0), 
                           x + self.padding, y + self.padding + 65)
    end
end

-- Draw notifications
function UIManager:drawNotifications()
    local x = self.screenWidth - 350 - self.margin
    local y = self.screenHeight - self.margin
    local width = 350
    local notificationHeight = 40
    
    for i, notification in ipairs(self.notifications) do
        local notifY = y - (i * (notificationHeight + 5))  
        
        -- Notification background
        local bgColor = self.colors.panel
        if notification.type == "success" then
            bgColor = {bgColor[1], bgColor[2] + 0.1, bgColor[3], bgColor[4] * notification.alpha}
        elseif notification.type == "warning" then
            bgColor = {bgColor[1] + 0.1, bgColor[2] + 0.05, bgColor[3], bgColor[4] * notification.alpha}
        elseif notification.type == "danger" then
            bgColor = {bgColor[1] + 0.1, bgColor[2], bgColor[3], bgColor[4] * notification.alpha}
        end
        
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", x, notifY, width, notificationHeight)
        
        -- Text
        love.graphics.setColor(self.colors.text[1], self.colors.text[2], self.colors.text[3], notification.alpha)
        love.graphics.print(notification.message, x + self.padding, notifY + self.padding)
    end
end

-- Draw pause overlay
function UIManager:drawPauseOverlay()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    -- Pause text
    love.graphics.setColor(self.colors.accent)
    local text = "⏸️ PAUSED"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    love.graphics.print(text, (self.screenWidth - textWidth) / 2, self.screenHeight / 2)
end

-- Set UI state
function UIManager:setState(state)
    if UI_STATES[state] then
        self.currentState = state
        if self.eventBus and type(self.eventBus.publish) == "function" then
            self.eventBus:publish("ui_state_changed", {state = state})
        end
    end
end

-- Toggle panel visibility
function UIManager:togglePanel(panel)
    if self.panelVisibility[panel] ~= nil then
        self.panelVisibility[panel] = not self.panelVisibility[panel]
        if self.eventBus and type(self.eventBus.publish) == "function" then
            self.eventBus:publish("ui_panel_toggled", {panel = panel, visible = self.panelVisibility[panel]})
        end
    end
end

-- Handle screen resize
function UIManager:resize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_resized", {width = width, height = height})
    end
end

-- Get comprehensive state
function UIManager:getState()
    return {
        currentState = self.currentState,
        panelVisibility = self.panelVisibility,
        notifications = self.notifications,
        nextNotificationId = self.nextNotificationId
    }
end

-- Load state
function UIManager:loadState(state)
    if not state then return end
    
    if state.currentState then
        self.currentState = state.currentState
    end
    
    if state.panelVisibility then
        self.panelVisibility = state.panelVisibility
    end
    
    if state.notifications then
        self.notifications = state.notifications
    end
    
    if state.nextNotificationId then
        self.nextNotificationId = state.nextNotificationId
    end
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_state_loaded", {time = os.time()})
    end
end

-- Initialize method for GameLoop integration  
function UIManager:initialize()
    self.currentState = UI_STATES.SPLASH
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_initialized_splash", {time = os.time()})
    end
end

-- Shutdown method for GameLoop integration
function UIManager:shutdown()
    if self.eventBus and type(self.eventBus.publish) == "function" then
        self.eventBus:publish("ui_shutdown", {time = os.time()})
    end
end

return UIManager
