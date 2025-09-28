-- Crisis Response Mode - Real-time Incident Management
-- Real-time operations mode for handling security incidents

local Notifier = require("src.utils.notifier")

local AdminMode = {}
AdminMode.__index = AdminMode

-- Create new admin mode
function AdminMode.new(systems)
    local self = setmetatable({}, AdminMode)
    self.systems = systems
    
    -- Crisis Mode state
    self.currentCrisis = nil
    self.crisisTimer = 0
    self.responseLog = {}
    
    -- Sample crisis scenario (TODO: Move to dedicated Crisis System)
    self.sampleCrisis = {
        id = "phishing_campaign_001",
        title = "PHISHING CAMPAIGN DETECTED",
        description = "Targeted phishing emails detected across client network",
        severity = "HIGH",
        timeLimit = 300, -- 5 minutes to respond
        stages = {
            {
                name = "Initial Detection",
                description = "Unusual email traffic patterns detected",
                complete = true
            },
            {
                name = "Analysis Required",
                description = "Determine scope and impact of phishing campaign",
                complete = false,
                options = {
                    {key = "1", action = "Deploy Incident Responder", cost = "specialist_time"},
                    {key = "2", action = "Run Automated Analysis", cost = "processing_power"},
                    {key = "3", action = "Manual Investigation", cost = "time"}
                }
            },
            {
                name = "Containment",
                description = "Block malicious emails and quarantine affected systems",
                complete = false
            }
        }
    }
    
    return self
end

function AdminMode:update(dt)
    -- Update crisis timer if in crisis
    if self.currentCrisis then
        self.crisisTimer = self.crisisTimer + dt
        
        -- Check for crisis timeout
        if self.crisisTimer >= self.currentCrisis.timeLimit then
            self:resolveCrisis("timeout")
        end
    end
end

function AdminMode:draw()
    -- Get terminal theme from UI manager
    local theme = self.systems.ui.theme
    
    -- Draw crisis mode header with special styling
    local contentY = theme:drawHeader("🚨 CRISIS RESPONSE CENTER 🚨", "Real-time Incident Management System")
    
    local y = contentY + 20
    
    -- Show current crisis or status
    if self.currentCrisis then
        -- Active crisis display with high alert styling
        theme:drawPanel(20, y, 980, 300, "🚨 ACTIVE INCIDENT - CODE RED")
        local crisisY = y + 25
        
        theme:drawText("INCIDENT:", 30, crisisY, theme:getColor("danger"))
        theme:drawText(self.currentCrisis.title, 150, crisisY, theme:getColor("warning"))
        crisisY = crisisY + 20
        
        theme:drawText("SEVERITY:", 30, crisisY, theme:getColor("danger"))
        theme:drawText(self.currentCrisis.severity, 150, crisisY, theme:getColor("danger"))
        crisisY = crisisY + 20
        
        theme:drawText("DETAILS:", 30, crisisY, theme:getColor("secondary"))
        theme:drawText(self.currentCrisis.description, 150, crisisY, theme:getColor("primary"))
        crisisY = crisisY + 30
        
        -- Time remaining with urgent styling
        local timeRemaining = math.max(0, self.currentCrisis.timeLimit - self.crisisTimer)
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        local timeColor = timeRemaining < 60 and theme:getColor("danger") or theme:getColor("warning")
        
        theme:drawText("TIME REMAINING:", 30, crisisY, theme:getColor("secondary"))
        theme:drawText(minutes .. ":" .. string.format("%02d", seconds), 200, crisisY, timeColor)
        
        -- Show crisis stages
        y = y + 320
        theme:drawPanel(20, y, 980, 200, "INCIDENT RESPONSE PROTOCOL")
        local stageY = y + 25
        
        for i, stage in ipairs(self.currentCrisis.stages) do
            local statusIcon = stage.complete and "[✓]" or "[○]"
            local statusColor = stage.complete and theme:getColor("success") or theme:getColor("warning")
            
            theme:drawText(statusIcon, 30, stageY, statusColor)
            theme:drawText(stage.name, 60, stageY, theme:getColor("secondary"))
            stageY = stageY + 15
            theme:drawText(stage.description, 60, stageY, theme:getColor("dimmed"))
            stageY = stageY + 20
            
            -- Show options for current stage
            if not stage.complete and stage.options then
                theme:drawText("RESPONSE OPTIONS:", 60, stageY, theme:getColor("accent"))
                stageY = stageY + 15
                for _, option in ipairs(stage.options) do
                    theme:drawText("[" .. option.key .. "]", 70, stageY, theme:getColor("warning"))
                    theme:drawText(option.action .. " (Cost: " .. option.cost .. ")", 110, stageY, theme:getColor("primary"))
                    stageY = stageY + 15
                end
                break -- Only show options for first incomplete stage
            end
        end
        
    else
        -- Monitoring mode display
        theme:drawPanel(20, y, 480, 250, "🔍 MONITORING STATUS")
        local monitorY = y + 25
        
        theme:drawText("SYSTEM STATUS:", 30, monitorY, theme:getColor("secondary"))
        theme:drawText("ALL SYSTEMS OPERATIONAL", 200, monitorY, theme:getColor("success"))
        monitorY = monitorY + 30
        
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
        
        y = y + 270
    end
    
    -- Response log panel
    if #self.responseLog > 0 then
        theme:drawPanel(20, y, 980, 120, "📝 RESPONSE LOG")
        local logY = y + 25
        
        for i = math.max(1, #self.responseLog - 4), #self.responseLog do
            local logColor = theme:getColor("dimmed")
            if string.find(self.responseLog[i], "ERROR") then
                logColor = theme:getColor("danger")
            elseif string.find(self.responseLog[i], "SUCCESS") then
                logColor = theme:getColor("success")
            end
            
            theme:drawText("> " .. self.responseLog[i], 30, logY, logColor)
            logY = logY + 15
        end
    end
    
    -- Status bar with crisis mode controls
    local statusText = self.currentCrisis and 
        "CRISIS ACTIVE | [1-3] Response Options | Press [A] to return to Idle Mode" or
        "MONITORING | [C] Simulate Crisis | [A] Return to Idle Mode"
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
    -- Handle crisis mode specific keys
    if self.currentCrisis then
        -- Handle response options during crisis
        if key == "1" or key == "2" or key == "3" then
            self:handleCrisisResponse(key)
        end
    else
        -- No active crisis
        if key == "c" then
            self:startCrisis()
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

-- Start a crisis scenario
function AdminMode:startCrisis()
    if self.currentCrisis then return end
    
    self.currentCrisis = {}
    for k, v in pairs(self.sampleCrisis) do
        self.currentCrisis[k] = v
    end
    
    -- Deep copy stages
    self.currentCrisis.stages = {}
    for i, stage in ipairs(self.sampleCrisis.stages) do
        self.currentCrisis.stages[i] = {}
        for k, v in pairs(stage) do
            self.currentCrisis.stages[i][k] = v
        end
    end
    
    self.crisisTimer = 0
    table.insert(self.responseLog, "🚨 CRISIS INITIATED: " .. self.currentCrisis.title)
    
    Notifier.notify(self.systems.eventBus, self.systems.ui, "🚨 Crisis started: " .. self.currentCrisis.title, "warning")
end

-- Handle crisis response
function AdminMode:handleCrisisResponse(key)
    if not self.currentCrisis then return end
    
    -- Find current stage
    local currentStage = nil
    local stageIndex = nil
    
    for i, stage in ipairs(self.currentCrisis.stages) do
        if not stage.complete then
            currentStage = stage
            stageIndex = i
            break
        end
    end
    
    if not currentStage or not currentStage.options then return end
    
    -- Find selected option
    local selectedOption = nil
    for _, option in ipairs(currentStage.options) do
        if option.key == key then
            selectedOption = option
            break
        end
    end
    
    if selectedOption then
        -- Execute response
        table.insert(self.responseLog, "▶️ RESPONSE: " .. selectedOption.action)
        
        -- Mark current stage as complete
        currentStage.complete = true
        
        -- Award mission tokens for successful response
        self.systems.eventBus:publish("add_resource", {
            resource = "missionTokens",
            amount = 1
        })
        
        -- Check if all stages complete
        local allComplete = true
        for _, stage in ipairs(self.currentCrisis.stages) do
            if not stage.complete then
                allComplete = false
                break
            end
        end
        
        if allComplete then
            self:resolveCrisis("success")
        end
    end
end

-- Resolve crisis
function AdminMode:resolveCrisis(outcome)
    if not self.currentCrisis then return end
    
    local timeBonus = 1.0
    if outcome == "success" then
        -- Calculate time bonus (faster resolution = better rewards)
        local timeUsed = self.crisisTimer
        local timeLimit = self.currentCrisis.timeLimit
        timeBonus = math.max(0.5, (timeLimit - timeUsed) / timeLimit + 0.5)
        
        local baseReward = {
            reputation = 15,
            money = 8000,
            missionTokens = 2
        }
        
        -- Apply time bonus
        local reputationGain = math.floor(baseReward.reputation * timeBonus)
        local moneyGain = math.floor(baseReward.money * timeBonus)
        local tokenGain = baseReward.missionTokens
        
        table.insert(self.responseLog, "✅ CRISIS RESOLVED SUCCESSFULLY")
        table.insert(self.responseLog, string.format("⏱️ Response Time: %.1fs (%.0f%% efficiency)", timeUsed, timeBonus * 100))
        table.insert(self.responseLog, string.format("💰 Earned: $%d, +%d reputation, +%d tokens", moneyGain, reputationGain, tokenGain))
        
        -- Award scaled rewards
        self.systems.eventBus:publish("add_resource", {
            resource = "reputation",
            amount = reputationGain
        })
        
        self.systems.eventBus:publish("add_resource", {
            resource = "money", 
            amount = moneyGain
        })
        
        self.systems.eventBus:publish("add_resource", {
            resource = "missionTokens",
            amount = tokenGain
        })
        
        Notifier.notify(self.systems.eventBus, self.systems.ui, string.format("✅ Crisis resolved! +$%d, +%d reputation, +%d tokens (%.0f%% efficiency)", 
              moneyGain, reputationGain, tokenGain, timeBonus * 100), "success")
        
    elseif outcome == "timeout" then
        table.insert(self.responseLog, "❌ CRISIS TIMED OUT - REPUTATION DAMAGE")
        table.insert(self.responseLog, "⚠️ Client confidence decreased")
        
        -- Penalty for timeout
        self.systems.eventBus:publish("add_resource", {
            resource = "reputation",
            amount = -5
        })
        
        Notifier.notify(self.systems.eventBus, self.systems.ui, "❌ Crisis timed out! -5 reputation", "error")
    end
    
    self.currentCrisis = nil
    self.crisisTimer = 0
end

return AdminMode