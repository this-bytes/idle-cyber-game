-- SOC View Scene - Main Operational Interface
-- Central command view for SOC operations: threat detection, incident response, and resource management
-- Uses SmartUIManager for modern component-based UI

local SOCView = {}
SOCView.__index = SOCView

local SmartUIManager = require("src.ui.smart_ui_manager")
local NotificationPanel = require("src.ui.notification_panel")

-- Create new SOC view scene
function SOCView.new(eventBus)
    local self = setmetatable({}, SOCView)

    -- Dependencies
    self.systems = {} -- Injected by SceneManager on enter
    self.eventBus = eventBus

    -- UI Manager
    self.uiManager = nil

    -- Internal State
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    self.upgrades = {}

    -- UI Components
    self.notificationPanel = NotificationPanel.new(eventBus)

    -- Panel navigation
    self.selectedPanel = "threats" -- Default to threats panel
    self.panels = {
        threats = {name = "Threat Monitor", icon = "🛡️"},
        incidents = {name = "Incident Response", icon = "🚨"},
        resources = {name = "Resource Status", icon = "📊"},
        upgrades = {name = "Upgrades", icon = "⬆️"},
        contracts = {name = "Contracts", icon = "📋"},
        specialists = {name = "Specialists", icon = "👥"},
        skills = {name = "Skills", icon = "🎯"}
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
    self.eventDisplayDuration = 5.0
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

        -- Offline earnings notification
        self.eventBus:subscribe("offline_earnings_calculated", function(data)
            self:showOfflineEarnings(data)
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

        -- Achievement events
        self.eventBus:subscribe("achievement_unlocked", function(data)
            self:showAchievementNotification(data.achievement)
        end)
    end

    return self
end

-- Enter SOC view scene
function SOCView:enter(data)
    print("🛡️ SOCView: SOC operations center activated")

    -- Initialize Smart UI Manager
    self.uiManager = SmartUIManager.new(self.eventBus, self.systems.resourceManager)
    self.uiManager:initialize()

    -- Refresh data every time the scene is entered
    self:updateData()
    self:updateSOCCapabilities()

    -- Build the SOC UI
    self:buildSOCUI()

    -- Register focusable elements for keyboard navigation
    self:registerFocusableElements()
end

-- Build the SOC UI using SmartUIManager components
function SOCView:buildSOCUI()
    if not self.uiManager then return end

    -- Set current state to game
    self.uiManager.currentState = "game"

    -- Build the main UI structure
    self.uiManager:buildUI()

    -- Customize for SOC view
    self:customizeSOCUI()
end

-- Customize the UI for SOC-specific functionality
function SOCView:customizeSOCUI()
    if not self.uiManager or not self.uiManager.gameUI then return end

    local container = self.uiManager.gameUI

    -- Update header with SOC status
    local header = container.children[1] -- Header is first child
    if header then
        header.title = "🛡️ SOC Command Center - Alert: " .. self.socStatus.alertLevel
    end

    -- Update center panel with SOC panels
    local mainContent = container.children[2] -- Main content is second child
    if mainContent and mainContent.children[2] then -- Center panel
        local centerPanel = mainContent.children[2]
        self:buildSOCCenterPanel(centerPanel)
    end
end

-- Build the center panel with SOC-specific content
function SOCView:buildSOCCenterPanel(centerPanel)
    -- Clear existing content
    centerPanel:clearChildren()

    -- Add panel navigation tabs
    local tabBar = self:createPanelTabs()
    centerPanel:addChild(tabBar)

    -- Add main content area
    local contentArea = self:createPanelContent()
    centerPanel:addChild(contentArea)
end

-- Create navigation tabs for different panels
function SOCView:createPanelTabs()
    local tabBar = require("src.ui.components.box").new({
        direction = "horizontal",
        gap = 5,
        padding = {10, 10, 10, 10},
        flex = 0
    })

    for key, panel in pairs(self.panels) do
        local tab = require("src.ui.components.button").new({
            text = panel.icon .. " " .. panel.name,
            onClick = function()
                self.selectedPanel = key
                self:customizeSOCUI() -- Rebuild UI with new panel
            end,
            variant = (key == self.selectedPanel) and "primary" or "secondary"
        })
        tabBar:addChild(tab)
    end

    return tabBar
end

-- Create content for the selected panel
function SOCView:createPanelContent()
    local scrollContainer = require("src.ui.components.scroll_container").new({
        flex = 1,
        padding = {10, 10, 10, 10}
    })

    -- Add content based on selected panel
    if self.selectedPanel == "threats" then
        self:addThreatsContent(scrollContainer)
    elseif self.selectedPanel == "incidents" then
        self:addIncidentsContent(scrollContainer)
    elseif self.selectedPanel == "resources" then
        self:addResourcesContent(scrollContainer)
    elseif self.selectedPanel == "upgrades" then
        self:addUpgradesContent(scrollContainer)
    elseif self.selectedPanel == "contracts" then
        self:addContractsContent(scrollContainer)
    elseif self.selectedPanel == "specialists" then
        self:addSpecialistsContent(scrollContainer)
    elseif self.selectedPanel == "skills" then
        self:addSkillsContent(scrollContainer)
    end

    return scrollContainer
end

-- Add threats panel content
function SOCView:addThreatsContent(container)
    local title = require("src.ui.components.text").new({
        text = "🛡️ Threat Monitor",
        size = "large",
        color = {1, 0.5, 0}
    })
    container:addChild(title)

    -- Active threats
    if self.systems.threatSystem then
        local threats = self.systems.threatSystem:getActiveThreats() or {}
        if #threats > 0 then
            for _, threat in ipairs(threats) do
                local threatPanel = require("src.ui.components.panel").new({
                    title = threat.name or "Unknown Threat",
                    cornerStyle = "round"
                })

                local threatText = require("src.ui.components.text").new({
                    text = string.format("Severity: %s\nProgress: %.1f%%\nDescription: %s",
                        threat.severity or "Unknown",
                        (threat.progress or 0) * 100,
                        threat.description or "No description available")
                })
                threatPanel:addChild(threatText)
                container:addChild(threatPanel)
            end
        else
            local noThreats = require("src.ui.components.text").new({
                text = "✅ No active threats detected",
                color = {0, 1, 0}
            })
            container:addChild(noThreats)
        end
    end
end

-- Add incidents panel content
function SOCView:addIncidentsContent(container)
    local title = require("src.ui.components.text").new({
        text = "🚨 Incident Response",
        size = "large",
        color = {1, 0, 0}
    })
    container:addChild(title)

    -- Active incidents would go here
    local status = require("src.ui.components.text").new({
        text = "Active incidents: " .. #self.socStatus.activeIncidents,
        color = #self.socStatus.activeIncidents > 0 and {1, 0, 0} or {0, 1, 0}
    })
    container:addChild(status)
end

-- Add resources panel content
function SOCView:addResourcesContent(container)
    local title = require("src.ui.components.text").new({
        text = "📊 Resource Status",
        size = "large",
        color = {0, 1, 1}
    })
    container:addChild(title)

    -- Resource display
    if self.resources then
        local grid = require("src.ui.components.grid").new({
            columns = 2,
            gap = 10
        })

        for resourceName, amount in pairs(self.resources) do
            if type(amount) == "number" then
                local resourcePanel = require("src.ui.components.panel").new({
                    title = resourceName:gsub("^%l", string.upper),
                    cornerStyle = "cut"
                })

                local amountText = require("src.ui.components.text").new({
                    text = string.format("%.0f", amount),
                    size = "large",
                    color = {1, 1, 0}
                })
                resourcePanel:addChild(amountText)
                grid:addChild(resourcePanel)
            end
        end

        container:addChild(grid)
    end
end

-- Add upgrades panel content
function SOCView:addUpgradesContent(container)
    local title = require("src.ui.components.text").new({
        text = "⬆️ Upgrades",
        size = "large",
        color = {1, 0.5, 0}
    })
    container:addChild(title)

    -- Available upgrades would go here
    local upgradeCount = self.upgrades and #self.upgrades or 0
    local countText = require("src.ui.components.text").new({
        text = "Purchased upgrades: " .. upgradeCount
    })
    container:addChild(countText)
end

-- Add contracts panel content
function SOCView:addContractsContent(container)
    local title = require("src.ui.components.text").new({
        text = "📋 Contracts",
        size = "large",
        color = {0, 1, 0.5}
    })
    container:addChild(title)

    -- Active contracts
    if self.contracts then
        for _, contract in ipairs(self.contracts) do
            local contractPanel = require("src.ui.components.panel").new({
                title = contract.name or "Unknown Contract",
                cornerStyle = "round"
            })

            local contractText = require("src.ui.components.text").new({
                text = string.format("Revenue: $%d/sec\nDuration: %s\nStatus: %s",
                    contract.revenue or 0,
                    contract.duration or "Unknown",
                    contract.status or "Active")
            })
            contractPanel:addChild(contractText)
            container:addChild(contractPanel)
        end
    end
end

-- Add specialists panel content
function SOCView:addSpecialistsContent(container)
    local title = require("src.ui.components.text").new({
        text = "👥 Specialists",
        size = "large",
        color = {1, 0, 1}
    })
    container:addChild(title)

    -- Specialists would go here
    local specialistCount = self.specialists and #self.specialists or 0
    local countText = require("src.ui.components.text").new({
        text = "Active specialists: " .. specialistCount
    })
    container:addChild(countText)
end

-- Add skills panel content
function SOCView:addSkillsContent(container)
    local title = require("src.ui.components.text").new({
        text = "🎯 Skills",
        size = "large",
        color = {0.5, 1, 0}
    })
    container:addChild(title)

    -- Skills would go here
    local skillsText = require("src.ui.components.text").new({
        text = "Skill progression system"
    })
    container:addChild(skillsText)
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

    -- Number keys for panel selection (1-7) - map to panel keys
    local panelKeys = {"threats", "incidents", "resources", "upgrades", "contracts", "specialists", "skills"}
    local panelNumber = tonumber(key)
    if panelNumber and panelNumber >= 1 and panelNumber <= #panelKeys then
        self.selectedPanel = panelKeys[panelNumber]
        self:customizeSOCUI() -- Rebuild UI with new panel
        return
    end

    -- TAB for focus navigation
    if key == "tab" then
        self:navigateFocus(love.keyboard.isDown("lshift") and "prev" or "next")
        return
    end

    -- Arrow keys for panel navigation
    if key == "up" or key == "left" then
        local currentIndex = 1
        for i, panelKey in ipairs(panelKeys) do
            if panelKey == self.selectedPanel then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #panelKeys end
        self.selectedPanel = panelKeys[currentIndex]
        self:customizeSOCUI()
    elseif key == "down" or key == "right" then
        local currentIndex = 1
        for i, panelKey in ipairs(panelKeys) do
            if panelKey == self.selectedPanel then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex + 1
        if currentIndex > #panelKeys then currentIndex = 1 end
        self.selectedPanel = panelKeys[currentIndex]
        self:customizeSOCUI()
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

-- Handle threat detection event
function SOCView:handleThreatDetected(threat)
    if not threat then return end
    
    -- Create incident from threat
    local incident = {
        id = threat.id or (#self.socStatus.activeIncidents + 1),
        name = threat.name or "Unknown Threat",
        description = threat.description or "Security incident detected",
        severity = threat.severity or "MEDIUM",
        timeRemaining = threat.duration or 30,
        threat = threat
    }
    
    table.insert(self.socStatus.activeIncidents, incident)
    
    -- Add notification
    if self.notificationPanel then
        self.notificationPanel:addNotification(
            "Threat Detected: " .. incident.name,
            incident.severity
        )
    end
    
    print("🚨 SOCView: Threat detected - " .. incident.name)
end

-- Handle incident resolution
function SOCView:handleIncidentResolved(data)
    if not data or not data.incident then return end
    
    -- Remove incident from active list
    for i = #self.socStatus.activeIncidents, 1, -1 do
        local incident = self.socStatus.activeIncidents[i]
        if incident.id == data.incident.id then
            table.remove(self.socStatus.activeIncidents, i)
            break
        end
    end
    
    -- Add notification
    if self.notificationPanel then
        self.notificationPanel:addNotification(
            "Incident Resolved: " .. (data.incident.name or "Unknown"),
            "SUCCESS"
        )
    end
    
    print("✅ SOCView: Incident resolved - " .. (data.incident.name or "Unknown"))
end

-- Show offline earnings notification
function SOCView:showOfflineEarnings(data)
    if not data or not self.notificationPanel then return end
    
    local message = string.format(
        "Welcome back! Away for %s\\nEarned: $%d | Damage: $%d | Net: $%d",
        data.timeAway or "unknown",
        data.earnings or 0,
        data.damage or 0,
        data.netGain or 0
    )
    
    self.notificationPanel:addNotification(message, "INFO")
    print("💰 SOCView: Displayed offline earnings notification")
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
    -- Use SmartUIManager for modern component-based rendering
    if self.uiManager then
        -- Update UI data before drawing
        self:updateUIData()

        -- Draw the UI
        self.uiManager:draw()

        -- Draw toast notifications
        self.uiManager.toastManager:draw()

        -- Draw notification panel on top
        self.notificationPanel:draw()

        -- Draw current event display
        self:drawEventDisplay()

        -- Draw ripple effects on top of everything
        if self.systems.clickRewardSystem and self.systems.clickRewardSystem.drawRipples then
            self.systems.clickRewardSystem:drawRipples()
        end
    else
        -- Fallback to basic rendering if UI manager not available
        love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SOC Command Center - Loading UI...", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
    end
end

-- Update UI data before drawing
function SOCView:updateUIData()
    if not self.uiManager then return end

    -- Update resource displays
    self:updateData()

    -- Update SOC status
    self:updateSOCCapabilities()

    -- Refresh UI if data changed
    if self.uiManager.needsRebuild then
        self:customizeSOCUI()
        self.uiManager.needsRebuild = false
    end
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
    
    local y = 80
    if self.systems.resourceManager then
        local resources = self.systems.resourceManager:getState()
        
        -- Money with income rate
        local money = resources.money or 0
        local incomeRate = resources.moneyPerSecond or 0
        love.graphics.setColor(0, 1, 0) -- Green for money
        love.graphics.print(string.format("💰 Money: $%s", self:formatNumber(money)), self.layout.sidebarWidth + 20, y)
        love.graphics.setColor(0.7, 0.7, 0.7) -- Gray for rate
        love.graphics.print(string.format("Income: +$%s/sec", self:formatNumber(incomeRate)), self.layout.sidebarWidth + 30, y + 15)
        love.graphics.setColor(1, 1, 1) -- Reset color
        
        y = y + 40
        
        -- Reputation
        local reputation = resources.reputation or 0
        local repRate = resources.reputationPerSecond or 0
        love.graphics.setColor(0, 0.8, 1) -- Blue for reputation
        love.graphics.print(string.format("🏆 Reputation: %s", self:formatNumber(reputation)), self.layout.sidebarWidth + 20, y)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("Growth: +%s/sec", self:formatNumber(repRate)), self.layout.sidebarWidth + 30, y + 15)
        love.graphics.setColor(1, 1, 1)
        
        y = y + 40
        
        -- XP
        local xp = resources.xp or 0
        local xpRate = resources.xpPerSecond or 0
        love.graphics.setColor(1, 0.8, 0) -- Gold for XP
        love.graphics.print(string.format("⭐ XP: %s", self:formatNumber(xp)), self.layout.sidebarWidth + 20, y)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("Gain: +%s/sec", self:formatNumber(xpRate)), self.layout.sidebarWidth + 30, y + 15)
        love.graphics.setColor(1, 1, 1)
        
        y = y + 40
        
        -- Mission Tokens (rare currency)
        local tokens = resources.missionTokens or 0
        love.graphics.setColor(1, 0, 0) -- Red for rare tokens
        love.graphics.print(string.format("🎯 Mission Tokens: %d", tokens), self.layout.sidebarWidth + 20, y)
        love.graphics.setColor(1, 1, 1)
        
        y = y + 30
        
        -- Idle progress summary
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("=== Idle Progress ===", self.layout.sidebarWidth + 20, y)
        y = y + 20
        
        local totalEarned = resources.totalMoneyEarned or 0
        local totalSpent = resources.totalMoneySpent or 0
        love.graphics.print(string.format("Total Earned: $%s", self:formatNumber(totalEarned)), self.layout.sidebarWidth + 30, y)
        y = y + 15
        love.graphics.print(string.format("Total Spent: $%s", self:formatNumber(totalSpent)), self.layout.sidebarWidth + 30, y)
        y = y + 15
        love.graphics.print(string.format("Net Worth: $%s", self:formatNumber(totalEarned - totalSpent)), self.layout.sidebarWidth + 30, y)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.print("Resource system not available.", self.layout.sidebarWidth + 20, y)
    end
end

-- Helper function to format large numbers
function SOCView:formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return string.format("%.0f", num)
    end
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
