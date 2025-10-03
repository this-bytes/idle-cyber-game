-- Incident Response Mode - Real-time Incident Management
-- Real-time operations mode for handling security incidents

local SmartUIManager = require("src.ui.smart_ui_manager")

local AdminMode = {}
AdminMode.__index = AdminMode

-- Create new admin mode
function AdminMode.new()
    local self = setmetatable({}, AdminMode)
    self.systems = nil -- Will be injected by SceneManager
    self.uiManager = nil -- Will be initialized in enter()
    
    -- Incident Mode state
    self.responseLog = {}
    
    return self
end

-- Enter the admin mode scene
function AdminMode:enter(data)
    -- Initialize Smart UI Manager
    self.uiManager = SmartUIManager.new(self.systems.eventBus, self.systems.resourceManager)
    self.uiManager:initialize()
    
    -- Subscribe to specialist level-up events
    if self.systems and self.systems.eventBus then
        self.systems.eventBus:subscribe("specialist_leveled_up", function(data)
            local message = string.format("⭐ %s leveled up to Level %d!", 
                data.specialist.name, data.newLevel)
            table.insert(self.responseLog, message)
        end)
        
        -- Subscribe to Incident completion events
        self.systems.eventBus:subscribe("Incident_completed", function(data)
            local outcomeText = {
                success = "✅ Incident RESOLVED SUCCESSFULLY",
                partial = "⚠️ Incident PARTIALLY RESOLVED",
                failure = "❌ Incident RESPONSE FAILED",
                timeout = "⏰ Incident TIMEOUT - RESPONSE FAILED"
            }
            table.insert(self.responseLog, outcomeText[data.outcome] or "Incident ENDED")
            table.insert(self.responseLog, string.format("💰 Rewards: $%d | 🌟 Reputation: %+d | 📈 XP: %d",
                data.moneyAwarded or 0, data.reputationChange or 0, data.xpAwarded or 0))
        end)
    end
end

function AdminMode:update(dt)
    -- Update Incident system timer
    if self.systems.Incident then
        -- Incident system handles its own timing
        -- We just need to check if Incident ended
        local activeIncident = self.systems.Incident:getActiveIncident()
        if activeIncident ~= self.lastActiveIncident then
            if activeIncident and not self.lastActiveIncident then
                -- New Incident started
                table.insert(self.responseLog, "🚨 Incident INITIATED: " .. activeIncident.name)
            elseif not activeIncident and self.lastActiveIncident then
                -- Incident ended
                table.insert(self.responseLog, "✅ Incident RESOLVED")
            end
            self.lastActiveIncident = activeIncident
        end
    end
end

function AdminMode:draw()
    if not self.uiManager then
        -- uiManager is not ready, draw a loading message or just return
        love.graphics.print("Loading Admin Mode...", 10, 10)
        return
    end
    
    -- Get terminal theme from UI manager
    local theme = self.uiManager.theme
    
    -- Draw Incident mode header with special styling
    local contentY = theme:drawHeader("🚨 Incident RESPONSE CENTER 🚨", "Real-time Incident Management System")
    
    local y = contentY + 20
    
    -- Get current Incident from Incident system
    local currentIncident = self.systems.Incident and self.systems.Incident:getActiveIncident() or nil
    
    -- Show current Incident or status
    if currentIncident then
        -- Active Incident display with high alert styling
        theme:drawPanel(20, y, 980, 350, "🚨 ACTIVE INCIDENT - CODE RED")
        local IncidentY = y + 25
        
        -- Incident header info in terminal style
        theme:drawText("╔═══════════════════════════════════════════════════════════════════╗", 30, IncidentY, theme:getColor("danger"))
        IncidentY = IncidentY + 15
        theme:drawText("║ INCIDENT:", 30, IncidentY, theme:getColor("danger"))
        theme:drawText(currentIncident.name, 150, IncidentY, theme:getColor("warning"))
        theme:drawText("║", 680, IncidentY, theme:getColor("danger"))
        IncidentY = IncidentY + 15
        
        theme:drawText("║ SEVERITY:", 30, IncidentY, theme:getColor("danger"))
        theme:drawText(string.upper(currentIncident.severity), 150, IncidentY, theme:getColor("danger"))
        theme:drawText("║", 680, IncidentY, theme:getColor("danger"))
        IncidentY = IncidentY + 15
        
        theme:drawText("║ THREAT ID:", 30, IncidentY, theme:getColor("secondary"))
        theme:drawText(currentIncident.id or "N/A", 150, IncidentY, theme:getColor("dimmed"))
        theme:drawText("║", 680, IncidentY, theme:getColor("danger"))
        IncidentY = IncidentY + 15
        
        -- Time remaining with urgent styling
        local timeRemaining = self.systems.Incident:getTimeRemaining()
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        local timeColor = timeRemaining < 60 and theme:getColor("danger") or theme:getColor("warning")
        
        theme:drawText("║ TIME LEFT:", 30, IncidentY, theme:getColor("secondary"))
        theme:drawText(minutes .. ":" .. string.format("%02d", seconds), 150, IncidentY, timeColor)
        theme:drawText("║", 680, IncidentY, theme:getColor("danger"))
        IncidentY = IncidentY + 15
        theme:drawText("╚═══════════════════════════════════════════════════════════════════╝", 30, IncidentY, theme:getColor("danger"))
        
        -- Show Incident stages
        y = y + 370
        theme:drawPanel(20, y, 980, 250, "📋 INCIDENT RESPONSE PROTOCOL")
        local stageY = y + 25
        
        for i, stage in ipairs(currentIncident.stages) do
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
        
        local contractStats = nil
        if self.systems.contractSystem and self.systems.contractSystem.getStats then
            contractStats = self.systems.contractSystem:getStats()
        else
            contractStats = { activeContracts = 0 }
        end
        theme:drawText("RISK SOURCES:", 530, riskY, theme:getColor("secondary"))
        riskY = riskY + 20
        theme:drawText("ACTIVE CONTRACTS:", 540, riskY, theme:getColor("dimmed"))
        theme:drawText(tostring(contractStats.activeContracts or 0), 720, riskY, theme:getColor("warning"))
        riskY = riskY + 15
        theme:drawText("EXPOSURE LEVEL:", 540, riskY, theme:getColor("dimmed"))
        
        -- Show team readiness
        local specialistStats = { available = 0, total = 0 }
        local teamBonuses = { efficiency = 1.0, speed = 1.0, defense = 1.0 }
        if self.systems.specialistSystem then
            if self.systems.specialistSystem.getStats then
                specialistStats = self.systems.specialistSystem:getStats()
            end
            if self.systems.specialistSystem.getTeamBonuses then
                teamBonuses = self.systems.specialistSystem:getTeamBonuses()
            end
        end
        
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
        theme:drawText("Press [C] to simulate Incident scenario", 540, riskY, theme:getColor("primary"))
        
        -- Specialist roster panel with XP bars
        y = y + 270
        theme:drawPanel(20, y, 980, 180, "👥 SPECIALIST ROSTER")
        local rosterY = y + 25
        
        local allSpecialists = {}
        if self.systems.specialistSystem and self.systems.specialistSystem.getAllSpecialists then
            allSpecialists = self.systems.specialistSystem:getAllSpecialists()
        end
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
        theme:drawText("Press [C] to simulate Incident scenario", 30, monitorY, theme:getColor("primary"))
        
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
            elseif string.find(self.responseLog[i], "🚨") or string.find(self.responseLog[i], "Incident") then
                logColor = theme:getColor("warning")
                prefix = "│ [!!!] "
            end
            
            theme:drawText(prefix .. self.responseLog[i], 30, logY, logColor)
            logY = logY + 15
        end
        
        theme:drawText("└───────────────────────────────────────────────────────────────────┘", 30, logY, theme:getColor("border"))
    end
    
    -- Status bar with Incident mode controls
    local currentIncident = self.systems.Incident and self.systems.Incident:getActiveIncident() or nil
    local statusText = currentIncident and 
        "Incident ACTIVE | [1-3] Response Options | [A] Return to Idle Mode" or
        "MONITORING | [C] Simulate Incident | [H] Help | [A] Return to Idle Mode | [TAB] Toggle Modes"
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
    -- Incident mode focuses on keyboard interactions
    -- Mouse clicking could be used for specialist deployment in future
    return false
end

function AdminMode:keypressed(key)
    -- Get current Incident status
    local currentIncident = self.systems.Incident and self.systems.Incident:getActiveIncident() or nil
    
    -- Handle Incident mode specific keys
    if currentIncident then
        -- Handle response options during Incident
        if key == "1" or key == "2" or key == "3" then
            self:handleIncidentResponse(key)
        end
    else
        -- No active Incident
        if key == "c" then
            self:startIncident()
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
    table.insert(self.responseLog, "║ [C] - Start Incident simulation")
    table.insert(self.responseLog, "║ [H] - Show this help")
    table.insert(self.responseLog, "║ [A] - Return to Idle Mode")
    table.insert(self.responseLog, "║ [TAB] - Toggle between modes")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ ADMIN TOOLS:")
    table.insert(self.responseLog, "║ [R] - Reload JSON data")
    table.insert(self.responseLog, "║ [S] - Save data to JSON")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ Incident RESPONSE:")
    table.insert(self.responseLog, "║ [1-3] - Select response options during Incident")
    table.insert(self.responseLog, "║")
    table.insert(self.responseLog, "║ For web admin interface: open /admin in browser")
    table.insert(self.responseLog, "╚══════════════════════════════════════════════════════════════════╝")
    print("📚 Admin mode help displayed")
end

-- Mode lifecycle methods
function AdminMode:enter()
    table.insert(self.responseLog, "🚨 ADMIN MODE ACTIVATED")
    table.insert(self.responseLog, "🔍 SOC monitoring systems online")
    table.insert(self.responseLog, "📚 Press [H] for help or [C] to start Incident simulation")
    print("🚨 Entering Admin Mode - Incident Response Center")
end

function AdminMode:exit()
    table.insert(self.responseLog, "👋 EXITING ADMIN MODE")
    -- Reset Incident if leaving mid-Incident (optional)
    local currentIncident = self.systems.Incident:getActiveIncident()
    if currentIncident then
        table.insert(self.responseLog, "⚠️ Incident abandoned - returning to monitoring")
        self.systems.Incident:resolveIncident("failure")
    end
    print("👋 Exiting Admin Mode")
end

-- Start a Incident scenario
function AdminMode:startIncident()
    local currentIncident = self.systems.Incident:getActiveIncident()
    if currentIncident then return end
    
    -- Start a random Incident from available definitions
    local IncidentDefinitions = self.systems.Incident:getAllIncidentDefinitions()
    local IncidentIds = {}
    for id, _ in pairs(IncidentDefinitions) do
        table.insert(IncidentIds, id)
    end
    
    if #IncidentIds > 0 then
        local randomId = IncidentIds[math.random(#IncidentIds)]
        self.systems.Incident:startIncident(randomId)
    else
        table.insert(self.responseLog, "⚠️ No Incident definitions available")
    end
end

-- Handle Incident response
function AdminMode:handleIncidentResponse(key)
    local currentIncident = self.systems.Incident:getActiveIncident()
    if not currentIncident then return end
    
    -- Get current stage
    local currentStage = self.systems.Incident:getCurrentStage()
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
            -- Use ability through Incident system
            local success, effectiveness = self.systems.Incident:useAbility(
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
