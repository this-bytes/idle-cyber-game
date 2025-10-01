-- SOC View Scene - Main Operational Interface
-- Central command view for SOC operations: threat detection, incident response, and resource management
-- Emulates real-life SOC workflow with continuous monitoring and response capabilities

local SOCView = {}
SOCView.__index = SOCView

local NotificationPanel = require("src.ui.notification_panel")

-- Create new SOC view scene
function SOCView.new(eventBus)
    -- Ensure updateSOCCapabilities is always defined (no-op fallback for tests)
    if not self.updateSOCCapabilities then
        self.updateSOCCapabilities = function() end
    end

    local self = setmetatable({}, SOCView)
    -- Ensure updateSOCCapabilities is always defined (no-op fallback for tests)
    if not self.updateSOCCapabilities then
        self.updateSOCCapabilities = function() end
    end

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
        -- Feedback/Juice state
        self.feedbackPopups = {} -- {text, x, y, color, dy, alpha, timer, duration}
        self.overlayText = nil
        self.overlayColor = {1,1,1}
        self.overlayTimer = 0
        self.overlayDuration = 1.2

    -- Event System State
    self.currentEvent = nil
    self.eventDisplayTime = 0
    self.eventDisplayDuration = 5.0 -- How long to show simple events
    self.showingChoiceEvent = false

    -- Subscribe to long-lived events
    if self.eventBus then
        -- Use a helper to bind all event subscriptions so initialize() can reuse it
        local function bind()
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

                self.eventBus:subscribe("threat_detected", function(event)
                    local threatObj = event and event.threat
                    if not threatObj then return end
                    if not threatObj.name and threatObj.id then threatObj.name = tostring(threatObj.id) end
                    self:handleThreatDetected(threatObj)
                    self:showOverlay("Threat Detected! ⚠️", {1,0.4,0.2})
                end)

                self.eventBus:subscribe("incident_resolved", function(data)
                    self:handleIncidentResolved(data)
                    self:showOverlay("Incident Resolved! 🛡️", {0.2,1,0.6})
                end)
                self.eventBus:subscribe("security_upgrade_purchased", function(data)
                    self:updateSOCCapabilities()
                    self:showOverlay("Upgrade Installed! ⚡", {0.7,0.9,1})
                end)
                -- Dynamic Event System integration
                self.eventBus:subscribe("dynamic_event_triggered", function(data)
                    self:handleDynamicEvent(data.event)
                    self:showOverlay("Event Triggered! ✨", {1,1,0.2})
                end)
                -- Specialist progression events
                self.eventBus:subscribe("specialist_leveled_up", function(data)
                    self:handleSpecialistLevelUp(data)
                    self:showOverlay("Specialist Leveled Up! 🚀", {0.5,0.9,1})
                end)
                -- UI update events
                self.eventBus:subscribe("resource_changed", function(ev)
                    self:updateData()
                    if ev and ev.resource and ev.delta and ev.delta > 0 then
                        self:addFeedbackPopup("+"..tostring(ev.delta), ev.resource)
                    end
                end)
                self.eventBus:subscribe("contract_completed", function(ev)
                    self:updateData()
                    self:showOverlay("Contract Secured! 💰", {1,1,0.2})
                end)
                self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
                self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
                self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    -- Attach eventBus if provided
    if eventBus then
        self.eventBus = eventBus
    end
    -- Ensure systems table exists for test wiring
    if not self.systems then self.systems = {} end
    -- Recalculate capabilities
    self:updateSOCCapabilities()
    -- Feedback/Juice: Animated number popups
    -- If initialization provided the event bus, ensure subscriptions are bound
    if self.eventBus then
        -- Rebind event subscriptions (safe to call multiple times)
        -- Mirror the subscription behavior from constructor
        self.eventBus:subscribe("threat_detected", function(event)
            local threatObj = event and event.threat
            if not threatObj then return end
            if not threatObj.name and threatObj.id then threatObj.name = tostring(threatObj.id) end
            self:handleThreatDetected(threatObj)
        end)

        self.eventBus:subscribe("incident_resolved", function(data) self:handleIncidentResolved(data) end)
        self.eventBus:subscribe("security_upgrade_purchased", function(data) self:updateSOCCapabilities() end)
        self.eventBus:subscribe("dynamic_event_triggered", function(data) self:handleDynamicEvent(data.event) end)
        self.eventBus:subscribe("specialist_leveled_up", function(data) self:handleSpecialistLevelUp(data) end)
        self.eventBus:subscribe("resource_changed", function() self:updateData() end)
        self.eventBus:subscribe("contract_accepted", function() self:updateData() end)
        self.eventBus:subscribe("contract_completed", function() self:updateData() end)

        self.eventBus:subscribe("specialist_hired", function() self:updateData() end)
        self.eventBus:subscribe("upgrade_purchased", function() self:updateData() end)
    end
    return true
end

-- Minimal threat scan simulation for tests
function SOCView:performThreatScan()
    -- Simple deterministic scan that emits a threat_detected event
    local threat = {
        id = "scan-" .. tostring(os.time()),
        name = "Simulated Threat",
        type = "simulated",
        severity = "LOW"
    }

    if self.eventBus then
        self.eventBus:publish("threat_detected", { threat = threat, source = "soc_view" })
    end
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

-- Handle a detected threat event: add to active incidents
function SOCView:handleThreatDetected(threat)
    if not threat then return end
    -- Ensure minimal fields
    local incident = {
        id = threat.id or tostring(os.time()),
        name = threat.name or "Unknown Threat",
        type = threat.type or "unknown",
        severity = threat.severity or "LOW",
        timeRemaining = 30.0 -- default incident duration in seconds for tests
    }

    if not self.socStatus then self.socStatus = { activeIncidents = {} } end
    table.insert(self.socStatus.activeIncidents, incident)
    -- Update alert level after adding
    self:updateAlertLevel()
end

-- Handle incident resolved events (remove by id)
function SOCView:handleIncidentResolved(data)
    if not data or not data.id then return end
    if not self.socStatus or not self.socStatus.activeIncidents then return end
    for i = #self.socStatus.activeIncidents, 1, -1 do
        if self.socStatus.activeIncidents[i].id == data.id then
            table.remove(self.socStatus.activeIncidents, i)
        end
    end
    self:updateAlertLevel()
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

    -- Animate feedback popups
    for i=#self.feedbackPopups,1,-1 do
        local p = self.feedbackPopups[i]
        p.timer = p.timer + dt
        p.y = p.y + p.dy * dt
        p.alpha = 1 - (p.timer/p.duration)
        if p.timer >= p.duration then table.remove(self.feedbackPopups, i) end
    end
    -- Animate overlay
    if self.overlayText then
        self.overlayTimer = self.overlayTimer - dt
        if self.overlayTimer <= 0 then self.overlayText = nil end
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
    if love and love.graphics then
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
end
    if love and love.graphics then
        -- Draw feedback popups
        for _,p in ipairs(self.feedbackPopups) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
            love.graphics.setFont(love.graphics.newFont(18))
            love.graphics.print(p.text, p.x, p.y)
        end
        love.graphics.setColor(1,1,1,1)
        -- Draw overlay text
        if self.overlayText then
            love.graphics.setColor(self.overlayColor[1], self.overlayColor[2], self.overlayColor[3], 0.92)
            love.graphics.setFont(love.graphics.newFont(28))
            local w = love.graphics.getWidth()
            love.graphics.printf(self.overlayText, 0, 60, w, "center")
            love.graphics.setColor(1,1,1,1)
        end
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


-- Feedback/Juice: Animated number popups
function SOCView:addFeedbackPopup(text, resource)
    local color = {1,1,1}
    if resource == "money" then color = {0.7,1,0.2}
    elseif resource == "xp" then color = {0.5,0.8,1}
    elseif resource == "reputation" then color = {1,0.7,0.2}
    end
    local x = 160; local y = 32 -- HUD position (tweak as needed)
    table.insert(self.feedbackPopups, {
        text = text,
        x = x,
        y = y,
        color = color,
        dy = -18,
        alpha = 1,
        timer = 0,
        duration = 1.0
    })
end

function SOCView:showOverlay(text, color)
    self.overlayText = text
    self.overlayColor = color or {1,1,1}
    self.overlayTimer = self.overlayDuration
end


end

-- Feedback/Juice: Animated number popups
function SOCView:addFeedbackPopup(text, resource)
    local color = {1,1,1}
    if resource == "money" then color = {0.7,1,0.2}
    elseif resource == "xp" then color = {0.5,0.8,1}
    elseif resource == "reputation" then color = {1,0.7,0.2}
    end
    local x = 160; local y = 32 -- HUD position (tweak as needed)
    table.insert(self.feedbackPopups, {
        text = text,
        x = x,
        y = y,
        color = color,
        dy = -18,
        alpha = 1,
        timer = 0,
        duration = 1.0
    })
end

function SOCView:showOverlay(text, color)
    self.overlayText = text
    self.overlayColor = color or {1,1,1}
    self.overlayTimer = self.overlayDuration
end

return SOCView
