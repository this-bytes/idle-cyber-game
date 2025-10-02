-- Incident Response Scene - Active Threat Management
-- Handles real-time incident response when major threats are detected
-- Provides interactive management of critical SOC incidents

local IncidentResponse = {}
IncidentResponse.__index = IncidentResponse

function IncidentResponse.new(eventBus)
    local self = setmetatable({}, IncidentResponse)
    self.eventBus = eventBus
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
    
    print("🚨 IncidentResponse: Initialized incident response scene")
    return self
end

function IncidentResponse:enter(data)
    print("🚨 IncidentResponse: Entering incident response mode")
    
    -- Get the active threat from the data
    if data and data.threat then
        self.activeThreat = data.threat
        self.threatIntegrity = 100 -- Start with full integrity
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
        
        -- Filter for available specialists
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
        print("Warning: specialistSystem not found in IncidentResponse:enter")
        self:addTerminalLine("⚠️  Warning: Specialist system unavailable")
    end
end

function IncidentResponse:addTerminalLine(text)
    table.insert(self.terminalLines, text)
    if #self.terminalLines > self.maxTerminalLines then
        table.remove(self.terminalLines, 1)
    end
end

function IncidentResponse:update(dt)
    if not self.activeThreat then return end
    
    -- Simulate threat progression and response
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - self.incidentStartTime
    
    -- Auto-response logic
    if self.autoResponseEnabled and #self.availableSpecialists > 0 then
        -- Specialists automatically work on the threat
        local damagePerSecond = 0
        for _, specialist in ipairs(self.availableSpecialists) do
            -- Calculate damage based on specialist skills (simplified)
            local skillBonus = specialist.level or 1
            damagePerSecond = damagePerSecond + (skillBonus * 2) -- 2 damage per level per second
        end
        
        self.threatIntegrity = self.threatIntegrity - (damagePerSecond * dt)
        self.responseProgress = self.responseProgress + (damagePerSecond * dt * 0.5) -- Progress slower than damage
        
        -- Add occasional status updates
        if math.random() < 0.02 then -- 2% chance per frame
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
        self:addTerminalLine("� Incident Summary:")
        self:addTerminalLine("   Duration: " .. string.format("%.1f", elapsed) .. " seconds")
        self:addTerminalLine("   Specialists Deployed: " .. #self.availableSpecialists)
        self:addTerminalLine("   Response Effectiveness: " .. string.format("%.1f%%", self.responseProgress))
        
        -- Award XP and reputation
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
        
        -- Mark threat as resolved
        self.activeThreat = nil
    end
end

function IncidentResponse:exit()
    print("🚨 IncidentResponse: Exiting incident response mode")
end

function IncidentResponse:draw()
    -- Set up terminal-style appearance
    love.graphics.setColor(0, 0.8, 0) -- Green terminal text
    love.graphics.setFont(love.graphics.newFont(14))
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local lineHeight = 20
    local y = 20
    
    -- Draw terminal border
    love.graphics.setColor(0, 0.8, 0, 0.3)
    love.graphics.rectangle("line", 10, 10, screenWidth - 20, screenHeight - 20)
    love.graphics.setColor(0, 0.8, 0)
    
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
    
    -- Draw help text
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("ESC: Return to SOC View", screenWidth - 200, screenHeight - 30)
end

function IncidentResponse:keypressed(key)
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
        -- Assign selected specialist
        local specialist = self.availableSpecialists[self.selectedSpecialistIndex]
        if specialist and self.systems and self.systems.threatSystem then
            local success = self.systems.threatSystem:assignSpecialist(self.activeThreat.id, specialist.id)
            if success then
                -- Mark specialist as busy
                if self.systems.specialistSystem then
                    self.systems.specialistSystem:assignSpecialist(specialist.id, self.activeThreat.timeRemaining)
                end
                
                -- Start resolution process
                self:startThreatResolution(specialist)
            end
        end
    end
end

function IncidentResponse:startThreatResolution(specialist)
    -- Calculate resolution based on specialist stats and threat severity
    local resolutionPower = specialist.defense + specialist.efficiency
    local threatDifficulty = self.activeThreat.severity
    
    -- Higher specialist power vs threat difficulty = higher success chance
    local successChance = math.min(0.95, resolutionPower / (threatDifficulty + 5))
    
    -- Simulate resolution process (instant for now, could be animated)
    if math.random() < successChance then
        -- Success!
        if self.systems.threatSystem then
            self.systems.threatSystem:resolveThreat(self.activeThreat.id)
        end
        print("✅ Threat resolved by " .. specialist.name)
    else
        -- Failure
        if self.systems.threatSystem then
            self.systems.threatSystem:failThreat(self.activeThreat.id)
        end
        print("❌ Failed to resolve threat with " .. specialist.name)
    end
    
    -- Return to SOC view
    self.eventBus:publish("scene_request", {scene = "soc_view"})
end

function IncidentResponse:mousepressed(x, y, button)
    -- TODO: Implement mouse interactions for specialist selection
end

return IncidentResponse