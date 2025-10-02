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

    -- Keyboard Navigation State (Phase 2)
    self.focusedElement = nil
    self.focusableElements = {}
    self.focusIndex = 1

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

        -- Phase 2: Manual income events
        self.eventBus:subscribe("input_action_manual_income", function(event)
            -- The ClickRewardSystem handles the actual reward processing
            -- We just need to provide visual feedback here if needed
            print("🎮 SOCView: Manual income action triggered from " .. (event.source or "unknown"))
        end)
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

    -- Register focusable elements for keyboard navigation (Phase 2)
    self:registerFocusableElements()
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

-- Register focusable elements for keyboard navigation (Phase 2)
function SOCView:registerFocusableElements()
    self.focusableElements = {
        {
            id = "money_counter",
            bounds = {x = 20, y = 80, width = 280, height = 40},
            action = "manual_income"
        },
        {
            id = "manual_income_button",
            bounds = {x = 320, y = 80, width = 120, height = 40},
            action = "manual_income"
        }
    }

    -- Set initial focus
    self.focusedElement = self.focusableElements[1]
end

-- Handle keyboard input for navigation (Phase 2)
function SOCView:keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    -- Number keys for panel selection (1-7)
    local panelNumber = tonumber(key)
    if panelNumber and panelNumber >= 1 and panelNumber <= #self.panels then
        self.selectedPanel = panelNumber
        return
    end

    -- TAB for focus navigation
    if key == "tab" then
        self:navigateFocus(love.keyboard.isDown("lshift") and "prev" or "next")
        return
    end

    -- Arrow keys for panel navigation
    if key == "up" then
        self.selectedPanel = self.selectedPanel - 1
        if self.selectedPanel < 1 then self.selectedPanel = #self.panels end
    elseif key == "down" then
        self.selectedPanel = self.selectedPanel + 1
        if self.selectedPanel > #self.panels then self.selectedPanel = 1 end
    elseif key == "return" or key == "kpenter" then
        -- Activate focused element
        if self.focusedElement then
            self:activateFocusedElement()
        end
    end
end

-- Navigate focus between elements
function SOCView:navigateFocus(direction)
    if #self.focusableElements == 0 then return end

    local currentIndex = 1
    for i, element in ipairs(self.focusableElements) do
        if element == self.focusedElement then
            currentIndex = i
            break
        end
    end

    if direction == "next" then
        currentIndex = currentIndex % #self.focusableElements + 1
    elseif direction == "prev" then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #self.focusableElements end
    end

    self.focusedElement = self.focusableElements[currentIndex]
end

-- Activate the currently focused element
function SOCView:activateFocusedElement()
    if not self.focusedElement then return end

    if self.focusedElement.action == "manual_income" then
        -- Trigger manual income through event bus
        if self.eventBus then
            self.eventBus:publish("input_action_manual_income", {
                source = "keyboard_activation",
                data = {}
            })
        end
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
    -- Apply screen shake effect (Phase 2)
    local shakeX, shakeY = 0, 0
    if self.systems.clickRewardSystem and self.systems.clickRewardSystem.getScreenShakeOffset then
        shakeX, shakeY = self.systems.clickRewardSystem:getScreenShakeOffset()
    end
    
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)

    -- Draw Header with Money Counter (CLICKABLE!)
    love.graphics.printf("SOC Command Center - Alert Level: " .. self.socStatus.alertLevel, 0, 10, love.graphics.getWidth(), "center")

    -- Draw Money Counter (Phase 2 - Clickable!)
    self:drawMoneyCounter()

    -- Draw Manual Income Button (Phase 2)
    self:drawManualIncomeButton()

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

    -- Draw keyboard navigation hints (Phase 2)
    self:drawKeyboardHints()
    
    -- Draw notification panel on top of everything
    self.notificationPanel:draw()
    
    -- Draw ripple effects on top of everything (Phase 2)
    if self.systems.clickRewardSystem and self.systems.clickRewardSystem.drawRipples then
        self.systems.clickRewardSystem:drawRipples()
    end
    
    love.graphics.pop() -- End screen shake transform
end

-- Draw clickable money counter (Phase 2)
function SOCView:drawMoneyCounter()
    local moneyX, moneyY = 20, 80
    local moneyWidth, moneyHeight = 280, 40

    -- Check if this element is focused
    local isFocused = self.focusedElement and self.focusedElement.id == "money_counter"

    -- Draw focus indicator if focused
    if isFocused then
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow focus ring
        love.graphics.rectangle("line", moneyX - 3, moneyY - 3, moneyWidth + 6, moneyHeight + 6)
        love.graphics.setColor(1, 1, 0, 0.2) -- Yellow background tint
        love.graphics.rectangle("fill", moneyX, moneyY, moneyWidth, moneyHeight)
    end

    -- Draw background rectangle (clickable area)
    love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
    love.graphics.rectangle("fill", moneyX, moneyY, moneyWidth, moneyHeight)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", moneyX, moneyY, moneyWidth, moneyHeight)

    -- Draw money text
    local money = self.resources.money or 0
    local income = self.resources.income or 0
    local moneyText = string.format("$%s (+$%s/sec)", self:formatNumber(money), self:formatNumber(income))

    love.graphics.setColor(1, 1, 0) -- Gold color for money
    love.graphics.printf(moneyText, moneyX, moneyY + 10, moneyWidth, "center")
    love.graphics.setColor(1, 1, 1)

    -- Draw click hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(12))
    local hintText = "Click or press SPACE/M"
    if isFocused and self.systems.clickRewardSystem and self.systems.clickRewardSystem.getCurrentClickValue then
        local clickValue = self.systems.clickRewardSystem:getCurrentClickValue()
        hintText = string.format("Click: +$%s | SPACE/M", self:formatNumber(clickValue))
    end
    love.graphics.printf(hintText, moneyX, moneyY + 25, moneyWidth, "center")
    love.graphics.setFont(love.graphics.newFont()) -- Reset to default
    love.graphics.setColor(1, 1, 1)
end

-- Draw manual income button (Phase 2)
function SOCView:drawManualIncomeButton()
    local buttonX, buttonY = 320, 80
    local buttonWidth, buttonHeight = 120, 40

    -- Store button bounds for click detection
    self.manualIncomeButtonBounds = {
        x = buttonX,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight
    }

    -- Check if this element is focused
    local isFocused = self.focusedElement and self.focusedElement.id == "manual_income_button"

    -- Button colors based on state
    local isHovered = self:isMouseOverButton(buttonX, buttonY, buttonWidth, buttonHeight)
    local bgColor, textColor

    if isFocused then
        bgColor = {0.8, 0.8, 0.2, 0.9} -- Yellow focus
        textColor = {0, 0, 0}
    elseif isHovered then
        bgColor = {0.4, 0.6, 0.8, 0.9} -- Light blue hover
        textColor = {1, 1, 1}
    else
        bgColor = {0.3, 0.5, 0.7, 0.8} -- Blue normal
        textColor = {1, 1, 1}
    end

    -- Draw focus indicator if focused
    if isFocused then
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow focus ring
        love.graphics.rectangle("line", buttonX - 3, buttonY - 3, buttonWidth + 6, buttonHeight + 6)
    end

    -- Draw button background
    love.graphics.setColor(unpack(bgColor))
    love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)

    -- Draw button text
    love.graphics.setColor(unpack(textColor))
    local clickValue = "$1"
    if self.systems.clickRewardSystem and self.systems.clickRewardSystem.getCurrentClickValue then
        local value = self.systems.clickRewardSystem:getCurrentClickValue()
        clickValue = self:formatNumber(value)
    end
    love.graphics.printf("+" .. clickValue, buttonX, buttonY + 8, buttonWidth, "center")

    -- Draw keybind hint
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.printf("[SPACE]", buttonX, buttonY + 22, buttonWidth, "center")
    love.graphics.setFont(love.graphics.newFont()) -- Reset font
    love.graphics.setColor(1, 1, 1)
end

-- Check if mouse is over a button
function SOCView:isMouseOverButton(x, y, width, height)
    if not love.mouse then return false end
    local mouseX, mouseY = love.mouse.getPosition()
    return mouseX >= x and mouseX <= x + width and mouseY >= y and mouseY <= y + height
end

-- Format large numbers
function SOCView:formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
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

-- Draw keyboard navigation hints (Phase 2)
function SOCView:drawKeyboardHints()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local hintY = screenHeight - 30

    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, hintY, screenWidth, 30)
    love.graphics.setColor(1, 1, 1)

    -- Draw hints
    love.graphics.setFont(love.graphics.newFont(12))
    local hints = {
        "TAB: Navigate UI",
        "↑↓: Change Panel",
        "1-7: Select Panel",
        "ENTER: Activate",
        "SPACE/M: Manual Income"
    }

    local hintText = table.concat(hints, " | ")
    love.graphics.printf(hintText, 10, hintY + 8, screenWidth - 20, "left")

    love.graphics.setFont(love.graphics.newFont()) -- Reset font
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
