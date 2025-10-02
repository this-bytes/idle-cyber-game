-- Crisis Response Mode - Real-time Incident Management
-- Real-time operations mode for handling security incidents

local AdminMode = {}
AdminMode.__index = AdminMode

-- Create new admin mode
function AdminMode.new(systems)
    local self = setmetatable({}, AdminMode)
    self.systems = systems
    
    -- Crisis Mode state
    self.responseLog = {}
    
    -- Subscribe to specialist level-up events
    if self.systems.eventBus then
        self.systems.eventBus:subscribe("specialist_leveled_up", function(data)
            local message = string.format("⭐ %s leveled up to Level %d!", 
                data.specialist.name, data.newLevel)
            table.insert(self.responseLog, message)
        end)
        
        -- Subscribe to crisis completion events
        self.systems.eventBus:subscribe("crisis_completed", function(data)
            local outcomeText = {
                success = "✅ CRISIS RESOLVED SUCCESSFULLY",
                partial = "⚠️ CRISIS PARTIALLY RESOLVED",
                failure = "❌ CRISIS RESPONSE FAILED",
                timeout = "⏰ CRISIS TIMEOUT - RESPONSE FAILED"
            }
            table.insert(self.responseLog, outcomeText[data.outcome] or "CRISIS ENDED")
            table.insert(self.responseLog, string.format("💰 Rewards: $%d | 🌟 Reputation: %+d | 📈 XP: %d",
                data.moneyAwarded or 0, data.reputationChange or 0, data.xpAwarded or 0))
        end)
    end
    
    return self
end

function AdminMode:update(dt)
    -- Update crisis system timer
    if self.systems.crisis then
        -- Crisis system handles its own timing
        -- We just need to check if crisis ended
        local activeCrisis = self.systems.crisis:getActiveCrisis()
        if activeCrisis ~= self.lastActiveCrisis then
            if activeCrisis and not self.lastActiveCrisis then
                -- New crisis started
                table.insert(self.responseLog, "🚨 CRISIS INITIATED: " .. activeCrisis.name)
            elseif not activeCrisis and self.lastActiveCrisis then
                -- Crisis ended
                table.insert(self.responseLog, "✅ CRISIS RESOLVED")
            end
            self.lastActiveCrisis = activeCrisis
        end
    end
end

function AdminMode:draw()
    -- Get terminal theme from UI manager
    local theme = self.systems.uiManager.theme
    
    -- Draw crisis mode header with special styling
    local contentY = theme:drawHeader("🚨 CRISIS RESPONSE CENTER 🚨", "Real-time Incident Management System")
    
    local y = contentY + 20
    
    -- Get current crisis from crisis system
    local currentCrisis = self.systems.crisis and self.systems.crisis:getActiveCrisis() or nil
    
    -- Show current crisis or status
    if currentCrisis then
        -- Active crisis display with high alert styling
        theme:drawPanel(20, y, 980, 350, "🚨 ACTIVE INCIDENT - CODE RED")
        local crisisY = y + 25
        
        -- Crisis header info in terminal style
        theme:drawText("╔═══════════════════════════════════════════════════════════════════╗", 30, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 15
        theme:drawText("║ INCIDENT:", 30, crisisY, theme:getColor("danger"))
        theme:drawText(currentCrisis.name, 150, crisisY, theme:getColor("warning"))
        theme:drawText("║", 680, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 15
        
        theme:drawText("║ SEVERITY:", 30, crisisY, theme:getColor("danger"))
        theme:drawText(string.upper(currentCrisis.severity), 150, crisisY, theme:getColor("danger"))
        theme:drawText("║", 680, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 15
        
        theme:drawText("║ THREAT ID:", 30, crisisY, theme:getColor("secondary"))
        theme:drawText(currentCrisis.id or "N/A", 150, crisisY, theme:getColor("dimmed"))
        theme:drawText("║", 680, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 15
        
        -- Time remaining with urgent styling
        local timeRemaining = self.systems.crisis:getTimeRemaining()
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        local timeColor = timeRemaining < 60 and theme:getColor("danger") or theme:getColor("warning")
        
        theme:drawText("║ TIME LEFT:", 30, crisisY, theme:getColor("secondary"))
        theme:drawText(minutes .. ":" .. string.format("%02d", seconds), 150, crisisY, timeColor)
        theme:drawText("║", 680, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 15
        theme:drawText("╚═══════════════════════════════════════════════════════════════════╝", 30, crisisY, theme:getColor("danger"))
        
        -- Show crisis stages
        y = y + 370
        theme:drawPanel(20, y, 980, 250, "📋 INCIDENT RESPONSE PROTOCOL")
        local stageY = y + 25
        
        for i, stage in ipairs(currentCrisis.stages) do
            local statusIcon = stage.completed and "[✓]" or "[○]"
            local statusColor = stage.completed and theme:getColor("success") or theme:getColor("warning")
            
            theme:drawText(statusIcon, 30, stageY, statusColor)
            theme:drawText(string.format("%d. %s", i, stage.name), 60, stageY, theme:getColor("secondary"))
            stageY = stageY + 15
            
            -- Show description
            theme:drawText("   " .. stage.description, 60, stageY, theme:getColor("dimmed"))
            stageY = stageY + 15
            
            -- Show options for current stage
            if not stage.completed and stage.options then
                theme:drawText("   ┌─ RESPONSE OPTIONS:", 60, stageY, theme:getColor("accent"))
                stageY = stageY + 15
                for optIdx, option in ipairs(stage.options) do
                    theme:drawText("   │ [" .. optIdx .. "]", 70, stageY, theme:getColor("warning"))
                    theme:drawText(option.text, 110, stageY, theme:getColor("primary"))
                    if option.description then
                        theme:drawText("(" .. option.description .. ")", 320, stageY, theme:getColor("dimmed"))
                    end
                    stageY = stageY + 15
                end
                theme:drawText("   └─", 60, stageY, theme:getColor("accent"))
                stageY = stageY + 10
                break -- Only show options for first incomplete stage
            end
            stageY = stageY + 5
        end
        
        -- Risk assessment panel
        theme:drawPanel(520, y, 480, 250, "⚠️ THREAT ASSESSMENT")
        local riskY = y + 25
        
        local contractStats = self.systems.contracts:getStats()
        theme:drawText("RISK SOURCES:", 530, riskY, theme:getColor("secondary"))
        riskY = riskY + 20
        theme:drawText("ACTIVE CONTRACTS:", 540, riskY, theme:getColor("dimmed"))
        theme:drawText(tostring(contractStats.activeContracts or 0), 720, riskY, theme:getColor("warning"))
        riskY = riskY + 15
        theme:drawText("EXPOSURE LEVEL:", 540, riskY, theme:getColor("dimmed"))
        
        -- Show team readiness
        local specialistStats = self.systems.specialists:getStats()
        local teamBonuses = self.systems.specialists:getTeamBonuses()
        
        theme:drawText("TEAM READINESS:", 30, monitorY, theme:getColor("secondary"))
        monitorY = monitorY + 20
        theme:drawText("SPECIALISTS:", 40, monitorY, theme:getColor("dimmed"))
        theme:drawText(specialistStats.available .. "/" .. specialistStats.total .. " ready", 200, monitorY, theme:getColor("primary"))
        monitorY = monitorY + 15
        theme:drawText("EFFICIENCY:", 40, monitorY, theme:getColor("dimmed"))
        theme:drawText(string.format("%.1fx", teamBonuses.efficiency), 200, monitorY, theme:getColor("accent"))
        monitorY = monitorY + 15
        theme:drawText("RESPONSE SPEED:", 40, monitorY, theme:getColor("dimmed"))
        theme:drawText(string.format("%.1fx", teamBonuses.speed), 200, monitorY, theme:getColor("accent"))
        monitorY = monitorY + 15
        theme:drawText("DEFENSE RATING:", 40, monitorY, theme:getColor("dimmed"))
        theme:drawText(string.format("%.1fx", teamBonuses.defense), 200, monitorY, theme:getColor("accent"))
        
        -- Risk assessment panel
        theme:drawPanel(520, y, 480, 250, "⚠️ THREAT ASSESSMENT")
        local riskY = y + 25
        
        local contractStats = self.systems.contracts:getStats()
        theme:drawText("RISK SOURCES:", 530, riskY, theme:getColor("secondary"))
        riskY = riskY + 20
        theme:drawText("ACTIVE CONTRACTS:", 540, riskY, theme:getColor("dimmed"))
        theme:drawText(tostring(contractStats.activeContracts or 0), 720, riskY, theme:getColor("warning"))
        riskY = riskY + 15
        theme:drawText("EXPOSURE LEVEL:", 540, riskY, theme:getColor("dimmed"))
        theme:drawText("MEDIUM", 720, riskY, theme:getColor("warning"))
        riskY = riskY + 30
        
        theme:drawText("SIMULATION:", 530, riskY, theme:getColor("accent"))
        riskY = riskY + 20
        theme:drawText("Press [C] to simulate crisis scenario", 540, riskY, theme:getColor("primary"))
        
        -- Specialist roster panel with XP bars
        y = y + 270
        theme:drawPanel(20, y, 980, 180, "👥 SPECIALIST ROSTER")
        local rosterY = y + 25
        
        local allSpecialists = self.systems.specialists:getAllSpecialists()
        local specialistCount = 0
        for specialistId, specialist in pairs(allSpecialists) do
            if specialistCount < 4 then -- Show first 4 specialists
                -- Draw specialist info
                theme:drawText(specialist.name, 30, rosterY, theme:getColor("primary"))
                
                -- Draw level
                theme:drawText("Lv." .. (specialist.level or 1), 250, rosterY, theme:getColor("accent"))
                
                -- Draw XP bar
                local xp = specialist.xp or 0
                local nextLevelXp = self.systems.specialists:getXpForNextLevel(specialist.level or 1)
                
                if nextLevelXp then
                    local xpPercent = math.min(1.0, xp / nextLevelXp)
                    local barWidth = 150
                    local barHeight = 10
                    
                    -- Background
                    love.graphics.setColor(0.2, 0.2, 0.2, 1)
                    love.graphics.rectangle("fill", 320, rosterY + 3, barWidth, barHeight)
                    
                    -- Filled portion
                    love.graphics.setColor(0.3, 0.8, 0.3, 1)
                    love.graphics.rectangle("fill", 320, rosterY + 3, barWidth * xpPercent, barHeight)
                    
                    -- Border
                    love.graphics.setColor(0.5, 0.5, 0.5, 1)
                    love.graphics.rectangle("line", 320, rosterY + 3, barWidth, barHeight)
                    
                    -- XP text
                    theme:drawText(xp .. "/" .. nextLevelXp .. " XP", 480, rosterY, theme:getColor("dimmed"))
                else
                    theme:drawText("MAX LEVEL", 320, rosterY, theme:getColor("success"))
                end
                
                -- Status
                local statusText = specialist.status == "available" and "✓ Ready" or "⏳ Busy"
                local statusColor = specialist.status == "available" and theme:getColor("success") or theme:getColor("warning")
                theme:drawText(statusText, 650, rosterY, statusColor)
                
                rosterY = rosterY + 18
                specialistCount = specialistCount + 1
            end
        end
        
        y = y + 200
    else
        -- Monitoring mode display
        theme:drawPanel(20, y, 480, 250, "🔍 MONITORING STATUS")
        local monitorY = y + 25
        
        theme:drawText("SYSTEM STATUS:", 30, monitorY, theme:getColor("secondary"))
        theme:drawText("ALL SYSTEMS OPERATIONAL", 200, monitorY, theme:getColor("success"))
        monitorY = monitorY + 30
        theme:drawText("Press [C] to simulate crisis scenario", 30, monitorY, theme:getColor("primary"))
        
        y = y + 270
    end
    
    -- Response log panel with terminal-style formatting
    if #self.responseLog > 0 then
        theme:drawPanel(20, y, 980, 150, "📝 RESPONSE LOG")
        local logY = y + 25
        
        theme:drawText("┌─ RECENT ACTIVITY ─────────────────────────────────────────────────┐", 30, logY, theme:getColor("border"))
        logY = logY + 15
        
        for i = math.max(1, #self.responseLog - 6), #self.responseLog do
            local logColor = theme:getColor("dimmed")
            local prefix = "│ "
            
            if string.find(self.responseLog[i], "ERROR") then
                logColor = theme:getColor("danger")
                prefix = "│ [ERR] "
            elseif string.find(self.responseLog[i], "SUCCESS") or string.find(self.responseLog[i], "✅") then
                logColor = theme:getColor("success")
                prefix = "│ [OK]  "
            elseif string.find(self.responseLog[i], "🚨") or string.find(self.responseLog[i], "CRISIS") then
                logColor = theme:getColor("warning")
                prefix = "│ [!!!] "
            end
            
            theme:drawText(prefix .. self.responseLog[i], 30, logY, logColor)
            logY = logY + 15
        end
        
        theme:drawText("└───────────────────────────────────────────────────────────────────┘", 30, logY, theme:getColor("border"))
    end
    
    -- Status bar with crisis mode controls
    local currentCrisis = self.systems.crisis and self.systems.crisis:getActiveCrisis() or nil
    local statusText = currentCrisis and 
        "CRISIS ACTIVE | [1-3] Response Options | [A] Return to Idle Mode" or
        "MONITORING | [C] Simulate Crisis | [H] Help | [A] Return to Idle Mode | [TAB] Toggle Modes"
    theme:drawStatusBar(statusText)

    -- Admin editor quick-controls (visible in Admin Mode)
    local w, h = love.graphics.getDimensions()
    local x = w - 360
    local y = 20
    theme:drawPanel(x, y, 340, 140, "⚙️ ADMIN DATA EDITOR")
    local innerY = y + 30
    theme:drawText("[R] Reload data from JSON", x + 10, innerY, theme:getColor("accent"))
    innerY = innerY + 18
    theme:drawText("[S] Save current data to JSON", x + 10, innerY, theme:getColor("accent"))
    innerY = innerY + 18
    theme:drawText("Open /admin in browser to use UI", x + 10, innerY, theme:getColor("dimmed"))
end

function AdminMode:mousepressed(x, y, button)
    -- Crisis mode focuses on keyboard interactions
    -- Mouse clicking could be used for specialist deployment in future
    return false
end

function AdminMode:keypressed(key)
    -- Get current crisis status
    local currentCrisis = self.systems.crisis and self.systems.crisis:getActiveCrisis() or nil
    
    -- Handle crisis mode specific keys
    if currentCrisis then
        -- Handle response options during crisis
        if key == "1" or key == "2" or key == "3" then
            self:handleCrisisResponse(key)
        end
    else
        -- No active crisis
        if key == "c" then
            self:startCrisis()
        elseif key == "h" then
            -- Show help information
            self:showHelp()
        end
        -- Admin quick keys
        if key == "r" then
            -- Reload JSON data modules
            local ok1, err1 = pcall(function()
                local defs = require("src.data.defs")
                if defs and defs.reloadFromJSON then defs.reloadFromJSON() end
            end)
            local ok2, err2 = pcall(function()
                local contracts = require("src.data.contracts")
                if contracts and contracts.reloadFromJSON then contracts.reloadFromJSON() end
            end)
            table.insert(self.responseLog, "🔁 Reloaded data: defs=" .. tostring(ok1) .. ", contracts=" .. tostring(ok2))
        elseif key == "s" then
            -- Save current in-memory data to JSON
            local ok1, err1 = pcall(function()
                local defs = require("src.data.defs")
                if defs and defs.saveToJSON then defs.saveToJSON() end
            end)
            local ok2, err2 = pcall(function()
                local contracts = require("src.data.contracts")
                if contracts and contracts.saveToJSON then contracts.saveToJSON() end
            end)
            table.insert(self.responseLog, "💾 Saved data: defs=" .. tostring(ok1) .. ", contracts=" .. tostring(ok2))
        end
    end
end

-- Show help information
function AdminMode:showHelp()
    table.insert(self.responseLog, "╔══════════════════════════════════════════════════════════════════╗")
    table.insert(self.responseLog, "║ ADMIN MODE HELP SYSTEM")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ KEY BINDINGS:")
    table.insert(self.responseLog, "║ [C] - Start crisis simulation")
    table.insert(self.responseLog, "║ [H] - Show this help")
    table.insert(self.responseLog, "║ [A] - Return to Idle Mode")
    table.insert(self.responseLog, "║ [TAB] - Toggle between modes")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ ADMIN TOOLS:")
    table.insert(self.responseLog, "║ [R] - Reload JSON data")
    table.insert(self.responseLog, "║ [S] - Save data to JSON")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ CRISIS RESPONSE:")
    table.insert(self.responseLog, "║ [1-3] - Select response options during crisis")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ For web admin interface: open /admin in browser")
    table.insert(self.responseLog, "╚══════════════════════════════════════════════════════════════════╝")
    print("📚 Admin mode help displayed")
end

-- Mode lifecycle methods
function AdminMode:enter()
    table.insert(self.responseLog, "🚨 ADMIN MODE ACTIVATED")
    table.insert(self.responseLog, "🔍 SOC monitoring systems online")
    table.insert(self.responseLog, "📚 Press [H] for help or [C] to start crisis simulation")
    print("🚨 Entering Admin Mode - Crisis Response Center")
end

function AdminMode:exit()
    table.insert(self.responseLog, "👋 EXITING ADMIN MODE")
    -- Reset crisis if leaving mid-crisis (optional)
    local currentCrisis = self.systems.crisis:getActiveCrisis()
    if currentCrisis then
        table.insert(self.responseLog, "⚠️ Crisis abandoned - returning to monitoring")
        self.systems.crisis:resolveCrisis("failure")
    end
    print("👋 Exiting Admin Mode")
end

-- Start a crisis scenario
function AdminMode:startCrisis()
    local currentCrisis = self.systems.crisis:getActiveCrisis()
    if currentCrisis then return end
    
    -- Start a random crisis from available definitions
    local crisisDefinitions = self.systems.crisis:getAllCrisisDefinitions()
    local crisisIds = {}
    for id, _ in pairs(crisisDefinitions) do
        table.insert(crisisIds, id)
    end
    
    if #crisisIds > 0 then
        local randomId = crisisIds[math.random(#crisisIds)]
        self.systems.crisis:startCrisis(randomId)
    else
        table.insert(self.responseLog, "⚠️ No crisis definitions available")
    end
end

-- Handle crisis response
function AdminMode:handleCrisisResponse(key)
    local currentCrisis = self.systems.crisis:getActiveCrisis()
    if not currentCrisis then return end
    
    -- Get current stage
    local currentStage = self.systems.crisis:getCurrentStage()
    if not currentStage or not currentStage.options then return end
    
    -- Convert key to number (1, 2, 3 -> 1, 2, 3)
    local optionIndex = tonumber(key)
    if not optionIndex or optionIndex < 1 or optionIndex > #currentStage.options then
        return
    end
    
    local selectedOption = currentStage.options[optionIndex]
    if selectedOption then
        -- Execute response
        local timestamp = os.date("[%H:%M:%S]")
        table.insert(self.responseLog, timestamp .. " EXECUTING: " .. selectedOption.text)
        
        -- Get CEO to deploy
        local ceo = self.systems.specialists:getSpecialist(0)
        if ceo then
            -- Use ability through crisis system
            local success, effectiveness = self.systems.crisis:useAbility(
                0, -- CEO id
                selectedOption.requiredAbility or "basic_analysis",
                currentStage.id,
                ceo.abilities or {}
            )
            
            if success then
                table.insert(self.responseLog, timestamp .. " STAGE COMPLETE - Effectiveness: " .. string.format("%.0f%%", effectiveness * 100))
            end
        end
        
        -- Award mission tokens for response
        self.systems.eventBus:publish("add_resource", {
            resource = "missionTokens",
            amount = 1
        })
    end
end

return AdminMode
