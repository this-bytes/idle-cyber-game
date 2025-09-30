-- SOC Stats System - Security Operations Centre Statistical Backbone
-- SOC REFACTOR: Provides unified offense/defense/detection/analysis metrics
-- The missing stats layer that transforms fortress architecture into complete SOC

local SOCStats = {}
SOCStats.__index = SOCStats

-- SOC Capability Categories (the missing backbone)
local CAPABILITY_TYPES = {
    OFFENSE = "offense",           -- Penetration testing, red team capabilities  
    DEFENSE = "defense",           -- Threat mitigation, incident response
    DETECTION = "detection",       -- Monitoring, alerting, threat hunting
    ANALYSIS = "analysis",         -- Forensics, intelligence, research
    COORDINATION = "coordination", -- Team efficiency, resource allocation
    AUTOMATION = "automation"      -- Process efficiency, tool integration
}

-- Stat Tiers for progression scaling
local STAT_TIERS = {
    BASIC = {threshold = 0, multiplier = 1.0, label = "Basic"},
    INTERMEDIATE = {threshold = 50, multiplier = 1.5, label = "Intermediate"}, 
    ADVANCED = {threshold = 100, multiplier = 2.0, label = "Advanced"},
    EXPERT = {threshold = 200, multiplier = 3.0, label = "Expert"},
    ELITE = {threshold = 500, multiplier = 5.0, label = "Elite"}
}

-- Create new SOC stats system
function SOCStats.new(eventBus, resourceManager, securityUpgrades, threatSimulation)
    local self = setmetatable({}, SOCStats)
    
    -- Core dependencies
    self.eventBus = eventBus
    self.resourceManager = resourceManager
    self.securityUpgrades = securityUpgrades
    self.threatSimulation = threatSimulation
    
    -- SOC Capability Stats (the missing backbone)
    self.capabilities = {}
    self.modifiers = {}
    self.history = {}
    
    -- Performance tracking
    self.metrics = {
        incidentsHandled = 0,
        threatsDetected = 0,
        avgResponseTime = 0,
        clientSatisfaction = 100
    }
    
    -- Initialize capabilities
    self:initializeCapabilities()
    
    -- Subscribe to events for stat updates
    self:subscribeToEvents()
    
    return self
end

-- Initialize SOC capability baseline
function SOCStats:initializeCapabilities()
    -- Base SOC capabilities (company starts with minimal SOC)
    for _, capType in pairs(CAPABILITY_TYPES) do
        self.capabilities[capType] = {
            base = 10,           -- Starting capability
            equipment = 0,       -- From security upgrades
            personnel = 0,       -- From specialists
            training = 0,        -- From skill development
            total = 10          -- Calculated total
        }
        self.modifiers[capType] = 1.0
    end  
    
    -- Set initial SOC profile - small consultancy
    self.capabilities[CAPABILITY_TYPES.DEFENSE].base = 15      -- Slightly better at defense
    self.capabilities[CAPABILITY_TYPES.ANALYSIS].base = 12     -- Some analysis capability
    self.capabilities[CAPABILITY_TYPES.OFFENSE].base = 5       -- Limited red team ability
    self.capabilities[CAPABILITY_TYPES.DETECTION].base = 8     -- Basic monitoring
    
    self:recalculateCapabilities()
    print("🛡️ SOC Stats: Initialized capability baseline")
end

-- Subscribe to relevant events that affect SOC stats
function SOCStats:subscribeToEvents()
    -- Security upgrades affect capabilities
    self.eventBus:subscribe("upgrade_purchased", function(data)
        self:updateEquipmentCapabilities()
        self:recalculateCapabilities()
        print("🔧 SOC Stats: Equipment capabilities updated")
    end)
    
    -- Specialist changes affect personnel capabilities  
    self.eventBus:subscribe("specialist_hired", function(data)
        self:updatePersonnelCapabilities()
        self:recalculateCapabilities()
        print("👥 SOC Stats: Personnel capabilities updated")
    end)
    
    -- Threat resolution improves stats
    self.eventBus:subscribe("threat_resolved", function(data)
        self.metrics.incidentsHandled = self.metrics.incidentsHandled + 1
        self:gainExperience(data.threat.type, 1)
        print("📈 SOC Stats: Experience gained from incident resolution")
    end)
    
    -- Threat detection improves detection stats
    self.eventBus:subscribe("threat_detected", function(event)
        local threatObj = event and event.threat
        if not threatObj then
            return
        end

        self.metrics.threatsDetected = self.metrics.threatsDetected + 1
        self:improveCapability("detection", 0.1)
        print("🎯 SOC Stats: Detection capability improved")
    end)
end

-- Update equipment-based capabilities from security upgrades
function SOCStats:updateEquipmentCapabilities()
    if not self.securityUpgrades then return end
    
    -- Reset equipment bonuses
    for _, capType in pairs(CAPABILITY_TYPES) do
        if self.capabilities[capType] then
            self.capabilities[capType].equipment = 0
        end
    end
    
    -- Calculate equipment bonuses from owned upgrades
    local owned = self.securityUpgrades:getAllOwnedUpgrades()
    for upgradeId, count in pairs(owned) do
        local upgradeDef = self.securityUpgrades:getUpgradeDefinition(upgradeId)
        if upgradeDef and upgradeDef.socCapabilities then
            for capType, bonus in pairs(upgradeDef.socCapabilities) do
                if self.capabilities[capType] then
                    self.capabilities[capType].equipment = self.capabilities[capType].equipment + (bonus * count)
                end
            end
        end
    end
end

-- Update personnel-based capabilities (would integrate with specialist system)
function SOCStats:updatePersonnelCapabilities()
    -- Reset personnel bonuses
    for _, capType in pairs(CAPABILITY_TYPES) do
        if self.capabilities[capType] then
            self.capabilities[capType].personnel = 0
        end
    end
    
    -- For now, provide basic personnel scaling
    -- In full implementation, this would query specialist system
    local specialistCount = self.resourceManager:getResource("specialists") or 1
    local personnelBonus = (specialistCount - 1) * 5 -- +5 per additional specialist
    
    self.capabilities[CAPABILITY_TYPES.COORDINATION].personnel = personnelBonus
    self.capabilities[CAPABILITY_TYPES.DEFENSE].personnel = personnelBonus * 0.6
    self.capabilities[CAPABILITY_TYPES.ANALYSIS].personnel = personnelBonus * 0.8
end

-- Improve a specific capability through experience
function SOCStats:improveCapability(capabilityType, amount)
    if not self.capabilities[capabilityType] then return end
    
    self.capabilities[capabilityType].training = self.capabilities[capabilityType].training + amount
    self:recalculateCapabilities()
    
    -- Publish capability improvement event
    self.eventBus:publish("soc_capability_improved", {
        capability = capabilityType,
        amount = amount,
        newTotal = self.capabilities[capabilityType].total
    })
end

-- Gain experience from specific threat types
function SOCStats:gainExperience(threatType, amount)
    -- Map threat types to capabilities that counter them
    local threatCapabilityMap = {
        phishing = {"detection", "analysis"},
        malware = {"defense", "analysis"},
        apt = {"detection", "analysis", "coordination"},
        zeroday = {"defense", "analysis"},
        ransomware = {"defense", "coordination"},
        ddos = {"defense", "automation"},
        social_engineering = {"analysis", "coordination"},
        supply_chain = {"detection", "analysis", "coordination"}
    }
    
    local relevantCaps = threatCapabilityMap[threatType] or {"defense"}
    for _, capType in ipairs(relevantCaps) do
        self:improveCapability(capType, amount * 0.5)
    end
end

-- Recalculate total capabilities from all sources
function SOCStats:recalculateCapabilities()
    for capType, cap in pairs(self.capabilities) do
        -- Total = base + equipment + personnel + training
        cap.total = cap.base + cap.equipment + cap.personnel + cap.training
        
        -- Apply global modifier
        cap.total = cap.total * self.modifiers[capType]
        
        -- Ensure minimum value
        cap.total = math.max(1, cap.total)
    end
end

-- Get current SOC capability rating
function SOCStats:getCapability(capabilityType)
    if not self.capabilities[capabilityType] then return 0 end
    return self.capabilities[capabilityType].total
end

-- Get capability tier for UI display
function SOCStats:getCapabilityTier(capabilityType)
    local total = self:getCapability(capabilityType)
    
    for tierName, tier in pairs(STAT_TIERS) do
        if total >= tier.threshold then
            return tier.label, tier.multiplier
        end
    end
    
    return STAT_TIERS.BASIC.label, STAT_TIERS.BASIC.multiplier
end

-- Get comprehensive SOC status for dashboard
function SOCStats:getSOCStatus()
    local status = {
        capabilities = {},
        metrics = self.metrics,
        overallRating = 0,
        recommendations = {}
    }
    
    -- Calculate capabilities with tiers
    local totalRating = 0
    local capCount = 0
    for _, capType in pairs(CAPABILITY_TYPES) do
        local value = self:getCapability(capType)
        local tier, multiplier = self:getCapabilityTier(capType)
        
        status.capabilities[capType] = {
            value = value,
            tier = tier,
            multiplier = multiplier,
            breakdown = self.capabilities[capType]
        }
        
        totalRating = totalRating + value
        capCount = capCount + 1
    end
    
    status.overallRating = math.floor(totalRating / capCount)
    
    -- Generate recommendations based on weakest areas
    status.recommendations = self:generateRecommendations()
    
    return status
end

-- Generate SOC improvement recommendations
function SOCStats:generateRecommendations()
    local recommendations = {}
    
    -- Find weakest capabilities
    local weakest = nil
    local weakestValue = math.huge
    
    for _, capType in pairs(CAPABILITY_TYPES) do
        local value = self:getCapability(capType)
        if value < weakestValue then
            weakestValue = value
            weakest = capType
        end
    end
    
    -- Generate specific recommendations
    if weakest == "offense" then
        table.insert(recommendations, "Consider penetration testing training to improve red team capabilities")
    elseif weakest == "defense" then
        table.insert(recommendations, "Invest in incident response procedures and defensive tools")
    elseif weakest == "detection" then
        table.insert(recommendations, "Upgrade monitoring systems and threat hunting capabilities")
    elseif weakest == "analysis" then
        table.insert(recommendations, "Enhance forensics tools and threat intelligence analysis")
    elseif weakest == "coordination" then
        table.insert(recommendations, "Improve team communication and incident coordination processes")
    elseif weakest == "automation" then
        table.insert(recommendations, "Automate routine tasks and integrate security tools")
    end
    
    return recommendations
end

-- Update method for real-time stat changes
function SOCStats:update(dt)
    -- Update performance metrics
    self:updateMetrics(dt)
    
    -- Gradual training improvements over time
    self:applyTrainingDecay(dt)
end

-- Update performance metrics
function SOCStats:updateMetrics(dt)
    -- Calculate average response time based on capabilities
    local defenseRating = self:getCapability("defense")
    local coordinationRating = self:getCapability("coordination")
    
    self.metrics.avgResponseTime = math.max(30, 300 - (defenseRating + coordinationRating) * 2)
    
    -- Client satisfaction based on overall performance
    local overallRating = 0
    local count = 0
    for _, capType in pairs(CAPABILITY_TYPES) do
        overallRating = overallRating + self:getCapability(capType)
        count = count + 1
    end
    overallRating = overallRating / count
    
    self.metrics.clientSatisfaction = math.min(100, math.max(0, 50 + overallRating))
end

-- Apply gradual decay to training bonuses (encouraging continuous improvement)
function SOCStats:applyTrainingDecay(dt)
    local decayRate = 0.001 -- Very slow decay
    
    for capType, cap in pairs(self.capabilities) do
        if cap.training > 0 then
            cap.training = math.max(0, cap.training - decayRate * dt)
        end
    end
    
    self:recalculateCapabilities()
end

-- Save state
function SOCStats:saveState()
    return {
        capabilities = self.capabilities,
        modifiers = self.modifiers,
        metrics = self.metrics
    }
end

-- Load state  
function SOCStats:loadState(state)
    if not state then return end
    
    if state.capabilities then
        self.capabilities = state.capabilities
    end
    
    if state.modifiers then
        self.modifiers = state.modifiers
    end
    
    if state.metrics then
        self.metrics = state.metrics
    end
    
    self:recalculateCapabilities()
    print("🛡️ SOC Stats: State loaded successfully")
end

-- Initialize method for GameLoop integration
function SOCStats:initialize()
    self:updateEquipmentCapabilities()
    self:updatePersonnelCapabilities()
    self:recalculateCapabilities()
    print("🛡️ SOC Stats: Fortress architecture integration complete")
end

-- Shutdown method for GameLoop integration
function SOCStats:shutdown()
    print("🛡️ SOC Stats: Shutdown complete")
end

return SOCStats