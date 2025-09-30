-- SOC View Scene - Main Operational Interface
-- Central command view for SOC operations: threat detection, incident response, and resource management
-- Emulates real-life SOC workflow with continuous monitoring and response capabilities

local SOCView = {}
SOCView.__index = SOCView

-- Create new SOC view scene
function SOCView.new(systems, eventBus)
    local self = setmetatable({}, SOCView)
    
    -- Dependencies
    self.systems = systems or {}
    self.eventBus = eventBus

    -- Internal State
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    self.upgrades = {}

    -- UI State
    self.layout = {
        headerHeight = 80,
        sidebarWidth = 250,
        panelSpacing = 10
    }
    self.selectedPanel = 1
    self.panels = {
        {name = "Threat Monitor", key = "threats"},
        {name = "Incident Response", key = "incidents"},
        {name = "Resource Status", key = "resources"},
        {name = "Upgrades", key = "upgrades"},
        {name = "Contracts", key = "contracts"},
        {name = "Specialists", key = "specialists"}
    }

    -- Game Logic State
    self.socStatus = {
        alertLevel = "GREEN",
        activeIncidents = {},
        detectionCapability = 0,
        responseCapability = 0,
        lastThreatScan = 0,
        scanInterval = 5.0
    }

    -- Event System State
    self.currentEvent = nil
    self.eventDisplayTime = 0
    self.eventDisplayDuration = 5.0 -- How long to show simple events
    self.showingChoiceEvent = false

    -- Subscribe to long-lived events
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function(event)
            local threatObj = event and event.threat
            if not threatObj then return end
            if not threatObj.name and threatObj.id then threatObj.name = tostring(threatObj.id) end
            self:handleThreatDetected(threatObj)
        end)

        self.eventBus:subscribe("incident_resolved", function(data) self:handleIncidentResolved(data) end)
        self.eventBus:subscribe("security_upgrade_purchased", function(data) self:updateSOCCapabilities() end)
        
        -- Dynamic Event System integration
        self.eventBus:subscribe("dynamic_event_triggered", function(data)
            self:handleDynamicEvent(data.event)
        end)
        
        -- UI update events
        self.eventBus:subscribe("resource_changed", function() self:updateData() end)
        self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
        self.eventBus:subscribe("contract_completed", function() self:updateData() end)
        self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
        self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    end

    -- Initial data fetch
    if self.systems.resourceManager then
        self.resources = self.systems.resourceManager:getState()
    end
    self:updateSOCCapabilities()

    print("🛡️ SOCView: Initialized SOC operational interface")
    return self
end

-- Enter SOC view scene
function SOCView:enter(data)
    print("🛡️ SOCView: SOC operations center activated")
    -- Refresh data every time the scene is entered
    self:updateData()
end

-- Exit SOC view scene
function SOCView:exit()
    print("Exiting SOC View")
    -- Unsubscribe from events if necessary in the future
end

function SOCView:updateData()
    if self.systems.resourceManager then
        self.resources = self.systems.resourceManager:getState()
    end
    if self.systems.contractSystem then
        self.contracts = self.systems.contractSystem:getActiveContracts()
    end
    if self.systems.specialistSystem then
        self.specialists = self.systems.specialistSystem:getAllSpecialists()
        self.availableForHire = self.systems.specialistSystem:getAvailableForHire()
    end
    if self.systems.upgradeSystem then
        self.upgrades = self.systems.upgradeSystem:getPurchasedUpgrades()
    end
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
    
    -- Update event display timer
    if self.currentEvent and not self.showingChoiceEvent then
        self.eventDisplayTime = self.eventDisplayTime + dt
        if self.eventDisplayTime >= self.eventDisplayDuration then
            self.currentEvent = nil
            self.eventDisplayTime = 0
        end
    end
end

function SOCView:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)

    local y = 10
    love.graphics.printf("SOC Command Center - Alert Level: " .. self.socStatus.alertLevel, 0, y, love.graphics.getWidth(), "center")
    y = y + 30

    -- Draw Resources
    love.graphics.print("== Resources ==", 10, y)
    y = y + 20
    if self.resources then
        for name, value in pairs(self.resources) do
            love.graphics.print(string.format("%s: %s", name, tostring(value)), 20, y)
            y = y + 15
        end
    end
    y = y + 10

    -- Draw Active Contracts
    love.graphics.print("== Active Contracts ==", 10, y)
    y = y + 20
    if self.contracts and next(self.contracts) then
        for id, contract in pairs(self.contracts) do
            love.graphics.print(string.format("[%s] %s - Time Left: %d", id, contract.clientName, contract.remainingTime), 20, y)
            y = y + 15
        end
    else
        love.graphics.print("No active contracts.", 20, y)
        y = y + 15
    end
    y = y + 10

    -- Draw Specialists
    love.graphics.print("== Your Specialists ==", 10, y)
    y = y + 20
    if self.specialists and next(self.specialists) then
        for id, specialist in pairs(self.specialists) do
            love.graphics.print(string.format("[%s] %s (Lvl %d)", id, specialist.name, specialist.level), 20, y)
            y = y + 15
        end
    else
        love.graphics.print("No specialists hired.", 20, y)
        y = y + 15
    end
    y = y + 10

    -- Draw Available for Hire
    love.graphics.print("== Available for Hire (Press 'h' to hire first) ==", 10, y)
    y = y + 20
    if self.availableForHire and #self.availableForHire > 0 then
        for i, specialist in ipairs(self.availableForHire) do
            local cost = specialist.cost.money or "N/A"
            love.graphics.print(string.format("[%d] %s (Cost: %s)", i, specialist.name, cost), 20, y)
            y = y + 15
        end
    else
        love.graphics.print("No specialists available for hire.", 20, y)
        y = y + 15
    end
    y = y + 10

    -- Draw Available Upgrades
    love.graphics.print("== Available Upgrades (Press 'u' to buy first) ==", 10, y)
    y = y + 20
    if self.systems.upgradeSystem then
        local availableUpgrades = self.systems.upgradeSystem:getAvailableUpgrades()
        if availableUpgrades and #availableUpgrades > 0 then
            for _, upgrade in ipairs(availableUpgrades) do
                local cost = upgrade.cost.money or "N/A"
                love.graphics.print(string.format("[%s] %s (Cost: %s)", upgrade.id, upgrade.name, cost), 20, y)
                y = y + 15
            end
        else
            love.graphics.print("No new upgrades available.", 20, y)
            y = y + 15
        end
    end
    
    -- Draw current event at the bottom of the screen
    self:drawEventDisplay()
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
        local money = math.floor(self.resourceManager:getResource("money") or 0)
        local reputation = math.floor(self.resourceManager:getResource("reputation") or 0)
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
        elseif selectedPanel.key == "contracts" then
            self:drawContractsPanel(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
        elseif selectedPanel.key == "specialists" then
            self:drawSpecialistsPanel(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
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
    love.graphics.print("[C] - Start Contract", 15, actionY + 25)
    love.graphics.print("[H] - Hire Specialist", 15, actionY + 50)
    love.graphics.print("[M] - Main Menu", 15, actionY + 75)
    love.graphics.print("[S] - Save Game", 15, actionY + 100)
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
        love.graphics.print("Money: $" .. math.floor(self.resourceManager:getResource("money") or 0), x, y + 30)
        love.graphics.print("Reputation: " .. math.floor(self.resourceManager:getResource("reputation") or 0), x, y + 50)
        love.graphics.print("XP: " .. math.floor(self.resourceManager:getResource("xp") or 0), x, y + 70)
        love.graphics.print("Mission Tokens: " .. math.floor(self.resourceManager:getResource("missionTokens") or 0), x, y + 90)
        
        -- Resource generation rates
        love.graphics.print("Generation Rates:", x, y + 130)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        -- This part is tricky as simple generation is not the whole picture with contracts.
        -- A better approach would be to sum up income from active contracts.
        if self.contractSystem then
            local incomeRate = 0
            for _, contract in ipairs(self.contractSystem:getActiveContracts()) do
                incomeRate = incomeRate + (contract.data.rewards.money / contract.data.duration)
            end
            love.graphics.print("• Money: $" .. string.format("%.2f", incomeRate) .. "/sec", x + 20, y + 155)
        end
    end
end

-- Draw upgrades panel
function SOCView:drawUpgradesPanel(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("🔧 Security Infrastructure", x, y)
    
    if self.upgradeSystem then
        local availableUpgrades = self.upgradeSystem:getAvailableUpgrades()
        
        if #availableUpgrades == 0 then
            love.graphics.setColor(0.8, 0.8, 0.2, 1)
            love.graphics.print("No new upgrades available.", x, y + 30)
        else
            love.graphics.print("Available Upgrades:", x, y + 30)
            for i, upgrade in ipairs(availableUpgrades) do
                love.graphics.setColor(0.2, 0.8, 0.2, 1)
                love.graphics.print("• " .. upgrade.name .. " ($" .. upgrade.cost.money .. ")", x + 20, y + 50 + (i - 1) * 25)
            end
        end
        
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("Press [U] to purchase first available upgrade", x, y + height - 30)
    end
end

function SOCView:drawContractsPanel(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("📄 Contracts", x, y)

    if self.contractSystem then
        love.graphics.print("Active Contracts:", x, y + 30)
        local activeContracts = self.contractSystem:getActiveContracts()
        if #activeContracts == 0 then
            love.graphics.print("  None", x, y + 50)
        else
            for i, contract in ipairs(activeContracts) do
                local progress = contract.progress * 100
                love.graphics.print("  - " .. contract.data.title .. " (" .. string.format("%.1f", progress) .. "%)", x, y + 30 + i * 20)
            end
        end

        love.graphics.print("Available Contracts:", x, y + 100)
        local availableContracts = self.dataManager:getData("contracts")
        if not availableContracts or #availableContracts.contracts == 0 then
             love.graphics.print("  None", x, y + 120)
        else
            for i, contract in ipairs(availableContracts.contracts) do
                 love.graphics.print("  - " .. contract.title, x, y + 100 + i * 20)
            end
        end
    end
end

function SOCView:drawSpecialistsPanel(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("👥 Specialists", x, y)

    if self.specialistSystem then
        love.graphics.print("Owned Specialists:", x, y + 30)
        local owned = self.specialistSystem:getOwnedSpecialists()
        if #owned == 0 then
            love.graphics.print("  None", x, y + 50)
        else
            for i, specialist in ipairs(owned) do
                love.graphics.print("  - " .. specialist.data.name, x, y + 30 + i * 20)
            end
        end

        love.graphics.print("Available for Hire:", x, y + 100)
        local available = self.dataManager:getData("specialists")
        if not available or #available.specialists == 0 then
            love.graphics.print("  None", x, y + 120)
        else
            for i, specialist in ipairs(available.specialists) do
                love.graphics.print("  - " .. specialist.name .. " ($" .. specialist.cost .. ")", x, y + 100 + i * 20)
            end
        end
    end
end

-- Handle key input
function SOCView:keypressed(key)
    -- Handle event choices first (highest priority)
    if self.showingChoiceEvent and self.currentEvent and self.currentEvent.choices then
        local choiceNum = tonumber(key)
        if choiceNum and choiceNum >= 1 and choiceNum <= #self.currentEvent.choices then
            self:handleEventChoice(choiceNum)
            return
        end
    end
    
    if key == "up" then
        self.selectedPanel = math.max(1, self.selectedPanel - 1)
    elseif key == "down" then
        self.selectedPanel = math.min(#self.panels, self.selectedPanel + 1)
    elseif key == "c" then
        if self.contractSystem and self.dataManager then
            local contracts = self.dataManager:getData("contracts")
            if contracts and #contracts.contracts > 0 then
                self.contractSystem:startContract(contracts.contracts[1].id)
            end
        end
    elseif key == "h" then
        if self.systems.specialistSystem then
            local availableForHire = self.systems.specialistSystem:getAvailableForHire()
            if availableForHire and #availableForHire > 0 then
                -- Hire the first one in the list (index 1)
                self.systems.specialistSystem:hireSpecialist(1)
            end
        end
    elseif key == "u" then
        if self.systems.upgradeSystem then
            local availableUpgrades = self.systems.upgradeSystem:getAvailableUpgrades()
            if availableUpgrades and #availableUpgrades > 0 then
                self.systems.upgradeSystem:purchaseUpgrade(availableUpgrades[1].id)
            end
        end
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

-- Handle threat detection
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

-- Dynamic Event System Methods
function SOCView:handleDynamicEvent(event)
    if not event then return end
    
    self.currentEvent = event
    self.eventDisplayTime = 0
    
    if event.type == "choice" then
        self.showingChoiceEvent = true
        print("🎯 Choice event displayed: " .. event.description)
    else
        self.showingChoiceEvent = false
        print("📢 Event triggered: " .. event.description)
    end
end

function SOCView:drawEventDisplay()
    if not self.currentEvent then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Event panel dimensions
    local panelWidth = math.min(600, screenWidth - 40)
    local panelHeight = self.showingChoiceEvent and 200 or 120
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = screenHeight - panelHeight - 20
    
    -- Draw panel background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    
    -- Draw panel border
    local borderColor = self:getEventTypeColor(self.currentEvent.type)
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Draw event type indicator
    love.graphics.setColor(borderColor)
    love.graphics.print("● " .. string.upper(self.currentEvent.type), panelX + 10, panelY + 10)
    
    -- Draw event description
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.currentEvent.description, panelX + 10, panelY + 35, panelWidth - 20, "left")
    
    if self.showingChoiceEvent and self.currentEvent.choices then
        -- Draw choices
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("Choose an option:", panelX + 10, panelY + 80)
        
        for i, choice in ipairs(self.currentEvent.choices) do
            love.graphics.setColor(0.7, 0.9, 1, 1)
            love.graphics.print(string.format("[%d] %s", i, choice.text), panelX + 20, panelY + 95 + (i - 1) * 20)
        end
        
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("Press number key to choose", panelX + 10, panelY + panelHeight - 25)
    else
        -- Show auto-close timer for simple events
        local remaining = self.eventDisplayDuration - self.eventDisplayTime
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print(string.format("Auto-closing in %.1f seconds", remaining), panelX + 10, panelY + panelHeight - 25)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function SOCView:getEventTypeColor(eventType)
    if eventType == "positive" then
        return {0.2, 0.8, 0.2, 1} -- Green
    elseif eventType == "negative" then
        return {0.8, 0.2, 0.2, 1} -- Red
    elseif eventType == "choice" then
        return {0.2, 0.6, 1, 1} -- Blue
    else
        return {0.6, 0.6, 0.6, 1} -- Gray for neutral
    end
end

function SOCView:handleEventChoice(choiceIndex)
    if not self.currentEvent or not self.currentEvent.choices then return end
    
    local choice = self.currentEvent.choices[choiceIndex]
    if not choice then return end
    
    print("🎯 Player chose: " .. choice.text)
    
    -- Process choice effects
    if choice.effects.chance then
        -- Probabilistic effects
        local random = math.random()
        local totalProbability = 0
        
        for _, outcome in ipairs(choice.effects.chance) do
            totalProbability = totalProbability + outcome.probability
            if random <= totalProbability then
                print("🎲 Outcome selected with " .. (outcome.probability * 100) .. "% chance")
                if outcome.effect then
                    self.eventBus:publish("resource_add", outcome.effect)
                end
                break
            end
        end
    elseif choice.effects then
        -- Direct effects
        self.eventBus:publish("resource_add", choice.effects)
    end
    
    -- Clear the event
    self.currentEvent = nil
    self.showingChoiceEvent = false
    self.eventDisplayTime = 0
end

return SOCView