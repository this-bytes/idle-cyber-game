-- Incident Response Scene - Active Threat Management (LUIS Version)
-- Handles real-time incident response when major threats are detected
-- Migrated to LUIS (Love UI System) for consistency with new UI framework

local IncidentResponseLuis = {}
IncidentResponseLuis.__index = IncidentResponseLuis

function IncidentResponseLuis.new(eventBus, luis)
    local self = setmetatable({}, IncidentResponseLuis)
    self.eventBus = eventBus
    self.luis = luis
    self.layerName = "incident_response"
    self.systems = {} -- Injected by SceneManager on enter
    
    -- Incident state
    self.activeThreat = nil
    self.availableSpecialists = {}
    self.selectedSpecialistIndex = 1
    self.incidentStartTime = 0
    self.incidentLog = {}
    self.threatIntegrity = 100
    self.responseProgress = 0
    self.autoResponseEnabled = true
    
    -- Terminal-style UI
    self.terminalLines = {}
    self.maxTerminalLines = 20
    self.terminalScroll = 0
    
    print("🚨 IncidentResponseLuis: Initialized incident response scene")
    return self
end

function IncidentResponseLuis:load(data)
    print("🚨 IncidentResponseLuis: Entering incident response mode")
    
    -- Create LUIS layer
    self.luis.newLayer(self.layerName)
    self.luis.setCurrentLayer(self.layerName)
    
    -- Get the active threat from the data
    if data and data.threat then
        self.activeThreat = data.threat
        self.threatIntegrity = 100
        self.responseProgress = 0
        self.incidentStartTime = love.timer.getTime()
        
        -- Initialize terminal
        self.terminalLines = {}
        self:addTerminalLine("╔══════════════════════════════════════════════════════════════╗")
        self:addTerminalLine("║                    INCIDENT RESPONSE TERMINAL                    ║")
        self:addTerminalLine("╚══════════════════════════════════════════════════════════════╝")
        self:addTerminalLine("")
        self:addTerminalLine("🚨 ALERT: " .. self.activeThreat.name .. " detected!")
        self:addTerminalLine("📝 " .. self.activeThreat.description)
        self:addTerminalLine("")
        self:addTerminalLine("Initializing response protocols...")
        self:addTerminalLine("Loading specialist team...")
        
        print("🚨 Responding to threat: " .. self.activeThreat.name)
    end
    
    -- Get available specialists
    if self.systems and self.systems.specialistSystem then
        local specialists = self.systems.specialistSystem:getTeam()
        self.availableSpecialists = {}
        
        for id, specialist in pairs(specialists) do
            if specialist.status == "available" then
                table.insert(self.availableSpecialists, specialist)
            end
        end
        
        self:addTerminalLine("Found " .. #self.availableSpecialists .. " available specialists")
        self:addTerminalLine("Auto-response protocol: " .. (self.autoResponseEnabled and "ENABLED" or "DISABLED"))
        self:addTerminalLine("")
        self:addTerminalLine("Type 'help' for available commands")
    else
        print("Warning: specialistSystem not found in IncidentResponseLuis:load")
        self:addTerminalLine("⚠️  Warning: Specialist system unavailable")
    end
    
    -- Build UI
    self:buildUI()
end

function IncidentResponseLuis:buildUI()
    local luis = self.luis
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local gridSize = luis.gridSize
    
    -- Calculate center positions
    local centerCol = math.floor(screenWidth / gridSize / 2)
    local centerRow = math.floor(screenHeight / gridSize / 2)
    
    -- Title
    local title = luis.newLabel("🚨 INCIDENT RESPONSE TERMINAL", 40, 2, 2, centerCol - 20)
    luis.insertElement(self.layerName, title)
    
    -- Terminal output area (simplified - actual text drawn manually for terminal effect)
    local terminalInfo = luis.newLabel("Terminal output displayed below", 40, 1, 4, centerCol - 20)
    luis.insertElement(self.layerName, terminalInfo)
    
    -- Return button
    local returnButton = luis.newButton(
        "↩ Return to SOC View (ESC)",
        25, 3,
        function()
            if self.eventBus then
                self.eventBus:publish("scene_request", {scene = "soc_view"})
            end
        end,
        nil,
        centerRow + 15,
        centerCol - 12
    )
    luis.insertElement(self.layerName, returnButton)
    
    print("🚨 IncidentResponseLuis: UI built")
end

function IncidentResponseLuis:addTerminalLine(text)
    table.insert(self.terminalLines, text)
    if #self.terminalLines > self.maxTerminalLines then
        table.remove(self.terminalLines, 1)
    end
end

function IncidentResponseLuis:update(dt)
    if not self.activeThreat then return end
    
    -- Simulate threat progression and response
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - self.incidentStartTime
    
    -- Auto-response logic
    if self.autoResponseEnabled and #self.availableSpecialists > 0 then
        local damagePerSecond = 0
        for _, specialist in ipairs(self.availableSpecialists) do
            local skillBonus = specialist.level or 1
            damagePerSecond = damagePerSecond + (skillBonus * 2)
        end
        
        self.threatIntegrity = self.threatIntegrity - (damagePerSecond * dt)
        self.responseProgress = self.responseProgress + (damagePerSecond * dt * 0.5)
        
        if math.random() < 0.02 then
            local messages = {
                "Specialist analyzing threat patterns...",
                "Deploying countermeasures...",
                "Isolating affected systems...",
                "Gathering forensic evidence...",
                "Coordinating with external teams...",
                "Updating incident playbook..."
            }
            self:addTerminalLine("⚡ " .. messages[math.random(#messages)])
        end
    end
    
    -- Check for incident completion
    if self.threatIntegrity <= 0 then
        self:addTerminalLine("")
        self:addTerminalLine("✅ THREAT NEUTRALIZED!")
        self:addTerminalLine("📊 Incident Summary:")
        self:addTerminalLine("   Duration: " .. string.format("%.1f", elapsed) .. " seconds")
        self:addTerminalLine("   Specialists Deployed: " .. #self.availableSpecialists)
        self:addTerminalLine("   Response Effectiveness: " .. string.format("%.1f%%", self.responseProgress))
        
        local xpReward = math.floor(self.activeThreat.baseDamage * 0.1)
        local repReward = math.floor(self.activeThreat.baseDamage * 0.05)
        
        self:addTerminalLine("   XP Gained: " .. xpReward)
        self:addTerminalLine("   Reputation Gained: " .. repReward)
        
        if self.systems.resourceManager then
            self.systems.resourceManager:addResource("xp", xpReward)
            self.systems.resourceManager:addResource("reputation", repReward)
        end
        
        self:addTerminalLine("")
        self:addTerminalLine("Press ESC to return to SOC View")
        
        self.activeThreat = nil
    end
end

function IncidentResponseLuis:draw()
    -- Draw terminal output manually (LUIS doesn't handle this well)
    -- This is acceptable as the terminal is dynamic content
    love.graphics.setColor(0, 0.8, 0)
    love.graphics.setFont(love.graphics.newFont(14))
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local lineHeight = 20
    local y = 100
    
    -- Draw terminal lines
    for i, line in ipairs(self.terminalLines) do
        love.graphics.print(line, 20, y)
        y = y + lineHeight
    end
    
    -- Draw threat status if active
    if self.activeThreat then
        y = screenHeight - 120
        
        -- Threat integrity bar
        love.graphics.print("Threat Integrity:", 20, y)
        y = y + lineHeight
        
        local barWidth = 300
        local barHeight = 20
        love.graphics.setColor(0.8, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", 20, y, barWidth, barHeight)
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", 20, y, barWidth * (self.threatIntegrity / 100), barHeight)
        love.graphics.setColor(0, 0.8, 0)
        love.graphics.rectangle("line", 20, y, barWidth, barHeight)
        love.graphics.print(string.format("%.1f%%", self.threatIntegrity), 20 + barWidth + 10, y)
        
        y = y + lineHeight + 10
        
        -- Response progress
        love.graphics.print("Response Progress:", 20, y)
        y = y + lineHeight
        
        love.graphics.setColor(0.2, 0.8, 0.2, 0.5)
        love.graphics.rectangle("fill", 20, y, barWidth, barHeight)
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", 20, y, barWidth * math.min(self.responseProgress / 100, 1), barHeight)
        love.graphics.setColor(0, 0.8, 0)
        love.graphics.rectangle("line", 20, y, barWidth, barHeight)
        love.graphics.print(string.format("%.1f%%", math.min(self.responseProgress, 100)), 20 + barWidth + 10, y)
        
        y = y + lineHeight + 10
        
        -- Specialists deployed
        love.graphics.print("Specialists Deployed: " .. #self.availableSpecialists, 20, y)
        y = y + lineHeight
        
        -- Auto-response status
        local autoStatus = self.autoResponseEnabled and "ENABLED" or "DISABLED"
        love.graphics.print("Auto-Response: " .. autoStatus, 20, y)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function IncidentResponseLuis:exit()
    print("🚨 IncidentResponseLuis: Exiting incident response mode")
    
    if self.luis.isLayerEnabled(self.layerName) then
        self.luis.disableLayer(self.layerName)
        print("🚨 IncidentResponseLuis: Layer disabled")
    end
end

function IncidentResponseLuis:keypressed(key)
    if key == "escape" then
        self.eventBus:publish("scene_request", {scene = "soc_view"})
        return
    end
    
    if not self.activeThreat or #self.availableSpecialists == 0 then
        return
    end
    
    if key == "up" then
        self.selectedSpecialistIndex = math.max(1, self.selectedSpecialistIndex - 1)
    elseif key == "down" then
        self.selectedSpecialistIndex = math.min(#self.availableSpecialists, self.selectedSpecialistIndex + 1)
    elseif key == "return" or key == "enter" then
        local specialist = self.availableSpecialists[self.selectedSpecialistIndex]
        if specialist and self.systems and self.systems.threatSystem then
            local success = self.systems.threatSystem:assignSpecialist(self.activeThreat.id, specialist.id)
            if success then
                if self.systems.specialistSystem then
                    self.systems.specialistSystem:assignSpecialist(specialist.id, self.activeThreat.timeRemaining)
                end
                self:startThreatResolution(specialist)
            end
        end
    end
end

function IncidentResponseLuis:startThreatResolution(specialist)
    local resolutionPower = specialist.defense + specialist.efficiency
    local threatDifficulty = self.activeThreat.severity
    local successChance = math.min(0.95, resolutionPower / (threatDifficulty + 5))
    
    if math.random() < successChance then
        if self.systems.threatSystem then
            self.systems.threatSystem:resolveThreat(self.activeThreat.id)
        end
        print("✅ Threat resolved by " .. specialist.name)
    else
        if self.systems.threatSystem then
            self.systems.threatSystem:failThreat(self.activeThreat.id)
        end
        print("❌ Failed to resolve threat with " .. specialist.name)
    end
    
    self.eventBus:publish("scene_request", {scene = "soc_view"})
end

return IncidentResponseLuis
