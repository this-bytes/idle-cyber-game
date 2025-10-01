-- Smart UI Integration Demo
-- Demonstrates the Smart UI Framework integrated into the game
-- Run with: love integration_demo

local ScrollContainer = require("src.ui.components.scroll_container")
local Box = require("src.ui.components.box")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")
local Grid = require("src.ui.components.grid")
local ToastManager = require("src.ui.toast_manager")

local IntegrationDemo = {}
IntegrationDemo.__index = IntegrationDemo

function IntegrationDemo.new()
    local self = setmetatable({}, IntegrationDemo)
    
    self.root = nil
    self.toastManager = ToastManager.new()
    self.needsRebuild = true
    self.currentDemo = "main_menu" -- main_menu, soc_view, components
    
    return self
end

function IntegrationDemo:buildUI()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    self.root = ScrollContainer.new({
        backgroundColor = {0.05, 0.05, 0.1, 1},
        showScrollbars = true,
        scrollSpeed = 30
    })
    
    local content = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {10, 10, 10, 10}
    })
    self.root:addChild(content)
    
    -- Demo selector
    content:addChild(self:createDemoSelector())
    
    -- Current demo content
    if self.currentDemo == "main_menu" then
        content:addChild(self:createMainMenuDemo())
    elseif self.currentDemo == "soc_view" then
        content:addChild(self:createSOCViewDemo())
    elseif self.currentDemo == "components" then
        content:addChild(self:createComponentsDemo())
    end
    
    self.needsRebuild = false
end

function IntegrationDemo:createDemoSelector()
    local panel = Panel.new({
        title = "🎨 Smart UI Integration Demo - Select View",
        cornerStyle = "cut",
        glow = true,
        minHeight = 80
    })
    
    local buttonBox = Box.new({
        direction = "horizontal",
        gap = 10,
        padding = {10, 10, 10, 10}
    })
    
    local demos = {
        {key = "main_menu", label = "Main Menu Demo"},
        {key = "soc_view", label = "SOC View Demo"},
        {key = "components", label = "Components Demo"}
    }
    
    for _, demo in ipairs(demos) do
        local isSelected = (self.currentDemo == demo.key)
        local btn = Button.new({
            label = demo.label,
            onClick = function()
                self.currentDemo = demo.key
                self.needsRebuild = true
                self.toastManager:show("Switched to " .. demo.label, {type = "info"})
            end,
            normalColor = isSelected and {0.3, 0.5, 0.8, 1} or {0.2, 0.2, 0.3, 1},
            normalBorderColor = isSelected and {0, 1, 1, 1} or {0.5, 0.5, 0.6, 1}
        })
        buttonBox:addChild(btn)
    end
    
    panel:addChild(buttonBox)
    return panel
end

function IntegrationDemo:createMainMenuDemo()
    local container = Box.new({
        direction = "vertical",
        gap = 20,
        align = "center"
    })
    
    -- Title panel
    local titlePanel = Panel.new({
        title = "🛡️ SOC Command Center",
        cornerStyle = "cut",
        glow = true,
        minWidth = 600,
        minHeight = 150
    })
    
    local subtitle = Text.new({
        text = "Cybersecurity Operations Management\n(Main Menu Demo)",
        color = {0.7, 0.9, 1, 1},
        align = "center",
        fontSize = 16
    })
    titlePanel:addChild(subtitle)
    container:addChild(titlePanel)
    
    -- Menu buttons
    local menuPanel = Panel.new({
        title = "Main Menu",
        cornerStyle = "rounded",
        minWidth = 400
    })
    
    local buttonBox = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {20, 20, 20, 20}
    })
    
    local menuItems = {
        "Start SOC Operations",
        "Load Previous SOC",
        "SOC Settings",
        "Exit"
    }
    
    for i, item in ipairs(menuItems) do
        local btn = Button.new({
            label = item,
            minWidth = 360,
            onClick = function()
                self.toastManager:show("Selected: " .. item, {type = "success"})
            end
        })
        buttonBox:addChild(btn)
    end
    
    menuPanel:addChild(buttonBox)
    container:addChild(menuPanel)
    
    return container
end

function IntegrationDemo:createSOCViewDemo()
    local container = Box.new({
        direction = "vertical",
        gap = 10
    })
    
    -- Header
    local header = Panel.new({
        title = "🛡️ SOC Command Center - Alert: GREEN",
        cornerStyle = "cut",
        minHeight = 80
    })
    
    local resourceBox = Box.new({
        direction = "horizontal",
        gap = 20,
        padding = {10, 10, 10, 10}
    })
    
    resourceBox:addChild(Text.new({text = "💰 $25,000", color = {0.2, 0.8, 0.3, 1.0}}))
    resourceBox:addChild(Text.new({text = "⭐ 150", color = {0.2, 0.8, 0.9, 1.0}}))
    resourceBox:addChild(Text.new({text = "📈 500 XP", color = {0.9, 0.7, 0.2, 1.0}}))
    
    header:addChild(resourceBox)
    container:addChild(header)
    
    -- Main content
    local mainArea = Box.new({
        direction = "horizontal",
        gap = 10,
        flex = 1
    })
    
    -- Sidebar
    local sidebar = Panel.new({
        title = "Panels",
        cornerStyle = "square",
        minWidth = 200
    })
    
    local sidebarBox = Box.new({
        direction = "vertical",
        gap = 5,
        padding = {10, 10, 10, 10}
    })
    
    local panels = {"Threat Monitor", "Incidents", "Resources", "Contracts", "Specialists"}
    for _, panelName in ipairs(panels) do
        local btn = Button.new({
            label = panelName,
            minWidth = 180,
            onClick = function()
                self.toastManager:show("Opened: " .. panelName, {type = "info"})
            end
        })
        sidebarBox:addChild(btn)
    end
    
    sidebar:addChild(sidebarBox)
    mainArea:addChild(sidebar)
    
    -- Main panel
    local mainPanel = Panel.new({
        title = "🚨 Threat Monitor",
        cornerStyle = "rounded",
        flex = 2
    })
    
    local contentBox = Box.new({
        direction = "vertical",
        gap = 10,
        padding = {15, 15, 15, 15}
    })
    
    contentBox:addChild(Text.new({
        text = "Detection Capability: 150",
        color = {0.2, 0.8, 0.9, 1.0}
    }))
    
    contentBox:addChild(Text.new({
        text = "Response Capability: 200",
        color = {0.2, 0.8, 0.3, 1.0}
    }))
    
    contentBox:addChild(Text.new({
        text = "✓ No active threats",
        color = {0.2, 0.8, 0.3, 1.0}
    }))
    
    mainPanel:addChild(contentBox)
    mainArea:addChild(mainPanel)
    
    container:addChild(mainArea)
    
    return container
end

function IntegrationDemo:createComponentsDemo()
    local container = Box.new({
        direction = "vertical",
        gap = 15
    })
    
    -- Panels demo
    local panelsRow = Box.new({
        direction = "horizontal",
        gap = 10
    })
    
    local styles = {"square", "rounded", "cut"}
    for _, style in ipairs(styles) do
        local panel = Panel.new({
            title = style:upper() .. " Panel",
            cornerStyle = style,
            glow = (style == "cut"),
            minWidth = 200,
            minHeight = 100
        })
        panel:addChild(Text.new({
            text = "Panel with\n" .. style .. " corners",
            align = "center"
        }))
        panelsRow:addChild(panel)
    end
    container:addChild(panelsRow)
    
    -- Buttons demo
    local buttonsPanel = Panel.new({
        title = "Button Variations",
        cornerStyle = "rounded"
    })
    
    local buttonsBox = Box.new({
        direction = "horizontal",
        gap = 10,
        padding = {15, 15, 15, 15}
    })
    
    local buttonTypes = {
        {label = "Success", type = "success"},
        {label = "Warning", type = "warning"},
        {label = "Error", type = "error"},
        {label = "Info", type = "info"}
    }
    
    for _, btnType in ipairs(buttonTypes) do
        local btn = Button.new({
            label = btnType.label,
            onClick = function()
                self.toastManager:show("Clicked " .. btnType.label, {type = btnType.type})
            end
        })
        buttonsBox:addChild(btn)
    end
    
    buttonsPanel:addChild(buttonsBox)
    container:addChild(buttonsPanel)
    
    -- Grid demo
    local gridPanel = Panel.new({
        title = "Grid Layout Example",
        cornerStyle = "square"
    })
    
    local grid = Grid.new({
        columns = 3,
        columnGap = 10,
        rowGap = 10,
        padding = {15, 15, 15, 15}
    })
    
    local specialists = {
        {name = "Alice", role = "Analyst", level = 5},
        {name = "Bob", role = "Engineer", level = 3},
        {name = "Charlie", role = "Manager", level = 7}
    }
    
    for _, spec in ipairs(specialists) do
        grid:addChild(Text.new({text = spec.name, color = {0.2, 0.8, 0.9, 1.0}}))
        grid:addChild(Text.new({text = spec.role, color = {0.9, 0.9, 0.9, 1.0}}))
        grid:addChild(Text.new({text = "Level " .. spec.level, color = {0.2, 0.8, 0.3, 1.0}}))
    end
    
    gridPanel:addChild(grid)
    container:addChild(gridPanel)
    
    return container
end

function IntegrationDemo:update(dt)
    self.toastManager:update(dt)
    
    if self.needsRebuild then
        self:buildUI()
    end
end

function IntegrationDemo:draw()
    if not self.root then
        self:buildUI()
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    self.root:measure(screenWidth, screenHeight)
    self.root:layout(0, 0, screenWidth, screenHeight)
    self.root:render()
    
    self.toastManager:render()
    
    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    love.graphics.print("Press F12 to take screenshot | ESC to quit | Click buttons to see toasts", 10, screenHeight - 20)
end

function IntegrationDemo:mousepressed(x, y, button)
    if self.toastManager:mousepressed(x, y, button) then
        return true
    end
    
    if self.root then
        return self.root:mousepressed(x, y, button)
    end
end

function IntegrationDemo:mousereleased(x, y, button)
    if self.root then
        return self.root:mousereleased(x, y, button)
    end
end

function IntegrationDemo:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:mousemoved(x, y, dx, dy)
    end
end

function IntegrationDemo:wheelmoved(x, y)
    if self.root and self.root.mouseWheel then
        return self.root:mouseWheel(x, y)
    end
end

function IntegrationDemo:keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f12" then
        love.graphics.captureScreenshot("smart_ui_demo_" .. os.time() .. ".png")
        self.toastManager:show("Screenshot captured!", {type = "success"})
    end
end

return IntegrationDemo
