-- Admin Mode - "The Admin's Watch" - Crisis Response Mode
-- Real-time operations mode for handling security incidents

local ConfigLoader = require("src.utils.config_loader")

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
    
    -- Config loader for dynamic crisis scenarios
    self.configLoader = ConfigLoader.new()
    
    -- Load crisis definitions from config file
    self.crisisDefinitions = self:loadCrisisConfigurations()
    
    -- Sample crisis scenario (fallback if config loading fails)
    self.sampleCrisis = self:getSampleCrisis()
    
    return self
end

-- Load crisis configurations from JSON file
function AdminMode:loadCrisisConfigurations()
    local configPath = "data/config/crises.json"
    local crises = self.configLoader:loadConfig("crises", configPath)
    
    if not crises then
        print("⚠️ Failed to load crisis config, using fallback crises")
        return {phishing_campaign_001 = self:getSampleCrisis()}
    end
    
    return crises
end

-- Get sample crisis definition (fallback)
function AdminMode:getSampleCrisis()
    return {
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
end

-- Reload crisis configurations from file
function AdminMode:reloadCrisisConfigurations()
    local configPath = "data/config/crises.json"
    local wasUpdated = self.configLoader:checkForUpdates("crises", configPath)
    
    if wasUpdated then
        self.crisisDefinitions = self.configLoader:getConfig("crises")
        print("🔄 Crisis configurations reloaded")
        
        -- If we have an active crisis, update it if the config changed
        if self.currentCrisis then
            local updatedCrisis = self.crisisDefinitions[self.currentCrisis.id]
            if updatedCrisis then
                -- Preserve current progress but update stages and options
                local savedTimer = self.crisisTimer
                self.currentCrisis = self:deepCopy(updatedCrisis)
                self.crisisTimer = savedTimer
                print("🔄 Updated active crisis configuration")
            end
        end
        
        return true
    end
    
    return false
end

-- Deep copy table (for crisis updates)
function AdminMode:deepCopy(original)
    local originalType = type(original)
    local copy
    if originalType == 'table' then
        copy = {}
        for originalKey, originalValue in next, original, nil do
            copy[self:deepCopy(originalKey)] = self:deepCopy(originalValue)
        end
        setmetatable(copy, self:deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Trigger a specific crisis by ID
function AdminMode:triggerCrisis(crisisId)
    local crisisDef = self.crisisDefinitions[crisisId]
    if not crisisDef then
        print("❌ Crisis not found: " .. tostring(crisisId))
        return false
    end
    
    self.currentCrisis = self:deepCopy(crisisDef)
    self.crisisTimer = 0
    self.responseLog = {}
    
    table.insert(self.responseLog, "🚨 CRISIS INITIATED: " .. self.currentCrisis.title)
    print("🚨 Crisis triggered: " .. self.currentCrisis.title)
    return true
end

-- Trigger random crisis for testing
function AdminMode:triggerRandomCrisis()
    local crisisIds = {}
    for id, _ in pairs(self.crisisDefinitions) do
        table.insert(crisisIds, id)
    end
    
    if #crisisIds > 0 then
        local randomId = crisisIds[math.random(#crisisIds)]
        return self:triggerCrisis(randomId)
    end
    
    return false
end

function AdminMode:update(dt)
    -- Check for configuration updates (hot-reload)
    self:reloadCrisisConfigurations()
    
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
    -- Crisis Mode terminal-style UI
    love.graphics.setColor(0, 1, 0) -- Bright green for terminal feel
    love.graphics.print("🚨 CRISIS RESPONSE MODE - \"The Admin's Watch\"", 20, 20)
    love.graphics.setColor(1, 1, 1)
    
    local y = 60
    
    -- Show current crisis or status
    if self.currentCrisis then
        -- Active crisis display
        love.graphics.setColor(1, 0.3, 0.3) -- Red for urgent
        love.graphics.print("🔥 ACTIVE INCIDENT: " .. self.currentCrisis.title, 20, y)
        love.graphics.setColor(1, 1, 1)
        y = y + 25
        
        love.graphics.print("Severity: " .. self.currentCrisis.severity, 30, y)
        y = y + 20
        love.graphics.print("Description: " .. self.currentCrisis.description, 30, y)
        y = y + 20
        
        -- Time remaining
        local timeRemaining = math.max(0, self.currentCrisis.timeLimit - self.crisisTimer)
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        love.graphics.setColor(timeRemaining < 60 and {1, 0.3, 0.3} or {1, 1, 1})
        love.graphics.print("Time Remaining: " .. minutes .. ":" .. string.format("%02d", seconds), 30, y)
        love.graphics.setColor(1, 1, 1)
        y = y + 30
        
        -- Show crisis stages
        love.graphics.print("📊 INCIDENT STAGES:", 20, y)
        y = y + 25
        
        for i, stage in ipairs(self.currentCrisis.stages) do
            local status = stage.complete and "✅" or "🔄"
            love.graphics.print("   " .. status .. " " .. stage.name, 30, y)
            y = y + 15
            love.graphics.print("      " .. stage.description, 30, y)
            y = y + 20
            
            -- Show options for current stage
            if not stage.complete and stage.options then
                love.graphics.print("      Response Options:", 30, y)
                y = y + 15
                for _, option in ipairs(stage.options) do
                    love.graphics.print("        [" .. option.key .. "] " .. option.action .. " (Cost: " .. option.cost .. ")", 30, y)
                    y = y + 15
                end
                y = y + 10
                break -- Only show options for first incomplete stage
            end
        end
        
    else
        -- No active crisis - monitoring mode
        love.graphics.print("🔍 MONITORING MODE - All systems operational", 20, y)
        y = y + 25
        
        -- Show team readiness
        local specialistStats = self.systems.specialists:getStats()
        local teamBonuses = self.systems.specialists:getTeamBonuses()
        
        love.graphics.print("👥 TEAM READINESS:", 20, y)
        y = y + 25
        love.graphics.print("   Available Specialists: " .. specialistStats.available .. "/" .. specialistStats.total, 30, y)
        y = y + 20
        love.graphics.print("   Team Efficiency: " .. string.format("%.1fx", teamBonuses.efficiency), 30, y)
        y = y + 20
        love.graphics.print("   Response Speed: " .. string.format("%.1fx", teamBonuses.speed), 30, y)
        y = y + 20
        love.graphics.print("   Defense Rating: " .. string.format("%.1fx", teamBonuses.defense), 30, y)
        y = y + 30
        
        -- Active contracts (potential crisis sources)
        local contractStats = self.systems.contracts:getStats()
        love.graphics.print("⚠️ POTENTIAL RISK SOURCES:", 20, y)
        y = y + 25
        love.graphics.print("   Active Client Contracts: " .. contractStats.activeContracts, 30, y)
        y = y + 20
        love.graphics.print("   Threat Exposure Level: Medium", 30, y) -- TODO: Calculate from actual threats
        y = y + 30
        
        love.graphics.print("Press 'C' to simulate crisis scenario", 30, y)
        y = y + 20
    end
    
    -- Response log
    if #self.responseLog > 0 then
        y = y + 10
        love.graphics.print("📝 RESPONSE LOG:", 20, y)
        y = y + 20
        
        for i = math.max(1, #self.responseLog - 3), #self.responseLog do
            love.graphics.print("   " .. self.responseLog[i], 30, y)
            y = y + 15
        end
    end
    
    -- Instructions
    y = love.graphics.getHeight() - 100
    love.graphics.print("CRISIS MODE CONTROLS:", 20, y)
    y = y + 20
    love.graphics.print("• Number keys (1-3) - Select response options during crisis", 20, y)
    y = y + 15
    love.graphics.print("• 'C' - Simulate crisis (when not in crisis)", 20, y)
    y = y + 15
    love.graphics.print("• 'A' - Return to Idle Mode", 20, y)
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
        -- No active crisis - monitoring mode
        if key == "c" then
            self:startCrisis() -- Legacy crisis start
        elseif key == "t" then
            -- Trigger random crisis from config
            if not self:triggerRandomCrisis() then
                self:startCrisis() -- Fallback to legacy
            end
        elseif key == "r" then
            -- Reload configurations manually
            self:reloadCrisisConfigurations()
            print("🔄 Manually reloaded crisis configurations")
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
    
    print("🚨 Crisis started: " .. self.currentCrisis.title)
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
    
    if outcome == "success" then
        table.insert(self.responseLog, "✅ CRISIS RESOLVED SUCCESSFULLY")
        
        -- Award reputation and money
        self.systems.eventBus:publish("add_resource", {
            resource = "reputation",
            amount = 10
        })
        
        self.systems.eventBus:publish("add_resource", {
            resource = "money", 
            amount = 5000
        })
        
        print("✅ Crisis resolved successfully! +10 reputation, +$5000, +mission tokens")
        
    elseif outcome == "timeout" then
        table.insert(self.responseLog, "❌ CRISIS TIMEOUT - Partial failure")
        
        -- Minor penalties
        self.systems.eventBus:publish("add_resource", {
            resource = "reputation",
            amount = -5
        })
        
        print("❌ Crisis timed out! -5 reputation")
    end
    
    self.currentCrisis = nil
    self.crisisTimer = 0
end

return AdminMode