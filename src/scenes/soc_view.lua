-- SOC View Scene - Main Operational Interface
-- Central command view for SOC operations: threat detection, incident response, and resource management
-- Emulates real-life SOC workflow with continuous monitoring and response capabilities

local SOCView = {}
SOCView.__index = SOCView

local NotificationPanel = require("src.ui.notification_panel")

-- Create new SOC view scene
function SOCView.new(eventBus)
    local self = setmetatable({}, SOCView)
    
    -- Dependencies
    self.systems = {} -- Injected by SceneManager on enter
    self.eventBus = eventBus

    -- Internal State
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    self.upgrades = {}

    -- UI Components
    self.notificationPanel = NotificationPanel.new(eventBus)

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
        {name = "Specialists", key = "specialists"},
        {name = "Skills", key = "skills"}
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
        -- Specialist progression events
        self.eventBus:subscribe("specialist_leveled_up", function(data)
            self:handleSpecialistLevelUp(data)
        end)
        
        -- UI update events
        self.eventBus:subscribe("resource_changed", function() self:updateData() end)
        self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
        self.eventBus:subscribe("contract_completed", function() self:updateData() end)
        self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
        self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    end

    -- Initial data fetch is now done in :enter()
    -- if self.systems.resourceManager then
    --     self.resources = self.systems.resourceManager:getState()
    -- end
    -- self:updateSOCCapabilities()

    print("🛡️ SOCView: Initialized SOC operational interface")
    return self
end

-- Enter SOC view scene
function SOCView:enter(data)
    print("🛡️ SOCView: SOC operations center activated")
    -- Refresh data every time the scene is entered
    self:updateData()
    self:updateSOCCapabilities()
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
    -- Update UI components
    self.notificationPanel:update(dt)

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
            local level = specialist.level or 1
            local currentXp = specialist.xp or 0
            local nextLevelXp = "MAX"
            
            -- Get XP required for next level if available
            if self.systems.specialistSystem and self.systems.specialistSystem.getXpForNextLevel then
                local requiredXp = self.systems.specialistSystem:getXpForNextLevel(level)
                if requiredXp then
                    nextLevelXp = tostring(requiredXp)
                end
            end
            
            local xpDisplay = nextLevelXp == "MAX" and "[MAX LEVEL]" or "[" .. currentXp .. " / " .. nextLevelXp .. " XP]"
            love.graphics.print(string.format("[%s] %s (Lvl %d) %s", id, specialist.name, level, xpDisplay), 20, y)
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
    
    -- Draw notification panel on top of everything
    self.notificationPanel:draw()
end

function SOCView:keypressed(key)
    if self.showingChoiceEvent and self.currentEvent and self.currentEvent.choices then
        local choiceIndex = tonumber(key)
        if choiceIndex and choiceIndex > 0 and choiceIndex <= #self.currentEvent.choices then
            self.eventBus:publish("dynamic_event_choice_made", {
                eventId = self.currentEvent.id,
                choiceIndex = choiceIndex
            })
            self.currentEvent = nil
            self.showingChoiceEvent = false
        end
        return
    end

    if key == "m" then
        self.eventBus:publish("change_scene", { scene = "main_menu" })
    elseif key == "u" then
        if self.systems.upgradeSystem then
            local availableUpgrades = self.systems.upgradeSystem:getAvailableUpgrades()
            if availableUpgrades and #availableUpgrades > 0 then
                self.systems.upgradeSystem:purchaseUpgrade(availableUpgrades[1].id)
            end
        end
    elseif key == "h" then
        if self.systems.specialistSystem then
            local availableForHire = self.systems.specialistSystem:getAvailableForHire()
            if availableForHire and #availableForHire > 0 then
                self.systems.specialistSystem:hireSpecialist(1)
            end
        end
    elseif key == "t" then
        if self.systems.threatSystem then
            local activeThreats = self.systems.threatSystem:getActiveThreats()
            if #activeThreats > 0 then
                self.eventBus:publish("change_scene", {
                    scene = "incident_response",
                    data = { threat = activeThreats[1] }
                })
            end
        end
    elseif key == "s" then
        self.eventBus:publish("save_game_request")
    elseif key == "right" then
        self.selectedPanel = self.selectedPanel % #self.panels + 1
    elseif key == "left" then
        self.selectedPanel = self.selectedPanel - 1
        if self.selectedPanel < 1 then
            self.selectedPanel = #self.panels
        end
    end
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
        elseif selectedPanel.key == "skills" then
            self:drawSkillsPanel(contentX + 20, contentY + 50, contentWidth - 40, contentHeight - 70)
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

-- Draw the skills panel
function SOCView:drawSkillsPanel(x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("📚 Specialist Skills", x, y)
    
    if not self.systems.skillSystem or not self.systems.specialistSystem then
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print("Skill and/or Specialist systems not available.", x, y + 30)
        return
    end

    local specialists = self.systems.specialistSystem:getAllSpecialists()
    local skillSystem = self.systems.skillSystem
    
    local currentY = y + 30
    
    for specialistId, specialist in pairs(specialists) do
        if currentY > y + height - 50 then break end -- Prevent drawing off-panel

        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print(string.format("%s (Lvl %d)", specialist.name, specialist.level), x, currentY)
        currentY = currentY + 20

        local skillProgress = skillSystem:getSkillProgress(specialistId)
        if skillProgress and next(skillProgress) then
            for skillId, progress in pairs(skillProgress) do
                if currentY > y + height - 30 then break end

                local skillDef = skillSystem:getSkill(skillId)
                if skillDef then
                    local xpRequired = skillSystem:getXpRequiredForLevel(skillId, progress.level + 1)
                    local progressText = string.format("  - %s (Lvl %d): %d / %d XP", skillDef.name, progress.level, progress.xp, xpRequired)
                    
                    love.graphics.setColor(0.6, 0.8, 1, 1)
                    love.graphics.print(progressText, x + 15, currentY)
                    currentY = currentY + 18
                end
            end
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.print("  No skills unlocked.", x + 15, currentY)
            currentY = currentY + 18
        end
        currentY = currentY + 10 -- Spacing between specialists
    end
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
    
    -- Get active threats from ThreatSystem
    local activeThreats = {}
    local threatCount = 0
    if self.systems and self.systems.threatSystem then
        activeThreats = self.systems.threatSystem:getActiveThreats()
        threatCount = #activeThreats
    end
    
    -- Threat statistics
    love.graphics.print("Active Threats: " .. threatCount, x, y + 30)
    if threatCount > 0 then
        local highSeverityCount = 0
        for _, threat in ipairs(activeThreats) do
            if threat.severity >= 7 then
                highSeverityCount = highSeverityCount + 1
            end
        end
        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.print("High Severity: " .. highSeverityCount, x, y + 50)
    else
        love.graphics.setColor(0.5, 1, 0.5, 1)
        love.graphics.print("All systems secure", x, y + 50)
    end
    
    -- Active threat list
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Active Threats:", x, y + 80)
    
    if threatCount == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("• No active threats detected", x + 20, y + 105)
    else
        local maxDisplay = 4 -- Limit display to prevent UI overflow
        for i = 1, math.min(maxDisplay, threatCount) do
            local threat = activeThreats[i]
            local timeColor = {0.6, 0.6, 0.6, 1}
            if threat.timeRemaining < 15 then
                timeColor = {1, 0.2, 0.2, 1} -- Red for urgent
            elseif threat.timeRemaining < 30 then
                timeColor = {1, 0.8, 0.2, 1} -- Orange for warning
            end
            
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
            love.graphics.print("• " .. threat.name, x + 20, y + 95 + i * 20)
            love.graphics.setColor(timeColor[1], timeColor[2], timeColor[3], timeColor[4])
            love.graphics.print("(" .. math.ceil(threat.timeRemaining) .. "s)", x + 320, y + 95 + i * 20)
        end
        
        if threatCount > maxDisplay then
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.print("... and " .. (threatCount - maxDisplay) .. " more", x + 20, y + 95 + (maxDisplay + 1) * 20)
        end
    end
    
    -- Instructions for crisis response
    if threatCount > 0 then
        love.graphics.setColor(0.8, 0.8, 0.2, 1)
        love.graphics.print("High-severity threats will auto-trigger crisis mode", x, y + 220)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print("Press [T] to manually respond to active threats", x, y + 240)
    end
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
