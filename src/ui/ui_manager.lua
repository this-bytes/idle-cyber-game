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

    -- HUD panel (bottom right)
    local hudX, hudY, hudW, hudH = w - 330, h - 80, 320, 70
    self.theme:drawPanel(hudX, hudY, hudW, hudH, "Player Stats")
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

    -- Debug HUD: show player coordinates/velocity/input when game debug mode is on
    if self.systems and self.systems.gameState and self.systems.gameState.debugMode then
        local gs = self.systems.gameState
        local player = nil
        if gs and gs.modes and gs.modes.idle and gs.modes.idle.player then
            player = gs.modes.idle.player
        elseif self.systems and self.systems.player then
            player = self.systems.player
        end

        if player then
            local dx = player.vx or 0
            local dy = player.vy or 0
            local infoX, infoY = 10, love.graphics.getHeight() - 80
            self.theme:drawPanel(infoX, infoY, 300, 70, "DEBUG: PLAYER")
            self.theme:drawText(string.format("Pos: (%.1f, %.1f)", player.x, player.y), infoX + 12, infoY + 18, self.theme:getColor("primary"))
            self.theme:drawText(string.format("Vel: (%.1f, %.1f)", dx, dy), infoX + 12, infoY + 34, self.theme:getColor("warning"))
            local inputState = player.input or {}
            local inputText = string.format("Input: L:%s R:%s U:%s D:%s", tostring(inputState.left), tostring(inputState.right), tostring(inputState.up), tostring(inputState.down))
            self.theme:drawText(inputText, infoX + 12, infoY + 50, self.theme:getColor("accent"))
        end
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

-- Show offline progress summary
function UIManager:showOfflineProgress(progress, onClose)
    if not progress or not progress.idleTime then
        return
    end
    
    local idleMinutes = math.floor(progress.idleTime / 60)
    local idleHours = math.floor(idleMinutes / 60)
    local remainingMinutes = idleMinutes % 60
    
    local timeStr = ""
    if idleHours > 0 then
        timeStr = idleHours .. "h " .. remainingMinutes .. "m"
    else
        timeStr = idleMinutes .. "m"
    end
    
    local title = "⏰ Welcome Back! (" .. timeStr .. " offline)"
    
    local body = ""
    
    -- Earnings section
    if progress.earnings > 0 then
        body = body .. "💰 Earnings: $" .. progress.earnings .. "\n"
    end
    
    -- Damage section
    if progress.damage > 0 then
        body = body .. "⚠️ Cyber Damage: $" .. progress.damage .. "\n"
    end
    
    -- Net result
    body = body .. "\n"
    if progress.netGain > 0 then
        body = body .. "📈 Net Gain: $" .. progress.netGain .. "\n"
    elseif progress.netGain < 0 then
        body = body .. "📉 Net Loss: $" .. (-progress.netGain) .. "\n"
    else
        body = body .. "⚖️ Break Even\n"
    end
    
    -- Event summary
    if #progress.events > 0 then
        body = body .. "\n🛡️ Security Events:\n"
        
        -- Count events by type
        local eventCounts = {}
        for _, event in ipairs(progress.events) do
            eventCounts[event.name] = (eventCounts[event.name] or 0) + 1
        end
        
        -- Show top 3 most frequent
        local sortedEvents = {}
        for name, count in pairs(eventCounts) do
            table.insert(sortedEvents, {name = name, count = count})
        end
        table.sort(sortedEvents, function(a, b) return a.count > b.count end)
        
        for i = 1, math.min(3, #sortedEvents) do
            local event = sortedEvents[i]
            body = body .. "  • " .. event.name .. " x" .. event.count .. "\n"
        end
        
        if #sortedEvents > 3 then
            body = body .. "  • +" .. (#sortedEvents - 3) .. " other event types\n"
        end
    end
    
    body = body .. "\nPress any key to continue..."
    
    self.modal = { title = title, body = body, onClose = onClose }
end

function UIManager:resize(w, h)
    -- Handle window resize
end

return UIManager