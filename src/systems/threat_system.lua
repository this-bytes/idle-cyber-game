-- Threat System - Dynamic Threat Generation and Management
-- Generates periodic security threats that require player intervention
-- Integrates with existing CrisisGameSystem for interactive response

local ThreatSystem = {}
ThreatSystem.__index = ThreatSystem

-- Create new threat system
function ThreatSystem.new(eventBus, dataManager)
    local self = setmetatable({}, ThreatSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    
    -- Threat generation state
    self.threatGenerationTimer = 0
    self.threatGenerationInterval = 20 -- Generate threat every 20 seconds
    self.nextThreatId = 1
    
    -- Active threats (not yet resolved)
    self.activeThreats = {}
    
    -- Threat templates (will be loaded from JSON)
    self.threatTemplates = {}
    
    -- System state
    self.enabled = true
    
    return self
end

-- Initialize threat system
function ThreatSystem:initialize()
    -- Load threat data from JSON if available
    -- For now, use embedded threat templates
    self:loadThreatTemplates()
    
    print("🚨 ThreatSystem: Initialized with " .. #self.threatTemplates .. " threat templates")
end

-- Load threat templates (embedded for now, can be moved to JSON later)
function ThreatSystem:loadThreatTemplates()
    -- Try to load from DataManager first
    if self.dataManager then
        local threatData = self.dataManager:getData("threats")
        if threatData and #threatData > 0 then
            self.threatTemplates = threatData
            print("🚨 ThreatSystem: Loaded " .. #self.threatTemplates .. " threats from data file")
            return
        end
    end
    
    -- Fallback to embedded templates
    self.threatTemplates = {
        {
            id = "phishing_attempt",
            name = "Phishing Email Campaign",
            description = "Suspicious emails targeting client employees with credential harvesting links.",
            baseSeverity = 3,
            baseTimeToResolve = 45,
            category = "social_engineering"
        },
        {
            id = "ddos_attack",
            name = "Distributed Denial of Service",
            description = "Coordinated attack overwhelming client web infrastructure.",
            baseSeverity = 5,
            baseTimeToResolve = 30,
            category = "network_attack"
        },
        {
            id = "malware_detection",
            name = "Malware Signature Match",
            description = "Known malware samples detected in client network traffic.",
            baseSeverity = 4,
            baseTimeToResolve = 60,
            category = "malware"
        },
        {
            id = "data_exfiltration",
            name = "Suspicious Data Transfer",
            description = "Unusual outbound data transfer patterns detected from sensitive systems.",
            baseSeverity = 7,
            baseTimeToResolve = 90,
            category = "data_breach"
        },
        {
            id = "insider_threat",
            name = "Privilege Escalation Alert",
            description = "Employee account showing unusual access patterns and privilege requests.",
            baseSeverity = 6,
            baseTimeToResolve = 120,
            category = "insider_threat"
        }
    }
    print("🚨 ThreatSystem: Using embedded threat templates")
end

-- Update threat system
function ThreatSystem:update(dt)
    if not self.enabled then return end
    
    -- Update threat generation timer
    self.threatGenerationTimer = self.threatGenerationTimer + dt
    
    -- Generate new threats periodically
    if self.threatGenerationTimer >= self.threatGenerationInterval then
        self:generateThreat()
        self.threatGenerationTimer = 0
        
        -- Randomize next interval (15-25 seconds)
        self.threatGenerationInterval = 15 + math.random() * 10
    end
    
    -- Update active threats (countdown timers)
    for threatId, threat in pairs(self.activeThreats) do
        threat.timeRemaining = threat.timeRemaining - dt
        
        -- Check for automatic failure
        if threat.timeRemaining <= 0 then
            self:failThreat(threatId)
        end
    end
end

-- Generate a new threat
function ThreatSystem:generateThreat()
    if #self.threatTemplates == 0 then return end
    
    -- Select random threat template
    local template = self.threatTemplates[math.random(#self.threatTemplates)]
    
    -- Create threat instance with some randomization
    local threat = {
        id = "threat_" .. self.nextThreatId,
        templateId = template.id,
        name = template.name,
        description = template.description,
        severity = template.baseSeverity + math.random(-1, 2), -- ±1-2 severity variation
        timeToResolve = template.baseTimeToResolve,
        timeRemaining = template.baseTimeToResolve,
        category = template.category,
        status = "active",
        detectedAt = (love and love.timer and love.timer.getTime()) or os.clock()
    }
    
    -- Ensure severity stays within reasonable bounds
    threat.severity = math.max(1, math.min(10, threat.severity))
    
    -- Add to active threats
    self.activeThreats[threat.id] = threat
    self.nextThreatId = self.nextThreatId + 1
    
    -- Publish threat detected event
    self.eventBus:publish("threat_detected", { threat = threat })
    
    print("🚨 Threat detected: " .. threat.name .. " (Severity: " .. threat.severity .. ")")
    return threat
end

-- Assign specialist to threat
function ThreatSystem:assignSpecialist(threatId, specialistId)
    local threat = self.activeThreats[threatId]
    if not threat then return false end
    
    threat.assignedSpecialist = specialistId
    threat.status = "responding"
    
    -- Publish assignment event
    self.eventBus:publish("specialist_assigned_to_threat", {
        threatId = threatId,
        specialistId = specialistId
    })
    
    print("🛡️ Specialist " .. specialistId .. " assigned to threat: " .. threat.name)
    return true
end

-- Resolve threat successfully
function ThreatSystem:resolveThreat(threatId)
    local threat = self.activeThreats[threatId]
    if not threat then return false end
    
    -- Calculate rewards based on severity and response time
    local responseTime = threat.timeToResolve - threat.timeRemaining
    local efficiency = math.max(0.1, threat.timeRemaining / threat.timeToResolve)
    
    local rewards = {
        money = threat.severity * 100 * efficiency,
        reputation = math.ceil(threat.severity * 0.5),
        experience = threat.severity * 10
    }
    
    -- Publish success event
    self.eventBus:publish("threat_resolved", {
        status = "success",
        threat = threat,
        rewards = rewards,
        responseTime = responseTime
    })
    
    -- Remove from active threats
    self.activeThreats[threatId] = nil
    
    print("✅ Threat resolved: " .. threat.name .. " (+$" .. math.floor(rewards.money) .. ")")
    return true
end

-- Fail threat (time expired or mishandled)
function ThreatSystem:failThreat(threatId)
    local threat = self.activeThreats[threatId]
    if not threat then return false end
    
    -- Calculate penalties based on severity
    local penalties = {
        money = threat.severity * 50,
        reputation = threat.severity * 1
    }
    
    -- Publish failure event
    self.eventBus:publish("threat_resolved", {
        status = "failure",
        threat = threat,
        penalties = penalties
    })
    
    -- Remove from active threats
    self.activeThreats[threatId] = nil
    
    print("❌ Threat failed: " .. threat.name .. " (-$" .. penalties.money .. ", -" .. penalties.reputation .. " reputation)")
    return true
end

-- Get all active threats
function ThreatSystem:getActiveThreats()
    local threats = {}
    for _, threat in pairs(self.activeThreats) do
        table.insert(threats, threat)
    end
    
    -- Sort by severity (highest first)
    table.sort(threats, function(a, b) return a.severity > b.severity end)
    return threats
end

-- Get threat by ID
function ThreatSystem:getThreat(threatId)
    return self.activeThreats[threatId]
end

-- Enable/disable threat generation
function ThreatSystem:setEnabled(enabled)
    self.enabled = enabled
    print("🚨 ThreatSystem: " .. (enabled and "Enabled" or "Disabled"))
end

-- Get system status
function ThreatSystem:getStatus()
    return {
        enabled = self.enabled,
        activeThreats = self:getActiveThreats(),
        nextThreatIn = self.threatGenerationInterval - self.threatGenerationTimer
    }
end

return ThreatSystem