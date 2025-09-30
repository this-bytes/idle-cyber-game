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
    ROSTER = "roster",     -- Specialist roster
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

    -- Ensure a safe love.graphics fallback for headless tests
    -- Many tests run without the full LÖVE environment; provide minimal no-op
    -- implementations so UI draw calls don't error in headless mode.
    if not (love and love.graphics) then
        love = love or {}
        love.graphics = {
            getWidth = function() return self.screenWidth end,
            getHeight = function() return self.screenHeight end,
            getFont = function()
                return {
                    getWidth = function(_, s) return (#tostring(s) * 6) end
                }
            end,
            setColor = function() end,
            rectangle = function() end,
            print = function() end
        }
    end
    
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
        [UI_PANELS.ROSTER] = true,   -- Always visible for Phase 1
        [UI_PANELS.NOTIFICATIONS] = true
    }
    
    -- Initialize panel data
    self.panelData = {
        [UI_PANELS.HUD] = {
            title = "Idle Sec Ops",
            subtitle = "Cybersecurity Consultancy Simulator",
            money = 0,
            incomePerSec = 0,
            reputation = 0
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
        [UI_PANELS.ROSTER] = {
            specialists = {},
            starterSpecialists = {} -- 3 starter specialists for Phase 1
        },
        [UI_PANELS.NOTIFICATIONS] = {
            messages = self.notifications
        }
    }
    
    print("🖥️ UIManager: Initialized cybersecurity-themed UI panels")
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
    -- Expect canonical event table: { threat = <obj>, defenseEffectiveness = <num>, ... }
    self.eventBus:subscribe("threat_detected", function(event)
        local threatObj = event and event.threat
        if not threatObj then
            return
        end

        self:updateThreatDisplay()
        local name = (threatObj.name and threatObj.name) or tostring(threatObj.id or "Unknown")
        self:showNotification("🚨 Threat Detected: " .. name, "danger")
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
end

-- Utility function for formatting numbers (e.g., 1234 -> "1.23k")
function UIManager:formatNumber(num)
    if num >= 1000000 then
        return string.format("%.2fm", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.2fk", num / 1000)
    else
        return string.format("%.0f", num)
    end
end

-- Utility function for formatting income per second
function UIManager:formatIncomePerSec(num)
    return self:formatNumber(num) .. "/sec"
end

-- Update resource display
function UIManager:updateResourceDisplay(data)
    if not self.panelData[UI_PANELS.RESOURCES] then
        self.panelData[UI_PANELS.RESOURCES] = {resources = {}}
    end
    
    -- Get fresh resource data
    self.panelData[UI_PANELS.RESOURCES].resources = self.resourceManager:getAllResources()
end

-- Update HUD display with money, income/sec, and reputation
function UIManager:updateHUDDisplay()
    if not self.panelData[UI_PANELS.HUD] then
        self.panelData[UI_PANELS.HUD] = {
            title = "Idle Sec Ops",
            subtitle = "Cybersecurity Consultancy Simulator",
            money = 0,
            incomePerSec = 0,
            reputation = 0
        }
    end
    
    -- Get current resource values
    self.panelData[UI_PANELS.HUD].money = self.resourceManager:getResource("money") or 0
    self.panelData[UI_PANELS.HUD].reputation = self.resourceManager:getResource("reputation") or 0
    
    -- Calculate income per second from resource generation
    self.panelData[UI_PANELS.HUD].incomePerSec = self.resourceManager:getGeneration("money") or 0
end

-- Update specialist roster display
function UIManager:updateRosterDisplay()
    if not self.panelData[UI_PANELS.ROSTER] then
        self.panelData[UI_PANELS.ROSTER] = {
            specialists = {},
            starterSpecialists = {}
        }
    end
    
    -- Create 3 starter specialists for Phase 1 placeholder
    if #self.panelData[UI_PANELS.ROSTER].starterSpecialists == 0 then
        self.panelData[UI_PANELS.ROSTER].starterSpecialists = {
            {
                id = 1,
                name = "You (CEO)",
                role = "Security Lead",
                level = 1,
                status = "Active",
                efficiency = 1.0
            },
            {
                id = 2,
                name = "Alex Rivera",
                role = "Junior Analyst",
                level = 1,
                status = "Ready",
                efficiency = 1.2
            },
            {
                id = 3,
                name = "Sam Chen",
                role = "Network Admin",
                level = 1,
                status = "Ready",
                efficiency = 1.1
            }
        }
    end
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
    
    print("📢 UIManager: " .. message)
end

-- Update UI system
function UIManager:update(dt)
    -- Update notifications
    self:updateNotifications(dt)
    
    -- Update performance stats
    if self.gameLoop then
        self.panelData[UI_PANELS.STATS].performance = self.gameLoop:getPerformanceMetrics()
    end
    
    -- Update HUD data (money, income/sec, reputation)
    self:updateHUDDisplay()
    
    -- Update specialist roster
    if self.panelVisibility[UI_PANELS.ROSTER] then
        self:updateRosterDisplay()
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
    elseif self.currentState == UI_STATES.GAME or self.currentState == UI_STATES.PAUSED then
        self:drawGameUI()
        if self.currentState == UI_STATES.PAUSED then
            self:drawPauseOverlay()
        end
    end
end

-- Draw loading screen
function UIManager:drawLoadingScreen()
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    
    love.graphics.setColor(self.colors.text)
    local text = "Loading Idle Sec Ops..."
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
    
    if self.panelVisibility[UI_PANELS.ROSTER] then
        self:drawRosterPanel()
    end
    
    if self.panelVisibility[UI_PANELS.NOTIFICATIONS] then
        self:drawNotifications()
    end
end

-- Draw HUD panel
function UIManager:drawHUDPanel()
    local x, y = self.margin, self.margin
    local width = 450
    local height = 80
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print(self.panelData[UI_PANELS.HUD].title, x + self.padding, y + self.padding)
    
    -- Resource displays in a row
    love.graphics.setColor(self.colors.text)
    local yOffset = 25
    
    -- Money display
    local money = self.panelData[UI_PANELS.HUD].money
    local moneyText = "💰 " .. self:formatNumber(money)
    love.graphics.print(moneyText, x + self.padding, y + self.padding + yOffset)
    
    -- Income per second display  
    local incomePerSec = self.panelData[UI_PANELS.HUD].incomePerSec
    local incomeText = "📈 " .. self:formatIncomePerSec(incomePerSec)
    love.graphics.print(incomeText, x + self.padding + 120, y + self.padding + yOffset)
    
    -- Reputation display
    local reputation = self.panelData[UI_PANELS.HUD].reputation
    local repText = "⭐ " .. self:formatNumber(reputation) .. " Rep"
    love.graphics.print(repText, x + self.padding + 240, y + self.padding + yOffset)
    
    -- Sub-labels
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Money", x + self.padding, y + self.padding + yOffset + 15)
    love.graphics.print("Income", x + self.padding + 120, y + self.padding + yOffset + 15)
    love.graphics.print("Reputation", x + self.padding + 240, y + self.padding + yOffset + 15)
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

-- Draw specialist roster panel
function UIManager:drawRosterPanel()
    local x, y = self.margin, self.screenHeight - 150 - self.margin
    local width = self.screenWidth - (2 * self.margin)
    local height = 150
    
    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("👥 Specialist Roster", x + self.padding, y + self.padding)
    
    -- Draw starter specialists in a row
    local specialists = self.panelData[UI_PANELS.ROSTER].starterSpecialists
    local specialistWidth = (width - (4 * self.padding)) / 3
    
    for i, specialist in ipairs(specialists) do
        local specX = x + self.padding + ((i - 1) * (specialistWidth + self.padding))
        local specY = y + self.padding + 25
        local specHeight = height - 50
        
        -- Specialist card background
        love.graphics.setColor(self.colors.backgroundLight)
        love.graphics.rectangle("fill", specX, specY, specialistWidth, specHeight)
        love.graphics.setColor(self.colors.border)
        love.graphics.rectangle("line", specX, specY, specialistWidth, specHeight)
        
        -- Specialist info
        love.graphics.setColor(self.colors.text)
        love.graphics.print(specialist.name, specX + 5, specY + 5)
        
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(specialist.role, specX + 5, specY + 20)
        love.graphics.print("Level " .. specialist.level, specX + 5, specY + 35)
        
        -- Status indicator
        local statusColor = self.colors.success
        if specialist.status == "Ready" then
            statusColor = self.colors.accent
        end
        love.graphics.setColor(statusColor)
        love.graphics.print("● " .. specialist.status, specX + 5, specY + 50)
        
        -- Efficiency display
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Eff: " .. string.format("%.1fx", specialist.efficiency), 
                           specX + 5, specY + 65)
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
        print("🖥️ UIManager: State changed to " .. state)
    end
end

-- Toggle panel visibility
function UIManager:togglePanel(panel)
    if self.panelVisibility[panel] ~= nil then
        self.panelVisibility[panel] = not self.panelVisibility[panel]
        print("🖥️ UIManager: Toggled " .. panel .. " panel")
    end
end

-- Handle screen resize
function UIManager:resize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    print("🖥️ UIManager: Resized to " .. width .. "x" .. height)
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
    
    print("🖥️ UIManager: State loaded successfully")
end

-- Initialize method for GameLoop integration  
function UIManager:initialize()
    self.currentState = UI_STATES.SPLASH
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    print("🖥️ UIManager: Fortress architecture integration complete")
end

-- Shutdown method for GameLoop integration
function UIManager:shutdown()
    print("🖥️ UIManager: Shutdown complete")
end

return UIManager
