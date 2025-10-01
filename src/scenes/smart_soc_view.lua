-- Smart SOC View - Main game view using Smart UI Framework
-- Replaces manual drawing with component-based UI
-- Phase 5 integration: Main game interface with Smart UI

local ScrollContainer = require("src.ui.components.scroll_container")
local Box = require("src.ui.components.box")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")
local Grid = require("src.ui.components.grid")
local ToastManager = require("src.ui.toast_manager")

local SmartSOCView = {}
SmartSOCView.__index = SmartSOCView

function SmartSOCView.new(eventBus)
    local self = setmetatable({}, SmartSOCView)
    
    -- Dependencies
    self.eventBus = eventBus
    self.systems = {}
    
    -- Data
    self.resources = {}
    self.contracts = {}
    self.specialists = {}
    self.upgrades = {}
    
    -- UI State
    self.selectedPanel = "threats"
    self.root = nil
    self.needsRebuild = true
    
    -- Toast manager
    self.toastManager = ToastManager.new()
    
    -- SOC Status
    self.socStatus = {
        alertLevel = "GREEN",
        activeIncidents = {},
        detectionCapability = 0,
        responseCapability = 0,
        lastThreatScan = 0,
        scanInterval = 5.0
    }
    
    -- Subscribe to events
    if self.eventBus then
        self.eventBus:subscribe("threat_detected", function(event)
            local threatObj = event and event.threat
            if threatObj then
                self:handleThreatDetected(threatObj)
            end
        end)
        
        self.eventBus:subscribe("resource_changed", function()
            self:updateData()
            self.needsRebuild = true
        end)
        
        self.eventBus:subscribe("contract_accepted", function()
            self:updateData()
            self.needsRebuild = true
        end)
        
        self.eventBus:subscribe("specialist_hired", function(data)
            self:updateData()
            self.needsRebuild = true
            if data and data.specialist then
                self.toastManager:show("Hired: " .. data.specialist.name, {type = "success"})
            end
        end)
        
        self.eventBus:subscribe("upgrade_purchased", function(data)
            self:updateData()
            self.needsRebuild = true
            if data and data.upgrade then
                self.toastManager:show("Purchased: " .. data.upgrade.name, {type = "success"})
            end
        end)
    end
    
    print("🛡️ Smart SOCView initialized")
    return self
end

-- Scene lifecycle
function SmartSOCView:enter(data)
    print("🛡️ Smart SOCView: SOC operations center activated")
    self:updateData()
    self:updateSOCCapabilities()
    self.needsRebuild = true
end

function SmartSOCView:exit()
    print("🛡️ Smart SOCView: Exiting")
end

-- Update data from systems
function SmartSOCView:updateData()
    if self.systems.resourceManager then
        self.resources = self.systems.resourceManager:getState()
    end
    if self.systems.contractSystem then
        self.contracts = self.systems.contractSystem:getActiveContracts()
    end
    if self.systems.specialistSystem then
        self.specialists = self.systems.specialistSystem:getAllSpecialists()
    end
    if self.systems.upgradeSystem then
        self.upgrades = self.systems.upgradeSystem:getPurchasedUpgrades()
    end
end

function SmartSOCView:updateSOCCapabilities()
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

-- Handle threat detection
function SmartSOCView:handleThreatDetected(threat)
    local threatName = threat.name or "Unknown Threat"
    self.toastManager:show("🚨 Threat Detected: " .. threatName, {
        type = "error",
        duration = 5.0
    })
    
    table.insert(self.socStatus.activeIncidents, {
        threat = threat,
        timeRemaining = 30.0
    })
    
    self.needsRebuild = true
end

-- Build UI
function SmartSOCView:buildUI()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Root scroll container
    self.root = ScrollContainer.new({
        backgroundColor = {0.05, 0.05, 0.1, 1},
        showScrollbars = true,
        scrollSpeed = 30
    })
    
    -- Main content
    local content = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {10, 10, 10, 10}
    })
    self.root:addChild(content)
    
    -- Header
    content:addChild(self:createHeader())
    
    -- Main area
    local mainArea = Box.new({
        direction = "horizontal",
        gap = 10,
        flex = 1
    })
    
    -- Sidebar
    mainArea:addChild(self:createSidebar())
    
    -- Main panel
    mainArea:addChild(self:createMainPanel())
    
    content:addChild(mainArea)
    
    self.needsRebuild = false
end

-- Create header
function SmartSOCView:createHeader()
    local header = Panel.new({
        title = "🛡️ SOC Command Center - Alert: " .. self.socStatus.alertLevel,
        cornerStyle = "cut",
        glow = self.socStatus.alertLevel == "RED",
        minHeight = 80,
        flex = 0
    })
    
    -- Resource display
    local resourceBox = Box.new({
        direction = "horizontal",
        gap = 20,
        padding = {10, 10, 10, 10}
    })
    
    if self.resources and self.resources.resources then
        local money = self.resources.resources.money or 0
        local reputation = self.resources.resources.reputation or 0
        local xp = self.resources.resources.xp or 0
        
        resourceBox:addChild(Text.new({
            text = "💰 $" .. string.format("%.0f", money),
            color = {0.2, 0.8, 0.3, 1.0}
        }))
        
        resourceBox:addChild(Text.new({
            text = "⭐ " .. string.format("%.0f", reputation),
            color = {0.2, 0.8, 0.9, 1.0}
        }))
        
        resourceBox:addChild(Text.new({
            text = "📈 " .. string.format("%.0f", xp) .. " XP",
            color = {0.9, 0.7, 0.2, 1.0}
        }))
    end
    
    header:addChild(resourceBox)
    return header
end

-- Create sidebar
function SmartSOCView:createSidebar()
    local sidebar = Panel.new({
        title = "Panels",
        cornerStyle = "square",
        minWidth = 200,
        flex = 0
    })
    
    local buttonBox = Box.new({
        direction = "vertical",
        gap = 5,
        padding = {10, 10, 10, 10}
    })
    
    local panels = {
        {key = "threats", label = "Threat Monitor"},
        {key = "incidents", label = "Incidents"},
        {key = "resources", label = "Resources"},
        {key = "contracts", label = "Contracts"},
        {key = "specialists", label = "Specialists"},
        {key = "upgrades", label = "Upgrades"}
    }
    
    for _, panel in ipairs(panels) do
        local isSelected = (self.selectedPanel == panel.key)
        local btn = Button.new({
            label = panel.label,
            minWidth = 180,
            onClick = function()
                self.selectedPanel = panel.key
                self.needsRebuild = true
            end,
            -- Use different colors for selected button
            normalColor = isSelected and {0.3, 0.5, 0.8, 1} or {0.2, 0.2, 0.3, 1},
            normalBorderColor = isSelected and {0, 1, 1, 1} or {0.5, 0.5, 0.6, 1}
        })
        buttonBox:addChild(btn)
    end
    
    sidebar:addChild(buttonBox)
    return sidebar
end

-- Create main panel
function SmartSOCView:createMainPanel()
    local panel = Panel.new({
        title = self:getPanelTitle(),
        cornerStyle = "rounded",
        flex = 2
    })
    
    local content = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {15, 15, 15, 15}
    })
    
    -- Add panel-specific content
    if self.selectedPanel == "threats" then
        self:addThreatsContent(content)
    elseif self.selectedPanel == "incidents" then
        self:addIncidentsContent(content)
    elseif self.selectedPanel == "resources" then
        self:addResourcesContent(content)
    elseif self.selectedPanel == "contracts" then
        self:addContractsContent(content)
    elseif self.selectedPanel == "specialists" then
        self:addSpecialistsContent(content)
    elseif self.selectedPanel == "upgrades" then
        self:addUpgradesContent(content)
    end
    
    panel:addChild(content)
    return panel
end

-- Get panel title
function SmartSOCView:getPanelTitle()
    local titles = {
        threats = "🚨 Threat Monitor",
        incidents = "⚠️ Active Incidents",
        resources = "📊 Resource Status",
        contracts = "📄 Contracts",
        specialists = "👥 Specialists",
        upgrades = "🔧 Security Upgrades"
    }
    return titles[self.selectedPanel] or "Panel"
end

-- Add threats content
function SmartSOCView:addThreatsContent(container)
    container:addChild(Text.new({
        text = "Detection Capability: " .. self.socStatus.detectionCapability,
        color = {0.2, 0.8, 0.9, 1.0}
    }))
    
    container:addChild(Text.new({
        text = "Response Capability: " .. self.socStatus.responseCapability,
        color = {0.2, 0.8, 0.3, 1.0}
    }))
    
    if #self.socStatus.activeIncidents > 0 then
        for i, incident in ipairs(self.socStatus.activeIncidents) do
            local threatName = incident.threat and incident.threat.name or "Unknown"
            container:addChild(Text.new({
                text = string.format("⚠️ %s (%.1fs remaining)", threatName, incident.timeRemaining),
                color = {1.0, 0.4, 0.2, 1.0}
            }))
        end
    else
        container:addChild(Text.new({
            text = "✓ No active threats",
            color = {0.2, 0.8, 0.3, 1.0}
        }))
    end
end

-- Add incidents content
function SmartSOCView:addIncidentsContent(container)
    if #self.socStatus.activeIncidents == 0 then
        container:addChild(Text.new({
            text = "No active incidents",
            color = {0.6, 0.6, 0.6, 1.0}
        }))
    else
        for i, incident in ipairs(self.socStatus.activeIncidents) do
            local threatName = incident.threat and incident.threat.name or "Unknown Incident"
            container:addChild(Text.new({
                text = string.format("[%d] %s - %.1fs remaining", i, threatName, incident.timeRemaining),
                color = {1.0, 0.4, 0.2, 1.0}
            }))
        end
    end
end

-- Add resources content
function SmartSOCView:addResourcesContent(container)
    if self.resources and self.resources.resources then
        for resourceName, amount in pairs(self.resources.resources) do
            container:addChild(Text.new({
                text = resourceName .. ": " .. string.format("%.2f", amount),
                color = {0.9, 0.9, 0.9, 1.0}
            }))
        end
    else
        container:addChild(Text.new({
            text = "No resource data available",
            color = {0.6, 0.6, 0.6, 1.0}
        }))
    end
end

-- Add contracts content
function SmartSOCView:addContractsContent(container)
    if self.contracts and #self.contracts > 0 then
        for i, contract in ipairs(self.contracts) do
            local contractText = string.format("%s - $%.0f/mo", 
                contract.client or "Unknown Client",
                contract.revenue or 0)
            container:addChild(Text.new({
                text = contractText,
                color = {0.2, 0.8, 0.9, 1.0}
            }))
        end
    else
        container:addChild(Text.new({
            text = "No active contracts",
            color = {0.6, 0.6, 0.6, 1.0}
        }))
    end
end

-- Add specialists content
function SmartSOCView:addSpecialistsContent(container)
    if self.specialists then
        local count = 0
        for _ in pairs(self.specialists) do
            count = count + 1
        end
        
        if count > 0 then
            for id, specialist in pairs(self.specialists) do
                local name = specialist.name or "Unknown"
                local role = specialist.role or "Unknown Role"
                container:addChild(Text.new({
                    text = string.format("%s (%s)", name, role),
                    color = {0.2, 0.8, 0.9, 1.0}
                }))
            end
        else
            container:addChild(Text.new({
                text = "No specialists hired",
                color = {0.6, 0.6, 0.6, 1.0}
            }))
        end
    else
        container:addChild(Text.new({
            text = "Specialist system not available",
            color = {0.6, 0.6, 0.6, 1.0}
        }))
    end
end

-- Add upgrades content
function SmartSOCView:addUpgradesContent(container)
    if self.upgrades and #self.upgrades > 0 then
        for i, upgrade in ipairs(self.upgrades) do
            container:addChild(Text.new({
                text = upgrade.name or "Unknown Upgrade",
                color = {0.2, 0.8, 0.3, 1.0}
            }))
        end
    else
        container:addChild(Text.new({
            text = "No upgrades purchased",
            color = {0.6, 0.6, 0.6, 1.0}
        }))
    end
end

-- Update
function SmartSOCView:update(dt)
    -- Update toast manager
    self.toastManager:update(dt)
    
    -- Update active incidents
    for i = #self.socStatus.activeIncidents, 1, -1 do
        local incident = self.socStatus.activeIncidents[i]
        incident.timeRemaining = incident.timeRemaining - dt
        
        if incident.timeRemaining <= 0 then
            table.remove(self.socStatus.activeIncidents, i)
            self.toastManager:show("Incident auto-resolved", {type = "info"})
            self.needsRebuild = true
        end
    end
    
    -- Rebuild if needed
    if self.needsRebuild then
        self:buildUI()
    end
end

-- Draw
function SmartSOCView:draw()
    if not self.root then
        self:buildUI()
    end
    
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Measure and layout
    self.root:measure(screenWidth, screenHeight)
    self.root:layout(0, 0, screenWidth, screenHeight)
    
    -- Render
    self.root:render()
    
    -- Render toasts on top
    self.toastManager:render()
end

-- Mouse events
function SmartSOCView:mousepressed(x, y, button)
    -- Check toasts first
    if self.toastManager:mousepressed(x, y, button) then
        return true
    end
    
    -- Pass to root component
    if self.root then
        return self.root:mousepressed(x, y, button)
    end
    
    return false
end

function SmartSOCView:mousereleased(x, y, button)
    if self.root then
        return self.root:mousereleased(x, y, button)
    end
    return false
end

function SmartSOCView:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:mousemoved(x, y, dx, dy)
    end
    return false
end

function SmartSOCView:wheelmoved(x, y)
    if self.root and self.root.mouseWheel then
        return self.root:mouseWheel(x, y)
    end
    return false
end

function SmartSOCView:keypressed(key)
    -- Panel navigation with number keys
    if tonumber(key) then
        local panelKeys = {"threats", "incidents", "resources", "contracts", "specialists", "upgrades"}
        local panelIndex = tonumber(key)
        if panelIndex >= 1 and panelIndex <= #panelKeys then
            self.selectedPanel = panelKeys[panelIndex]
            self.needsRebuild = true
        end
    end
end

return SmartSOCView
