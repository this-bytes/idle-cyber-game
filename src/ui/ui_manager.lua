-- UI Manager
-- Handles all user interface elements and screens

local UIManager = {}
UIManager.__index = UIManager

local TerminalTheme = require("src.ui.terminal_theme")

-- Create new UI manager
-- Accepts either an eventBus (legacy) or the full systems table
function UIManager.new(systemsOrEventBus)
    local self = setmetatable({}, UIManager)
    if systemsOrEventBus and systemsOrEventBus.getAllResources then
        -- Looks like a system object; keep as legacy eventBus
        self.eventBus = systemsOrEventBus
        self.systems = nil
    elseif systemsOrEventBus and systemsOrEventBus.eventBus then
        -- systems table was passed
        self.systems = systemsOrEventBus
        self.eventBus = systemsOrEventBus.eventBus
    else
        self.systems = nil
        self.eventBus = nil
    end

    -- UI state
    self.activeScreens = {}
    self.showFPS = false
    self.modal = nil -- { title, body, timer, onClose }
    -- Whether to render the full terminal panels (header, large panels)
    -- Default to false so the office map is the primary view after splash
    self.showFullTerminal = false
    
    -- Initialize terminal theme
    self.theme = TerminalTheme.new()
    
    return self
end

function UIManager:update(dt)
    -- Update terminal theme effects
    self.theme:update(dt)
    
    -- Update active UI screens
    if self.modal then
        if self.modal.timer then
            self.modal.timer = math.max(0, self.modal.timer - dt)
            if self.modal.timer == 0 and self.modal.onClose then
                self.modal.onClose()
                self.modal = nil
            end
        end
    end
end

function UIManager:draw()
    -- Draw HUD (compact overlay) instead of full-screen background to avoid covering game mode
    local w, h = love.graphics.getDimensions()

    -- HUD panel (top-left)
    local hudX, hudY, hudW, hudH = 10, 10, 320, 70
    self.theme:drawPanel(hudX, hudY, hudW, hudH, "HUD")
    if self.systems and self.systems.resources then
        local res = self.systems.resources:getAllResources()
        local money = res.money or 0
        local rep = res.reputation or 0
        local xp = res.xp or 0
        self.theme:drawText("$" .. string.format("%.0f", money), hudX + 12, hudY + 18, self.theme:getColor("success"))
        self.theme:drawText("Rep: " .. tostring(math.floor(rep)), hudX + 120, hudY + 18, self.theme:getColor("accent"))
        self.theme:drawText("XP: " .. tostring(math.floor(xp)), hudX + 220, hudY + 18, self.theme:getColor("primary"))
    else
        self.theme:drawText("$0", hudX + 12, hudY + 18, self.theme:getColor("success"))
    end

    -- FPS toggle display
    if self.showFPS then
        self.theme:drawText("FPS: " .. love.timer.getFPS(), hudX + 12, hudY + 42, self.theme:getColor("warning"))
    end

    -- Draw modal if present
    if self.modal then
        local w, h = love.graphics.getDimensions()
        -- Dim background
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Modal box
        local mw, mh = math.min(600, w - 100), math.min(300, h - 100)
        local mx, my = (w - mw) / 2, (h - mh) / 2
        love.graphics.setColor(0.05, 0.05, 0.06, 0.98)
        love.graphics.rectangle("fill", mx, my, mw, mh, 6, 6)
        love.graphics.setColor(0.1, 0.9, 0.9, 1)
        love.graphics.printf(self.modal.title or "", mx + 20, my + 18, mw - 40, "center")
        love.graphics.setColor(1,1,1,0.95)
        love.graphics.printf(self.modal.body or "", mx + 20, my + 58, mw - 40, "left")
        love.graphics.setColor(1,1,1,0.9)
        love.graphics.printf("Press any key to continue", mx + 20, my + mh - 40, mw - 40, "center")
    end
end

function UIManager:mousepressed(x, y, button)
    -- Handle UI clicks
    return false
end

function UIManager:keypressed(key)
    if key == "f" then
        self.showFPS = not self.showFPS
    end
    if key == "tab" then
        -- Toggle the large terminal overlay
        self.showFullTerminal = not self.showFullTerminal
        print("🔲 Terminal overlay " .. (self.showFullTerminal and "shown" or "hidden"))
        return
    end
    if self.modal then
        -- Close modal on any key
        local onClose = self.modal.onClose
        self.modal = nil
        if onClose then onClose() end
    end
end

function UIManager:showTutorial(title, body, onClose)
    self.modal = { title = title, body = body, onClose = onClose }
end

function UIManager:resize(w, h)
    -- Handle window resize
end

return UIManager