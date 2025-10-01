-- Smart UI Manager - Modernized UI management using Smart UI Framework
-- Replaces old drawing code with component-based rendering
-- Integrates ToastManager and provides viewport management

local ScrollContainer = require("src.ui.components.scroll_container")
local Box = require("src.ui.components.box")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")
local Grid = require("src.ui.components.grid")
local ToastManager = require("src.ui.toast_manager")

local SmartUIManager = {}
SmartUIManager.__index = SmartUIManager

-- UI States
local UI_STATES = {
    LOADING = "loading",
    SPLASH = "splash",
    GAME = "game",
    PAUSED = "paused"
}

function SmartUIManager.new(eventBus, resourceManager)
    local self = setmetatable({}, SmartUIManager)
    
    -- Dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    
    -- State
    self.currentState = UI_STATES.LOADING
    self.screenWidth = 1024
    self.screenHeight = 768
    
    -- Toast notification system
    self.toastManager = ToastManager.new()
    
    -- Root UI components
    self.root = nil
    self.gameUI = nil
    
    -- UI rebuild needed flag
    self.needsRebuild = true
    
    -- Panel visibility state
    self.panelVisibility = {
        resources = true,
        threats = false,
        contracts = false,
        specialists = false,
        upgrades = false
    }
    
    -- Color scheme
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
    
    return self
end

-- Initialize the UI manager
function SmartUIManager:initialize()
    self.currentState = UI_STATES.SPLASH
    self:buildUI()
    
    -- Subscribe to events
    if self.eventBus then
        self.eventBus:subscribe("resource_changed", function(data)
            self:onResourceChanged(data)
        end)
        
        self.eventBus:subscribe("threat_detected", function(data)
            self:showNotification("Threat detected: " .. (data.threat.name or "Unknown"), "warning")
        end)
        
        self.eventBus:subscribe("contract_completed", function(data)
            self:showNotification("Contract completed!", "success")
        end)
    end
    
    print("🖥️ Smart UI Manager initialized")
end

-- Build the UI component tree
function SmartUIManager:buildUI()
    -- Root scroll container (handles viewport management)
    self.root = ScrollContainer.new({
        backgroundColor = self.colors.background,
        showScrollbars = true,
        scrollSpeed = 30
    })
    
    -- Main content container
    local content = Box.new({
        direction = "vertical",
        gap = 20,
        padding = {20, 20, 20, 20}
    })
    self.root:addChild(content)
    
    if self.currentState == UI_STATES.SPLASH then
        self:buildSplashScreen(content)
    elseif self.currentState == UI_STATES.GAME then
        self:buildGameUI(content)
    end
    
    self.needsRebuild = false
end

-- Build splash screen
function SmartUIManager:buildSplashScreen(container)
    local splashPanel = Panel.new({
        title = "🛡️ Idle Sec Ops",
        cornerStyle = "cut",
        glow = true,
        minHeight = 200,
        padding = {30, 30, 30, 30}
    })
    
    local subtitle = Text.new({
        text = "Security Operations Center Simulator",
        color = self.colors.accent,
        align = "center",
        fontSize = 16
    })
    splashPanel:addChild(subtitle)
    
    local instructions = Text.new({
        text = "Press SPACE to start",
        color = self.colors.text,
        align = "center",
        fontSize = 14
    })
    splashPanel:addChild(instructions)
    
    container:addChild(splashPanel)
end

-- Build game UI
function SmartUIManager:buildGameUI(container)
    -- Store reference for updates
    self.gameUI = container
    
    -- Header with title and resources
    local header = self:createHeader()
    container:addChild(header)
    
    -- Main content area with panels
    local mainContent = Box.new({
        direction = "horizontal",
        gap = 20,
        flex = 1
    })
    
    -- Left sidebar with navigation
    local sidebar = self:createSidebar()
    mainContent:addChild(sidebar)
    
    -- Center panel area
    local centerPanel = self:createCenterPanel()
    mainContent:addChild(centerPanel)
    
    -- Right sidebar with additional info
    local rightSidebar = self:createRightSidebar()
    mainContent:addChild(rightSidebar)
    
    container:addChild(mainContent)
end

-- Create header component
function SmartUIManager:createHeader()
    local header = Panel.new({
        title = "🛡️ SOC Command Center",
        cornerStyle = "cut",
        minHeight = 80,
        flex = 0
    })
    
    -- Resource display
    if self.resourceManager then
        local resourceBox = Box.new({
            direction = "horizontal",
            gap = 20,
            padding = {10, 10, 10, 10}
        })
        
        -- Money
        local money = self.resourceManager:getResource("money") or 0
        local moneyText = Text.new({
            text = "💰 $" .. string.format("%.0f", money),
            color = self.colors.success
        })
        resourceBox:addChild(moneyText)
        
        -- Reputation
        local reputation = self.resourceManager:getResource("reputation") or 0
        local repText = Text.new({
            text = "⭐ Rep: " .. string.format("%.0f", reputation),
            color = self.colors.accent
        })
        resourceBox:addChild(repText)
        
        header:addChild(resourceBox)
    end
    
    return header
end

-- Create sidebar navigation
function SmartUIManager:createSidebar()
    local sidebar = Panel.new({
        title = "Navigation",
        cornerStyle = "square",
        minWidth = 200,
        flex = 0
    })
    
    local buttonBox = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {10, 10, 10, 10}
    })
    
    -- Navigation buttons
    local buttons = {
        {label = "Dashboard", key = "dashboard"},
        {label = "Contracts", key = "contracts"},
        {label = "Specialists", key = "specialists"},
        {label = "Threats", key = "threats"},
        {label = "Upgrades", key = "upgrades"}
    }
    
    for _, btnData in ipairs(buttons) do
        local btn = Button.new({
            label = btnData.label,
            minWidth = 180,
            onClick = function()
                self:onNavigationClick(btnData.key)
            end
        })
        buttonBox:addChild(btn)
    end
    
    sidebar:addChild(buttonBox)
    return sidebar
end

-- Create center panel
function SmartUIManager:createCenterPanel()
    local panel = Panel.new({
        title = "Main Display",
        cornerStyle = "rounded",
        flex = 2
    })
    
    local content = Text.new({
        text = "Welcome to the SOC Command Center!\n\nSelect an option from the sidebar to get started.",
        color = self.colors.text,
        wrap = true,
        padding = {20, 20, 20, 20}
    })
    
    panel:addChild(content)
    return panel
end

-- Create right sidebar
function SmartUIManager:createRightSidebar()
    local sidebar = Panel.new({
        title = "Status",
        cornerStyle = "square",
        minWidth = 200,
        flex = 0
    })
    
    local statusText = Text.new({
        text = "All systems operational",
        color = self.colors.success,
        padding = {10, 10, 10, 10}
    })
    
    sidebar:addChild(statusText)
    return sidebar
end

-- Update the UI
function SmartUIManager:update(dt)
    -- Update toast notifications
    self.toastManager:update(dt)
    
    -- Rebuild UI if needed
    if self.needsRebuild then
        self:buildUI()
    end
end

-- Render the UI
function SmartUIManager:draw()
    if self.root then
        -- Measure and layout root component
        self.root:measure(self.screenWidth, self.screenHeight)
        self.root:layout(0, 0, self.screenWidth, self.screenHeight)
        
        -- Render
        self.root:render()
    end
    
    -- Render toasts on top
    self.toastManager:render()
end

-- Show a notification
function SmartUIManager:showNotification(message, type, duration)
    self.toastManager:show(message, {
        type = type or "info",
        duration = duration or 3.0
    })
end

-- Handle state changes
function SmartUIManager:setState(newState)
    if self.currentState ~= newState then
        self.currentState = newState
        self.needsRebuild = true
    end
end

-- Handle resource changes
function SmartUIManager:onResourceChanged(data)
    -- Mark for rebuild to update resource display
    self.needsRebuild = true
end

-- Handle navigation clicks
function SmartUIManager:onNavigationClick(key)
    print("Navigation clicked:", key)
    self:showNotification("Navigated to " .. key, "info")
    
    -- Publish event for other systems
    if self.eventBus then
        self.eventBus:publish("ui_navigation", {destination = key})
    end
end

-- Handle window resize
function SmartUIManager:resize(w, h)
    self.screenWidth = w
    self.screenHeight = h
    self.needsRebuild = true
    print("🖥️ Smart UI Manager resized to " .. w .. "x" .. h)
end

-- Handle mouse events
function SmartUIManager:mousepressed(x, y, button)
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

function SmartUIManager:mousereleased(x, y, button)
    if self.root then
        return self.root:mousereleased(x, y, button)
    end
    return false
end

function SmartUIManager:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:mousemoved(x, y, dx, dy)
    end
    return false
end

-- Handle mouse wheel (for scrolling)
function SmartUIManager:wheelmoved(x, y)
    if self.root and self.root.mouseWheel then
        return self.root:mouseWheel(x, y)
    end
    return false
end

-- Get current state
function SmartUIManager:getState()
    return {
        currentState = self.currentState,
        panelVisibility = self.panelVisibility
    }
end

-- Load state
function SmartUIManager:loadState(state)
    if not state then return end
    
    if state.currentState then
        self:setState(state.currentState)
    end
    
    if state.panelVisibility then
        self.panelVisibility = state.panelVisibility
        self.needsRebuild = true
    end
end

-- Shutdown
function SmartUIManager:shutdown()
    print("🖥️ Smart UI Manager shutdown")
end

return SmartUIManager
