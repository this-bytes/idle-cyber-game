-- ThreatSimulation - Comprehensive Cybersecurity Threat Processing Engine
-- Fortress Refactor: Realistic threat modeling with defense infrastructure integration
-- Simulates real-world cyber threats and defensive responses for the cybersecurity business

local ThreatSimulation = {}
ThreatSimulation.__index = ThreatSimulation

-- Threat classification system
local THREAT_TYPES = {
    PHISHING = "phishing",
    MALWARE = "malware", 
    BRUTEFORCE = "bruteforce",
    DDOS = "ddos",
    APT = "apt",
    ZERODAY = "zeroday",
    INSIDER = "insider",
    RANSOMWARE = "ransomware"
}

-- Threat severity levels
local THREAT_SEVERITY = {
    LOW = { multiplier = 0.5, color = {0.2, 0.8, 0.2} },
    MEDIUM = { multiplier = 1.0, color = {0.8, 0.8, 0.2} },
    HIGH = { multiplier = 2.0, color = {0.8, 0.5, 0.2} },
    CRITICAL = { multiplier = 4.0, color = {0.8, 0.2, 0.2} }
}

-- Create new threat simulation system
function ThreatSimulation.new(eventBus, resourceManager, securityUpgrades, statsSystem)
    local self = setmetatable({}, ThreatSimulation)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.securityUpgrades = securityUpgrades
    self.statsSystem = statsSystem
    
    -- Threat tracking
    self.activeThreats = {}
    self.threatHistory = {}
    self.nextThreatId = 1
    
    -- Simulation parameters
    self.threatFrequency = 1.0 -- Base threats per minute
    self.lastThreatTime = 0
    self.threatTimer = 0
    
    -- Initialize threat definitions
    self:initializeThreatTypes()
    
    -- Subscribe to events
    self:subscribeToEvents()
    
    return self
end

-- Initialize threat type definitions with realistic cybersecurity characteristics
function ThreatSimulation:initializeThreatTypes()
    self.threatTypes = {
        [THREAT_TYPES.PHISHING] = {
            name = "Phishing Attack",
            baseFrequency = 300, -- Every 5 minutes on average
            baseDamage = 50,
            description = "Email-based social engineering attempt",
            defenseTypes = {"emailFilter", "securityTraining"},
            severityWeights = {low = 60, medium = 30, high = 8, critical = 2}
        },
        
        [THREAT_TYPES.MALWARE] = {
            name = "Malware Infection", 
            baseFrequency = 420, -- Every 7 minutes on average
            baseDamage = 75,
            description = "Malicious software attempting system compromise",
            defenseTypes = {"antivirus", "intrusionDetection"},
            severityWeights = {low = 40, medium = 40, high = 15, critical = 5}
        },
        
        [THREAT_TYPES.BRUTEFORCE] = {
            name = "Brute Force Attack",
            baseFrequency = 600, -- Every 10 minutes on average  
            baseDamage = 40,
            description = "Automated password cracking attempt",
            defenseTypes = {"accessControl", "basicFirewall"},
            severityWeights = {low = 70, medium = 25, high = 4, critical = 1}
        },
        
        [THREAT_TYPES.DDOS] = {
            name = "DDoS Attack",
            baseFrequency = 900, -- Every 15 minutes on average
            baseDamage = 100,
            description = "Distributed denial of service attack",
            defenseTypes = {"enterpriseFirewall", "trafficShaping"},
            severityWeights = {low = 30, medium = 40, high = 25, critical = 5}
        },
        
        [THREAT_TYPES.APT] = {
            name = "Advanced Persistent Threat",
            baseFrequency = 1800, -- Every 30 minutes on average
            baseDamage = 200,
            description = "Sophisticated long-term infiltration attempt",
            defenseTypes = {"threatIntelligence", "siem"},
            severityWeights = {low = 10, medium = 30, high = 40, critical = 20}
        },
        
        [THREAT_TYPES.ZERODAY] = {
            name = "Zero-Day Exploit",
            baseFrequency = 3600, -- Every hour on average
            baseDamage = 300,
            description = "Previously unknown vulnerability exploitation",
            defenseTypes = {"aiThreatDetection", "behavioralAnalysis"},
            severityWeights = {low = 5, medium = 15, high = 50, critical = 30}
        },
        
        [THREAT_TYPES.INSIDER] = {
            name = "Insider Threat",
            baseFrequency = 2400, -- Every 40 minutes on average
            baseDamage = 150,
            description = "Malicious or negligent insider activity",
            defenseTypes = {"securityTraining", "accessControl"},
            severityWeights = {low = 20, medium = 35, high = 35, critical = 10}
        },
        
        [THREAT_TYPES.RANSOMWARE] = {
            name = "Ransomware Attack",
            baseFrequency = 1200, -- Every 20 minutes on average
            baseDamage = 250,
            description = "Data encryption extortion attempt",
            defenseTypes = {"antivirus", "secureDataCenter"},
            severityWeights = {low = 15, medium = 25, high = 35, critical = 25}
        }
    }
    
    print("🚨 ThreatSimulation: Initialized realistic cybersecurity threat catalog")
end

-- Subscribe to relevant events
function ThreatSimulation:subscribeToEvents()
    -- Handle security upgrades affecting threat mitigation
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self:updateThreatMitigation()
    end)
    
    -- Handle contract activity increasing threat visibility
    self.eventBus:subscribe("contract_accepted", function(data)
        self.threatFrequency = self.threatFrequency + 0.1 -- More activity = more threats
    end)
    
    -- Handle facility changes
    self.eventBus:subscribe("facility_upgraded", function(data)
        self:updateThreatMitigation()
    end)
end

-- Update threat simulation
function ThreatSimulation:update(dt)
    local currentTime = love.timer and love.timer.getTime() or os.clock()
    
    if self.lastThreatTime == 0 then
        self.lastThreatTime = currentTime
    end
    
    self.threatTimer = self.threatTimer + dt
    
    -- Check for new threats based on frequency
    local timeSinceLastThreat = currentTime - self.lastThreatTime
    local detectionBoost = 1
    if self.statsSystem then
        local derived = self.statsSystem:getDerived()
        detectionBoost = 1 + (derived.detectionEfficiency or 0)
    end
    local adjustedFrequency = self.threatFrequency * detectionBoost
    local avgThreatInterval = 60 / adjustedFrequency -- Convert per-minute to seconds
    
    if timeSinceLastThreat >= avgThreatInterval then
        -- Random chance to spawn threat (makes timing less predictable)
        if math.random() < 0.3 then -- 30% chance per check
            self:generateThreat()
            self.lastThreatTime = currentTime
        end
    end
    
    -- Update active threats
    self:updateActiveThreats(dt)
end

-- Generate a new threat
function ThreatSimulation:generateThreat()
    -- Select threat type based on weighted probabilities
    local threatType = self:selectRandomThreatType()
    local threatData = self.threatTypes[threatType]
    
    if not threatData then return end
    
    -- Determine threat severity
    local severity = self:selectThreatSeverity(threatData.severityWeights)
    
    -- Create threat instance
    local threat = {
        id = self.nextThreatId,
        type = threatType,
        name = threatData.name,
        severity = severity,
        baseDamage = threatData.baseDamage,
        actualDamage = threatData.baseDamage * THREAT_SEVERITY[severity].multiplier,
        description = threatData.description,
        defenseTypes = threatData.defenseTypes,
        timestamp = love.timer and love.timer.getTime() or os.clock(),
        status = "active", -- active, mitigated, completed
        mitigationProgress = 0
    }
    
    self.nextThreatId = self.nextThreatId + 1
    
    -- Calculate defense effectiveness
    local defenseEffectiveness = self:calculateDefenseEffectiveness(threat)
    threat.defenseEffectiveness = defenseEffectiveness
    
    -- Add to active threats
    self.activeThreats[threat.id] = threat
    
    -- Publish threat detected event
    self.eventBus:publish("threat_detected", {
        threat = threat,
        defenseEffectiveness = defenseEffectiveness
    })
    
    print("🚨 ThreatSimulation: Generated " .. threat.name .. " (" .. severity .. ")")
    
    return threat
end

-- Select random threat type with realistic weighting
function ThreatSimulation:selectRandomThreatType()
    -- Weight common threats higher, advanced threats lower
    local weights = {
        [THREAT_TYPES.PHISHING] = 30,
        [THREAT_TYPES.MALWARE] = 25,
        [THREAT_TYPES.BRUTEFORCE] = 20,
        [THREAT_TYPES.DDOS] = 10,
        [THREAT_TYPES.RANSOMWARE] = 8,
        [THREAT_TYPES.INSIDER] = 4,
        [THREAT_TYPES.APT] = 2,
        [THREAT_TYPES.ZERODAY] = 1
    }
    
    return self:weightedRandomSelect(weights)
end

-- Select threat severity based on type-specific weights
function ThreatSimulation:selectThreatSeverity(severityWeights)
    local weights = {}
    
    for severity, weight in pairs(severityWeights) do
        if severity == "low" then
            weights["LOW"] = weight
        elseif severity == "medium" then
            weights["MEDIUM"] = weight
        elseif severity == "high" then
            weights["HIGH"] = weight
        elseif severity == "critical" then
            weights["CRITICAL"] = weight
        end
    end
    
    return self:weightedRandomSelect(weights)
end

-- Weighted random selection helper
function ThreatSimulation:weightedRandomSelect(weights)
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for item, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return item
        end
    end
    
    -- Fallback
    local items = {}
    for item in pairs(weights) do
        table.insert(items, item)
    end
    return items[1]
end

-- Calculate defense effectiveness against a threat
function ThreatSimulation:calculateDefenseEffectiveness(threat)
    local baseDefense = 0.1 -- 10% base defense
    if self.statsSystem then
        local derived = self.statsSystem:getDerived()
        baseDefense = baseDefense + (derived.defenseEfficiency or 0) * 0.4
    end
    local upgradeDefense = 0
    
    -- Check security upgrades
    if self.securityUpgrades then
        for _, defenseType in ipairs(threat.defenseTypes) do
            local upgradeCount = self.securityUpgrades:getUpgradeCount(defenseType)
            if upgradeCount > 0 then
                upgradeDefense = upgradeDefense + (upgradeCount * 0.15) -- 15% per relevant upgrade
            end
        end
        
        -- Add general security infrastructure bonus
        local totalThreatReduction = self.securityUpgrades:getTotalThreatReduction()
        upgradeDefense = upgradeDefense + totalThreatReduction
    end
    
    -- Calculate final effectiveness (diminishing returns)
    local offenseAssist = 0
    if self.statsSystem then
        local derived = self.statsSystem:getDerived()
        offenseAssist = (derived.offenseEfficiency or 0) * 0.2
    end
    local totalDefense = baseDefense + upgradeDefense + offenseAssist
    local effectiveness = 1 - math.exp(-totalDefense * 2) -- Exponential curve for diminishing returns
    
    return math.min(effectiveness, 0.98) -- Cap at 98% (never perfect defense)
end

-- Update active threats
function ThreatSimulation:updateActiveThreats(dt)
    local threatsToRemove = {}
    
    for threatId, threat in pairs(self.activeThreats) do
        if threat.status == "active" then
            -- Automatic mitigation progress based on defense effectiveness
            threat.mitigationProgress = threat.mitigationProgress + (threat.defenseEffectiveness * dt * 20)
            
            if threat.mitigationProgress >= 100 then
                -- Threat successfully mitigated
                threat.status = "mitigated"
                self:completeThreat(threat, true)
                table.insert(threatsToRemove, threatId)
            else
                -- Check if threat causes damage (gradual damage over time)
                local damageRate = (1 - threat.defenseEffectiveness) * threat.actualDamage * dt / 10
                if damageRate > 0 then
                    self:applyThreatDamage(threat, damageRate)
                end
            end
        elseif threat.status == "mitigated" or threat.status == "completed" then
            table.insert(threatsToRemove, threatId)
        end
    end
    
    -- Remove completed threats
    for _, threatId in ipairs(threatsToRemove) do
        self.activeThreats[threatId] = nil
    end
end

-- Complete a threat (successfully mitigated or failed)
function ThreatSimulation:completeThreat(threat, mitigated)
    -- Add to history
    table.insert(self.threatHistory, {
        threat = threat,
        mitigated = mitigated,
        timestamp = love.timer and love.timer.getTime() or os.clock()
    })
    
    -- Limit history size
    if #self.threatHistory > 100 then
        table.remove(self.threatHistory, 1)
    end
    
    -- Publish completion event
    self.eventBus:publish("threat_completed", {
        threat = threat,
        mitigated = mitigated
    })
    
    -- Award resources for successful mitigation
    if mitigated then
        local rewardMultiplier = THREAT_SEVERITY[threat.severity].multiplier
        local baseReward = 10
        
        self.resourceManager:addResource("money", baseReward * rewardMultiplier)
        self.resourceManager:addResource("xp", baseReward * rewardMultiplier * 0.5)
        self.resourceManager:addResource("reputation", math.floor(rewardMultiplier))
        
        print("🛡️ ThreatSimulation: Successfully mitigated " .. threat.name)
    else
        print("💥 ThreatSimulation: Failed to mitigate " .. threat.name)
    end
end

-- Apply threat damage
function ThreatSimulation:applyThreatDamage(threat, damage)
    -- Reduce money (business impact)
    local moneyLoss = damage * 2
    self.resourceManager:addResource("money", -moneyLoss)
    
    -- Reduce reputation for high-severity threats
    if threat.severity == "HIGH" or threat.severity == "CRITICAL" then
        self.resourceManager:addResource("reputation", -1)
    end
    
    -- Publish damage event
    self.eventBus:publish("threat_damage_applied", {
        threat = threat,
        damage = damage,
        moneyLoss = moneyLoss
    })
end

-- Update threat mitigation capabilities
function ThreatSimulation:updateThreatMitigation()
    -- Recalculate defense effectiveness for all active threats
    for _, threat in pairs(self.activeThreats) do
        threat.defenseEffectiveness = self:calculateDefenseEffectiveness(threat)
    end
end

-- Get active threats
function ThreatSimulation:getActiveThreats()
    return self.activeThreats
end

-- Get threat history
function ThreatSimulation:getThreatHistory(limit)
    limit = limit or 10
    local history = {}
    local startIndex = math.max(1, #self.threatHistory - limit + 1)
    
    for i = startIndex, #self.threatHistory do
        table.insert(history, self.threatHistory[i])
    end
    
    return history
end

-- Get threat statistics
function ThreatSimulation:getThreatStatistics()
    local stats = {
        totalThreats = #self.threatHistory,
        activeThreats = 0,  -- Fixed typo from activeThreat
        mitigatedThreats = 0,
        failedThreats = 0,
        severityBreakdown = {LOW = 0, MEDIUM = 0, HIGH = 0, CRITICAL = 0}
    }
    
    -- Count active threats
    for _ in pairs(self.activeThreats) do
        stats.activeThreats = stats.activeThreats + 1
    end
    
    -- Analyze history
    for _, entry in ipairs(self.threatHistory) do
        if entry.mitigated then
            stats.mitigatedThreats = stats.mitigatedThreats + 1
        else
            stats.failedThreats = stats.failedThreats + 1
        end
        
        stats.severityBreakdown[entry.threat.severity] = 
            stats.severityBreakdown[entry.threat.severity] + 1
    end
    
    return stats
end

-- Get comprehensive state
function ThreatSimulation:getState()
    return {
        activeThreats = self.activeThreats,
        threatHistory = self.threatHistory,
        nextThreatId = self.nextThreatId,
        threatFrequency = self.threatFrequency
    }
end

-- Load state
function ThreatSimulation:loadState(state)
    if not state then return end
    
    if state.activeThreats then
        self.activeThreats = state.activeThreats
    end
    
    if state.threatHistory then
        self.threatHistory = state.threatHistory
    end
    
    if state.nextThreatId then
        self.nextThreatId = state.nextThreatId
    end
    
    if state.threatFrequency then
        self.threatFrequency = state.threatFrequency
    end
    
    print("🚨 ThreatSimulation: State loaded successfully")
end

-- Initialize method for GameLoop integration
function ThreatSimulation:initialize()
    self.lastThreatTime = love.timer and love.timer.getTime() or os.clock()
    print("🚨 ThreatSimulation: Fortress architecture integration complete")
end

-- Shutdown method for GameLoop integration
function ThreatSimulation:shutdown()
    print("🚨 ThreatSimulation: Shutdown complete")
end

return ThreatSimulation
