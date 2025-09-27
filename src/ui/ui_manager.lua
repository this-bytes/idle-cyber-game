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
    
    -- Toast system
    self.toasts = {}
    self.maxToasts = 5
    
    -- Log system for terminal
    self.logs = {}
    self.maxLogs = 100
    self.showFullTerminal = false
    self.terminalScroll = 0
    self.terminalLineHeight = 20
    self.terminalPadding = 10
    
    -- HUD animation state
    self.hudAnimations = {
        money = {current = 0, target = 0, deltas = {}},
        reputation = {current = 0, target = 0, deltas = {}},
        xp = {current = 0, target = 0, deltas = {}}
    }
    
    -- Initialize terminal theme
    self.theme = TerminalTheme.new()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Subscribe to UI events
function UIManager:subscribeToEvents()
    if not self.eventBus then return end
    
    -- Handle toast notifications
    self.eventBus:subscribe("ui.toast", function(data)
        self:showToast(data.text or data.message or "Notification", 
                      data.type or "info", 
                      data.duration or 3.0)
    end)
    
    -- Handle log messages
    self.eventBus:subscribe("ui.log", function(data)
        self:addLogMessage(data.text or data.message or "Log", 
                          data.severity or "info")
    end)
    
    -- Handle success events
    self.eventBus:subscribe("ui.success", function(data)
        self:showToast(data.text or data.message or "Success!", "success", 2.0)
    end)
    
    -- Handle error events  
    self.eventBus:subscribe("ui.error", function(data)
        self:showToast(data.text or data.message or "Error!", "error", 4.0)
    end)
    
    -- Handle resource updates for HUD animations
    self.eventBus:subscribe("resource_changed", function(data)
        if data.resource == "money" then
            local delta = data.newAmount - self.hudAnimations.money.current
            self:addFloatingDelta("money", delta)
            self.hudAnimations.money.target = data.newAmount
        elseif data.resource == "reputation" then
            local delta = data.newAmount - self.hudAnimations.reputation.current
            self:addFloatingDelta("reputation", delta)
            self.hudAnimations.reputation.target = data.newAmount
        elseif data.resource == "xp" then
            local delta = data.newAmount - self.hudAnimations.xp.current
            self:addFloatingDelta("xp", delta)
            self.hudAnimations.xp.target = data.newAmount
        end
    end)
end

-- Show a toast notification
function UIManager:showToast(message, type, duration)
    local toast = {
        message = message,
        type = type or "info",
        duration = duration or 3.0,
        timeLeft = duration or 3.0,
        alpha = 0,
        yOffset = 0,
        animationPhase = "enter" -- "enter", "show", "exit"
    }
    
    table.insert(self.toasts, toast)
    
    -- Remove old toasts if we have too many
    while #self.toasts > self.maxToasts do
        table.remove(self.toasts, 1)
    end
    
    print("📱 TOAST: " .. message .. " (" .. type .. ")")
end

-- Add a log message
function UIManager:addLogMessage(message, severity)
    local logEntry = {
        message = message,
        severity = severity or "info",
        timestamp = os.date("%H:%M:%S")
    }
    
    table.insert(self.logs, logEntry)
    
    -- Keep log size manageable
    while #self.logs > self.maxLogs do
        table.remove(self.logs, 1)
    end
    
    print("📝 LOG [" .. severity:upper() .. "]: " .. message)
end

-- Add floating delta for HUD animations
function UIManager:addFloatingDelta(resource, delta)
    if delta == 0 then return end
    
    local anim = self.hudAnimations[resource]
    if anim then
        table.insert(anim.deltas, {
            value = delta,
            alpha = 1.0,
            yOffset = 0,
            timeLeft = 2.0
        })
    end
end

function UIManager:update(dt)
    -- Update terminal theme effects
    self.theme:update(dt)
    
    -- Update toasts
    for i = #self.toasts, 1, -1 do
        local toast = self.toasts[i]
        
        -- Update animation phases
        if toast.animationPhase == "enter" then
            toast.alpha = math.min(1.0, toast.alpha + dt * 4)
            toast.yOffset = math.max(0, toast.yOffset - dt * 100)
            if toast.alpha >= 1.0 then
                toast.animationPhase = "show"
            end
        elseif toast.animationPhase == "show" then
            toast.timeLeft = toast.timeLeft - dt
            if toast.timeLeft <= 0.5 then
                toast.animationPhase = "exit"
            end
        elseif toast.animationPhase == "exit" then
            toast.alpha = math.max(0, toast.alpha - dt * 2)
            if toast.alpha <= 0 then
                table.remove(self.toasts, i)
            end
        end
    end
    
    -- Update HUD animations
    for resource, anim in pairs(self.hudAnimations) do
        -- Smooth money value interpolation
        local diff = anim.target - anim.current
        if math.abs(diff) > 0.1 then
            anim.current = anim.current + diff * dt * 3
        else
            anim.current = anim.target
        end
        
        -- Update floating deltas
        for j = #anim.deltas, 1, -1 do
            local delta = anim.deltas[j]
            delta.timeLeft = delta.timeLeft - dt
            delta.alpha = delta.timeLeft / 2.0
            delta.yOffset = delta.yOffset - dt * 50
            
            if delta.timeLeft <= 0 then
                table.remove(anim.deltas, j)
            end
        end
    end
    
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
    if not love or not love.graphics then return end
    
    -- Draw HUD (compact overlay) instead of full-screen background to avoid covering game mode
    local w, h = love.graphics.getDimensions()

    -- Enhanced HUD panel (bottom right)
    local hudX, hudY, hudW, hudH = w - 350, h - 100, 340, 90
    self.theme:drawPanel(hudX, hudY, hudW, hudH, "Player Stats")
    
    if self.systems and self.systems.resources then
        local res = self.systems.resources:getAllResources()
        local money = res.money or 0
        local rep = res.reputation or 0
        local xp = res.xp or 0
        
        -- Use animated values for smooth transitions
        local animMoney = self.hudAnimations.money.current > 0 and self.hudAnimations.money.current or money
        local animRep = self.hudAnimations.reputation.current > 0 and self.hudAnimations.reputation.current or rep
        local animXP = self.hudAnimations.xp.current > 0 and self.hudAnimations.xp.current or xp
        
        -- Format large numbers
        local function formatNumber(num)
            if num >= 1000000 then
                return string.format("%.1fm", num / 1000000)
            elseif num >= 1000 then
                return string.format("%.1fk", num / 1000)
            else
                return string.format("%.0f", num)
            end
        end
        
        self.theme:drawText("$" .. formatNumber(animMoney), hudX + 12, hudY + 18, self.theme:getColor("success"))
        self.theme:drawText("Rep: " .. formatNumber(animRep), hudX + 120, hudY + 18, self.theme:getColor("accent"))
        self.theme:drawText("XP: " .. formatNumber(animXP), hudX + 220, hudY + 18, self.theme:getColor("primary"))
        
        -- Show income rate if available
        if self.systems.contracts then
            local incomeRate = 0
            if self.systems.contracts.getTotalIncomeRate then
                incomeRate = self.systems.contracts:getTotalIncomeRate()
            end
            if incomeRate > 0 then
                self.theme:drawText("+" .. formatNumber(incomeRate) .. "/sec", hudX + 12, hudY + 38, self.theme:getColor("info"))
            end
        end
        
        -- Draw floating deltas
        for resource, anim in pairs(self.hudAnimations) do
            for _, delta in ipairs(anim.deltas) do
                if delta.alpha > 0 then
                    local color = delta.value > 0 and self.theme:getColor("success") or self.theme:getColor("error")
                    color = {color[1], color[2], color[3], delta.alpha}
                    
                    local deltaText = (delta.value > 0 and "+" or "") .. formatNumber(delta.value)
                    local deltaX = hudX + (resource == "money" and 12 or resource == "reputation" and 120 or 220)
                    local deltaY = hudY + 18 + delta.yOffset
                    
                    love.graphics.setColor(color[1], color[2], color[3], color[4])
                    love.graphics.print(deltaText, deltaX, deltaY)
                end
            end
        end
    else
        self.theme:drawText("$0", hudX + 12, hudY + 18, self.theme:getColor("success"))
    end

    -- Draw toasts
    self:drawToasts()

    -- FPS toggle display
    if self.showFPS then
        self.theme:drawText("FPS: " .. (love.timer and love.timer.getFPS() or 60), hudX + 12, hudY + 62, self.theme:getColor("warning"))
    end

    -- Draw terminal overlay if active
    if self.showFullTerminal then
        self:drawTerminal()
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

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw toast notifications
function UIManager:drawToasts()
    if not love or not love.graphics then return end
    
    local w, h = love.graphics.getDimensions()
    local toastX = w - 320
    local toastY = 120
    local toastSpacing = 60
    
    for i, toast in ipairs(self.toasts) do
        local y = toastY + (i - 1) * toastSpacing + toast.yOffset
        
        -- Toast background
        local bgColor = {0.1, 0.1, 0.1, 0.9 * toast.alpha}
        if toast.type == "success" then
            bgColor = {0.1, 0.6, 0.1, 0.9 * toast.alpha}
        elseif toast.type == "error" then
            bgColor = {0.6, 0.1, 0.1, 0.9 * toast.alpha}
        elseif toast.type == "warning" then
            bgColor = {0.6, 0.6, 0.1, 0.9 * toast.alpha}
        end
        
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        love.graphics.rectangle("fill", toastX, y, 300, 50, 5, 5)
        
        -- Toast text
        love.graphics.setColor(1, 1, 1, toast.alpha)
        love.graphics.printf(toast.message, toastX + 10, y + 15, 280, "left")
    end
end

-- Draw terminal overlay
function UIManager:drawTerminal()
    if not love or not love.graphics then return end
    
    local w, h = love.graphics.getDimensions()
    local termW, termH = w * 0.8, h * 0.6
    local termX, termY = (w - termW) / 2, (h - termH) / 2
    
    -- Terminal background
    love.graphics.setColor(0.02, 0.02, 0.03, 0.95)
    love.graphics.rectangle("fill", termX, termY, termW, termH, 8, 8)
    
    -- Terminal border
    love.graphics.setColor(0.1, 0.9, 0.9, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", termX, termY, termW, termH, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Terminal title
    love.graphics.setColor(0.1, 0.9, 0.9, 1)
    love.graphics.printf("SYSTEM LOG", termX + 20, termY + 15, termW - 40, "center")
    
    -- Log entries
    local logStartY = termY + 50
    local logHeight = termH - 100
    local maxVisibleLogs = math.floor(logHeight / self.terminalLineHeight)
    
    local startIndex = math.max(1, #self.logs - maxVisibleLogs + 1 - self.terminalScroll)
    local endIndex = math.min(#self.logs, startIndex + maxVisibleLogs - 1)
    
    for i = startIndex, endIndex do
        local log = self.logs[i]
        local y = logStartY + (i - startIndex) * self.terminalLineHeight
        
        -- Color based on severity
        local color = {0.8, 0.8, 0.8, 1}
        if log.severity == "error" then
            color = {1, 0.3, 0.3, 1}
        elseif log.severity == "warning" then
            color = {1, 1, 0.3, 1}
        elseif log.severity == "success" then
            color = {0.3, 1, 0.3, 1}
        elseif log.severity == "info" then
            color = {0.3, 0.8, 1, 1}
        end
        
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        local logText = "[" .. log.timestamp .. "] " .. log.message
        love.graphics.print(logText, termX + 20, y)
    end
    
    -- Help text
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.printf("TAB: Close • ↑/↓: Scroll", termX + 20, termY + termH - 30, termW - 40, "center")
end

function UIManager:mousepressed(x, y, button)
    -- Handle UI clicks
    return false
end

function UIManager:keypressed(key)
    if key == "f" then
        self.showFPS = not self.showFPS
        return true
    end
    
    if key == "tab" then
        -- Toggle the large terminal overlay
        self.showFullTerminal = not self.showFullTerminal
        self:addLogMessage("Terminal overlay " .. (self.showFullTerminal and "shown" or "hidden"), "info")
        return true
    end
    
    -- Handle terminal scrolling when terminal is open
    if self.showFullTerminal then
        if key == "up" then
            self.terminalScroll = math.min(self.terminalScroll + 1, math.max(0, #self.logs - 10))
            return true
        elseif key == "down" then 
            self.terminalScroll = math.max(self.terminalScroll - 1, 0)
            return true
        elseif key == "pageup" then
            self.terminalScroll = math.min(self.terminalScroll + 10, math.max(0, #self.logs - 10))
            return true
        elseif key == "pagedown" then
            self.terminalScroll = math.max(self.terminalScroll - 10, 0)
            return true
        elseif key == "home" then
            self.terminalScroll = math.max(0, #self.logs - 10)
            return true
        elseif key == "end" then
            self.terminalScroll = 0
            return true
        end
    end
    
    if self.modal then
        -- Close modal on any key
        local onClose = self.modal.onClose
        self.modal = nil
        if onClose then onClose() end
        return true
    end
    
    return false
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
    
    body = body .. "\nPress any key to continue..."
    
    self.modal = { title = title, body = body, onClose = onClose }
end

function UIManager:resize(w, h)
    -- Handle window resize
end

return UIManager