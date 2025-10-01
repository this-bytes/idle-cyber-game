-- Main Menu - Using Smart UI Framework
-- Clean, modern main menu with component-based rendering

local ScrollContainer = require("src.ui.components.scroll_container")
local Box = require("src.ui.components.box")
local Panel = require("src.ui.components.panel")
local Text = require("src.ui.components.text")
local Button = require("src.ui.components.button")

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new(eventBus)
    local self = setmetatable({}, MainMenu)
    
    self.eventBus = eventBus
    self.root = nil
    self.needsRebuild = true
    
    -- Menu configuration
    self.menuItems = {
        {text = "Start SOC Operations", action = "start_game"},
        {text = "Load Previous SOC", action = "load_game"},
        {text = "SOC Settings", action = "settings"},
        {text = "Exit", action = "quit"}
    }
    
    print("🏠 Smart MainMenu: Initialized")
    return self
end

-- Scene lifecycle
function MainMenu:enter(data)
    print("🏠 Smart MainMenu: Entered")
    self.needsRebuild = true
    -- Debug: perform a one-time layout and auto-click simulation to trace input
    if not self._debug_autoclick_done then
        -- Ensure UI built
        if self.needsRebuild then
            self:buildUI()
        end
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        if self.root and self.root.measure and self.root.layout then
            self.root:measure(screenWidth, screenHeight)
            self.root:layout(0, 0, screenWidth, screenHeight)
        end

        -- Walk tree to find first button
        local function findButton(component)
            if not component then return nil end
            if component.className == "MainMenuButton" or (component.id and tostring(component.id):match("^main_btn_")) then
                return component
            end
            for _, c in ipairs(component.children or {}) do
                local found = findButton(c)
                if found then return found end
            end
            return nil
        end

        local target = findButton(self.root)
        if target then
            local cx = target.x + (target.width or 0) / 2
            local cy = target.y + (target.height or 0) / 2
            print(string.format("[UI DEBUG] Auto-clicking at x=%.1f y=%.1f (target id=%s class=%s)", cx, cy, tostring(target.id), tostring(target.className)))
            local handled = self:mousepressed(cx, cy, 1)
            print(string.format("[UI DEBUG] Auto-click handled=%s", tostring(handled)))
        else
            print("[UI DEBUG] Auto-click: target button not found in root tree")
        end

        self._debug_autoclick_done = true
    end
end

function MainMenu:exit()
    print("🏠 Smart MainMenu: Exited")
end

-- Build UI
function MainMenu:buildUI()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Root scroll container
    self.root = ScrollContainer.new({
        backgroundColor = {0.05, 0.1, 0.15, 1},
        showScrollbars = false
    })
    
    -- Main content container
    local content = Box.new({
        direction = "vertical",
        align = "center",
        justify = "center",
        gap = 30,
        padding = {50, 50, 50, 50}
    })
    self.root:addChild(content)
    
    -- Title panel
    local titlePanel = Panel.new({
        title = "🛡️ SOC Command Center",
        cornerStyle = "cut",
        glow = true,
        minWidth = 600,
        minHeight = 150
    })
    
    local subtitle = Text.new({
        text = "Cybersecurity Operations Management",
        color = {0.7, 0.9, 1, 1},
        align = "center",
        fontSize = 16
    })
    titlePanel:addChild(subtitle)
    
    content:addChild(titlePanel)
    
    -- Menu buttons panel
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
    
    for i, menuItem in ipairs(self.menuItems) do
        local btn = Button.new({
            id = "main_btn_" .. tostring(i),
            className = "MainMenuButton",
            label = menuItem.text,
            minWidth = 360,
            onClick = function()
                self:handleMenuAction(menuItem.action)
            end
        })
        buttonBox:addChild(btn)
    end
    
    menuPanel:addChild(buttonBox)
    content:addChild(menuPanel)
    
    -- Footer
    local footer = Text.new({
        text = "Idle Sec Ops - v1.0 - Made with LÖVE",
        color = {0.5, 0.5, 0.6, 1},
        align = "center",
        fontSize = 12
    })
    content:addChild(footer)
    
    self.needsRebuild = false
end

-- Handle menu action
function MainMenu:handleMenuAction(action)
    print("🏠 Smart MainMenu: Action selected:", action)
    
    if action == "start_game" then
        -- Request SOC view scene
        if self.eventBus then
            self.eventBus:publish("request_scene_change", {scene = "soc_view"})
        end
    elseif action == "load_game" then
        -- TODO: Implement load game
        print("Load game not yet implemented")
    elseif action == "settings" then
        -- TODO: Implement settings
        print("Settings not yet implemented")
    elseif action == "quit" then
        love.event.quit()
    end
end

-- Update
function MainMenu:update(dt)
    if self.needsRebuild then
        self:buildUI()
    end
end

-- Draw
function MainMenu:draw()
    if not self.root then
        self:buildUI()
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Measure and layout
    self.root:measure(screenWidth, screenHeight)
    self.root:layout(0, 0, screenWidth, screenHeight)
    
    -- Render
    self.root:render()
end

-- Mouse events
function MainMenu:mousepressed(x, y, button)
    print(string.format("[UI DEBUG] MainMenu:mousepressed x=%.1f y=%.1f button=%s root=%s", x, y, tostring(button), tostring(self.root ~= nil)))
    if self.root then
        return self.root:onMousePress(x, y, button)
    end
    return false
end

function MainMenu:mousereleased(x, y, button)
    if self.root then
        return self.root:onMouseRelease(x, y, button)
    end
    return false
end

function MainMenu:mousemoved(x, y, dx, dy)
    if self.root then
        return self.root:onMouseMove(x, y)
    end
    return false
end

-- Keyboard
function MainMenu:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return MainMenu
