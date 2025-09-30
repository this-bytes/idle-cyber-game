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

function SOCView:updateSOCCapabilities()
    self.socStatus.detectionCapability = 0
    self.socStatus.responseCapability = 0
    
    if self.systems.specialistSystem then
        local specialists = self.systems.specialistSystem:getAllSpecialists()
        for _, specialist in pairs(specialists) do
            if specialist.stats then
                self.socStatus.detectionCapability = self.socStatus.detectionCapability + (specialist.stats.analysis or 0)
                self.socStatus.responseCapability = self.socStatus.responseCapability + (specialist.stats.resolve or 0)
            end
        end
    end
end

function SOCView:updateAlertLevel()
    if self.socStatus.activeIncidents and #self.socStatus.activeIncidents > 0 then
        self.socStatus.alertLevel = "RED"
    elseif self.socStatus.activeIncidents and #self.socStatus.activeIncidents > 2 then
        self.socStatus.alertLevel = "ORANGE"
    else
        self.socStatus.alertLevel = "GREEN"
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

    -- Draw Header
    love.graphics.printf("SOC Command Center - Alert Level: " .. self.socStatus.alertLevel, 0, 10, love.graphics.getWidth(), "center")

    -- Draw Sidebar with panel options
    local y = 50
    love.graphics.print("== Panels ==", 10, y)
    y = y + 20
    for i, panel in ipairs(self.panels) do
        local color = {1, 1, 1}
        if i == self.selectedPanel then
            color = {0, 1, 0} -- Highlight selected panel
        end
        love.graphics.setColor(unpack(color))
        love.graphics.print(string.format("[%d] %s", i, panel.name), 20, y)
        y = y + 15
    end
    love.graphics.setColor(1, 1, 1)

    -- Draw a vertical line to separate sidebar
    love.graphics.line(self.layout.sidebarWidth - 5, 0, self.layout.sidebarWidth - 5, love.graphics.getHeight())

    -- Draw the main content panel
    self:drawMainPanel()
    
    -- Draw current event at the bottom of the screen
    self:drawEventDisplay()
    
    -- Draw notification panel on top of everything
    self.notificationPanel:draw()
end

function SOCView:drawMainPanel()
    local panelKey = self.panels[self.selectedPanel].key
    
    local panelDrawers = {
        threats = function() self:drawThreatsPanel() end,
        incidents = function() self:drawIncidentsPanel() end,
        resources = function() self:drawResourcesPanel() end,
        upgrades = function() self:drawUpgradesPanel() end,
        contracts = function() self:drawContractsPanel() end,
        specialists = function() self:drawSpecialistsPanel() end,
        skills = function() self:drawSkillsPanel() end
    }

    if panelDrawers[panelKey] then
        panelDrawers[panelKey]()
    else
        love.graphics.print("Panel not implemented: " .. panelKey, self.layout.sidebarWidth + 10, 50)
    end
end

function SOCView:drawThreatsPanel()
    love.graphics.print("Threat Monitor Panel", self.layout.sidebarWidth + 10, 50)
    -- Placeholder
end

function SOCView:drawIncidentsPanel()
    love.graphics.print("Incident Response Panel", self.layout.sidebarWidth + 10, 50)
    -- Placeholder
end

function SOCView:drawResourcesPanel()
    love.graphics.print("Resource Status Panel", self.layout.sidebarWidth + 10, 50)
    -- Placeholder
end

function SOCView:drawUpgradesPanel()
    love.graphics.print("Upgrades Panel", self.layout.sidebarWidth + 10, 50)
    local y = 80
    if self.systems.upgradeSystem then
        local availableUpgrades = self.systems.upgradeSystem:getAvailableUpgrades()
        if availableUpgrades and #availableUpgrades > 0 then
            for _, upgrade in ipairs(availableUpgrades) do
                local cost = upgrade.cost.money or "N/A"
                love.graphics.print(string.format("[%s] %s (Cost: %s)", upgrade.id, upgrade.name, cost), self.layout.sidebarWidth + 20, y)
                y = y + 15
            end
        else
            love.graphics.print("No new upgrades available.", self.layout.sidebarWidth + 20, y)
        end
    end
end

function SOCView:drawContractsPanel()
    love.graphics.print("Contracts Panel", self.layout.sidebarWidth + 10, 50)
    local y = 80
    if self.contracts and next(self.contracts) then
        for id, contract in pairs(self.contracts) do
            love.graphics.print(string.format("[%s] %s - Time Left: %d", id, contract.clientName, contract.remainingTime), self.layout.sidebarWidth + 20, y)
            y = y + 15
        end
    else
        love.graphics.print("No active contracts.", self.layout.sidebarWidth + 20, y)
    end
end

function SOCView:drawSpecialistsPanel()
    love.graphics.print("Specialists Panel", self.layout.sidebarWidth + 10, 50)
    local y = 80
    if self.specialists and next(self.specialists) then
        for id, specialist in pairs(self.specialists) do
            local level = specialist.level or 1
            local currentXp = specialist.xp or 0
            local nextLevelXp = "MAX"
            
            if self.systems.specialistSystem and self.systems.specialistSystem.getXpForNextLevel then
                local requiredXp = self.systems.specialistSystem:getXpForNextLevel(level)
                if requiredXp then
                    nextLevelXp = tostring(requiredXp)
                end
            end
            
            local xpDisplay = nextLevelXp == "MAX" and "[MAX LEVEL]" or "[" .. currentXp .. " / " .. nextLevelXp .. " XP]"
            love.graphics.print(string.format("[%s] %s (Lvl %d) %s", id, specialist.name, level, xpDisplay), self.layout.sidebarWidth + 20, y)
            y = y + 15
        end
    else
        love.graphics.print("No specialists hired.", self.layout.sidebarWidth + 20, y)
    end
end

function SOCView:drawEventDisplay()
    -- Placeholder for drawing dynamic events
    if self.currentEvent then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 50, love.graphics.getHeight() - 150, love.graphics.getWidth() - 100, 100)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.currentEvent.description, 60, love.graphics.getHeight() - 140, love.graphics.getWidth() - 120, "left")
    end
end

function SOCView:drawSkillsPanel()
    love.graphics.print("Skills Panel", self.layout.sidebarWidth + 10, 50)
    
    local y = 80
    if self.specialists and next(self.specialists) then
        for _, specialist in pairs(self.specialists) do
            love.graphics.print(specialist.name, self.layout.sidebarWidth + 20, y)
            y = y + 20
            if specialist.skills and next(specialist.skills) then
                for skillId, skillData in pairs(specialist.skills) do
                    local skillDef = self.systems.skillSystem:getSkillDefinition(skillId)
                    if skillDef then
                        local level = skillData.level or 1
                        local xp = skillData.xp or 0
                        local requiredXp = self.systems.skillSystem:getXpForNextLevel(level) or "MAX"
                        
                        -- Skill Name, Level, and XP
                        love.graphics.print(string.format("- %s (Lvl %d) [%d/%s XP]", skillDef.name, level, xp, tostring(requiredXp)), self.layout.sidebarWidth + 30, y)
                        y = y + 15
                        
                        -- Skill Description
                        love.graphics.setColor(0.8, 0.8, 0.8)
                        love.graphics.printf(skillDef.description, self.layout.sidebarWidth + 40, y, love.graphics.getWidth() - self.layout.sidebarWidth - 50, "left")
                        y = y + 30 -- Add some space after description
                        
                        -- Skill Effects
                        if skillDef.effects then
                            love.graphics.setColor(0.7, 0.9, 1) -- Light blue for effects
                            for _, effect in ipairs(skillDef.effects) do
                                local effectValue = self.systems.skillSystem:getEffectValueForLevel(skillId, effect.type, level)
                                love.graphics.print(string.format("  - %s: +%.2f%s", effect.description, effectValue, effect.isPercentage and "%" or ""), self.layout.sidebarWidth + 40, y)
                                y = y + 15
                            end
                        end
                        love.graphics.setColor(1, 1, 1)
                        y = y + 10 -- Space between skills
                    end
                end
            else
                love.graphics.print("  No skills.", self.layout.sidebarWidth + 30, y)
                y = y + 15
            end
            y = y + 20 -- Space between specialists
        end
    else
        love.graphics.print("No specialists hired.", self.layout.sidebarWidth + 20, y)
    end
end

function SOCView:keypressed(key)
    if self.showingChoiceEvent and self.currentEvent and self.currentEvent.choices then
        local choiceIndex = tonumber(key)
        if choiceIndex and choiceIndex > 0 and choiceIndex <= #self.currentEvent.choices then
            self:handleEventChoice(choiceIndex)
            return
        end
    end

    -- Panel navigation
    if key == "left" then
        self.selectedPanel = self.selectedPanel - 1
        if self.selectedPanel < 1 then self.selectedPanel = #self.panels end
    elseif key == "right" then
        self.selectedPanel = self.selectedPanel + 1
        if self.selectedPanel > #self.panels then self.selectedPanel = 1 end
    elseif key == "escape" then
        -- Could add a pause menu here later
    end
end

return SOCView
