-- SOC View Scene - Main Operational Interface
-- Central command view for SOC operations: threat detection, incident response, and resource management
-- Emulates real-life SOC workflow with continuous monitoring and response capabilities

local SOCView = {}
SOCView.__index = SOCView

-- Create new SOC view scene
function SOCView.new()
    local self = setmetatable({}, SOCView)
    
    -- Scene state
    self.eventBus = nil
    self.resourceManager = nil
    self.threatSimulation = nil
    self.securityUpgrades = nil
    
    -- SOC operational state
    self.socStatus = {
        alertLevel = "GREEN", -- GREEN, YELLOW, ORANGE, RED
        activeIncidents = {},
        detectionCapability = 0,
        responseCapability = 0,
        lastThreatScan = 0,
        scanInterval = 5.0 -- Scan every 5 seconds
    }
    
    -- UI layout
    self.layout = {
        headerHeight = 80,
        sidebarWidth = 250,
        panelSpacing = 10
    }
    
    -- Navigation
    self.selectedPanel = 1
    self.panels = {
        {name = "Threat Monitor", key = "threats"},
        {name = "Incident Response", key = "incidents"},
        {name = "Resource Status", key = "resources"},
        {name = "Upgrades", key = "upgrades"}
    }
    
    return self
end

-- Initialize SOC view
function SOCView:initialize(eventBus)
    self.eventBus = eventBus

    -- Ensure default scene state exists if module wasn't instantiated via new()
    if not self.socStatus then
        self.socStatus = {
            alertLevel = "GREEN",
            activeIncidents = {},
            detectionCapability = 0,
            responseCapability = 0,
            lastThreatScan = 0,
            scanInterval = 5.0
        }
    end

    if not self.layout then
        self.layout = {
            headerHeight = 80,
            sidebarWidth = 250,
            panelSpacing = 10
        }
    end

    if not self.selectedPanel then
        self.selectedPanel = 1
    end

    if not self.panels then
        self.panels = {
            {name = "Threat Monitor", key = "threats"},
            {name = "Incident Response", key = "incidents"},
            {name = "Resource Status", key = "resources"},
            {name = "Upgrades", key = "upgrades"}
        }
    end

    -- Subscribe to SOC events
    if self.eventBus then
        -- Canonical event shape: { threat = <obj>, ... }
        -- Consumers now expect the canonical payload to simplify event handling.
        self.eventBus:subscribe("threat_detected", function(event)
            local threatObj = event and event.threat

            if not threatObj then
                return
            end

            -- Ensure threatObj has a name (fallback to id)
            if not threatObj.name and threatObj.id then
                threatObj.name = tostring(threatObj.id)
            end

            self:handleThreatDetected(threatObj)
        end)

        self.eventBus:subscribe("incident_resolved", function(data)
            self:handleIncidentResolved(data)
        end)

        self.eventBus:subscribe("security_upgrade_purchased", function(data)
            self:updateSOCCapabilities()
        end)
    end

    print("🛡️ SOCView: Initialized SOC operational interface")
end

-- Enter SOC view scene
function SOCView:enter(data)
    -- Get system references from the game
    if data and data.systems then
        self.resourceManager = data.systems.resourceManager
        self.threatSimulation = data.systems.threatSimulation
        self.securityUpgrades = data.systems.securityUpgrades
    end
    
    self:updateSOCCapabilities()
    print("🛡️ SOCView: SOC operations center activated")
end

-- Exit SOC view scene
function SOCView:exit()
    print("🛡️ SOCView: SOC operations center deactivated")
end

-- Update SOC view
function SOCView:update(dt)
    -- Update threat scanning
    self.socStatus.lastThreatScan = self.socStatus.lastThreatScan + dt
    
    if self.socStatus.lastThreatScan >= self.socStatus.scanInterval then
        self:performThreatScan()
        self.socStatus.lastThreatScan = 0
    end
    
    -- Update alert level based on active incidents
    self:updateAlertLevel()
    
    -- Update incident timers
    for i = #self.socStatus.activeIncidents, 1, -1 do
        local incident = self.socStatus.activeIncidents[i]
        incident.timeRemaining = incident.timeRemaining - dt
        
        if incident.timeRemaining <= 0 then
            self:autoResolveIncident(incident)
            table.remove(self.socStatus.activeIncidents, i)
        end
    end
end

-- Draw SOC view
function SOCView:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.02, 0.05, 0.08, 1) -- Very dark blue SOC background
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw header
    self:drawHeader()
    
    -- Draw main content area
    self:drawMainContent()
    
    -- Draw sidebar
    self:drawSidebar()
    
    -- Draw status indicators
    self:drawStatusIndicators()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw SOC header
function SOCView:drawHeader()
    local screenWidth = love.graphics.getWidth()
    local headerHeight = self.layout.headerHeight
    
    -- Header background
    love.graphics.setColor(0.1, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, headerHeight)
    
    -- Title
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.print("🛡️ SOC Command Center", 20, 20)
    
    -- Alert level indicator
    local alertColor = self:getAlertLevelColor()
    love.graphics.setColor(alertColor)
    love.graphics.print("Alert Level: " .. self.socStatus.alertLevel, screenWidth - 200, 20)
    
    -- Active incidents count
    love.graphics.setColor(1, 1, 1, 1)
    local incidentCount = #self.socStatus.activeIncidents
    love.graphics.print("Active Incidents: " .. incidentCount, 20, 50)
    
    -- Resources summary
    if self.resourceManager then
        local money = self.resourceManager:getResource("money") or 0
        local reputation = self.resourceManager:getResource("reputation") or 0
        love.graphics.print("Budget: $" .. money .. " | Reputation: " .. reputation, 300, 50)
    end
end

-- Draw main content area
function SOCView:drawMainContent()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local contentX = self.layout.sidebarWidth + self.layout.panelSpacing
    local contentY = self.layout.headerHeight + self.layout.panelSpacing
    local contentWidth = screenWidth - contentX - self.layout.panelSpacing
    local contentHeight = screenHeight - contentY - self.layout.panelSpacing
    
    -- Content background
    love.graphics.setColor(0.05, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", contentX, contentY, contentWidth, contentHeight)
    
    -- Draw selected panel content
    local selectedPanel = self.panels[self.selectedPanel]
    if selectedPanel then
        love.graphics.setColor(0.2, 0.8, 1, 1)
        love.graphics.print(selectedPanel.name, contentX + 20, contentY + 20)
        
        if selectedPanel.key == "threats" then
            self:drawThreatMonitor(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
        elseif selectedPanel.key == "incidents" then
            self:drawIncidentResponse(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
        elseif selectedPanel.key == "resources" then
            self:drawResourceStatus(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
        elseif selectedPanel.key == "upgrades" then
            self:drawUpgradesPanel(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
        end
    end
end

-- Draw sidebar with navigation
function SOCView:drawSidebar()
    local sidebarWidth = self.layout.sidebarWidth
    local screenHeight = love.graphics.getHeight()
    local sidebarY = self.layout.headerHeight
    
    -- Sidebar background
    love.graphics.setColor(0.08, 0.12, 0.16, 1)
    love.graphics.rectangle("fill", 0, sidebarY, sidebarWidth, screenHeight - sidebarY)
    
    -- Navigation panels
    local itemHeight = 40
    local startY = sidebarY + 20
    
    for i, panel in ipairs(self.panels) do
        local y = startY + (i - 1) * (itemHeight + 5)
        local isSelected = (i == self.selectedPanel)
        
        -- Highlight selected panel
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
            love.graphics.rectangle("fill", 5, y - 2, sidebarWidth - 10, itemHeight)
        end
        
        -- Panel text
        local textColor = isSelected and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 1}
        love.graphics.setColor(textColor)
        love.graphics.print(panel.name, 15, y + 10)
    end
    
    -- Quick actions
    love.graphics.setColor(0.5, 0.8, 0.5, 1)
    love.graphics.print("Quick Actions:", 15, startY + (#self.panels + 1) * (itemHeight + 5))
    
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local actionY = startY + (#self.panels + 2) * (itemHeight + 5)
    love.graphics.print("[U] - Upgrade Shop", 15, actionY)
    love.graphics.print("[M] - Main Menu", 15, actionY + 25)
    love.graphics.print("[S] - Save Game", 15, actionY + 50)
end

-- Draw status indicators
function SOCView:drawStatusIndicators()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Capability indicators
    local indicatorY = screenHeight - 60
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Detection: " .. self.socStatus.detectionCapability .. "%", 20, indicatorY)
    love.graphics.print("Response: " .. self.socStatus.responseCapability .. "%", 200, indicatorY)
    
    -- Scan timer
    local scanProgress = 1 - (self.socStatus.lastThreatScan / self.socStatus.scanInterval)
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", screenWidth - 120, indicatorY, scanProgress * 100, 20)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", screenWidth - 120, indicatorY, 100, 20)
    love.graphics.print("Scan", screenWidth - 110, indicatorY + 25)
end

-- Draw threat monitor panel
function SOCView:drawThreatMonitor(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("🚨 Real-time Threat Detection", x, y)
    
    -- Threat statistics
    if self.threatSimulation and type(self.threatSimulation.getThreatStatistics) == "function" then
        local stats = self.threatSimulation:getThreatStatistics() or {}
        love.graphics.print("Threats Detected: " .. (stats.totalThreats or 0), x, y + 30)
        love.graphics.print("Active Threats: " .. (stats.activeThreats or 0), x, y + 50)
        love.graphics.print("Mitigated: " .. (stats.mitigatedThreats or 0) .. " | Failed: " .. (stats.failedThreats or 0), x, y + 70)
    else
        love.graphics.print("Threat statistics unavailable", x, y + 30)
    end
    
    -- Recent threat activity (placeholder)
    love.graphics.print("Recent Activity:", x, y + 110)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("• Network scan attempt blocked", x + 20, y + 135)
    love.graphics.print("• Phishing email quarantined", x + 20, y + 155)
    love.graphics.print("• Malware signature updated", x + 20, y + 175)
end

-- Draw incident response panel
function SOCView:drawIncidentResponse(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("🚨 Active Incidents", x, y)
    
    if #self.socStatus.activeIncidents == 0 then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.print("No active incidents - SOC operating normally", x, y + 30)
    else
        for i, incident in ipairs(self.socStatus.activeIncidents) do
            local incidentY = y + 30 + (i - 1) * 60
            
            -- Incident severity color
            local severityColor = {0.8, 0.8, 0.2, 1} -- Default yellow
            if incident.severity == "high" then
                severityColor = {0.8, 0.2, 0.2, 1} -- Red
            elseif incident.severity == "low" then
                severityColor = {0.2, 0.8, 0.2, 1} -- Green
            end
            
            love.graphics.setColor(severityColor)
            love.graphics.print("• " .. incident.name, x, incidentY)
            
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            love.graphics.print("Time remaining: " .. math.ceil(incident.timeRemaining) .. "s", x + 20, incidentY + 20)
            love.graphics.print("Impact: " .. incident.impact, x + 20, incidentY + 35)
        end
    end
end

-- Draw resource status panel
function SOCView:drawResourceStatus(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("💰 Resource Overview", x, y)
    
    if self.resourceManager then
        love.graphics.print("Money: $" .. (self.resourceManager:getResource("money") or 0), x, y + 30)
        love.graphics.print("Reputation: " .. (self.resourceManager:getResource("reputation") or 0), x, y + 50)
        love.graphics.print("XP: " .. (self.resourceManager:getResource("xp") or 0), x, y + 70)
        love.graphics.print("Mission Tokens: " .. (self.resourceManager:getResource("missionTokens") or 0), x, y + 90)
        
        -- Resource generation rates
        love.graphics.print("Generation Rates:", x, y + 130)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("• Money: $" .. (self.resourceManager:getGeneration("money") or 0) .. "/sec", x + 20, y + 155)
        love.graphics.print("• Reputation: " .. (self.resourceManager:getGeneration("reputation") or 0) .. "/sec", x + 20, y + 175)
    end
end

-- Draw upgrades panel
function SOCView:drawUpgradesPanel(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("🔧 Security Infrastructure", x, y)
    
    if self.securityUpgrades then
        local owned = self.securityUpgrades:getOwnedUpgrades() or {}
        
        if #owned == 0 then
            love.graphics.setColor(0.8, 0.8, 0.2, 1)
            love.graphics.print("No upgrades installed - Basic protection only", x, y + 30)
        else
            love.graphics.print("Installed Upgrades:", x, y + 30)
            for i, upgrade in ipairs(owned) do
                love.graphics.setColor(0.2, 0.8, 0.2, 1)
                love.graphics.print("• " .. upgrade.name, x + 20, y + 50 + (i - 1) * 25)
            end
        end
        
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("Press [U] to open upgrade shop", x, y + height - 30)
    end
end

-- Handle key input
function SOCView:keypressed(key)
    if key == "up" then
        self.selectedPanel = math.max(1, self.selectedPanel - 1)
    elseif key == "down" then
        self.selectedPanel = math.min(#self.panels, self.selectedPanel + 1)
    elseif key == "u" then
        self.eventBus:publish("scene_request", {scene = "upgrade_shop"})
    elseif key == "m" then
        self.eventBus:publish("scene_request", {scene = "main_menu"})
    elseif key == "s" then
        self.eventBus:publish("save_game_request", {})
    elseif key == "escape" then
        self.eventBus:publish("scene_request", {scene = "main_menu"})
    end
end

-- Handle mouse input
function SOCView:mousepressed(x, y, button)
    -- Handle sidebar panel selection
    if x <= self.layout.sidebarWidth and y >= self.layout.headerHeight then
        local itemHeight = 40
        local startY = self.layout.headerHeight + 20
        
        for i, panel in ipairs(self.panels) do
            local panelY = startY + (i - 1) * (itemHeight + 5)
            if y >= panelY and y <= panelY + itemHeight then
                self.selectedPanel = i
                break
            end
        end
    end
end

-- SOC operational methods
function SOCView:performThreatScan()
    -- Simulate threat detection based on capabilities
    if math.random() < (self.socStatus.detectionCapability / 100) then
        local threat = self:generateThreat()
        if threat then
            -- Publish canonical event shape for threat detection
            self.eventBus:publish("threat_detected", { threat = threat, source = "soc_view" })
        end
    end
end

function SOCView:generateThreat()
    local threatTypes = {
        {name = "Port Scan", severity = "low", impact = "Reconnaissance attempt"},
        {name = "Phishing Email", severity = "medium", impact = "Credential theft attempt"},
        {name = "Malware Detection", severity = "high", impact = "System compromise attempt"},
        {name = "DDoS Attack", severity = "high", impact = "Service disruption"}
    }
    
    local threat = threatTypes[math.random(#threatTypes)]
    threat.id = "threat_" .. os.time() .. "_" .. math.random(1000)
    threat.timeRemaining = math.random(30, 120) -- 30-120 seconds to resolve
    
    return threat
end

function SOCView:handleThreatDetected(threat)
    table.insert(self.socStatus.activeIncidents, threat)
    print("🚨 SOC: Threat detected - " .. threat.name)
end

function SOCView:handleIncidentResolved(incident)
    for i, activeIncident in ipairs(self.socStatus.activeIncidents) do
        if activeIncident.id == incident.id then
            table.remove(self.socStatus.activeIncidents, i)
            break
        end
    end
    print("✅ SOC: Incident resolved - " .. incident.name)
end

function SOCView:autoResolveIncident(incident)
    -- Auto-resolve incident based on response capability
    local successChance = self.socStatus.responseCapability / 100
    local success = math.random() < successChance
    
    if success then
        print("✅ SOC: Auto-resolved incident - " .. incident.name)
        if self.resourceManager then
            self.resourceManager:addResource("xp", 10)
            self.resourceManager:addResource("reputation", 1)
        end
    else
        print("❌ SOC: Failed to resolve incident - " .. incident.name)
        if self.resourceManager then
            self.resourceManager:addResource("money", -100)
            self.resourceManager:addResource("reputation", -2)
        end
    end
end

function SOCView:updateAlertLevel()
    local incidentCount = #self.socStatus.activeIncidents
    local highSeverityCount = 0
    
    for _, incident in ipairs(self.socStatus.activeIncidents) do
        if incident.severity == "high" then
            highSeverityCount = highSeverityCount + 1
        end
    end
    
    if highSeverityCount > 0 then
        self.socStatus.alertLevel = "RED"
    elseif incidentCount >= 3 then
        self.socStatus.alertLevel = "ORANGE"
    elseif incidentCount >= 1 then
        self.socStatus.alertLevel = "YELLOW"
    else
        self.socStatus.alertLevel = "GREEN"
    end
end

function SOCView:updateSOCCapabilities()
    -- Calculate capabilities based on upgrades
    self.socStatus.detectionCapability = 10 -- Base 10%
    self.socStatus.responseCapability = 20  -- Base 20%
    
    if self.securityUpgrades then
        local owned = self.securityUpgrades:getOwnedUpgrades() or {}
        for _, upgrade in ipairs(owned) do
            if upgrade.detectionImprovement then
                self.socStatus.detectionCapability = self.socStatus.detectionCapability + upgrade.detectionImprovement
            end
            if upgrade.responseImprovement then
                self.socStatus.responseCapability = self.socStatus.responseCapability + upgrade.responseImprovement
            end
        end
    end
    
    -- Cap capabilities at 95%
    self.socStatus.detectionCapability = math.min(95, self.socStatus.detectionCapability)
    self.socStatus.responseCapability = math.min(95, self.socStatus.responseCapability)
end

function SOCView:getAlertLevelColor()
    if self.socStatus.alertLevel == "GREEN" then
        return {0.2, 0.8, 0.2, 1}
    elseif self.socStatus.alertLevel == "YELLOW" then
        return {0.8, 0.8, 0.2, 1}
    elseif self.socStatus.alertLevel == "ORANGE" then
        return {0.8, 0.5, 0.2, 1}
    elseif self.socStatus.alertLevel == "RED" then
        return {0.8, 0.2, 0.2, 1}
    end
    return {1, 1, 1, 1}
end

return SOCView