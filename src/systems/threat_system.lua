-- Threat System - Dynamic Threat Generation and Management
-- Generates periodic security threats that require player intervention
-- Integrates with existing CrisisGameSystem for interactive response

local ThreatSystem = {}
ThreatSystem.__index = ThreatSystem

-- Create new threat system
function ThreatSystem.new(eventBus, dataManager, specialistSystem, skillSystem)
    local self = setmetatable({}, ThreatSystem)
    self.eventBus = eventBus
    self.dataManager = dataManager
    self.specialistSystem = specialistSystem
    self.skillSystem = skillSystem
    
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
    
    -- Subscribe to events
    self.eventBus:subscribe("specialist_ability_used", function(data)
        self:handleAbilityUsage(data)
    end)

    print("🚨 ThreatSystem: Initialized with " .. #self.threatTemplates .. " threat templates")
end

function ThreatSystem:handleAbilityUsage(data)
    -- A more complex system would use the incidentId to target a specific threat.
    local targetThreat = self.activeThreats[data.incidentId]

    if not targetThreat then
        self.eventBus:publish("admin_log", { message = "[SYSTEM] No active incident to target." })
        return
    end

    local abilityName = data.abilityName
    local skillDef = self.skillSystem:getSkillDefinition(abilityName)

    local damage = 10 -- Default damage if skill is not found or has no effect
    local logMessage = string.format("'%s' is executed.", abilityName)

    if skillDef and skillDef.activeEffect then
        damage = skillDef.activeEffect.baseAmount or damage
        if skillDef.activeEffect.description then
            logMessage = string.format(skillDef.activeEffect.description, abilityName)
        end
    else
        self.eventBus:publish("admin_log", { message = string.format("[WARNING] Skill '%s' has no defined active effect.", abilityName) })
    end
    
    self.eventBus:publish("admin_log", { message = logMessage })

    targetThreat.hp = targetThreat.hp - damage
    self.eventBus:publish("admin_log", { message = string.format("Threat '%s' takes %d damage. (HP: %d/%d)", targetThreat.name, damage, targetThreat.hp, targetThreat.baseHp) })

    if targetThreat.hp <= 0 then
        self:resolveThreat(targetThreat.id, "success")
    end
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
            category = "social_engineering",
            hp = 100
        },
        {
            id = "ddos_attack",
            name = "Distributed Denial of Service",
            description = "Coordinated attack overwhelming client web infrastructure.",
            baseSeverity = 5,
            baseTimeToResolve = 30,
            category = "network_attack",
            hp = 150
        },
        {
            id = "malware_detection",
            name = "Malware Signature Match",
            description = "Known malware samples detected in client network traffic.",
            baseSeverity = 4,
            baseTimeToResolve = 60,
            category = "malware",
            hp = 120
        },
        {
            id = "data_exfiltration",
            name = "Suspicious Data Transfer",
            description = "Unusual outbound data transfer patterns detected from sensitive systems.",
            baseSeverity = 7,
            baseTimeToResolve = 90,
            category = "data_breach",
            hp = 180
        },
        {
            id = "insider_threat",
            name = "Privilege Escalation Alert",
            description = "Employee account showing unusual access patterns and privilege requests.",
            baseSeverity = 6,
            baseTimeToResolve = 120,
            category = "insider_threat",
            hp = 160
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
    local newThreat = {
        id = self.nextThreatId,
        templateId = template.id,
        name = template.name,
        description = template.description,
        severity = template.baseSeverity,
        timeToResolve = template.baseTimeToResolve,
        category = template.category,
        hp = template.hp,
        baseHp = template.hp, -- Store original HP
        status = "active", -- active, resolved, failed
        assignedSpecialist = nil,
        spawnTime = love.timer.getTime()
    }
    
    self.activeThreats[newThreat.id] = newThreat
    self.nextThreatId = self.nextThreatId + 1
    
    self.eventBus:publish("threat_generated", {threat = newThreat})

    -- If threat is critical, force switch to Admin Mode
    if newThreat.severity >= 7 then
        self.eventBus:publish("admin_log", { message = "[CRITICAL] High-severity threat detected. Switching to Admin Mode." })
        self.eventBus:publish("request_scene_change", { scene = "admin_mode", data = { incident = newThreat } })
    end
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
    
    -- Immediately calculate resolution chance
    threat.resolutionChance = self:calculateThreatResolutionChance(threatId)
    print("   - Resolution chance: " .. string.format("%.1f%%", threat.resolutionChance * 100))

    return true
end

-- Calculate the chance of a specialist successfully resolving a threat
function ThreatSystem:calculateThreatResolutionChance(threatId)
    local threat = self.activeThreats[threatId]
    if not threat or not threat.assignedSpecialist then return 0 end

    local specialistId = threat.assignedSpecialist
    local specialistStats = self.specialistSystem:getSpecialistEffectiveStats(specialistId)
    if not specialistStats then return 0 end

    -- Determine the most relevant stat for the threat category
    local relevantStat = "efficiency" -- Default stat
    if threat.category == "network_attack" then
        relevantStat = "defense"
    elseif threat.category == "data_breach" or threat.category == "social_engineering" then
        relevantStat = "trace"
    elseif threat.category == "malware" or threat.category == "insider_threat" then
        relevantStat = "speed"
    end

    local statValue = specialistStats[relevantStat] or 1.0
    local threatSeverity = threat.severity or 5

    -- Formula: Chance is based on the ratio of stat to severity.
    -- A specialist with a stat equal to the severity has a 50% chance.
    -- The chance scales, capping at 95%.
    local chance = (statValue / threatSeverity) * 0.5
    
    return math.min(chance, 0.95) -- Cap at 95%
end

-- Resolve threat attempt
function ThreatSystem:attemptThreatResolution(threatId)
    local threat = self.activeThreats[threatId]
    if not threat or not threat.assignedSpecialist then return false end

    local chance = self:calculateThreatResolutionChance(threatId)
    local success = math.random() < chance

    if success then
        self:resolveThreat(threatId)
    else
        -- Optional: Implement partial failure or other consequences here
        print("🛡️ Specialist failed to resolve threat " .. threat.name .. " on this attempt.")
    end
    -- For now, we'll just let the timer run down on failure.
    -- A more complex system could have specialists make periodic attempts.
end

-- Resolve threat successfully
function ThreatSystem:resolveThreat(threatId, status)
    local threat = self.activeThreats[threatId]
    if not threat then return end
    
    threat.status = status
    
    local rewards = self:calculateRewards(threat, status)
    
    self.eventBus:publish("threat_resolved", {
        threat = threat,
        status = status,
        rewards = rewards
    })

    if status == "success" then
        self.eventBus:publish("admin_log", { message = string.format("[SUCCESS] Threat '%s' has been neutralized.", threat.name) })
    else
        self.eventBus:publish("admin_log", { message = string.format("[FAILURE] Failed to neutralize threat '%s'.", threat.name) })
    end
    
    -- Move from active to resolved (or just remove for now)
    self.activeThreats[threatId] = nil
end

function ThreatSystem:calculateRewards(threat, status)
    local responseTime = threat.timeToResolve - threat.timeRemaining
    local efficiency = math.max(0.1, threat.timeRemaining / threat.timeToResolve)
    
    local rewards = {
        money = threat.severity * 100 * efficiency,
        reputation = math.ceil(threat.severity * 0.5),
        experience = threat.severity * 10
    }
    
    return rewards
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