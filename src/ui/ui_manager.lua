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
    -- In-game log buffer and toast system
    self.logs = {} -- { {time=os.time(), severity="info", text="..."}, ... }
    self.maxLogs = 200
    self.toasts = {} -- { {text=.., type="info", timeRemaining=.., duration=..}, ... }
    -- Toast animation helpers
    -- Each toast will have: startTime, yOffset, alpha for animations
    self.hudValues = { money = 0, income = 0, reputation = 0, xp = 0, contracts = 0 }
    -- Terminal overlay state (scroll: 0 = bottom/latest)
    self.terminalScroll = 0
    self.terminalLineHeight = 16
    self.terminalPadding = 12
    -- HUD animation state
    self.hudAnim = { money = 0 }
    self.hudFloating = {} -- { {amount=123, age=0, duration=1.2}, ... }

    -- Subscribe to event bus messages if available
    if self.eventBus then
        -- Update HUD when resources change
        self.eventBus:subscribe("resources_updated", function(data)
            if data and data.resources then
                local r = data.resources
                local prevMoney = self.hudValues.money or 0
                self.hudValues.money = r.money or self.hudValues.money
                -- push floating delta if money changed
                local delta = (self.hudValues.money - prevMoney)
                if delta ~= 0 then
                    table.insert(self.hudFloating, { amount = delta, age = 0, duration = 1.2 })
                end
                self.hudValues.reputation = r.reputation or self.hudValues.reputation
                self.hudValues.xp = r.xp or self.hudValues.xp
                self.hudValues.missionTokens = r.missionTokens or self.hudValues.missionTokens
                self.hudValues.contracts = r.contracts or self.hudValues.contracts
            end
            if data and data.generation then
                self.hudValues.income = data.generation.money or self.hudValues.income
            end
        end)

        -- UI log/toast events
        self.eventBus:subscribe("ui.log", function(d)
            if d then self:log(d.text or tostring(d), d.severity) end
        end)
        self.eventBus:subscribe("ui.toast", function(d)
            if d then self:toast(d.text or tostring(d), d.type, d.duration) end
        end)
    end
    
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

    -- Update toasts animation state
    for i = #self.toasts, 1, -1 do
        local t = self.toasts[i]
        t.timeRemaining = t.timeRemaining - dt
        -- Animate yOffset and alpha (simple ease)
        local elapsed = (t.duration - t.timeRemaining)
        t.alpha = 1
        if elapsed < 0.15 then
            -- entering
            t.alpha = math.min(1, elapsed / 0.15)
            t.yOffset = (1 - t.alpha) * 8
        elseif t.timeRemaining < 0.15 then
            -- exiting
            t.alpha = math.max(0, t.timeRemaining / 0.15)
            t.yOffset = (1 - t.alpha) * 8
        else
            t.alpha = 1
            t.yOffset = 0
        end
        if t.timeRemaining <= 0 then
            table.remove(self.toasts, i)
        end
    end
end

function UIManager:draw()
    -- Draw HUD (compact overlay) instead of full-screen background to avoid covering game mode
    local w, h = love.graphics.getDimensions()

    -- HUD top bar (compact)
    local hudX, hudY, hudW, hudH = 10, 10, w - 20, 40
    self.theme:drawPanel(hudX, hudY, hudW, hudH, nil)
    local moneyText = "$" .. string.format("%.0f", self.hudValues.money or 0)
    local incomeText = "/s: $" .. string.format("%.1f", self.hudValues.income or 0)
    local repText = "Rep: " .. tostring(math.floor(self.hudValues.reputation or 0))
    local xpText = "XP: " .. tostring(math.floor(self.hudValues.xp or 0))
    local contractsText = "Contracts: " .. tostring(self.hudValues.contracts or 0)
    -- Friendly number formatting using animated hudAnim.money
    local function formatNumber(n)
        if not n then return "0" end
        if n >= 1000000 then
            return string.format("%.1fm", n / 1000000)
        elseif n >= 1000 then
            return string.format("%.1fk", n / 1000)
        else
            return tostring(math.floor(n))
        end
    end

    local displayedMoney = "$" .. formatNumber(math.floor(self.hudAnim.money or self.hudValues.money or 0))
    local displayedIncome = "/s: $" .. tostring(self.hudValues.income or 0)

    self.theme:drawText(displayedMoney .. " " .. displayedIncome, hudX + 12, hudY + 8, self.theme:getColor("success"))
    self.theme:drawText(repText .. "  " .. xpText, hudX + 220, hudY + 8, self.theme:getColor("accent"))
    self.theme:drawText(contractsText, hudX + hudW - 140, hudY + 8, self.theme:getColor("primary"))

    -- Draw floating deltas (e.g., +$50) near money HUD
    for i, f in ipairs(self.hudFloating) do
        local alpha = 1 - (f.age / f.duration)
        local sign = f.amount >= 0 and "+" or "-"
        local amt = math.abs(f.amount)
        local text = sign .. "$" .. formatNumber(math.floor(amt))
        local fx = hudX + 12 + 6
        local fy = hudY + 8 - (i * 14)
        local col = self.theme:getColor("success")
        if f.amount < 0 then col = self.theme:getColor("danger") end
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.print(text, fx, fy)
        love.graphics.setColor(1,1,1,1)
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

    -- Draw active toasts (top-right) with animation
    local toastX = w - 360
    local baseToastY = 10
    for i, t in ipairs(self.toasts) do
        local tw, th = 340, 36
        local ty = baseToastY + (i-1) * (th + 8) - (t.yOffset or 0)
        -- Apply alpha while drawing
        local color = self.theme:getColor("primary")
        if t.type == "success" then color = self.theme:getColor("success") end
        if t.type == "warn" then color = self.theme:getColor("warning") end
        if t.type == "error" then color = self.theme:getColor("danger") end
        -- Draw panel with alpha
        love.graphics.push()
        love.graphics.setColor(1,1,1,(t.alpha or 1) * 0.95)
        self.theme:drawPanel(toastX, ty, tw, th, nil)
        love.graphics.setColor(color[1], color[2], color[3], (t.alpha or 1))
        self.theme:drawText(t.text, toastX + 10, ty + 8, color)
        love.graphics.pop()
    end

    -- Draw small terminal status bar at bottom
    self.theme:drawStatusBar()

    -- Draw full terminal overlay when toggled
    if self.showFullTerminal then
        local tw = math.min(960, w - 80)
        local th = math.min(h - 140, math.floor(h * 0.6))
        local tx = (w - tw) / 2
        local ty = (h - th) / 2

        -- Panel background
        self.theme:drawPanel(tx, ty, tw, th, "TERMINAL")

        -- Calculate how many lines fit
        local innerTop = ty + 36
        local innerHeight = th - 48
        local linesPerPage = math.max(3, math.floor(innerHeight / self.terminalLineHeight))

        -- Clamp terminalScroll to available range
        local maxScroll = math.max(0, math.max(0, #self.logs - linesPerPage))
        if self.terminalScroll < 0 then self.terminalScroll = 0 end
        if self.terminalScroll > maxScroll then self.terminalScroll = maxScroll end

        -- Determine range to display (showing newest at bottom)
        local endIndex = math.max(0, #self.logs - self.terminalScroll)
        local startIndex = math.max(1, endIndex - linesPerPage + 1)

        -- Draw lines
        local y = innerTop
        for i = startIndex, endIndex do
            local entry = self.logs[i]
            if entry then
                local color = self.theme:getColor("primary")
                if entry.severity == "success" then color = self.theme:getColor("success") end
                if entry.severity == "warn" or entry.severity == "warning" then color = self.theme:getColor("warning") end
                if entry.severity == "error" or entry.severity == "danger" then color = self.theme:getColor("danger") end
                local timeStr = os.date("%H:%M:%S", entry.time)
                local text = string.format("[%s] %s", timeStr, entry.text)
                self.theme:drawText(text, tx + 12, y, color)
            end
            y = y + self.terminalLineHeight
        end

        -- Simple scrollbar indicator on right
        if #self.logs > 0 then
            local scrollAreaX = tx + tw - 18
            local scrollAreaY = innerTop
            local scrollAreaH = innerHeight
            love.graphics.setColor(0.05, 0.05, 0.06, 0.9)
            love.graphics.rectangle("fill", scrollAreaX, scrollAreaY, 12, scrollAreaH, 4, 4)
            -- Thumb
            local thumbH = math.max(20, (linesPerPage / math.max(1, #self.logs)) * scrollAreaH)
            local thumbPos = 0
            if #self.logs > linesPerPage then
                thumbPos = (self.terminalScroll / math.max(1, maxScroll)) * (scrollAreaH - thumbH)
            end
            love.graphics.setColor(self.theme:getColor("accent"))
            love.graphics.rectangle("fill", scrollAreaX + 2, scrollAreaY + thumbPos, 8, thumbH, 3, 3)
        end

        -- Helper text
        self.theme:drawText("↑/↓ PageUp/PageDown to scroll, TAB to close", tx + 12, ty + th - 22, self.theme:getColor("accent"))
    end
end


-- Log an entry into the in-game terminal and optionally print in debug
function UIManager:log(text, severity)
    severity = severity or "info"
    local entry = { time = os.time(), severity = severity, text = tostring(text) }
    table.insert(self.logs, entry)
    if #self.logs > self.maxLogs then
        table.remove(self.logs, 1)
    end
    -- If debug mode, forward to console too
    if self.systems and self.systems.gameState and self.systems.gameState.debugMode then
        print("[LOG] " .. severity:upper() .. ": " .. tostring(text))
    end
end

-- Show a short-lived toast notification
function UIManager:toast(text, type, duration)
    local d = duration or 3.0
    table.insert(self.toasts, { text = tostring(text), type = type or "info", timeRemaining = d, duration = d })
    -- Play a subtle sound if available (left as optional integration)
end

-- Update toasts lifetime
function UIManager:update(dt)
    -- existing terminal theme update
    self.theme:update(dt)
    -- Update active toasts
    for i = #self.toasts, 1, -1 do
        local t = self.toasts[i]
        t.timeRemaining = t.timeRemaining - dt
        if t.timeRemaining <= 0 then
            table.remove(self.toasts, i)
        end
    end

    -- Modal handling (keep existing behavior)
    if self.modal then
        if self.modal.timer then
            self.modal.timer = math.max(0, self.modal.timer - dt)
            if self.modal.timer == 0 and self.modal.onClose then
                self.modal.onClose()
                self.modal = nil
            end
        end
    end

    -- HUD money interpolation (simple easing)
    if type(self.hudValues.money) == "number" then
        local target = self.hudValues.money
        local cur = self.hudAnim.money or target
        local diff = target - cur
        local step = diff * math.min(1, dt * 6)
        self.hudAnim.money = cur + step
    end

    -- Update floating HUD deltas
    for i = #self.hudFloating, 1, -1 do
        local f = self.hudFloating[i]
        f.age = f.age + dt
        if f.age >= f.duration then
            table.remove(self.hudFloating, i)
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
        if self.eventBus then
            self.eventBus:publish("ui.log", { text = "🔲 Terminal overlay " .. (self.showFullTerminal and "shown" or "hidden"), severity = "info" })
            self.eventBus:publish("ui.toast", { text = "Terminal " .. (self.showFullTerminal and "opened" or "closed"), type = "info", duration = 1.5 })
        else
            print("🔲 Terminal overlay " .. (self.showFullTerminal and "shown" or "hidden"))
        end
        return
    end
    -- Terminal scrolling keys
    if self.showFullTerminal then
        if key == "up" or key == "kp8" then
            self.terminalScroll = math.min(self.terminalScroll + 1, math.max(0, #self.logs - 1))
            return
        elseif key == "down" or key == "kp2" then
            self.terminalScroll = math.max(self.terminalScroll - 1, 0)
            return
        elseif key == "pageup" then
            self.terminalScroll = math.min(self.terminalScroll + 10, math.max(0, #self.logs - 1))
            return
        elseif key == "pagedown" then
            self.terminalScroll = math.max(self.terminalScroll - 10, 0)
            return
        elseif key == "home" then
            self.terminalScroll = math.max(0, #self.logs - 1)
            return
        elseif key == "end" then
            self.terminalScroll = 0
            return
        end
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
        
        -- Count events by type and track mitigation
        local eventCounts = {}
        local mitigatedCount = 0
        for _, event in ipairs(progress.events) do
            eventCounts[event.name] = (eventCounts[event.name] or 0) + 1
            if event.mitigated then
                mitigatedCount = mitigatedCount + 1
            end
        end
        
        -- Show mitigation effectiveness
        local mitigationRate = math.floor((mitigatedCount / #progress.events) * 100)
        body = body .. "  🔒 " .. mitigationRate .. "% of attacks mitigated\n"
        
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
    else
        body = body .. "\n🛡️ No security incidents detected\n"
        body = body .. "  Your defenses held strong!\n"
    end
    
    body = body .. "\nPress any key to continue..."
    
    self.modal = { title = title, body = body, onClose = onClose }
end

function UIManager:resize(w, h)
    -- Handle window resize
end

return UIManager