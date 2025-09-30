-- Incident Response Scene - Active Threat Management
-- Handles real-time incident response when major threats are detected
-- Provides interactive management of critical SOC incidents

local IncidentResponse = {}
IncidentResponse.__index = IncidentResponse

function IncidentResponse.new(eventBus)
    local self = setmetatable({}, IncidentResponse)
    self.eventBus = eventBus
    self.systems = {} -- Injected by SceneManager on enter
    
    -- Crisis state
    self.activeThreat = nil
    self.availableSpecialists = {}
    self.selectedSpecialistIndex = 1
    
    print("🚨 IncidentResponse: Initialized incident response scene")
    return self
end

function IncidentResponse:enter(data)
    print("🚨 IncidentResponse: Entering incident response mode")
    
    -- Get the active threat from the data
    if data and data.threat then
        self.activeThreat = data.threat
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
    else
        print("Warning: specialistSystem not found in IncidentResponse:enter")
    end
end

function IncidentResponse:exit()
    print("🚨 IncidentResponse: Exiting incident response mode")
end

function IncidentResponse:update(dt)
    -- Update threat timer if we have an active threat
    if self.activeThreat then
        self.activeThreat.timeRemaining = self.activeThreat.timeRemaining - dt
        
        -- Check if time expired
        if self.activeThreat.timeRemaining <= 0 then
            -- Return to SOC view - threat will be failed by ThreatSystem
            self.eventBus:publish("scene_request", {scene = "soc_view"})
        end
    end
end

function IncidentResponse:draw()
    love.graphics.setColor(1, 1, 1, 1)
    
    if not self.activeThreat then
        love.graphics.print("🚨 No active threat", 50, 50)
        love.graphics.print("Press [ESC] to return to SOC", 50, 100)
        return
    end
    
    -- Draw threat information
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.print("🚨 ACTIVE THREAT", 50, 50)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Threat: " .. self.activeThreat.name, 50, 80)
    love.graphics.print("Severity: " .. self.activeThreat.severity .. "/10", 50, 100)
    love.graphics.print("Time Remaining: " .. math.ceil(self.activeThreat.timeRemaining) .. "s", 50, 120)
    love.graphics.print("Category: " .. (self.activeThreat.category or "unknown"), 50, 140)
    
    -- Draw description
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf(self.activeThreat.description, 50, 170, 700)
    
    -- Draw specialist assignment section
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.print("🛡️ ASSIGN SPECIALIST", 50, 220)
    
    love.graphics.setColor(1, 1, 1, 1)
    if #self.availableSpecialists == 0 then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("No specialists available!", 50, 250)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("Hire specialists to respond to threats effectively.", 50, 270)
    else
        love.graphics.print("Available Specialists:", 50, 250)
        
        -- List specialists
        for i, specialist in ipairs(self.availableSpecialists) do
            local y = 270 + (i - 1) * 25
            local color = (i == self.selectedSpecialistIndex) and {1, 1, 0, 1} or {1, 1, 1, 1}
            love.graphics.setColor(color[1], color[2], color[3], color[4])
            
            local prefix = (i == self.selectedSpecialistIndex) and "> " or "  "
            love.graphics.print(prefix .. i .. ". " .. specialist.name, 50, y)
            love.graphics.print("Defense: " .. specialist.defense .. " | Efficiency: " .. specialist.efficiency, 200, y)
        end
    end
    
    -- Draw controls
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("Controls:", 50, 400)
    love.graphics.print("↑/↓ - Select specialist", 50, 420)
    love.graphics.print("[ENTER] - Assign specialist to threat", 50, 440)
    love.graphics.print("[ESC] - Return to SOC (abandon threat)", 50, 460)
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